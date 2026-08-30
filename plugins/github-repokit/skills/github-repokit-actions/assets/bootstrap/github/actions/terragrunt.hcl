include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_repo = "<REPO_NAME>"

  # Optional. GitHub Actions does not require AWS or GCP. Set these after
  # a human applies bootstrap/aws/identity or bootstrap/gcp/identity.
  aws_role_arn = trimspace(get_env("AWS_ROLE_ARN", ""))
  gcp_wif      = trimspace(get_env("GCP_WORKLOAD_IDENTITY_PROVIDER", ""))
  gcp_sa       = trimspace(get_env("GCP_TERRAFORM_SA", ""))
  gcp_enabled  = local.gcp_wif != "" && local.gcp_sa != ""

  aws_variables = local.aws_role_arn != "" ? { AWS_ROLE_ARN = local.aws_role_arn } : {}
  gcp_variables = local.gcp_enabled ? {
    GCP_WORKLOAD_IDENTITY_PROVIDER = local.gcp_wif
    GCP_TERRAFORM_SA               = local.gcp_sa
  } : {}

  identity_variables = merge(local.aws_variables, local.gcp_variables)
}

terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-repository?ref=v1.0.0"
}

inputs = {
  repo_name = local.github_repo

  manage_repository_settings         = false
  write_repository_actions_variables = false

  github_environment_configs = {
    dev = {
      variables = local.identity_variables
    }
    prod = {
      protected           = true
      can_admins_bypass   = false
      prevent_self_review = true
      variables           = local.identity_variables
    }
  }
}
