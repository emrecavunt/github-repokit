# `github-wif-oidc` module interface

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-wif-oidc?ref=v1.0.0"
}
```

**Pin rule:** latest published tag on `emrecavunt/github-repokit`. Do not
invent tags. Do not track `main`.

## Typical inputs

| Input | Notes |
|---|---|
| `service_account_project_id` | Placeholder or human-provided project ID |
| `service_account_id` | e.g. `github-actions` |
| `github_owner` | Org or user login |
| `github_repositories` | Set of `owner/repo` |
| `create_project_wif_provider` | `true` creates pool+provider in the SA project; `false` requires existing pool/provider names |
| `target_project_roles` | Least privilege; default example is `roles/viewer` on the SA project |

Handoff (environment variables, not Terragrunt `dependency`):

| Output | Actions variable |
|---|---|
| `workload_identity_provider_name` | `GCP_WORKLOAD_IDENTITY_PROVIDER` |
| `terraform_apply_service_account_email` | `GCP_TERRAFORM_SA` |

This module does not write the workflow that calls
`google-github-actions/auth`.
