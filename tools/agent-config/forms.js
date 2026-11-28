"use strict";
// Each view edits a private model. The catalog still owns validation and native-file projection.
window.mountConfig = function mountConfig(doc, root, onChange) {
  const { Editor, parseDocument, parse, modify, applyEdits } =
    window.EditorTools;
  let reader = () => doc.text;
  const cleanups = [];
  const readonly = doc.external;
  const make = (tag, text = "", cls = "") => {
    const n = document.createElement(tag);
    if (text !== "") n.textContent = text;
    if (cls) n.className = cls;
    return n;
  };
  const changed = () => {
    if (!readonly) onChange();
  };
  const json = (value) => JSON.stringify(value, null, 2) + "\n";
  function input(title, value, update, kind = "text") {
    const label = make("label", "", "field"),
      name = make("span", title);
    const box = make(kind === "multiline" ? "textarea" : "input");
    if (kind !== "multiline") box.type = kind;
    box.disabled = readonly;
    box.value = value ?? "";
    box.oninput = () => {
      update(kind === "number" ? Number(box.value) : box.value);
      changed();
    };
    label.append(name, box);
    return label;
  }
  function choose(title, values, selected, update) {
    const label = make("label", "", "field"),
      box = make("select");
    for (const value of values) {
      const option = make("option", value);
      option.value = value;
      box.append(option);
    }
    box.value = selected;
    box.disabled = readonly;
    box.onchange = () => {
      update(box.value);
      changed();
    };
    label.append(make("span", title), box);
    return label;
  }
  function toggle(title, checked, update, disabled = false) {
    const label = make("label", "", "switch-label"),
      box = make("input");
    box.type = "checkbox";
    box.setAttribute("role", "switch");
    box.checked = checked;
    box.disabled = disabled || readonly;
    box.onchange = () => {
      update(box.checked);
      changed();
    };
    label.append(make("span", title), box);
    return label;
  }
  function btn(text, fn, cls = "minor") {
    const b = make("button", text, cls);
    b.type = "button";
    b.onclick = fn;
    b.disabled = readonly;
    return b;
  }
  function rich(host, original, label) {
    const controls = make("div", "", "editor-modes");
    controls.setAttribute("role", "group");
    controls.setAttribute("aria-label", label + "编辑模式");
    const formatted = make("button", "富文本");
    const source = make("button", "源码");
    formatted.type = source.type = "button";
    controls.append(formatted, source);
    const rendered = make("div", "", "richtext");
    const raw = make("textarea", "", "markdown-source");
    raw.setAttribute("aria-label", label + " Markdown 源码");
    raw.readOnly = readonly;
    raw.spellcheck = false;
    raw.hidden = true;
    host.append(controls, rendered, raw);

    let markdown = original;
    let baseline;
    let rte;
    function read() {
      if (!raw.hidden) {
        return raw.value === markdown.replace(/\r\n?/g, "\n")
          ? markdown
          : raw.value;
      }
      if (readonly) return original;
      const current = rte.getMarkdown();
      return current === baseline
        ? markdown
        : current.replace(/\n*$/, "") + (markdown.endsWith("\n") ? "\n" : "");
    }
    function select(rawMode) {
      formatted.setAttribute("aria-pressed", String(!rawMode));
      source.setAttribute("aria-pressed", String(rawMode));
      rendered.hidden = rawMode;
      raw.hidden = !rawMode;
    }
    source.onclick = () => {
      if (!raw.hidden) return;
      markdown = read();
      raw.value = markdown;
      select(true);
      raw.focus();
    };
    formatted.onclick = () => {
      if (raw.hidden) return;
      const next = read();
      if (!readonly && next !== markdown) {
        markdown = next;
        rte.setMarkdown(markdown, false);
      }
      if (!readonly) baseline = rte.getMarkdown();
      select(false);
    };
    raw.oninput = changed;
    select(false);
    if (readonly) {
      const view = Editor.factory({
        el: rendered,
        viewer: true,
        initialValue: original,
        usageStatistics: false,
      });
      cleanups.push(() => view.destroy());
      return read;
    }
    rte = new Editor({
      el: rendered,
      initialEditType: "wysiwyg",
      initialValue: original,
      hideModeSwitch: true,
      usageStatistics: false,
      language: "zh-CN",
      height: "auto",
      minHeight: "230px",
      autofocus: false,
      toolbarItems: [
        ["heading", "bold", "italic", "strike"],
        ["ul", "ol", "task", "quote"],
        ["link", "table", "code", "codeblock"],
      ],
    });
    const editable = rendered.querySelector(
      '.toastui-editor-ww-container [contenteditable="true"]',
    );
    editable?.setAttribute("aria-label", label);
    editable?.setAttribute("role", "textbox");
    editable?.setAttribute("aria-multiline", "true");
    baseline = rte.getMarkdown();
    rte.on("change", changed);
    cleanups.push(() => rte.destroy());
    return read;
  }
  function markdown() {
    const match = /^(---\r?\n)([\s\S]*?)(\r?\n---(?:\r?\n|$))/.exec(doc.text);
    let header = () => "";
    let body = doc.text;
    if (match && doc.group !== "Instructions") {
      const yaml = parseDocument(match[2]);
      if (yaml.errors.length)
        throw Error("无法读取 Markdown 元数据：" + yaml.errors[0].message);
      body = doc.text.slice(match[0].length);
      let metadataChanged = false;
      const fields = make("section", "", "meta-grid");
      for (const [key, value] of Object.entries(yaml.toJS() || {})) {
        const fieldName =
          {
            name: "名称",
            description: "调用说明",
            "user-invocable": "允许手动调用",
            "disable-model-invocation": "仅手动调用",
            "allowed-tools": "可用工具",
          }[key] || key;
        const set = (v) => {
          yaml.set(key, v);
          metadataChanged = true;
        };
        if (typeof value === "boolean")
          fields.append(toggle(fieldName, value, set));
        else if (typeof value === "string")
          fields.append(
            input(
              fieldName,
              value,
              set,
              key === "description" ? "multiline" : "text",
            ),
          );
        else {
          const nested = make("div");
          nested.append(make("h3", fieldName));
          tree(nested, value, [key], (_p, v) => {
            let obj = yaml.toJS();
            const tail = _p.slice(0, -1).reduce((o, k) => o[k], obj);
            tail[_p.at(-1)] = v;
            set(obj[key]);
          });
          fields.append(nested);
        }
      }
      root.append(fields);
      header = () =>
        metadataChanged ? "---\n" + String(yaml) + "---\n" : match[0];
    }
    const host = make("div");
    root.append(host);
    const readBody = rich(
      host,
      body,
      doc.group === "Skills" ? "Skill 正文" : "正文",
    );
    reader = () => header() + readBody();
  }
  function role(data) {
    const card = make("section", "", "role-card");
    card.append(
      make("small", "角色 · " + doc.scope),
      input(
        "角色说明",
        data.description,
        (v) => (data.description = v),
        "multiline",
      ),
      make("h3", "执行指令"),
    );
    const host = make("div");
    card.append(host);
    root.append(card);
    const body = rich(host, data.instructions, "角色执行指令");
    reader = () => json({ ...data, instructions: body() });
  }
  function portableHook(data) {
    root.append(
      choose(
        "触发事件",
        ["Stop", "UserPromptSubmit"],
        data.event,
        (v) => (data.event = v),
      ),
      input("执行命令", data.command, (v) => (data.command = v), "multiline"),
    );
    reader = () => json(data);
  }
  function nativeHooks(data) {
    const agy = doc.scope === "Antigravity";
    const render = () => {
      root.replaceChildren();
      const sources = agy ? Object.entries(data) : [["", data.hooks]];
      for (const [source, events] of sources) {
        if (!events || typeof events !== "object") continue;
        for (const [event, groups] of Object.entries(events)) {
          if (!Array.isArray(groups)) continue;
          const panel = make("section", "", "hook-event");
          const head = make("div", "", "section-head");
          head.append(make("h3", event), make("small", source || doc.scope));
          panel.append(head);
          groups.forEach((group, gi) => {
            const handlers = Array.isArray(group.hooks) ? group.hooks : [group];
            handlers.forEach((hook, hi) => {
              const card = make("div", "", "handler");
              const remove = () => {
                if (handlers === group.hooks) {
                  handlers.splice(hi, 1);
                  if (!handlers.length) groups.splice(gi, 1);
                } else groups.splice(gi, 1);
                if (!groups.length) delete events[event];
                render();
                changed();
              };
              const title = make("div", "", "section-head");
              title.append(
                make(
                  "b",
                  hook.type === "command" ? "执行命令" : hook.type || "处理器",
                ),
                btn("移除", remove),
              );
              card.append(title);
              if ("command" in hook)
                card.append(
                  input(
                    "Shell 命令",
                    hook.command,
                    (v) => (hook.command = v),
                    "multiline",
                  ),
                );
              if (handlers === group.hooks)
                card.append(
                  input("匹配工具", group.matcher || "", (v) => {
                    if (v) group.matcher = v;
                    else delete group.matcher;
                  }),
                );
              for (const [key, value] of Object.entries(hook))
                if (!["command", "type", "matcher", "hooks"].includes(key))
                  tree(card, value, [key], (path, v) => assign(hook, path, v));
              panel.append(card);
            });
          });
          root.append(panel);
        }
      }
      const addForm = make("div", "", "add-hook");
      let eventName = agy ? "PreInvocation" : "PreToolUse";
      const options = agy
        ? ["PreInvocation", "PreToolUse", "PostToolUse", "Stop"]
        : [
            "PreToolUse",
            "PostToolUse",
            "SessionStart",
            "UserPromptSubmit",
            "PermissionRequest",
            "Stop",
          ];
      addForm.append(
        choose("添加事件处理器", options, eventName, (v) => (eventName = v)),
        btn("＋ 添加命令", () => {
          const events = agy
            ? (data["agent-config"] ??= {})
            : (data.hooks ??= {});
          (events[eventName] ??= []).push(
            agy
              ? { type: "command", command: "true" }
              : { hooks: [{ type: "command", command: "true" }] },
          );
          render();
          changed();
        }),
      );
      root.append(addForm);
    };
    render();
    reader = () => json(data);
  }
  function assign(obj, path, value) {
    const parent = path.slice(0, -1).reduce((o, k) => o[k], obj);
    parent[path.at(-1)] = value;
  }
  // Native settings retain their scalar types and JSONC comments at unrelated paths.
  function tree(parent, value, path, update) {
    const title = String(path.at(-1) ?? "");
    if (value !== null && typeof value === "object") {
      const section = make("details", "", "nested");
      const keys = Object.keys(value);
      section.append(make("summary", title + " · " + keys.length));
      for (const key of keys)
        tree(
          section,
          value[key],
          [...path, Array.isArray(value) ? Number(key) : key],
          update,
        );
      parent.append(section);
    } else if (typeof value === "boolean")
      parent.append(toggle(title, value, (v) => update(path, v)));
    else if (value === null) parent.append(make("p", title + " · 未设置"));
    else
      parent.append(
        input(
          title,
          value,
          (v) => update(path, v),
          typeof value === "number" ? "number" : "text",
        ),
      );
  }
  function settings() {
    const errors = [],
      data = parse(doc.text, errors, { allowTrailingComma: true });
    if (errors.length || !data) {
      root.append(
        make(
          "p",
          doc.text.startsWith("当前无法") ? doc.text : "无法读取设置。",
        ),
      );
      return;
    }
    if (doc.fields) {
      for (const key of doc.fields)
        root.append(
          input(key, data[key], (v) => {
            if (v) data[key] = v;
            else delete data[key];
          }),
        );
      reader = () => json(data);
      return;
    }
    let source = doc.text;
    for (const [key, value] of Object.entries(data)) {
      tree(root, value, [key], (path, v) => {
        source = applyEdits(
          source,
          modify(source, path, v, {
            formattingOptions: { insertSpaces: true, tabSize: 2 },
          }),
        );
      });
    }
    reader = () => source;
  }
  function pluginPanel(value) {
    const live = doc.live || {},
      rows = new Map();
    if (Array.isArray(live)) {
      for (const row of live) rows.set(row.id, row);
    } else
      for (const [id, state] of Object.entries(live))
        rows.set(id, {
          id,
          enabled: typeof state === "boolean" ? state : state?.enabled,
        });
    if (doc.scope === "DeepSeek") {
      for (const [profile, names] of Object.entries(live)) {
        const card = make("section", "", "plugin-card");
        card.append(make("h3", profile));
        for (const n of names) card.append(make("p", n));
        root.append(card);
      }
      if (!Object.keys(live).length)
        root.append(make("p", "没有可显示的 profile。"));
      return;
    }
    const panel = make("div", "", "plugin-list");
    const search = make("input");
    search.type = "search";
    search.placeholder = "筛选插件名称或来源…";
    search.setAttribute("aria-label", "筛选插件名称或来源");
    root.append(search, panel);
    const render = () => {
      panel.replaceChildren();
      const ids = new Set([
        ...rows.keys(),
        ...value.keep,
        ...Object.keys(value.states),
      ]);
      const isKept = (id) =>
        value.keep.includes(id) || value.keep.includes(id.split("@")[0]);
      const sorted = [...ids].sort(
        (a, b) => Number(isKept(b)) - Number(isKept(a)) || a.localeCompare(b),
      );
      for (const id of sorted) {
        if (!id.toLowerCase().includes(search.value.trim().toLowerCase()))
          continue;
        const row = rows.get(id);
        const card = make("div", "", "plugin-card");
        const top = make("div", "", "plugin-title");
        top.append(make("b", id.split("@")[0]));
        const status =
          row?.enabled === true
            ? "已启用"
            : row?.enabled === false
              ? "已停用"
              : "未报告";
        top.append(
          make("span", status, "pill " + (row?.enabled ? "active" : "")),
        );
        card.append(top);
        const scopeDetail = [
          id.includes("@") ? id.split("@")[1] : "",
          row?.scope,
        ]
          .filter(Boolean)
          .join(" · ");
        if (scopeDetail) card.append(make("small", scopeDetail));
        const managed = row?.scope === "managed";
        const tools = make("div", "", "plugin-controls");
        const bare = id.split("@")[0];
        const inherited = bare !== id && value.keep.includes(bare);
        if (!id.endsWith("@builtin") || doc.scope !== "Claude Code")
          tools.append(
            toggle(
              "保留",
              isKept(id),
              (on) => {
                if (on && !isKept(id)) value.keep.push(id);
                if (!on) {
                  value.keep = value.keep.filter((n) => n !== id);
                  for (const [k] of Object.entries(value.states))
                    if (!isKept(k)) value.states[k] = false;
                }
                render();
              },
              managed || inherited,
            ),
          );
        if (doc.scope !== "Grok")
          tools.append(
            toggle(
              "启用",
              managed
                ? !!row?.enabled
                : (value.states[id] ?? row?.enabled ?? false),
              (on) => {
                if (on && !isKept(id) && !id.endsWith("@builtin"))
                  value.keep.push(id);
                value.states[id] = on;
                render();
              },
              managed ||
                (doc.scope === "Claude Code" && id.endsWith("@builtin")) ||
                (doc.scope === "Codex" && !id.includes("@")),
            ),
          );
        if (inherited) tools.append(make("small", "按名称保留"));
        if (managed) tools.append(make("small", "组织管理"));
        card.append(tools);
        panel.append(card);
      }
      if (!panel.childElementCount)
        panel.append(
          make("p", search.value ? "没有匹配的插件。" : "尚无插件。", "empty"),
        );
    };
    search.oninput = render;
    render();
    let newId = "";
    const add = make("div", "", "add-hook");
    add.append(
      input("添加到保留名单", newId, (v) => (newId = v)),
      btn("添加", () => {
        const id = newId.trim();
        if (!id || value.keep.includes(id)) return;
        value.keep.push(id);
        newId = "";
        add.querySelector("input").value = "";
        render();
        changed();
      }),
    );
    root.append(add);
    if (doc.inventoryError)
      root.prepend(
        make("p", "读取本机插件状态失败：" + doc.inventoryError, "warning"),
      );
    reader = () => json(value);
  }
  root.replaceChildren();
  if (doc.id.startsWith("panel:")) pluginPanel(JSON.parse(doc.text));
  else if (doc.id.endsWith(".md") || doc.id.startsWith("nix:")) markdown();
  else if (doc.group === "Agents") role(JSON.parse(doc.text));
  else if (doc.group === "Hooks") {
    const data = JSON.parse(doc.text);
    if (doc.id.startsWith("agents/profiles/")) portableHook(data);
    else nativeHooks(data);
  } else settings();
  const initial = reader();
  return {
    text() {
      const value = reader();
      return value === initial ? doc.text : value;
    },
    destroy() {
      for (const fn of cleanups) fn();
    },
  };
};
