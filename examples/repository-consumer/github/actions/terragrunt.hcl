include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_repo = get_env("EXAMPLE_GITHUB_REPO", "your-repo")
}

dependency "identity" {
  config_path = "../../gcp/identity"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    workload_identity_provider_name       = "projects/000000000000/locations/global/workloadIdentityPools/github/providers/github"
    terraform_apply_service_account_email = "github-actions@your-project.iam.gserviceaccount.com"
  }
}

terraform {
  source = "../../../../modules/github-repository"
}

inputs = {
  repo_name = local.github_repo

  # Environments and WIF variables only. Repo settings stay in
  # bootstrap/github/repository.
  manage_repository_settings         = false
  write_repository_actions_variables = false

  github_environment_configs = {
    dev = {
      variables = {
        GOOGLE_PROJECT                 = get_env("EXAMPLE_GCP_PROJECT_DEV", "your-project-dev")
        GCP_WORKLOAD_IDENTITY_PROVIDER = dependency.identity.outputs.workload_identity_provider_name
        GCP_TERRAFORM_SA               = dependency.identity.outputs.terraform_apply_service_account_email
      }
    }
    stage = {
      variables = {
        GOOGLE_PROJECT                 = get_env("EXAMPLE_GCP_PROJECT_STAGE", "your-project-stage")
        GCP_WORKLOAD_IDENTITY_PROVIDER = dependency.identity.outputs.workload_identity_provider_name
        GCP_TERRAFORM_SA               = dependency.identity.outputs.terraform_apply_service_account_email
      }
    }
    prod = {
      protected           = true
      can_admins_bypass   = false
      prevent_self_review = true
      variables = {
        GOOGLE_PROJECT                 = get_env("EXAMPLE_GCP_PROJECT_PROD", "your-project-prod")
        GCP_WORKLOAD_IDENTITY_PROVIDER = dependency.identity.outputs.workload_identity_provider_name
        GCP_TERRAFORM_SA               = dependency.identity.outputs.terraform_apply_service_account_email
      }
    }
  }
}
