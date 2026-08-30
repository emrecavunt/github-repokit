include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_repo = get_env("EXAMPLE_GITHUB_REPO", "your-repo")

  # Optional. GitHub Actions does not require AWS or GCP. Set these after
  # applying bootstrap/aws/identity or bootstrap/gcp/identity if you want
  # keyless cloud access from workflows.
  aws_role_arn  = trimspace(get_env("EXAMPLE_AWS_ROLE_ARN", ""))
  gcp_wif       = trimspace(get_env("EXAMPLE_GCP_WIF_PROVIDER", ""))
  gcp_sa        = trimspace(get_env("EXAMPLE_GCP_TERRAFORM_SA", ""))
  gcp_enabled   = local.gcp_wif != "" && local.gcp_sa != ""
  aws_variables = local.aws_role_arn != "" ? { AWS_ROLE_ARN = local.aws_role_arn } : {}

  gcp_projects = {
    dev   = get_env("EXAMPLE_GCP_PROJECT_DEV", "your-project-dev")
    stage = get_env("EXAMPLE_GCP_PROJECT_STAGE", "your-project-stage")
    prod  = get_env("EXAMPLE_GCP_PROJECT_PROD", "your-project-prod")
  }

  identity_variables = {
    for environment, project in local.gcp_projects : environment => merge(
      local.aws_variables,
      local.gcp_enabled ? {
        GOOGLE_PROJECT                 = project
        GCP_WORKLOAD_IDENTITY_PROVIDER = local.gcp_wif
        GCP_TERRAFORM_SA               = local.gcp_sa
      } : {}
    )
  }
}

terraform {
  source = "../../../../modules/github-repository"
}

inputs = {
  repo_name = local.github_repo

  # Environments only. Repo settings stay in bootstrap/github/repository.
  # Cloud WIF is optional: variables stay empty until identity outputs are passed.
  manage_repository_settings         = false
  write_repository_actions_variables = false

  github_environment_configs = {
    dev = {
      variables = local.identity_variables.dev
    }
    stage = {
      variables = local.identity_variables.stage
    }
    prod = {
      protected           = true
      can_admins_bypass   = false
      prevent_self_review = true
      variables           = local.identity_variables.prod
    }
  }
}
