"""Repository-backed documents and their native agent destinations."""

import hashlib
import json
import os
import re
import stat
import subprocess
import tempfile
import tomllib
from pathlib import Path

from native import PREFERENCES, plugins, preferences, update_native

CLIENTS = ["Claude Code", "Codex", "Antigravity", "Grok", "Zed", "DeepSeek"]
IDS = dict(zip(CLIENTS, ["claude", "codex", "antigravity", "grok", "zed", "deepseek"]))
SHARED = "Universal"
PLUGIN_CLIENTS = ("Claude Code", "Codex", "Grok", "Antigravity", "DeepSeek")
MANIFEST = "tools/symlink-guard/links.json"
PROMPT = "agents/AGENTS.md"
HOOK_FILES = {
    "Claude Code": "agents/claude-settings.json",
    "Codex": "agents/codex-hooks.json",
    "Antigravity": "agents/antigravity-hooks.json",
}
PROMPT_PATHS = dict(
    zip(
        CLIENTS,
        [
            ".claude/CLAUDE.md",
            ".codex/AGENTS.md",
            ".gemini/GEMINI.md",
            ".grok/AGENTS.md",
            ".config/zed/AGENTS.md",
            ".dsh/AGENTS.md",
        ],
    )
)
SKILL_PATHS = {
    "Claude Code": ".claude/skills",
    "Codex": ".codex/skills",
    "Antigravity": ".gemini/config/skills",
    "Grok": ".grok/skills",
    "DeepSeek": ".dsh/skills",
}
AGENT_PATHS = {
    "Claude Code": ".claude/agents",
    "Codex": ".codex/agents",
    "Antigravity": ".gemini/config/agents",
    "Grok": ".grok/agents",
}
CATEGORIES = ["Instructions", "Hooks", "Skills", "Agents", "Plugins", "Settings"]
SLUG = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*\Z")


def pretty(data):
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as out:
        tmp = Path(out.name)
        out.write(text.encode())
    try:
        tmp.chmod(stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600)
        tmp.replace(path)
    finally:
        tmp.unlink(missing_ok=True)


class Catalog:
    def __init__(self, repo, home):
        self.repo, self.home = repo.resolve(), home.resolve()
        self.touched = set()

    def path(self, rel):
        path = self.repo / rel
        if not path.resolve().is_relative_to(self.repo):
            raise ValueError("配置路径已移出仓库")
        return path

    def manifest(self):
        return json.loads(self.path(MANIFEST).read_text())

    def items(self):
        items = {}

        def add(rel, title, group, scope, note="", external=False):
            items[rel] = dict(
                id=rel,
                title=title,
                group=group,
                scope=scope,
                note=note,
                external=external,
            )

        add(PROMPT, "AGENTS.md", "Instructions", SHARED, "用户级共享提示词")
        for client, rel in HOOK_FILES.items():
            add(
                rel,
                client,
                "Hooks",
                client,
                "原生事件和命令"
                if client != "Claude Code"
                else "Claude 原生设置，Grok 也会读取兼容 hook",
            )
        add(
            "editors/zed/settings.json",
            "settings.json",
            "Settings",
            "Zed",
            "Zed 原生 JSONC",
        )
        for client, slug in IDS.items():
            policy = f"agents/policies/{slug}.json"
            if self.path(policy).exists():
                add(
                    policy,
                    "Plugin 保留名单",
                    "Plugins",
                    client,
                    "setup.py --plugins-only 使用的策略；保留名单不会安装插件。",
                )
        for client in PLUGIN_CLIENTS:
            add(
                "plugins:" + client,
                "本机插件状态",
                "Plugins",
                client,
                "本机配置 / 安装登记",
                True,
            )
        for client in ("Codex", "Antigravity"):
            add(
                f"agents/plugin-states/{IDS[client]}.json",
                "Plugin 启用开关",
                "Plugins",
                client,
                "以插件 ID 对应 true / false。启用项须在该客户端保留名单中。保存后点击应用插件策略。",
            )
        for client in PLUGIN_CLIENTS:
            add(
                "panel:" + client,
                client,
                "Plugins",
                client,
                "开关保存到工作树，应用策略后更新客户端。"
                if client != "DeepSeek"
                else "运行中的 profile",
                client == "DeepSeek",
            )
        for client in PREFERENCES:
            add(
                f"agents/preferences/{client.lower()}.json",
                "模型偏好",
                "Settings",
                client,
                "保存后写入 dotfiles 和本机原生 TOML，新会话读取。",
            )
        add(
            "settings:claude",
            "settings.json",
            "Settings",
            "Claude Code",
            "~/.claude/settings.json",
        )
        add(
            "settings:antigravity",
            "hooks.json",
            "Settings",
            "Antigravity",
            "~/.gemini/config/hooks.json",
        )
        add(
            "settings:deepseek",
            "运行配置",
            "Settings",
            "DeepSeek",
            "本机 profile 的组成",
            True,
        )
        for f in sorted(self.path("agents/skills").glob("*/SKILL.md")):
            add(str(f.relative_to(self.repo)), f.parent.name, "Skills", SHARED)
        for f in sorted(self.path("agents/agents").glob("*.md")):
            if not any(
                self.path(f"agents/profiles/{scope}/Agents/{f.stem}.json").exists()
                for scope in ("universal", "claude")
            ):
                add(
                    str(f.relative_to(self.repo)),
                    f.stem,
                    "Agents",
                    "Claude Code",
                    "Claude 原生定义，Grok 兼容读取",
                )
        scopes = {v: k for k, v in IDS.items()} | {"universal": SHARED}
        for f in sorted(self.path("agents/profiles").glob("*/*/*")):
            slug, group = f.parts[-3:-1]
            if f.is_file() and slug in scopes and group in CATEGORIES:
                add(str(f.relative_to(self.repo)), f.stem, group, scopes[slug])
        for f in sorted(self.path("agents/pstack/skills").glob("*/SKILL.md")):
            add(str(f.relative_to(self.repo)), f.parent.name, "Skills", SHARED, "pstack · 本地")
        return items

    def plugin_panel(self, item):
        client = item["scope"]
        slug = IDS[client]
        policy = self.path(f"agents/policies/{slug}.json")
        switches = self.path(f"agents/plugin-states/{slug}.json")
        states = json.loads(switches.read_text()) if switches.exists() else {}
        if client == "Claude Code":
            states = json.loads(self.path(HOOK_FILES[client]).read_text()).get(
                "enabledPlugins", {}
            )
        value = {
            "keep": json.loads(policy.read_text()) if policy.exists() else [],
            "states": states,
        }
        text = pretty(value)
        return dict(item, text=text, version=digest(text))

    def plugin_inventory(self, client):
        if client not in PLUGIN_CLIENTS:
            raise ValueError("未知的插件客户端")
        try:
            return dict(live=plugins(self.home, client), inventoryError="")
        except (OSError, ValueError, subprocess.SubprocessError) as exc:
            return dict(live={}, inventoryError=str(exc))

    def save_plugin_panel(self, doc, text):
        value = json.loads(text)
        if not isinstance(value, dict) or set(value) != {"keep", "states"}:
            raise ValueError("插件策略需要保留名单和启用状态")
        ids = value["keep"]
        states = value["states"]
        client = doc["scope"]
        slug = IDS[client]
        pattern = r"[a-zA-Z0-9._-]+(?:@[a-zA-Z0-9._-]+)?"
        if (
            not isinstance(ids, list)
            or not isinstance(states, dict)
            or not all(
                isinstance(k, str) and re.fullmatch(pattern, k) for k in [*ids, *states]
            )
            or not all(type(v) is bool for v in states.values())
        ):
            raise ValueError("插件名称或开关值无效")
        if client == "Claude Code" and any("@" not in k for k in [*ids, *states]):
            raise ValueError("Claude 插件名称需要包含 @marketplace")
        if client == "Claude Code" and any(
            k.endswith("@builtin") and v for k, v in states.items()
        ):
            raise ValueError("Claude 内置插件由停用策略管理")
        if client == "Codex" and any("@" not in k for k in states):
            raise ValueError("Codex 启用状态需要完整的插件 ID")
        if client == "Grok" and states:
            raise ValueError("Grok 使用保留名单管理插件")
        for name, enabled in states.items():
            if enabled and name not in ids and name.split("@")[0] not in ids:
                raise ValueError(f"请先保留 {name}")
        before = json.loads(doc["text"])
        changes = {}
        if ids != before["keep"]:
            changes[f"agents/policies/{slug}.json"] = pretty(ids)
        if states != before["states"]:
            if client == "Claude Code":
                rel = HOOK_FILES[client]
                config = json.loads(self.path(rel).read_text())
                config["enabledPlugins"] = states
                changes[rel] = pretty(config)
            else:
                changes[f"agents/plugin-states/{slug}.json"] = pretty(states)
        self.commit_plan(changes, {})
        return self.plugin_panel(
            {k: doc[k] for k in ("id", "title", "group", "scope", "external", "note")}
        )

    def read(self, key):
        item = self.items().get(key)
        if not item:
            raise ValueError("配置项不存在")
        if key.startswith("panel:"):
            return self.plugin_panel(item)
        f = self.path(key)
        if key.startswith("plugins:") or key == "settings:deepseek":
            try:
                text = pretty(plugins(self.home, item["scope"]))
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                text = "当前无法读取本机状态：" + str(error)
        elif key.startswith("agents/plugin-states/") and not f.exists():
            text = "{}\n"
        elif key.startswith("settings:"):
            text = self.path(HOOK_FILES[item["scope"]]).read_text()
        elif key.startswith("agents/preferences/") and not f.exists():
            text = pretty(preferences(self.home, item["scope"]))
        else:
            text = f.read_text()
        if key.startswith("agents/preferences/"):
            item["fields"] = PREFERENCES[item["scope"]][2]
        return dict(item, text=text, version=digest(text))

    def commit_plan(self, changes, links):
        # Check all destinations before writing. Never replace an unmanaged native file.
        for rel, target in links.items():
            slot = self.home / rel
            if not slot.parent.resolve().is_relative_to(self.home):
                raise ValueError(f"客户端目录已链接到其他位置：~/{rel}")
            previous = self.manifest()["links"].get(rel)
            if os.path.lexists(slot) and slot.resolve() != self.path(target).resolve():
                if (
                    not previous
                    or not slot.is_symlink()
                    or slot.resolve() != self.path(previous).resolve()
                ):
                    raise ValueError(f"已有独立配置：~/{rel}")
        old = {}
        installed = {}
        try:
            for rel, text in changes.items():
                path = self.path(rel)
                before = path.read_text() if path.exists() else None
                if before != text:
                    old[rel] = before
                    atomic(path, text)
            for rel, target in links.items():
                dest, src = self.home / rel, self.path(target)
                if dest.resolve() != src.resolve():
                    installed[dest] = os.readlink(dest) if dest.is_symlink() else None
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    tmp = dest.with_name(
                        "." + dest.name + ".agent-config-" + os.urandom(6).hex()
                    )
                    tmp.symlink_to(src)
                    tmp.replace(dest)
        except BaseException:
            for dest, before in installed.items():
                dest.unlink(missing_ok=True)
                if before is not None:
                    dest.symlink_to(before)
            for rel, before in old.items():
                if before is None:
                    self.path(rel).unlink(missing_ok=True)
                else:
                    atomic(self.path(rel), before)
            raise
        self.touched.update(old)

    def create(self, scope, group, name):
        if (
            scope not in [SHARED, *CLIENTS]
            or not SLUG.fullmatch(name)
            or len(name) > 60
        ):
            raise ValueError("名称请使用小写字母、数字和短横线")
        slug = "universal" if scope == SHARED else IDS[scope]
        stem = f"agents/profiles/{slug}/{group}/{name}"
        manifest = self.manifest()
        links = {}
        if group == "Instructions" and scope in CLIENTS:
            key = f"agents/profiles/{slug}/Instructions/AGENTS.md"
            text = self.path(PROMPT).read_text()
            links[PROMPT_PATHS[scope]] = key
        elif group == "Skills" and (scope == SHARED or scope in SKILL_PATHS):
            text = f"---\nname: {name}\ndescription: Describe when to use this skill.\n---\n\n# {name}\n"
            if scope == SHARED:
                key = f"agents/skills/{name}/SKILL.md"
                if name in manifest["skills"] or self.path(f"agents/pstack/skills/{name}").exists():
                    raise ValueError("同名 skill 已存在")
                manifest["skills"].append(name)
                for root in manifest["skillRoots"]:
                    links[root + "/" + name] = str(Path(key).parent)
            else:
                key = stem + ".md"
                links[f"{SKILL_PATHS[scope]}/{name}/SKILL.md"] = key
        elif group == "Agents" and (scope == SHARED or scope in AGENT_PATHS):
            key, text = (
                stem + ".json",
                pretty(
                    {"description": name, "instructions": "Describe this agent's role."}
                ),
            )
        elif group == "Hooks" and scope in [SHARED, *HOOK_FILES]:
            key, text = (
                stem + ".json",
                pretty({"event": "Stop", "command": f": agent-config-{name}"}),
            )
        else:
            raise ValueError("该客户端没有此类独立入口")
        if self.path(key).exists():
            raise ValueError("同名配置已存在")
        changes = {key: text}
        if group in ["Hooks", "Agents"]:
            self.render(key, scope, group, text, None, changes, links)
        if group != "Skills" or scope != SHARED:
            manifest["links"].update(links)
        if manifest != self.manifest():
            changes[MANIFEST] = pretty(manifest)
        self.commit_plan(changes, links)
        return self.read(key)

    def render(self, key, scope, group, text, before, changes, links):
        name = Path(key).stem
        data = json.loads(text)
        if group == "Agents":
            desc, body = data["description"], data["instructions"]
            if not all(isinstance(s, str) and s.strip() for s in (desc, body)):
                raise ValueError("description 和 instructions 不能为空")
            clients = (
                ["Claude Code", "Codex", "Antigravity"] if scope == SHARED else [scope]
            )
            for c in clients:
                if c == "Codex":
                    output = (
                        "\n".join(
                            f"{k} = {json.dumps(v, ensure_ascii=False)}"
                            for k, v in [
                                ("name", name),
                                ("description", desc),
                                ("developer_instructions", body),
                            ]
                        )
                        + "\n"
                    )
                    ext = "toml"
                    tomllib.loads(output)
                else:
                    output = f"---\nname: {name}\ndescription: {json.dumps(desc, ensure_ascii=False)}\n---\n\n{body}\n"
                    ext = "md"
                target = f"agents/rendered/{IDS[c]}/{name}.{ext}"
                if c == "Claude Code":
                    target = f"agents/agents/{name}.md"
                if before is None and self.path(target).exists():
                    raise ValueError(f"同名 agent 已存在：{target}")
                changes[target] = output
                if c != "Claude Code":
                    links[f"{AGENT_PATHS[c]}/{name}.{ext}"] = target
            return
        event, command = data["event"], data["command"]
        if (
            event not in ["Stop", "UserPromptSubmit"]
            or not isinstance(command, str)
            or not command.strip()
        ):
            raise ValueError("hook 需要 Stop 或 UserPromptSubmit 事件和非空 command")
        for c in HOOK_FILES if scope == SHARED else [scope]:
            rel = HOOK_FILES[c]
            native = json.loads(self.path(rel).read_text())
            if c == "Antigravity":
                ev = "PreInvocation" if event == "UserPromptSubmit" else event
                block_key = "agent-config-" + name
                if before is None and block_key in native:
                    raise ValueError(f"{c} 已有同名 hook：{name}")
                if before:
                    prev = json.loads(before)
                    prev_event = (
                        "PreInvocation"
                        if prev["event"] == "UserPromptSubmit"
                        else prev["event"]
                    )
                    expected = {
                        prev_event: [{"type": "command", "command": prev["command"]}]
                    }
                    if native.get(block_key) != expected:
                        raise ValueError(f"{c} 原生 hook 已改变，请先核对 {rel}")
                native[block_key] = {ev: [{"type": "command", "command": command}]}
            else:
                hooks = native["hooks"]
                if before:
                    prev = json.loads(before)
                    old_group = {
                        "hooks": [{"type": "command", "command": prev["command"]}]
                    }
                    if old_group not in hooks.get(prev["event"], []):
                        raise ValueError(f"{c} 原生 hook 已改变，请先核对 {rel}")
                    hooks[prev["event"]].remove(old_group)
                entry = {"hooks": [{"type": "command", "command": command}]}
                if entry in hooks.get(event, []):
                    raise ValueError(f"{c} 已有相同事件和命令")
                hooks.setdefault(event, []).append(entry)
            changes[rel] = pretty(native)

    def save(self, key, version, text):
        doc = self.read(key)
        if doc["external"] or doc["version"] != version:
            raise ValueError("文件已变化或为只读，请重新载入")
        if not isinstance(text, str) or len(text.encode()) > 1_000_000:
            raise ValueError("内容过长")
        if key.startswith("panel:"):
            return self.save_plugin_panel(doc, text)
        if key.startswith("settings:"):
            return self.save(HOOK_FILES[doc["scope"]], version, text) | {
                "id": key,
                "group": "Settings",
            }
        if key.startswith("agents/preferences/"):
            values = json.loads(text)
            native, content = update_native(self.home, doc["scope"], values)
            original = self.path(key).read_text() if self.path(key).exists() else None
            atomic(self.path(key), pretty(values))
            try:
                if preferences(self.home, doc["scope"]) != values:
                    atomic(native, content)
            except BaseException:
                if original is None:
                    self.path(key).unlink()
                else:
                    atomic(self.path(key), original)
                raise
            self.touched.add(key)
            return self.read(key)
        changes, links = {key: text}, {}
        if key == "editors/zed/settings.json":
            # Match strings before punctuation so URLs and quoted commas survive.
            tokens = r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/'
            stripped = re.sub(
                tokens, lambda m: m[0] if m[0].startswith('"') else " ", text
            )
            stripped = re.sub(
                r'"(?:\\.|[^"\\])*"|,\s*(?=[}\]])',
                lambda m: m[0] if m[0].startswith('"') else "",
                stripped,
            )
            if not isinstance(json.loads(stripped), dict):
                raise ValueError("Zed 设置需要 JSONC 对象")
        elif key.endswith(".json"):
            obj = json.loads(text)
            if key.startswith("agents/plugin-states/"):
                if not isinstance(obj, dict) or not all(
                    type(v) is bool for v in obj.values()
                ):
                    raise ValueError("需要插件 ID 到 true / false 的 JSON 对象")
                allowed = json.loads(
                    self.path(f"agents/policies/{IDS[doc['scope']]}.json").read_text()
                )
                for name, value in obj.items():
                    if (
                        value
                        and name not in allowed
                        and name.split("@")[0] not in allowed
                    ):
                        raise ValueError(f"请先将 {name} 加入本客户端的保留名单")
            elif doc["group"] == "Plugins":
                if not isinstance(obj, list) or not all(
                    isinstance(n, str)
                    and re.fullmatch(r"[a-zA-Z0-9._-]+(@[a-zA-Z0-9._-]+)?", n)
                    for n in obj
                ):
                    raise ValueError("需要插件 ID 的 JSON 数组")
                if doc["scope"] == "Claude Code" and any("@" not in n for n in obj):
                    raise ValueError("Claude 插件 ID 需要包含 @marketplace")
            elif not isinstance(obj, dict):
                raise ValueError("需要 JSON 对象")
        if key.startswith("agents/profiles/") and doc["group"] in ("Agents", "Hooks"):
            self.render(
                key, doc["scope"], doc["group"], text, doc["text"], changes, links
            )
        self.commit_plan(changes, links)
        return self.read(key)
