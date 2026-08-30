# `github-aws-oidc` module interface

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-aws-oidc?ref=v1.0.0"
}
```

**Pin rule:** latest published tag on `emrecavunt/github-repokit`. Do not
invent tags. Do not track `main`.

## Typical inputs

| Input | Notes |
|---|---|
| `role_name` | e.g. `github-actions-secrets` |
| `github_owner` | Org or user login |
| `github_repositories` | Set of `owner/repo` values; each must start with `github_owner/` |
| `create_oidc_provider` | `true` on a greenfield account; `false` + `oidc_provider_arn` to reuse |
| `secretsmanager_secret_arns` | Optional; placeholders only |
| `ssm_parameter_arns` | Optional; placeholders only |
| `allowed_environments` | Empty = any job on the trusted repos |

Handoff: `role_arn` → Actions variable `AWS_ROLE_ARN` via environment,
not Terragrunt `dependency`. This module does not write the workflow
that calls `aws-actions/configure-aws-credentials`.
