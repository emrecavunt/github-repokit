# github-repository

Per-repository GitHub governance: settings, team and collaborator access,
branch protection, CODEOWNERS, environments, and Actions variables.

## What it manages

- Optional `github_repository` settings (visibility, topics, homepage,
  issues, wiki, Dependabot alerts, delete-branch-on-merge,
  `archive_on_destroy`)
- Team and user collaborator permissions
- Branch protection v3 (signed commits, reviews, required checks)
- `.github/CODEOWNERS` as a managed file
- GitHub environments, including protected production environments
- Actions variables at environment scope, and optionally at repo scope
  (`write_repository_actions_variables`)

## Existing repositories

When `manage_repository_settings = true` (default `false`) and
`import_existing_repository = true` (default), the module imports
`github_repository.settings[0]` on first apply so you do not get
`422 name already exists`. Set `import_existing_repository = false` only
when this stack should create a brand-new repository.

On module versions without that import block, run a one-time import:

```bash
terragrunt import 'github_repository.settings[0]' <repo-name>
```

## Consumer layout

Agents should create two stacks that both source this module:

```text
bootstrap/github/repository/   # manage_repository_settings = true
bootstrap/github/actions/      # manage_repository_settings = false
```

Keep settings, teams, branch protection, and CODEOWNERS on
`repository`. Keep `github_environment_configs` on `actions`.
The actions stack does not require AWS or GCP. Optional identity
lives under `bootstrap/aws/identity` or `bootstrap/gcp/identity`.

## Environments

Prefer `github_environment_configs` for per-environment variables and
protection. The older `github_environments` + `github_actions_variables`
pair still works; matching names in `github_environment_configs` win.
