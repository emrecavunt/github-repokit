# bootstrap/github/actions

Environments and Actions variables only (`manage_repository_settings = false`).
Does not require AWS or GCP. Does not write workflow YAML.

**Apply is human-gated.**

```sh
export GITHUB_OWNER=your-org
export GITHUB_TOKEN=...
cd bootstrap/github
make tg-plan
make apply
```

After a human applies `bootstrap/aws/identity` or `bootstrap/gcp/identity`,
export `AWS_ROLE_ARN` / `GCP_WORKLOAD_IDENTITY_PROVIDER` /
`GCP_TERRAFORM_SA` and re-apply this stack. Never add a Terragrunt
`dependency` on identity.
