# Repository consumer example

This example is split into two stacks:

- `gcp/`: creates project-local GitHub OIDC/WIF + a deployer service account
- `github/`: configures the repository and its Actions environments

Copy the tree into a product repo as `bootstrap/gcp` and `bootstrap/github`
and replace the `EXAMPLE_*` environment variables. Nothing here is live:
defaults are placeholders.

Agents should create and manage GitHub bootstrap as:

```text
bootstrap/github/repository/   # settings, teams, protection, CODEOWNERS
bootstrap/github/actions/      # environments + Actions variables
```

Do not put environments on the repository stack, and do not manage repo
settings from the actions stack (`manage_repository_settings = false`).

## Flow

1. Apply `gcp/identity` first.
2. Apply `github/repository` and `github/actions` second.
3. `github/actions` reads outputs from `gcp/identity` via Terragrunt dependency.

## Layout

```text
examples/repository-consumer
├── gcp
│   ├── Makefile
│   ├── root.hcl
│   └── identity
│       └── terragrunt.hcl
└── github
    ├── Makefile
    ├── root.hcl
    ├── repository
    │   └── terragrunt.hcl
    └── actions
        └── terragrunt.hcl
```

## Required environment variables

- `GITHUB_TOKEN`
- `GITHUB_OWNER` (your user or organization)

Recommended overrides:

- `EXAMPLE_GCP_PROJECT_ID`
- `EXAMPLE_GITHUB_OWNER`
- `EXAMPLE_GITHUB_REPO`
- `EXAMPLE_GITHUB_USER` (admin collaborator on a personal repo)
- `EXAMPLE_CODEOWNERS` (for example `@your-org/platform-engineers`)
- `EXAMPLE_GCP_PROJECT_DEV`
- `EXAMPLE_GCP_PROJECT_STAGE`
- `EXAMPLE_GCP_PROJECT_PROD`

## Commands

```bash
export GITHUB_TOKEN=...
export GITHUB_OWNER=your-org
export EXAMPLE_GITHUB_OWNER=your-org
export EXAMPLE_GITHUB_REPO=your-repo
export EXAMPLE_GCP_PROJECT_ID=your-gcp-project

cd examples/repository-consumer/gcp
make tg-plan
make apply

cd ../github
make tg-plan
make apply
```

## Output handoff

`github/actions` consumes these outputs from `gcp/identity`:

- `workload_identity_provider_name` -> `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `terraform_apply_service_account_email` -> `GCP_TERRAFORM_SA`
