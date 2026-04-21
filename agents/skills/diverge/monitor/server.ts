// Diverge Monitor — Bun SSE server.
//
// Tails events.jsonl, discovers and watches the task directory, and
// broadcasts snapshot + deltas to connected clients via Server-Sent Events.
//
// Zero npm dependencies. Uses only Bun and node:fs built-ins.

import { watch, existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, dirname } from "node:path";

// -------------------------- types --------------------------

interface DivergEvent {
  ts: string;
  type: string;
  event: string;
  data: Record<string, unknown>;
}

interface TaskState {
  id: string;
  subject: string;
  status: string;
  owner: string;
  updatedAt: string;
}

interface MonitorState {
  meta: {
    goalSlug: string;
    direction: string;
    worktreePath: string;
    port: number;
    startedAt: string;
  };
  tasks: Record<string, TaskState>;
  events: DivergEvent[];
  completedAt: string | null;
  lastEventTs: number;
  emissionGap: boolean;
}

interface Cli {
  monitorDir: string;
  taskRoot: string;
  port: number;
  goalSlug: string;
  direction: string;
  worktree: string;
  gapThresholdMs: number;
}

// -------------------------- cli --------------------------

function parseArgs(argv: string[]): Cli {
  const env = (process as unknown as { env: Record<string, string | undefined> }).env;
  const home = env.HOME ?? "";
  const cli: Cli = {
    monitorDir: "",
    taskRoot: `${home}/.claude/tasks`,
    port: 0,
    goalSlug: "",
    direction: "",
    worktree: "",
    gapThresholdMs: 30_000,
  };
  for (let i = 2; i < argv.length; i++) {
    const k = argv[i];
    const v = argv[i + 1];
    switch (k) {
      case "--monitor-dir": cli.monitorDir = v; i++; break;
      case "--task-root": cli.taskRoot = v; i++; break;
      case "--port": cli.port = Number(v); i++; break;
      case "--goal-slug": cli.goalSlug = v; i++; break;
      case "--direction": cli.direction = v; i++; break;
      case "--worktree": cli.worktree = v; i++; break;
      case "--gap-threshold-ms": cli.gapThresholdMs = Number(v); i++; break;
    }
  }
  if (!cli.monitorDir || !cli.goalSlug || !cli.direction || !cli.worktree) {
    process.stderr.write(
      "usage: server.ts --monitor-dir <path> --goal-slug <s> --direction <s> --worktree <s> [--task-root <path>] [--port <n>] [--gap-threshold-ms <n>]\n"
    );
    process.exit(2);
  }
  return cli;
}

// -------------------------- server --------------------------

const cli = parseArgs(process.argv);
const startedAt = new Date().toISOString();

const state: MonitorState = {
  meta: {
    goalSlug: cli.goalSlug,
    direction: cli.direction,
    worktreePath: cli.worktree,
    port: 0,
    startedAt,
  },
  tasks: {},
  events: [],
  completedAt: null,
  lastEventTs: Date.now(),
  emissionGap: false,
};

const eventsPath = join(cli.monitorDir, "events.jsonl");
let lastReadOffset = 0;
let incompleteBuffer = "";

const clients = new Set<ReadableStreamDefaultController<Uint8Array>>();
const encoder = new TextEncoder();

function sseFrame(event: string, data: unknown): Uint8Array {
  return encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
}

function broadcast(event: string, data: unknown): void {
  const frame = sseFrame(event, data);
  for (const c of clients) {
    try { c.enqueue(frame); } catch { /* client gone */ }
  }
}

function pushEvent(ev: DivergEvent, bumpTs: boolean): void {
  state.events.push(ev);
  if (ev.type === "system" && ev.event === "run_ended") {
    state.completedAt = ev.ts;
  }
  // Track tasks from both event-stream and file-watcher sources.
  if (ev.type === "task" && ev.data && typeof ev.data === "object") {
    const d = ev.data as Record<string, unknown>;
    const id = d.taskId != null ? String(d.taskId) : "";
    if (id) {
      const prev = state.tasks[id];
      const next: TaskState = {
        id,
        subject: d.subject != null ? String(d.subject) : (prev?.subject ?? ""),
        status: d.status != null ? String(d.status) : (prev?.status ?? ""),
        owner: d.owner != null ? String(d.owner) : (prev?.owner ?? ""),
        updatedAt: ev.ts,
      };
      state.tasks[id] = next;
    }
  }
  if (bumpTs) {
    state.lastEventTs = Date.now();
    if (state.emissionGap) {
      state.emissionGap = false;
      const resolved: DivergEvent = {
        ts: new Date().toISOString(),
        type: "system",
        event: "emission_gap_resolved",
        data: {},
      };
      state.events.push(resolved);
      broadcast("delta", resolved);
    }
  }
  broadcast("delta", ev);
}

// -------------------------- jsonl tailing --------------------------

function readEventsFile(): void {
  if (!existsSync(eventsPath)) return;
  let stat;
  try { stat = statSync(eventsPath); } catch { return; }
  if (stat.size < lastReadOffset) {
    // Truncated — reset
    lastReadOffset = 0;
    incompleteBuffer = "";
  }
  if (stat.size === lastReadOffset) return;
  let text = "";
  try {
    const buf = readFileSync(eventsPath);
    text = buf.subarray(lastReadOffset).toString("utf8");
  } catch {
    return;
  }
  lastReadOffset = stat.size;
  const combined = incompleteBuffer + text;
  const lastNl = combined.lastIndexOf("\n");
  if (lastNl < 0) {
    incompleteBuffer = combined;
    return;
  }
  const ready = combined.slice(0, lastNl);
  incompleteBuffer = combined.slice(lastNl + 1);
  for (const line of ready.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      const ev = JSON.parse(trimmed) as DivergEvent;
      pushEvent(ev, true);
    } catch {
      // malformed — skip silently
    }
  }
}

// -------------------------- task dir --------------------------

let taskDir: string | null = null;
let taskWatcherAbort: { close: () => void } | null = null;

function discoverTaskDir(): void {
  if (taskDir) return;
  const breadcrumb = join(cli.monitorDir, "task-dir");
  if (existsSync(breadcrumb)) {
    try {
      const p = readFileSync(breadcrumb, "utf8").trim();
      if (p && existsSync(p)) {
        taskDir = p;
        startWatchingTasks();
        return;
      }
    } catch { /* ignore */ }
  }
  if (!existsSync(cli.taskRoot)) return;
  try {
    const startedMs = new Date(state.meta.startedAt).getTime();
    let best: { path: string; mtime: number } | null = null;
    for (const name of readdirSync(cli.taskRoot)) {
      const full = join(cli.taskRoot, name);
      let s;
      try { s = statSync(full); } catch { continue; }
      if (!s.isDirectory()) continue;
      const m = s.mtimeMs;
      if (m < startedMs - 60_000) continue;
      if (!best || m > best.mtime) best = { path: full, mtime: m };
    }
    if (best) {
      taskDir = best.path;
      startWatchingTasks();
    }
  } catch { /* ignore */ }
}

function readTaskFiles(): void {
  if (!taskDir || !existsSync(taskDir)) return;
  let files: string[];
  try { files = readdirSync(taskDir); } catch { return; }
  for (const name of files) {
    if (!name.endsWith(".json")) continue;
    const full = join(taskDir, name);
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(readFileSync(full, "utf8"));
    } catch {
      continue; // mid-write
    }
    const id = String(parsed.id ?? name.replace(/\.json$/, ""));
    const next: TaskState = {
      id,
      subject: String(parsed.subject ?? ""),
      status: String(parsed.status ?? ""),
      owner: String(parsed.owner ?? ""),
      updatedAt: new Date().toISOString(),
    };
    const prev = state.tasks[id];
    if (!prev || prev.status !== next.status || prev.subject !== next.subject || prev.owner !== next.owner) {
      state.tasks[id] = next;
      const ev: DivergEvent = {
        ts: next.updatedAt,
        type: "task",
        event: "task_file_sync",
        data: { taskId: id, subject: next.subject, status: next.status, owner: next.owner },
      };
      pushEvent(ev, true);
    }
  }
}

function startWatchingTasks(): void {
  if (!taskDir) return;
  try {
    const w = watch(taskDir, { persistent: false }, () => readTaskFiles());
    taskWatcherAbort = { close: () => { try { w.close(); } catch { /* ignore */ } } };
    readTaskFiles();
  } catch { /* ignore */ }
}

// -------------------------- init watch --------------------------

// Initial read
readEventsFile();

try {
  watch(cli.monitorDir, { persistent: false }, (_event, fname) => {
    if (fname === "events.jsonl" || fname === null) readEventsFile();
    if (fname === "task-dir") discoverTaskDir();
  });
} catch { /* ignore */ }

discoverTaskDir();

// -------------------------- heartbeat + gap --------------------------

const heartbeatTimer = setInterval(() => {
  broadcast("heartbeat", { ts: new Date().toISOString() });
}, 5000);

const gapTimer = setInterval(() => {
  const silentMs = Date.now() - state.lastEventTs;
  const hasInProgress = Object.values(state.tasks).some((t) => t.status === "in_progress");
  if (
    silentMs > cli.gapThresholdMs &&
    state.completedAt === null &&
    hasInProgress &&
    !state.emissionGap
  ) {
    state.emissionGap = true;
    const ev: DivergEvent = {
      ts: new Date().toISOString(),
      type: "system",
      event: "emission_gap",
      data: { silentSeconds: Math.round(silentMs / 1000) },
    };
    state.events.push(ev);
    broadcast("delta", ev);
  }
}, 5000);

// -------------------------- http --------------------------

const indexHtmlPath = join(import.meta.dir, "index.html");

function notFound(): Response {
  return new Response("Not Found", { status: 404 });
}

const server = Bun.serve({
  port: cli.port,
  fetch(req) {
    const url = new URL(req.url);
    if (req.method !== "GET") return notFound();
    if (url.pathname === "/") {
      return new Response(Bun.file(indexHtmlPath), {
        headers: { "Content-Type": "text/html; charset=utf-8" },
      });
    }
    if (url.pathname === "/events") {
      const body = new ReadableStream<Uint8Array>({
        start(controller) {
          clients.add(controller);
          controller.enqueue(sseFrame("snapshot", state));
        },
        cancel(controller) {
          clients.delete(controller);
        },
      });
      return new Response(body, {
        headers: {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Connection": "keep-alive",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }
    if (url.pathname === "/state") {
      return new Response(JSON.stringify(state), {
        headers: { "Content-Type": "application/json" },
      });
    }
    return notFound();
  },
});

state.meta.port = server.port;

// meta.json for launcher
try {
  Bun.write(
    join(cli.monitorDir, "meta.json"),
    JSON.stringify({
      goalSlug: cli.goalSlug,
      direction: cli.direction,
      worktreePath: cli.worktree,
      port: server.port,
      pid: process.pid,
      startedAt,
    }) + "\n"
  );
} catch { /* ignore */ }

// Announce port — launcher greps for this
process.stdout.write(`PORT:${server.port}\n`);
process.stderr.write("Monitor server ready\n");

// -------------------------- shutdown --------------------------

function shutdown(): void {
  clearInterval(heartbeatTimer);
  clearInterval(gapTimer);
  for (const c of clients) {
    try { c.close(); } catch { /* ignore */ }
  }
  clients.clear();
  if (taskWatcherAbort) {
    try { taskWatcherAbort.close(); } catch { /* ignore */ }
  }
  try { server.stop(); } catch { /* ignore */ }
  process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
