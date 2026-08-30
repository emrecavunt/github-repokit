include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  github_org  = get_env("EXAMPLE_GITHUB_OWNER", "your-org")
  github_repo = get_env("EXAMPLE_GITHUB_REPO", "your-repo")
  github_user = get_env("EXAMPLE_GITHUB_USER", "your-github-username")
  codeowners  = get_env("EXAMPLE_CODEOWNERS", "@your-org/platform-engineers")
}

terraform {
  source = "../../../../modules/github-repository"
}

inputs = {
  repo_name   = local.github_repo
  description = "Example consumer repository"
  visibility  = "private"

  users = {
    maintainer = {
      username   = local.github_user
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
    "*" = [local.codeowners]
  }

  write_repository_actions_variables = false
  manage_repository_settings         = true
  delete_branch_on_merge             = true
  has_issues                         = true
  has_wiki                           = false
  vulnerability_alerts               = true
  owner_is_organization              = true
}
