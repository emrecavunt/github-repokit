# Repository consumer example

GitHub bootstrap does **not** require AWS or GCP. Cloud identity is an
optional add-on you attach when workflows need keyless access to that
provider.

Copy the trees you need into a product repo:

```text
bootstrap/github/repository/   # settings, teams, protection, CODEOWNERS
bootstrap/github/actions/      # environments + Actions variables
bootstrap/aws/identity/        # optional AWS OIDC
bootstrap/gcp/identity/        # optional GCP WIF
```

Replace the `EXAMPLE_*` environment variables. Nothing here is live:
defaults are placeholders.

Do not put environments on the repository stack, and do not manage repo
settings from the actions stack (`manage_repository_settings = false`).

## Flow

1. Apply `github/repository` and `github/actions`. No cloud credentials.
2. If workflows need AWS secrets, apply `aws/identity`, then set
   `EXAMPLE_AWS_ROLE_ARN` from `role_arn` and re-apply `github/actions`.
3. If workflows need GCP, apply `gcp/identity`, then set
   `EXAMPLE_GCP_WIF_PROVIDER` and `EXAMPLE_GCP_TERRAFORM_SA` and re-apply
   `github/actions`.
4. You can add both providers, one, or neither. A future provider follows
   the same `bootstrap/<provider>/identity` shape.

## Layout

```text
examples/repository-consumer
├── aws
│   ├── Makefile
│   ├── root.hcl
│   └── identity
│       └── terragrunt.hcl
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

Recommended GitHub overrides:

- `EXAMPLE_GITHUB_OWNER`
- `EXAMPLE_GITHUB_REPO`
- `EXAMPLE_GITHUB_USER` (admin collaborator on a personal repo)
- `EXAMPLE_CODEOWNERS` (for example `@your-org/platform-engineers`)

Optional AWS identity:

- `EXAMPLE_AWS_REGION`
- `EXAMPLE_AWS_SECRET_ARN`
- `EXAMPLE_AWS_SSM_PARAMETER_ARN`
- `EXAMPLE_AWS_ROLE_ARN` (pass `aws/identity` `role_arn` into actions)

Optional GCP identity:

- `EXAMPLE_GCP_PROJECT_ID`
- `EXAMPLE_GCP_PROJECT_DEV`
- `EXAMPLE_GCP_PROJECT_STAGE`
- `EXAMPLE_GCP_PROJECT_PROD`
- `EXAMPLE_GCP_WIF_PROVIDER` (pass `gcp/identity` provider name into actions)
- `EXAMPLE_GCP_TERRAFORM_SA` (pass `gcp/identity` SA email into actions)

## Commands

GitHub only:

```bash
export GITHUB_TOKEN=...
export GITHUB_OWNER=your-org
export EXAMPLE_GITHUB_OWNER=your-org
export EXAMPLE_GITHUB_REPO=your-repo

cd examples/repository-consumer/github
make tg-plan
make apply
```

Optional AWS identity, then wire the role into Actions:

```bash
export EXAMPLE_AWS_REGION=eu-west-1
export EXAMPLE_AWS_SECRET_ARN=arn:aws:secretsmanager:eu-west-1:111111111111:secret:app/dev/*

cd examples/repository-consumer/aws
make tg-plan
make apply
export EXAMPLE_AWS_ROLE_ARN="$(cd identity && terragrunt output -raw role_arn)"

cd ../github
make apply
```

Optional GCP identity uses the same pattern with `EXAMPLE_GCP_WIF_PROVIDER`
and `EXAMPLE_GCP_TERRAFORM_SA`.

## Output handoff

`github/actions` reads identity through environment variables, not a
Terragrunt dependency, so the actions stack plans without AWS or GCP.

| Identity output | Actions variable |
| --- | --- |
| `aws/identity` `role_arn` | `AWS_ROLE_ARN` |
| `gcp/identity` `workload_identity_provider_name` | `GCP_WORKLOAD_IDENTITY_PROVIDER` |
| `gcp/identity` `terraform_apply_service_account_email` | `GCP_TERRAFORM_SA` |
