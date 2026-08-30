include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_owner = "<GITHUB_OWNER>"
  github_repo  = "<REPO_NAME>"
}

terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-aws-oidc?ref=v1.0.0"
}

inputs = {
  role_name            = "github-actions-secrets"
  github_owner         = local.github_owner
  github_repositories  = ["${local.github_owner}/${local.github_repo}"]
  create_oidc_provider = true

  secretsmanager_secret_arns = []
  ssm_parameter_arns         = []
}
