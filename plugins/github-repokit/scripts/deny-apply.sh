#!/bin/sh
# Claude Code PreToolUse hook: block IaC apply. Emits a JSON permission
# decision (deny) on stdout. Reads hook JSON on stdin. No secrets.
# Catches direct applies (terraform/terragrunt/tofu ... apply, including
# `terragrunt run --all apply` and `terraform -chdir=... apply`) and make
# targets that wrap them (`make apply`).
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
# Match "apply" anywhere in the same shell segment as the IaC binary or make,
# so flags/subcommands in between (run --all, -chdir=..., run-all) still hit.
APPLY_RE = re.compile(r"\b(terraform|terragrunt|tofu|make)\b[^|;&\n]*\bapply\b")
if APPLY_RE.search(cmd.lower()):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "github-repokit: IaC apply is human-gated. "
                "Run plan only; a human applies."
            ),
        }
    }))
    raise SystemExit(0)
raise SystemExit(0)
'
