---
name: github-repokit-actions
description: >-
  Add or complete GitHub Actions environments and environment-scoped Actions
  variables with GitHub RepoKit (bootstrap/github/actions). Use when the user
  asks for GitHub environments, protected production environments, or Actions
  variables as Terragrunt — even if they do not say "repokit". Does not write
  workflow YAML. Does not require AWS or GCP and must not add a Terragrunt
  dependency on identity. Ask before wiring AWS_ROLE_ARN or GCP WIF variables.
---

# GitHub RepoKit — actions

Adds or completes **environments and Actions variables**. Does not own
repository settings (`manage_repository_settings = false`). Does not write
`.github/workflows/*.yml`. Does not require AWS or GCP.

If `bootstrap/github/repository` is missing, run `github-repokit-repository`
first (or tell the human).

## Workflow

1. Read [references/module-interface.md](references/module-interface.md).
2. Detect the gap:
   - **Missing** — no actions stack → copy
     [assets/bootstrap/github/actions/](assets/bootstrap/github/actions/)
     into `bootstrap/github/actions/`. Copy `root.hcl` / `Makefile` from
     `github-repokit-repository` assets only when those files are absent.
     Do not overwrite an existing `root.hcl`.
   - **Partial** — `actions/terragrunt.hcl` exists without `include "root"`
     → wire include; drop inline provider generate.
   - **Non-standard path** (`bootstrap/github-actions`, …) → leave it.
   - **Complete** → stop.
3. Default environments: `dev` (unprotected) and `prod`
   (`protected = true`, `can_admins_bypass = false`). Add `stage` only if
   the human asked. Variables stay empty until identity exists.
4. **Cloud identity is opt-in.** Inventory whether workflows need AWS or
   GCP, then **ask** before wiring `AWS_ROLE_ARN`,
   `GCP_WORKLOAD_IDENTITY_PROVIDER`, or `GCP_TERRAFORM_SA`.
   - Human says no → empty `variables`. No identity stack.
   - Human says AWS → `github-repokit-aws-oidc` first; after a **human**
     apply, pass `role_arn` in as an env var and re-plan actions.
   - Human says GCP → `github-repokit-gcp-wif` the same way.
   Never add a Terragrunt `dependency` on identity.
5. Pin `?ref=` to the latest published tag. Print plan commands.
   **Stop. Do not apply.**

## Additional resources

- [references/module-interface.md](references/module-interface.md)
- [assets/bootstrap/github/actions/](assets/bootstrap/github/actions/)
