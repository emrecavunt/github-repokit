# Actions stack (`github-repository` with settings off)

Same module as the repository stack. This stack owns environments only.

```hcl
terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-repository?ref=v1.0.0"
}
```

**Pin rule:** latest published tag on `emrecavunt/github-repokit`. Do not
invent tags. Do not track `main`.

## Required inputs

| Input | Value on this stack |
|---|---|
| `repo_name` | Same as the repository stack |
| `manage_repository_settings` | `false` |
| `write_repository_actions_variables` | `false` unless the repo already writes repo-scoped vars |

## `github_environment_configs`

| Field | Notes |
|---|---|
| `variables` | `map(string)`. Stay empty until identity outputs are passed in |
| `protected` | `true` on production-like environments |
| `can_admins_bypass` | default `false` |
| `prevent_self_review` | module default `true` |

Identity handoff is **environment variables**, not Terragrunt dependency:

| Identity output | Actions variable |
|---|---|
| AWS `role_arn` | `AWS_ROLE_ARN` |
| GCP `workload_identity_provider_name` | `GCP_WORKLOAD_IDENTITY_PROVIDER` |
| GCP `terraform_apply_service_account_email` | `GCP_TERRAFORM_SA` |

Do not write workflow YAML. Do not create `bootstrap/aws` or
`bootstrap/gcp` from this skill.
