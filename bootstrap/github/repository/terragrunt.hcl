include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/github-repository"
}

inputs = {
  repo_name    = "github-bootstrapper"
  description  = "Terraform modules to bootstrap GitHub repository settings, branch protection, CODEOWNERS, Actions environments, and keyless GCP OIDC/WIF."
  visibility   = "public"
  homepage_url = "https://github.com/emrecavunt/github-bootstrapper"
  topics = [
    "terraform",
    "terragrunt",
    "github-actions",
    "oidc",
    "workload-identity",
    "bootstrap",
  ]

  users = {
    emrecavunt = {
      username   = "emrecavunt"
      permission = "admin"
    }
  }

  branch_protection_rules = {
    main = {
      pattern                         = "main"
      enforce_admins                  = false
      require_signed_commits          = true
      dismiss_stale_reviews           = true
      require_conversation_resolution = true
      restrict_push_access            = false
      push_restrictions_teams         = []
      require_code_owner_reviews      = true
      required_approving_review_count = 1
      required_status_checks          = false
    }
  }

  codeowners = {
    "*" = ["@emrecavunt"]
  }

  manage_repository_settings = true
  delete_branch_on_merge     = true
  has_issues                 = true
  has_wiki                   = false
  vulnerability_alerts       = true
}
