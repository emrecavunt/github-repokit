include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  project_id  = get_env("EXAMPLE_GCP_PROJECT_ID", "your-gcp-project")
  github_org  = get_env("EXAMPLE_GITHUB_OWNER", "your-org")
  github_repo = get_env("EXAMPLE_GITHUB_REPO", "your-repo")
}

terraform {
  source = "../../../../modules/github-wif-oidc"
}

inputs = {
  service_account_project_id   = local.project_id
  service_account_id           = "github-actions"
  service_account_display_name = "GitHub Actions"

  github_owner                = local.github_org
  github_repositories         = ["${local.github_org}/${local.github_repo}"]
  create_project_wif_provider = true

  target_project_roles = {
    (local.project_id) = [
      "roles/viewer",
    ]
  }
}
