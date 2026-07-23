#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, readFileSync, writeFileSync, unlinkSync } from "fs";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    port: { type: "string", default: "0" },
    dir: { type: "string" },
    "pid-file": { type: "string", default: "/tmp/view-plans.pid" },
  },
  strict: true,
});

const port = parseInt(values.port!, 10);
const dir = values.dir;
const pidFile = values["pid-file"]!;

if (!dir) {
  console.error("Error: --dir is required");
  process.exit(1);
}

if (!existsSync(dir)) {
  console.error(`Error: directory does not exist: ${dir}`);
  process.exit(1);
}

// Kill existing process if PID file exists
if (existsSync(pidFile)) {
  const oldPid = parseInt(readFileSync(pidFile, "utf-8").trim(), 10);
  if (!isNaN(oldPid)) {
    try {
      process.kill(oldPid, "SIGTERM");
    } catch {
      // Process already dead — ignore
    }
  }
  unlinkSync(pidFile);
}

const server = Bun.serve({
  port,
  async fetch(req) {
    const url = new URL(req.url);
    let pathname = url.pathname === "/" ? "/index.html" : url.pathname;
    const filePath = `${dir}${pathname}`;

    const file = Bun.file(filePath);
    if (await file.exists()) {
      return new Response(file);
    }
    return new Response("Not Found", { status: 404 });
  },
});

// Write PID file
writeFileSync(pidFile, String(process.pid));

console.log(`Serving at http://localhost:${server.port}`);

// Clean up on exit
function cleanup() {
  try {
    if (existsSync(pidFile)) {
      unlinkSync(pidFile);
    }
  } catch {
    // Best effort
  }
  process.exit(0);
}

process.on("SIGINT", cleanup);
process.on("SIGTERM", cleanup);
