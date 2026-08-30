output "repository" {
  description = "Name of the managed GitHub repository."
  value       = var.repo_name
}

output "team_repository_assignments" {
  description = "Team-to-repository permission assignments created by this module."
  value = {
    for key, resource in github_team_repository.this : key => {
      team_id    = resource.team_id
      permission = resource.permission
    }
  }
}

output "user_collaborators" {
  description = "User collaborators and their repository permissions."
  value = {
    for key, resource in github_repository_collaborator.this : key => {
      username   = resource.username
      permission = resource.permission
    }
  }
}

output "branch_protection_rules" {
  description = "Keys of the branch protection rules this module manages."
  value       = keys(github_branch_protection_v3.this)
}

output "repository_settings_managed" {
  description = "Whether this stack owns github_repository settings."
  value       = var.manage_repository_settings
}

output "github_environments" {
  description = "Names of the GitHub environments this module manages."
  value       = sort(keys(github_repository_environment.this))
}

output "github_actions_variable_names" {
  description = "GitHub Actions variable names written at environment and repository scope."
  value = {
    environment = distinct([for resource in github_actions_environment_variable.this : resource.variable_name])
    repository  = keys(github_actions_variable.repo_variables)
  }
}
