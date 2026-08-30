include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_org  = get_env("EXAMPLE_GITHUB_OWNER", "your-org")
  github_repo = get_env("EXAMPLE_GITHUB_REPO", "your-repo")
}

terraform {
  source = "../../../../modules/github-aws-oidc"
}

inputs = {
  role_name            = "github-actions-secrets"
  github_owner         = local.github_org
  github_repositories  = ["${local.github_org}/${local.github_repo}"]
  create_oidc_provider = true

  secretsmanager_secret_arns = compact([get_env("EXAMPLE_AWS_SECRET_ARN", "")])
  ssm_parameter_arns         = compact([get_env("EXAMPLE_AWS_SSM_PARAMETER_ARN", "")])
}
