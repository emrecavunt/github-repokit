include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  project_id   = "<GCP_PROJECT_ID>"
  github_owner = "<GITHUB_OWNER>"
  github_repo  = "<REPO_NAME>"
}

terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-wif-oidc?ref=v1.0.0"
}

inputs = {
  service_account_project_id   = local.project_id
  service_account_id           = "github-actions"
  service_account_display_name = "GitHub Actions"

  github_owner                = local.github_owner
  github_repositories         = ["${local.github_owner}/${local.github_repo}"]
  create_project_wif_provider = true

  target_project_roles = {
    (local.project_id) = [
      "roles/viewer",
    ]
  }
}
