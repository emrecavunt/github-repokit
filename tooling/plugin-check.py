#!/usr/bin/env python3
"""Plugin / catalog / eval-tree structure checks. stdlib only, no network.

Emits path:check-id:detail lines. Exit 1 on findings.
"""
from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(ROOT, "skills")
PLUGINS = os.path.join(ROOT, "plugins")
EVALS = os.path.join(ROOT, "evals")
CATALOG = os.path.join(ROOT, ".claude-plugin", "marketplace.json")
MARKETPLACE_NAME = "github-repokit"
SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
MCP_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"
NAME_RE = re.compile(r"^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$")
SHARED_FIELDS = ("name", "version", "description", "author", "license", "keywords")
ALLOWED_PLUGIN_DIRS = {"skills", ".claude-plugin", "agents", "commands", "hooks", "scripts", "bin"}
ALLOWED_PLUGIN_FILES = {"plugin.json", "mcp.json", ".mcp.json", "README.md", "CHANGELOG.md", "LICENSE"}
EVALS_RESERVED = {"workspaces", "README.md"}
SECRET_RE = re.compile(
    r"(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|"
    r"AIza[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|"
    r"xox[baprs]-[A-Za-z0-9-]{10,})",
    re.I,
)

FINDINGS = 0


def rel(path: str) -> str:
    return os.path.relpath(path, ROOT)


def fail(path: str, check: str, detail: str) -> None:
    global FINDINGS
    print(f"{rel(path)}:{check}:{detail}")
    FINDINGS += 1


def load_json(path: str, check: str) -> dict | None:
    if not os.path.isfile(path):
        fail(path, check, "missing file")
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except json.JSONDecodeError as exc:
        fail(path, check, f"invalid JSON: {exc}")
        return None
    if not isinstance(data, dict):
        fail(path, check, "top level must be an object")
        return None
    return data


def skill_names_in(container: str) -> list[str]:
    if not os.path.isdir(container):
        return []
    return sorted(
        e for e in os.listdir(container)
        if os.path.isdir(os.path.join(container, e)) and os.path.isfile(os.path.join(container, e, "SKILL.md"))
    )


def plugin_dirs() -> list[str]:
    if not os.path.isdir(PLUGINS):
        return []
    return sorted(
        e for e in os.listdir(PLUGINS)
        if os.path.isdir(os.path.join(PLUGINS, e)) and not e.startswith(".")
    )


def check_plugin_manifest(name: str) -> str | None:
    root = os.path.join(PLUGINS, name)
    open_path = os.path.join(root, "plugin.json")
    claude_path = os.path.join(root, ".claude-plugin", "plugin.json")
    open_m = load_json(open_path, "plugin-manifest")
    claude_m = load_json(claude_path, "plugin-manifest")

    if not NAME_RE.match(name) or ".." in name or "--" in name:
        fail(root, "plugin-manifest", f"directory name '{name}' violates Agent Plugins name rules")

    if open_m is not None:
        if open_m.get("$schema") != SCHEMA:
            fail(open_path, "plugin-manifest", f"$schema must be {SCHEMA}")
        for field in SHARED_FIELDS:
            if field not in open_m:
                fail(open_path, "plugin-manifest", f"missing {field}")
    if claude_m is not None:
        for field in SHARED_FIELDS:
            if field not in claude_m:
                fail(claude_path, "plugin-manifest", f"missing {field}")
        if "$schema" in claude_m:
            fail(claude_path, "plugin-manifest", "Claude manifest must not carry the Agent Plugins $schema")

    for path, m in ((open_path, open_m), (claude_path, claude_m)):
        if m is None:
            continue
        if m.get("name") != name:
            fail(path, "plugin-manifest", f"name '{m.get('name')}' != directory '{name}'")
        ver = m.get("version")
        if not isinstance(ver, str) or not SEMVER_RE.match(ver):
            fail(path, "plugin-manifest", f"version '{ver}' is not semver")
        for key in ("mcpServers", "userConfig"):
            if key in m:
                fail(path, "plugin-manifest", f"{key} belongs in mcp.json / .mcp.json, not the plugin manifest")

    if open_m is not None and claude_m is not None:
        for field in SHARED_FIELDS:
            if open_m.get(field) != claude_m.get(field):
                fail(claude_path, "plugin-manifest", f"{field} differs from plugin.json")

    skills = skill_names_in(os.path.join(root, "skills"))
    if not skills:
        fail(root, "plugin-manifest", "no skills/*/SKILL.md")
    for entry in sorted(os.listdir(root)):
        full = os.path.join(root, entry)
        if os.path.isdir(full):
            if entry in ALLOWED_PLUGIN_DIRS or re.match(r"^[a-z]{2,}\.[a-z0-9.-]+$", entry):
                continue
            fail(full, "plugin-manifest", "unexpected directory in plugin (evals/ belongs at evals/<skill>/)")
        elif entry not in ALLOWED_PLUGIN_FILES:
            fail(full, "plugin-manifest", "unexpected file in plugin root")

    check_mcp(root)
    check_hooks(root)

    if open_m is not None and claude_m is not None and open_m.get("version") == claude_m.get("version"):
        return open_m.get("version")
    return None


def _secret_scan(path: str, check: str, blob: str) -> None:
    if SECRET_RE.search(blob):
        fail(path, check, "looks like a secret/token; MCP and hooks must use env vars at runtime")


def check_mcp(root: str) -> None:
    portable = os.path.join(root, "mcp.json")
    claude = os.path.join(root, ".mcp.json")
    for path, require_schema in ((portable, True), (claude, False)):
        if not os.path.isfile(path):
            continue
        data = load_json(path, "plugin-mcp")
        if data is None:
            continue
        _secret_scan(path, "plugin-mcp", json.dumps(data))
        if require_schema and data.get("$schema") != MCP_SCHEMA:
            fail(path, "plugin-mcp", f"$schema must be {MCP_SCHEMA}")
        servers = data.get("mcpServers")
        if not isinstance(servers, dict) or not servers:
            fail(path, "plugin-mcp", "mcpServers must be a non-empty object")
            continue
        for name, cfg in servers.items():
            if not isinstance(cfg, dict):
                fail(path, "plugin-mcp", f"mcpServers.{name} must be an object")
                continue
            stype = cfg.get("type")
            url = cfg.get("url")
            if require_schema:
                if stype not in {"stdio", "http"}:
                    fail(path, "plugin-mcp", f"mcpServers.{name}.type must be stdio or http")
                if stype == "stdio":
                    cmd = cfg.get("command")
                    if not isinstance(cmd, str) or not cmd:
                        fail(path, "plugin-mcp", f"mcpServers.{name}.command is required")
                    elif cmd.startswith("./") and not os.path.isfile(os.path.join(root, cmd[2:])):
                        fail(path, "plugin-mcp", f"mcpServers.{name}.command {cmd} is not in the plugin")
            if stype == "http" or isinstance(url, str):
                if not isinstance(url, str) or not url.startswith("https://"):
                    fail(path, "plugin-mcp", f"mcpServers.{name}.url must be an https URL")
                elif re.search(r"://[^/]*:[^/]*@", url) or re.search(r"[?&](token|key|secret)=", url, re.I):
                    fail(path, "plugin-mcp", f"mcpServers.{name}.url must not embed credentials")
            headers = cfg.get("headers")
            if isinstance(headers, dict):
                for val in headers.values():
                    if isinstance(val, str) and SECRET_RE.search(val):
                        fail(path, "plugin-mcp", "headers must not embed secrets")
            env = cfg.get("env")
            if isinstance(env, dict):
                for val in env.values():
                    if isinstance(val, str) and SECRET_RE.search(val):
                        fail(path, "plugin-mcp", "env must not embed secrets")


def check_hooks(root: str) -> None:
    path = os.path.join(root, "hooks", "hooks.json")
    if not os.path.isfile(path):
        return
    data = load_json(path, "plugin-hooks")
    if data is None:
        return
    _secret_scan(path, "plugin-hooks", json.dumps(data))
    hooks = data.get("hooks")
    if not isinstance(hooks, dict) or not hooks:
        fail(path, "plugin-hooks", "hooks must be a non-empty object")
        return
    for event, groups in hooks.items():
        if not isinstance(groups, list):
            fail(path, "plugin-hooks", f"hooks.{event} must be an array")
            continue
        for i, group in enumerate(groups):
            if not isinstance(group, dict):
                continue
            inner = group.get("hooks") or []
            if not isinstance(inner, list):
                continue
            for j, hook in enumerate(inner):
                if not isinstance(hook, dict):
                    continue
                cmd = hook.get("command")
                if not isinstance(cmd, str):
                    continue
                if "${CLAUDE_PLUGIN_ROOT}" in cmd or cmd.startswith("./"):
                    stripped = cmd.strip().strip('"')
                    local = (
                        stripped.replace("${CLAUDE_PLUGIN_ROOT}/", "")
                        .replace("${CLAUDE_PLUGIN_ROOT}", "")
                        .lstrip("/")
                    )
                    if local.startswith("./"):
                        local = local[2:]
                    local = local.split()[0].strip('"')
                    if local and not os.path.isfile(os.path.join(root, local)):
                        fail(path, "plugin-hooks", f"hooks.{event}[{i}].hooks[{j}] command path missing: {local}")
                elif re.search(r"https?://", cmd):
                    fail(path, "plugin-hooks", f"hooks.{event}[{i}] command must stay inside the plugin")


def check_version_bump(plugins: list[str], versions: dict[str, str | None]) -> None:
    import subprocess

    def git(*args: str) -> str | None:
        try:
            out = subprocess.run(
                ["git", *args],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
        except OSError:
            return None
        if out.returncode != 0:
            return None
        return out.stdout

    if git("rev-parse", "--is-inside-work-tree") is None:
        return
    base = None
    for ref in ("origin/main", "main", "origin/master", "master"):
        mb = git("merge-base", "HEAD", ref)
        if mb:
            base = mb.strip()
            break
    if not base:
        return
    diff = git("diff", "--name-only", f"{base}...HEAD")
    if diff is None:
        return
    changed = [ln.strip() for ln in diff.splitlines() if ln.strip()]
    for name in plugins:
        skill_prefix = f"plugins/{name}/skills/"
        if not any(p.startswith(skill_prefix) for p in changed):
            continue
        show = git("show", f"{base}:plugins/{name}/plugin.json")
        if show is None:
            continue
        try:
            old = json.loads(show)
        except json.JSONDecodeError:
            continue
        old_ver = old.get("version")
        new_ver = versions.get(name)
        if old_ver and new_ver and old_ver == new_ver:
            fail(
                os.path.join(PLUGINS, name, "plugin.json"),
                "plugin-version-bump",
                f"skills under plugins/{name}/skills/ changed since {base[:7]} but version is still {new_ver}",
            )


def check_marketplace(plugins: list[str], versions: dict[str, str | None]) -> None:
    if not plugins and not os.path.isfile(CATALOG):
        return
    cat = load_json(CATALOG, "plugin-marketplace")
    if cat is None:
        return
    if cat.get("name") != MARKETPLACE_NAME:
        fail(CATALOG, "plugin-marketplace", f"marketplace name '{cat.get('name')}' != '{MARKETPLACE_NAME}'")
    if not isinstance(cat.get("owner"), dict) or not cat["owner"].get("name"):
        fail(CATALOG, "plugin-marketplace", "owner.name is required")
    meta = cat.get("metadata")
    if isinstance(meta, dict) and "pluginRoot" in meta:
        fail(CATALOG, "plugin-marketplace", "metadata.pluginRoot breaks Skills CLI nested discovery; remove it")
    entries = cat.get("plugins")
    if not isinstance(entries, list):
        fail(CATALOG, "plugin-marketplace", "plugins must be an array")
        return
    seen: set[str] = set()
    for i, e in enumerate(entries):
        if not isinstance(e, dict) or not e.get("name"):
            fail(CATALOG, "plugin-marketplace", f"plugins[{i}] needs a name")
            continue
        name = e["name"]
        if name in seen:
            fail(CATALOG, "plugin-marketplace", f"duplicate entry '{name}'")
        seen.add(name)
        if name not in plugins:
            fail(CATALOG, "plugin-marketplace", f"entry '{name}' has no plugins/{name}/ directory")
            continue
        src = e.get("source")
        if src != f"./plugins/{name}":
            fail(CATALOG, "plugin-marketplace", f"entry '{name}' source must be './plugins/{name}' (got {src!r})")
        if versions.get(name) is not None and e.get("version") != versions[name]:
            fail(CATALOG, "plugin-marketplace", f"entry '{name}' version {e.get('version')!r} != manifest {versions[name]!r}")
        for field in ("description", "category", "keywords"):
            if not e.get(field):
                fail(CATALOG, "plugin-marketplace", f"entry '{name}' missing {field}")
    for name in plugins:
        if name not in seen:
            fail(CATALOG, "plugin-marketplace", f"plugins/{name}/ is not listed")


def check_skill_unique(plugins: list[str]) -> dict[str, list[str]]:
    where: dict[str, list[str]] = {}
    for n in skill_names_in(SKILLS):
        where.setdefault(n, []).append(os.path.join(SKILLS, n))
    for p in plugins:
        for n in skill_names_in(os.path.join(PLUGINS, p, "skills")):
            where.setdefault(n, []).append(os.path.join(PLUGINS, p, "skills", n))
    for n, paths in sorted(where.items()):
        if len(paths) > 1:
            for path in paths[1:]:
                fail(path, "skill-unique", f"skill '{n}' also at {rel(paths[0])}")
    return where


def check_skill_manifest(where: dict[str, list[str]]) -> None:
    for name, paths in sorted(where.items()):
        for path in paths:
            skill = os.path.join(path, "SKILL.md")
            with open(skill, encoding="utf-8") as fh:
                text = fh.read()
            match = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
            if not match:
                fail(skill, "skill-manifest", "missing YAML frontmatter")
                continue
            fm = match.group(1)
            nm = re.search(r"^name:\s*(.+)\s*$", fm, re.M)
            if not nm or nm.group(1).strip() != name:
                fail(skill, "skill-manifest", f"frontmatter name must equal directory '{name}'")
            if not re.search(r"^description:\s*", fm, re.M):
                fail(skill, "skill-manifest", "missing description")
            if len(fm) > 1200:
                fail(skill, "skill-manifest", "frontmatter looks larger than the 1024-char description budget")


def check_evals_sync(where: dict[str, list[str]]) -> None:
    skills = set(where)
    suites: set[str] = set()
    if os.path.isdir(EVALS):
        for entry in sorted(os.listdir(EVALS)):
            full = os.path.join(EVALS, entry)
            if entry in EVALS_RESERVED or entry.startswith("."):
                continue
            if not os.path.isdir(full):
                fail(full, "skill-evals-sync", "unexpected file under evals/")
                continue
            suites.add(entry)
            if entry not in skills:
                fail(full, "skill-evals-sync", "eval suite has no skill of that name")
    for n in sorted(skills - suites):
        fail(os.path.join(EVALS, n), "skill-evals-sync", f"skill '{n}' has no evals/{n}/ suite")
    for top in (SKILLS, PLUGINS):
        if not os.path.isdir(top):
            continue
        for dirpath, dirnames, filenames in os.walk(top):
            if "evals" in dirnames:
                fail(os.path.join(dirpath, "evals"), "skill-evals-sync", "evals/ inside an installable unit; move to evals/<skill>/")
            if "evals.json" in filenames:
                fail(os.path.join(dirpath, "evals.json"), "skill-evals-sync", "evals.json inside an installable unit")
            dirnames[:] = [d for d in dirnames if d != ".git"]


def main() -> int:
    plugins = plugin_dirs()
    versions = {p: check_plugin_manifest(p) for p in plugins}
    check_marketplace(plugins, versions)
    check_version_bump(plugins, versions)
    where = check_skill_unique(plugins)
    check_skill_manifest(where)
    check_evals_sync(where)
    return 1 if FINDINGS else 0


if __name__ == "__main__":
    sys.exit(main())
