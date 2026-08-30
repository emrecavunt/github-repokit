# bootstrap/gcp/identity

Optional GCP Workload Identity Federation for GitHub Actions. Not
required to bootstrap GitHub environments.

**Apply is human-gated.** After apply, export
`workload_identity_provider_name` and
`terraform_apply_service_account_email` as
`GCP_WORKLOAD_IDENTITY_PROVIDER` / `GCP_TERRAFORM_SA` and re-apply
`bootstrap/github/actions`. Do not add a Terragrunt `dependency`.
