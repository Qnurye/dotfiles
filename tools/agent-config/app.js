"use strict";
const $ = (id) => document.getElementById(id);
const token =
  location.hash.slice(1) || sessionStorage.getItem("agent-config-token");
if (token) sessionStorage.setItem("agent-config-token", token);
history.replaceState(null, "", location.pathname);
const labels = {
  Instructions: "提示词",
  Hooks: "Hooks",
  Skills: "Skills",
  Agents: "Agents",
  Plugins: "Plugins",
  Settings: "客户端设置",
};
const hints = {
  Instructions:
    "创建该客户端的提示词副本。Codex、Claude、Antigravity、Zed 使用独立文件；Grok 和 DeepSeek 会叠加自己的全局提示词。Grok 还会读取 Claude 的兼容配置。",
  Hooks:
    "共享事件支持 Stop 和 UserPromptSubmit，写入 Claude、Codex 和 Antigravity 的原生配置。Grok 读取 Claude 兼容 hook。Codex 可能要求重新信任新命令。",
  Agents:
    "编辑角色说明和指令。共享定义生成 Claude / Grok、Codex 和 Antigravity 所需的原生文件。",
  Skills:
    "配置将写入所选范围的原生 skill 目录。Grok 同时索引 Claude 的兼容目录。",
};
let inventory,
  scope = "Universal",
  group = "Instructions",
  doc = null,
  mode = "preview",
  dirty = false,
  busy = false,
  sequence = 0;
let diff = [],
  timer;
const el = (tag, text, cls) => {
  const n = document.createElement(tag);
  n.textContent = text;
  if (cls) n.className = cls;
  return n;
};
async function api(name, data = {}) {
  const response = await fetch("/api/" + name, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Agent-Token": token || "",
    },
    body: JSON.stringify(data),
  });
  if (!response.headers.get("Content-Type")?.includes("application/json"))
    throw Error("连接已失效，请使用终端输出的完整地址重新打开。");
  const result = await response.json();
  if (!response.ok) throw Error(result.error);
  return result;
}
function notify(message) {
  $("notice").textContent = message;
}
function action(fn) {
  return async (e) => {
    try {
      await fn(e);
    } catch (err) {
      notify(err.message);
      if ($("diffDialog").open) $("diffError").textContent = err.message;
      if ($("createDialog").open) $("hint").textContent = err.message;
    }
  };
}
function leave() {
  if (busy) return false;
  if (dirty && !confirm("放弃尚未保存的修改？")) return false;
  clearTimeout(timer);
  dirty = false;
  return true;
}
function button(text, on, fn) {
  const b = el("button", text, on ? "on" : "");
  b.onclick = action(fn);
  return b;
}
function candidates() {
  const matches = inventory.items.filter(
    (i) =>
      i.group === group &&
      (scope === "Universal"
        ? i.scope === "Universal" ||
          ["Hooks", "Plugins", "Settings"].includes(group)
        : i.scope === scope ||
          i.scope === "Universal" ||
          (scope === "Grok" && i.scope === "Claude Code" && group === "Hooks")),
  );
  return matches.sort(
    (a, b) => Number(b.scope === scope) - Number(a.scope === scope),
  );
}
function chrome() {
  $("heading").textContent = scope;
  $("crumb").textContent = scope === "Universal" ? "共享配置" : "Coding agent";
  $("branch").textContent = inventory.branch || "detached HEAD";
  $("repo").textContent = inventory.path;
  $("scopes").replaceChildren(
    ...Object.keys(inventory.counts).map((n) =>
      button(n, n === scope, async () => {
        if (!leave()) return;
        scope = n;
        $("filter").value = "";
        await selectFirst();
      }),
    ),
  );
  $("groups").replaceChildren(
    ...inventory.groups.map((n) =>
      button(labels[n], n === group, async () => {
        if (!leave()) return;
        group = n;
        $("filter").value = "";
        await selectFirst();
      }),
    ),
  );
  $("new").disabled = !inventory.create[scope].length;
  const matches = candidates().filter((i) =>
    (i.title + " " + i.scope)
      .toLowerCase()
      .includes($("filter").value.toLowerCase()),
  );
  $("files").replaceChildren(
    ...matches.map((i) =>
      button(
        i.title + (i.scope !== scope ? " · " + i.scope : ""),
        doc?.id === i.id,
        async () => {
          if (leave()) await openDoc(i.id);
        },
      ),
    ),
  );
  if (!matches.length) $("files").append(el("p", "没有匹配的配置", "empty"));
}
function preview() {
  const box = $("render");
  box.replaceChildren();
  if (!doc) {
    box.textContent = "当前范围还没有这类配置。";
    return;
  }
  const text = $("editor").value;
  if (!doc.id.endsWith(".md") && !doc.id.startsWith("nix:")) {
    box.append(el("pre", text));
    return;
  }
  let code = null;
  for (const line of text.split("\n")) {
    if (line.startsWith("```")) {
      if (code) {
        box.append(code);
        code = null;
      } else code = el("pre", "");
      continue;
    }
    if (code) {
      code.textContent += line + "\n";
      continue;
    }
    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) box.append(el("h" + h[1].length, h[2]));
    else if (line) box.append(el("p", line));
  }
  if (code) box.append(code);
}
function paint() {
  chrome();
  const readOnly = !doc || doc.external;
  $("title").textContent = doc?.title || labels[group];
  $("path").textContent = doc?.id || "";
  const inherited =
    scope !== "Universal" && doc?.scope === "Universal" && !doc.external;
  $("note").textContent = [
    doc?.note,
    inherited
      ? "当前显示共享源。保存会影响使用它的客户端；独享配置请选「新建配置」。"
      : "",
  ]
    .filter(Boolean)
    .join(" · ");
  $("state").textContent = readOnly
    ? doc
      ? "只读"
      : ""
    : dirty
      ? "尚未保存"
      : "已保存";
  $("editor").hidden = mode === "preview" || readOnly;
  $("render").hidden = mode === "edit" && !readOnly;
  $("panes").classList.toggle("split", mode === "split" && !readOnly);
  $("split").classList.toggle("on", mode === "split");
  $("split").disabled = readOnly;
  $("save").disabled = readOnly || !dirty || busy;
  $("edit").disabled = readOnly;
  $("edit").classList.toggle("on", mode === "edit");
  $("preview").classList.toggle("on", mode === "preview");
  $("apply").hidden = doc?.group !== "Plugins" || readOnly;
  preview();
}
async function openDoc(id) {
  const seq = ++sequence;
  let next = id ? await api("read", { id }) : null;
  if (seq !== sequence) return;
  doc = next;
  dirty = false;
  $("editor").value = doc?.text || "";
  if (!doc || doc.external) mode = "preview";
  paint();
}
async function selectFirst() {
  await openDoc(candidates()[0]?.id);
}
async function reload() {
  inventory = await api("list");
}
async function save() {
  if (!dirty || busy || !doc) return;
  busy = true;
  const text = $("editor").value;
  try {
    doc = await api("save", { id: doc.id, text, version: doc.version });
    dirty = $("editor").value !== doc.text;
    notify("已保存到工作树");
  } finally {
    busy = false;
    paint();
  }
}
$("editor").oninput = () => {
  if (mode === "split") preview();
  dirty = $("editor").value !== doc.text;
  $("state").textContent = dirty ? "尚未保存" : "已保存";
  $("save").disabled = !dirty;
  clearTimeout(timer);
  if ($("autosave").checked) timer = setTimeout(action(save), 950);
};
$("autosave").onchange = () => {
  clearTimeout(timer);
  if ($("autosave").checked && dirty) timer = setTimeout(action(save), 950);
};
$("filter").oninput = chrome;
$("edit").onclick = () => {
  mode = "edit";
  paint();
  $("editor").focus();
};
$("split").onclick = () => {
  mode = "split";
  paint();
  $("editor").focus();
};
$("preview").onclick = () => {
  mode = "preview";
  paint();
};
$("save").onclick = action(save);
window.addEventListener("beforeunload", (e) => {
  if (dirty) {
    e.preventDefault();
    e.returnValue = "";
  }
});
window.addEventListener(
  "keydown",
  action(async (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === "s") {
      e.preventDefault();
      await save();
    }
  }),
);
$("new").onclick = () => {
  if (busy) return;
  $("scopeHint").textContent = scope;
  $("kind").replaceChildren(
    ...inventory.create[scope].map((k) => {
      const o = el("option", labels[k]);
      o.value = k;
      return o;
    }),
  );
  if (inventory.create[scope].includes(group)) $("kind").value = group;
  $("slug").value = "";
  $("kind").onchange();
  $("createDialog").showModal();
};
$("kind").onchange = () => {
  const k = $("kind").value;
  $("nameLabel").hidden = k === "Instructions";
  $("slug").required = k !== "Instructions";
  $("hint").textContent = hints[k];
};
$("creation").onsubmit = action(async (e) => {
  e.preventDefault();
  if (!leave()) return;
  const k = $("kind").value;
  const n = await api("create", {
    scope,
    group: k,
    name: k === "Instructions" ? "instructions" : $("slug").value,
  });
  $("createDialog").close();
  group = k;
  mode = "edit";
  await reload();
  await openDoc(n.id);
});
for (const b of document.querySelectorAll(".cancel"))
  b.onclick = () => b.closest("dialog").close();
$("review").onclick = action(async () => {
  if (dirty) await save();
  if (busy) return;
  diff = await api("diff");
  const list = $("diffs");
  list.replaceChildren();
  $("diffError").textContent = "";
  for (const f of diff) {
    const detail = el("details", "");
    const summary = el("summary", "");
    const check = el("input", "");
    check.type = "checkbox";
    check.value = f.path;
    check.checked = f.edited;
    summary.append(check, document.createTextNode(f.path));
    detail.append(summary, el("pre", f.diff));
    list.append(detail);
  }
  if (!diff.length) list.append(el("p", "没有待提交的配置修改。"));
  $("commit").disabled = !diff.length;
  $("diffDialog").showModal();
});
$("commit").onclick = action(async () => {
  const selected = new Set(
    [...$("diffs").querySelectorAll("input:checked")].map((n) => n.value),
  );
  if (!selected.size) throw Error("请勾选要提交的文件");
  $("commit").disabled = true;
  $("diffError").textContent = "Worktrunk 正在提交…";
  try {
    const versions = Object.fromEntries(
      diff.filter((f) => selected.has(f.path)).map((f) => [f.path, f.version]),
    );
    const sha = await api("commit", { versions });
    $("diffDialog").close();
    notify("已提交 " + sha);
  } finally {
    $("commit").disabled = false;
  }
});
$("apply").onclick = action(async () => {
  if (
    !confirm(
      "应用所有客户端的插件保留名单？名单以外的插件将按 setup.py 策略停用或归档。",
    )
  )
    return;
  await save();
  await api("plugins");
  notify("插件策略已应用");
});
action(async () => {
  await reload();
  await selectFirst();
})();
