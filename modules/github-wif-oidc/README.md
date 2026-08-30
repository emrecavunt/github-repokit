# github-wif-oidc

Optional GCP identity for GitHub Actions. Creates a Terraform apply service
account, project IAM, and Workload Identity Federation bindings so trusted
repositories can impersonate that account without a JSON key.

This stack is optional. GitHub Actions bootstrap does not require GCP.
Add it only when workflows need keyless GCP access. AWS uses
`modules/github-aws-oidc` the same way. This module does not write
workflow YAML.

Requires the Google provider `>= 6.0, < 9.0`.

## What it manages

- Terraform apply service account
- IAM roles for that service account across target projects
- `roles/iam.workloadIdentityUser` bindings for trusted GitHub repositories
- Optional project-local Workload Identity Pool and provider

## Inputs

Required:

- `service_account_project_id`
- `service_account_id`
- `service_account_display_name`
- `target_project_roles`
- `github_owner` (used in the default OIDC attribute condition)
- One or more trusted repos via `github_repository` or `github_repositories`

WIF mode:

- `create_project_wif_provider = false` (default): requires
  `workload_identity_pool_name` and `workload_identity_provider_name`
- `create_project_wif_provider = true`: creates the pool and provider in
  `service_account_project_id` and ignores existing provider inputs

The default attribute condition is
`assertion.repository_owner=="<github_owner>"` and
`assertion.repository` matching the trusted repository list. Override it
with `github_provider_attribute_condition` if you need a different claim
(for example a specific ref).

```hcl
github_provider_attribute_condition = "assertion.repository==\"your-org/your-repo\" && assertion.ref==\"refs/heads/main\""
```

## Outputs

- `terraform_apply_service_account_email`: set as `GCP_TERRAFORM_SA` on
  `bootstrap/github/actions`
- `terraform_apply_service_account_name`
- `workload_identity_provider_name`: set as `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `workload_identity_pool_name`
