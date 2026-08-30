---
name: github-repokit-aws-oidc
description: >-
  Add optional AWS IAM OIDC for GitHub Actions with GitHub RepoKit
  (bootstrap/aws/identity, modules/github-aws-oidc). Use when the user asks for
  AWS OIDC, an AWS_ROLE_ARN for Actions, or keyless AWS access from GitHub —
  even if they do not say "repokit". Do not run this skill unless the human
  asked for AWS. Does not write workflow YAML. After a human applies identity,
  pass role_arn into the actions stack as an environment variable; never a
  Terragrunt dependency.
---

# GitHub RepoKit — AWS OIDC

Creates `bootstrap/aws/identity` so GitHub Actions can assume an IAM role
via OIDC. **Do not run** unless the human asked for AWS.

Does not write workflow YAML. Does not add a Terragrunt `dependency` from
`bootstrap/github/actions`.

## Workflow

1. If the human did not ask for AWS, **stop**.
2. Read [references/module-interface.md](references/module-interface.md).
3. Detect the gap:
   - **Missing** → copy [assets/bootstrap/aws/](assets/bootstrap/aws/) to
     `bootstrap/aws/`. Fill `<GITHUB_OWNER>`, `<REPO_NAME>`, and optional
     secret/SSM ARNs (placeholders only).
   - **Non-standard path** → leave it.
   - **Complete** → stop.
4. Ask whether the AWS account already has a GitHub OIDC provider. If
   yes, set `create_oidc_provider = false` and pass `oidc_provider_arn`.
5. Pin `?ref=` to the latest published tag. Print plan commands.
   **Stop. Do not apply.**
6. After a **human** apply, tell them to export `role_arn` as
   `AWS_ROLE_ARN` and re-apply `bootstrap/github/actions`.

## Additional resources

- [references/module-interface.md](references/module-interface.md)
- [assets/bootstrap/aws/](assets/bootstrap/aws/)
