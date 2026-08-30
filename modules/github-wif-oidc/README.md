# github-wif-oidc

Reusable GCP identity bootstrap module for GitHub Actions OIDC + Workload Identity Federation.

This stack is optional. GitHub Actions bootstrap does not require GCP.
Add it only when workflows need keyless GCP access. AWS uses
`modules/github-aws-oidc` the same way.

## What it manages

- Terraform apply service account
- IAM roles for that service account across target projects
- `roles/iam.workloadIdentityUser` bindings for trusted GitHub repositories
- Optional project-local Workload Identity Pool + Provider

## Inputs

Required:

- `service_account_project_id`
- `service_account_id`
- `service_account_display_name`
- `target_project_roles`
- `github_owner` (used in the default OIDC attribute condition)
- One or more trusted repos via `github_repository` or `github_repositories`

WIF mode:

- `create_project_wif_provider = false` (default): requires `workload_identity_pool_name` and `workload_identity_provider_name`
- `create_project_wif_provider = true`: creates pool/provider in `service_account_project_id` and ignores existing provider inputs

The default attribute condition is
`assertion.repository_owner=="<github_owner>"` and
`assertion.repository` matching the trusted repository list. Override it
with `github_provider_attribute_condition` if you need a different claim
(for example a specific ref).

```hcl
github_provider_attribute_condition = "assertion.repository==\"your-org/your-repo\" && assertion.ref==\"refs/heads/main\""
```

## Outputs

- `terraform_apply_service_account_email`
- `terraform_apply_service_account_name`
- `workload_identity_provider_name`
- `workload_identity_pool_name`
