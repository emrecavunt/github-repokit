include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  codeowners = get_env("CODEOWNERS", "@your-org/platform-engineers")
}

terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-repository?ref=v1.0.0"
}

inputs = {
  repo_name   = "<REPO_NAME>"
  description = "<DESCRIPTION>"
  visibility  = "private"

  owner_is_organization = true

  teams = {}

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
}
