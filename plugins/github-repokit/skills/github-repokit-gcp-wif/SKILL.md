---
name: github-repokit-gcp-wif
description: >-
  Add optional GCP Workload Identity Federation for GitHub Actions with GitHub
  RepoKit (bootstrap/gcp/identity, modules/github-wif-oidc). Use when the user
  asks for WIF, workload identity, GCP_WORKLOAD_IDENTITY_PROVIDER, or keyless
  GCP from GitHub — even if they do not say "repokit". Do not run this skill
  unless the human asked for GCP. Does not write workflow YAML. After a human
  applies identity, pass outputs into the actions stack as environment
  variables; never a Terragrunt dependency.
---

# GitHub RepoKit — GCP WIF

Creates `bootstrap/gcp/identity` so GitHub Actions can impersonate a
service account via Workload Identity Federation. **Do not run** unless
the human asked for GCP.

Does not write workflow YAML. Does not add a Terragrunt `dependency`
from `bootstrap/github/actions`.

## Workflow

1. If the human did not ask for GCP, **stop**.
2. Read [references/module-interface.md](references/module-interface.md).
3. Detect the gap:
   - **Missing** → copy [assets/bootstrap/gcp/](assets/bootstrap/gcp/) to
     `bootstrap/gcp/`. Fill `<GCP_PROJECT_ID>`, `<GITHUB_OWNER>`,
     `<REPO_NAME>` with placeholders or values the human provided. Never
     copy live project numbers from another repo.
   - **Non-standard path** → leave it.
   - **Complete** → stop.
4. Ask whether a project-local WIF pool should be created
   (`create_project_wif_provider = true`) or an existing pool/provider
   reused (`false` + `workload_identity_pool_name` /
   `workload_identity_provider_name`).
5. Pin `?ref=` to the latest published tag. Print plan commands.
   **Stop. Do not apply.**
6. After a **human** apply, tell them to export
   `workload_identity_provider_name` and
   `terraform_apply_service_account_email` as
   `GCP_WORKLOAD_IDENTITY_PROVIDER` / `GCP_TERRAFORM_SA` and re-apply
   `bootstrap/github/actions`.

## Additional resources

- [references/module-interface.md](references/module-interface.md)
- [assets/bootstrap/gcp/](assets/bootstrap/gcp/)
