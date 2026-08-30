include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/emrecavunt/github-repokit.git//modules/github-repository?ref=v1.0.0"
}

inputs = {
  repo_name                  = "fixture-missing-actions"
  manage_repository_settings = true
  owner_is_organization      = true
}
