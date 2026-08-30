# bootstrap/aws/identity

Optional AWS OIDC role for GitHub Actions. Not required to bootstrap
GitHub environments.

**Apply is human-gated.** After apply, export `role_arn` as `AWS_ROLE_ARN`
and re-apply `bootstrap/github/actions`. Do not add a Terragrunt
`dependency`.
