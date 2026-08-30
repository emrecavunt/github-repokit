---
name: github-repokit-repository
description: >-
  Add or complete per-repo GitHub governance with GitHub RepoKit
  (bootstrap/github/repository via Terragrunt): settings, teams, branch
  protection, CODEOWNERS. Use when the user asks to bootstrap a GitHub
  repository, add CODEOWNERS, branch protection, team access, or repository
  settings as code — even if they do not say "repokit". Does not write workflow
  YAML, does not manage the GitHub organization, and does not create Actions
  environments (that is github-repokit-actions).
---

# GitHub RepoKit — repository

Adds or completes **per-repo** GitHub governance. Does not manage the GitHub
org. Does not write workflow YAML. Does not create environments (that is
`github-repokit-actions`).

## Workflow

1. Read [references/module-interface.md](references/module-interface.md).
2. Detect the gap:
   - **Missing** — no `bootstrap/**/*.hcl` consuming `modules/github-repository`
     → copy [assets/bootstrap/github/](assets/bootstrap/github/) to
     `bootstrap/github/` in the consumer. Fill `<REPO_NAME>` and
     `<DESCRIPTION>`.
   - **Partial** — a repository stack exists but has no working
     `include "root"` → add/wire `root.hcl`, drop inline
     `generate "provider"`.
   - **Non-standard path** (sibling `bootstrap/github-repository`,
     `bootstrap/github/repo`, …) → **leave the path**. Do not move state
     unless the human asks.
   - **Complete** — canonical stack already present → stop.
3. Pin `?ref=` to the latest **published** tag on
   `emrecavunt/github-repokit`. Do not invent tags. Do not track `main`.
4. Set `owner_is_organization` from the GitHub owner. Organizations may
   pass `teams`. User-owned repos set `owner_is_organization = false`,
   omit `teams`, and never add the owner as a collaborator.
5. New stacks: `required_status_checks = false` until a green required
   check exists. Then tell the human to set contexts and re-apply.
6. Print plan commands. **Stop. Do not run `terragrunt apply`.**

## Defaults (new stacks)

- Visibility `private`; signed commits; 1 approving review; CODEOWNER reviews
- `import_existing_repository = true` (module default)
- `write_repository_actions_variables = false`
- `delete_branch_on_merge = true`
- Placeholders only — no tokens, project IDs, or live cloud identifiers

## Additional resources

- [references/module-interface.md](references/module-interface.md)
- [assets/bootstrap/github/](assets/bootstrap/github/)
