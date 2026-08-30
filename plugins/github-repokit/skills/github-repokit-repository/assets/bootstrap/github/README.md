# bootstrap/github

Per-repo GitHub governance via `github-repokit//modules/github-repository`.
Settings changes go through this config — not the GitHub UI.

**Apply is human-gated.** Needs a `GITHUB_TOKEN` with repo admin (and
`admin:org` when assigning teams).

```sh
export GITHUB_OWNER=your-org
export GITHUB_TOKEN=...
cd bootstrap/github
make tg-init
make tg-plan
make apply
```

`import_existing_repository = true` imports an existing GitHub repo on
first apply. Fill `<REPO_NAME>` and `<DESCRIPTION>` before planning.

After a required CI check is green, set `required_status_checks = true`
and `required_status_check_contexts`, then re-apply.
