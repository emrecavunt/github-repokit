# plugins/

**Agent plugin** for GitHub RepoKit — four skills behind one install id,
in the [Agent Plugins 1.0](https://agent-plugins.org/specification) layout
that Claude Code, Cursor, Codex, VS Code / Copilot, and the Skills CLI can
consume:

```text
plugins/github-repokit/
  plugin.json                 # Agent Plugins 1.0 manifest
  .claude-plugin/plugin.json  # Claude Code manifest (same name/version/…)
  mcp.json / .mcp.json        # hosted GitHub MCP (host authenticates)
  hooks/ + scripts/           # deny terraform/terragrunt/tofu apply
  skills/<skill>/SKILL.md …   # SSOT — skills live only here
```

The catalog [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json)
lists the plugin with `"source": "./plugins/github-repokit"`. Do not set
`metadata.pluginRoot`.

Eval suites live at [`evals/<skill>/`](../evals/README.md), not inside the
plugin.

## Skills

| Skill | Use when |
|---|---|
| `github-repokit-repository` | Per-repo settings, teams, branch protection, CODEOWNERS |
| `github-repokit-actions` | Environments and Actions variables (no workflow YAML, no cloud required) |
| `github-repokit-aws-oidc` | Optional AWS OIDC — only if the human asked for AWS |
| `github-repokit-gcp-wif` | Optional GCP WIF — only if the human asked for GCP |

Apply order: repository → actions → human apply → optional identity →
pass outputs into actions via environment variables. `terragrunt apply`
is always human-gated.

## Install

- **Claude Code**: `/plugin marketplace add emrecavunt/github-repokit`
  then `/plugin install github-repokit@github-repokit`
- **Skills CLI**: `npx skills add emrecavunt/github-repokit --skill github-repokit-repository`
- **Cursor / Codex**: point the client at `plugins/github-repokit/`
  (Agent Plugins 1.0 `plugin.json`)

Any change under `plugins/github-repokit/skills/` bumps `version` in both
manifests and the catalog in the same PR.
