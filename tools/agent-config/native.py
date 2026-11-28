"""Public, non-secret fields that can be promoted from a local config into dotfiles."""

import json
import re
import subprocess
import tomllib

# Only these user preferences are exported. Tokens, OAuth and MCP environment
# variables live in the same native files and must never enter the web editor.
PREFERENCES = {
    "Codex": (
        ".codex/config.toml",
        "",
        ("model", "model_reasoning_effort", "personality", "service_tier"),
    ),
    "Grok": (".grok/config.toml", "models", ("default", "default_reasoning_effort")),
}


def preferences(home, client):
    rel, table, keys = PREFERENCES[client]
    path = home / rel
    cfg = tomllib.loads(path.read_text()) if path.exists() else {}
    values = cfg.get(table, {}) if table else cfg
    return {k: values[k] for k in keys if k in values}


def update_native(home, client, values):
    rel, table, keys = PREFERENCES[client]
    if (
        not isinstance(values, dict)
        or not values.keys() <= set(keys)
        or not all(isinstance(v, str) and v.strip() for v in values.values())
    ):
        raise ValueError("未知字段或空值。允许的字符串字段：" + ", ".join(keys))
    path = home / rel
    before = path.read_text() if path.exists() else ""
    original = tomllib.loads(before)
    expected = original.setdefault(table, {}) if table else original
    for key in keys:
        expected.pop(key, None)
    expected.update(values)
    headers = list(re.finditer(r"(?m)^\s*\[([^\n]+?)\][^\n]*$", before))
    start, end = 0, headers[0].start() if headers else len(before)
    if table:
        for i, m in enumerate(headers):
            if m[1] == table:
                start, end = (
                    m.end(),
                    headers[i + 1].start() if i + 1 < len(headers) else len(before),
                )
                break
        else:
            before += f"\n[{table}]\n"
            start = end = len(before)
    body = before[start:end]
    for key in keys:
        body = re.sub(r"(?m)^[ \t]*" + key + r"[ \t]*=[^\n]*\n?", "", body)
    body = (
        "\n"
        + "".join(
            f"{k} = {json.dumps(v, ensure_ascii=False)}\n" for k, v in values.items()
        )
        + body.lstrip("\n")
    )
    result = before[:start] + body + "\n" + before[end:]
    if tomllib.loads(result) != original:
        raise ValueError("当前 TOML 布局无法安全更新")
    return path, result


def plugins(home, client):
    if client == "Claude Code":
        rows = json.loads(
            subprocess.check_output(
                ["claude", "plugin", "list", "--json"],
                timeout=15,
                stderr=subprocess.DEVNULL,
            )
        )
        return [
            {
                key: row[key]
                for key in ("id", "enabled", "scope", "projectPath")
                if key in row
            }
            for row in rows
        ]
    if client == "Codex":
        cfg = tomllib.loads((home / ".codex/config.toml").read_text())
        return {name: v.get("enabled") for name, v in cfg.get("plugins", {}).items()}
    if client == "Antigravity":
        return json.loads((home / ".gemini/config/config.json").read_text()).get(
            "plugins", {}
        )
    if client == "Grok":
        data = json.loads(
            subprocess.check_output(
                ["grok", "inspect", "--json"], timeout=8, stderr=subprocess.DEVNULL
            )
        )
        return {p["name"]: p.get("enabled") for p in data.get("plugins", [])}
    if client == "DeepSeek":
        return {
            p.parent.name: json.loads(p.read_text())
            .get("dsh", {})
            .get("profile", {})
            .get("bundles", [])
            for p in (home / ".dsh/profiles").glob("*/package.json")
        }
    return {}


def apply_preferences(repo, home):
    from catalog import atomic

    for client in PREFERENCES:
        source = repo / f"agents/preferences/{client.lower()}.json"
        if source.exists():
            values = json.loads(source.read_text())
            if preferences(home, client) != values:
                path, text = update_native(home, client, values)
                atomic(path, text)
