# github-aws-oidc

Reusable AWS identity bootstrap for GitHub Actions OIDC. Creates (or reuses)
the account-level GitHub OIDC provider and an IAM role that trusted
repositories can assume to read Secrets Manager and SSM parameters.

This module does **not** write workflow YAML. Consumers call
`aws-actions/configure-aws-credentials` themselves and pass `role_arn`.

GitHub Actions bootstrap does **not** require this stack. Add it only when
the repo needs keyless AWS secret access.

## What it manages

- Optional `token.actions.githubusercontent.com` OIDC provider
- IAM role with `sts:AssumeRoleWithWebIdentity`, scoped to owner/repo
  (and optionally GitHub environments)
- Inline policy for Secrets Manager / SSM / KMS decrypt on the ARNs you pass
- Attachments of extra existing IAM policies

## Inputs

Required:

- `role_name`
- `github_owner`
- `github_repositories` (each value must be `github_owner/repo`)

OIDC mode:

- `create_oidc_provider = true` (default): creates the account-level
  provider and fetches thumbprints from GitHub's certificate chain
- `create_oidc_provider = false`: requires `oidc_provider_arn`

Secrets (all optional; omit them to create a role with no secret access):

- `secretsmanager_secret_arns`
- `ssm_parameter_arns`
- `kms_key_arns` (only when secrets use a customer-managed key)
- `additional_policy_arns`

Restrict assume-role to GitHub environments with `allowed_environments`.
When that set is empty, the trust policy allows `repo:owner/repo:*`.

## Outputs

- `role_arn` — set as `AWS_ROLE_ARN` on `bootstrap/github/actions` if you
  want workflows to assume this role
- `role_name`
- `oidc_provider_arn`

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-bootstrapper.git//modules/github-aws-oidc?ref=v1.0.0"
}

inputs = {
  role_name           = "github-actions-secrets"
  github_owner        = "your-org"
  github_repositories = ["your-org/your-repo"]
  create_oidc_provider = true

  secretsmanager_secret_arns = [
    "arn:aws:secretsmanager:eu-west-1:111111111111:secret:app/dev/*",
  ]
}
```
