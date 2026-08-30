# bootstrap/

This repository managing itself. The live stack is
`github/repository` (`modules/github-repository`). There is no
`github/actions` stack here — this library has no deploy environments.

Consumer repos that need both should use:

```text
bootstrap/github/repository/   # settings, teams, protection, CODEOWNERS
bootstrap/github/actions/      # environments + Actions variables
bootstrap/aws/identity/        # optional AWS OIDC
bootstrap/gcp/identity/        # optional GCP WIF
```

`github/actions` applies without AWS or GCP. See
`examples/repository-consumer` for the copy-ready split.

**Apply is human-gated.** Requires a GitHub token with repo admin on
`emrecavunt/github-repokit`.

```sh
cd github
GITHUB_TOKEN=... make tg-init
GITHUB_TOKEN=... make tg-plan
GITHUB_TOKEN=... make apply
```

`import_existing_repository = true` imports the existing repo on first
apply. The one-time `make tg-import-repo-settings REPO_NAME=github-repokit`
target remains if state was started without that import.
