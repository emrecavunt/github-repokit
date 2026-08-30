#!/bin/sh
# Claude Code PreToolUse hook: block IaC apply. Exit 2 = deny the tool call.
# Reads hook JSON on stdin. No secrets.
exec python3 -c '
import json, re, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    raise SystemExit(0)
inp = data.get("tool_input") or data.get("input") or {}
cmd = ""
if isinstance(inp, dict):
    cmd = str(inp.get("command") or inp.get("cmd") or "")
if re.search(r"\b(terraform|terragrunt|tofu)\s+apply\b", cmd.lower()):
    sys.stderr.write(
        "github-repokit: IaC apply is human-gated. Run plan only; a human applies.\n"
    )
    raise SystemExit(2)
raise SystemExit(0)
'
