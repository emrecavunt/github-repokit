# `github-repository` module interface

Consumer source:

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-repository?ref=v1.0.0"
}
```

**Pin rule:** use the latest published tag on `emrecavunt/github-repokit`
(`gh release list`). Do not invent tags. Do not track `main`. This
repository's self-bootstrap MAY use a relative path to `modules/`.

## Required

| Input | Notes |
|---|---|
| `repo_name` | GitHub repository name |

## Typical inputs

| Input | Default / habit |
|---|---|
| `description` | One line |
| `visibility` | `private` |
| `owner_is_organization` | `true` for orgs; `false` for user-owned (omit `teams`) |
| `teams` | Empty unless the human names a team slug |
| `users` | Empty unless the repo already lists collaborators. Never add the owner |
| `branch_protection_rules.main` | `pattern = "main"`, signed commits, 1 review, CODEOWNER reviews |
| `required_status_checks` | `false` until a green check exists; then `true` plus contexts |
| `codeowners` | `"*" = ["@your-org/platform-engineers"]` (placeholder) |
| `manage_repository_settings` | `true` on this stack |
| `import_existing_repository` | `true` (module default) |
| `delete_branch_on_merge` | `true` |
| `write_repository_actions_variables` | `false` |

Do not add `github_environment_configs` here — that is
`github-repokit-actions`.

Provider and remote state live in `bootstrap/github/root.hcl`
(`GITHUB_OWNER`, `GITHUB_TOKEN` at apply time — human only).
