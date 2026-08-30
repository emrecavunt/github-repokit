output "repository" {
  description = "Managed repository name."
  value       = var.repo_name
}

output "team_repository_assignments" {
  description = "Managed team to repository assignments."
  value = {
    for key, resource in github_team_repository.this : key => {
      team_id    = resource.team_id
      permission = resource.permission
    }
  }
}

output "user_collaborators" {
  description = "Managed user collaborators."
  value = {
    for key, resource in github_repository_collaborator.this : key => {
      username   = resource.username
      permission = resource.permission
    }
  }
}

output "branch_protection_rules" {
  description = "Managed branch protection rule keys."
  value       = keys(github_branch_protection_v3.this)
}

output "repository_settings_managed" {
  description = "Whether repository settings management is enabled."
  value       = var.manage_repository_settings
}

output "github_environments" {
  description = "Managed GitHub environment names."
  value       = sort(keys(github_repository_environment.this))
}

output "github_actions_variable_names" {
  description = "Managed GitHub Actions variable names."
  value = {
    environment = distinct([for resource in github_actions_environment_variable.this : resource.variable_name])
    repository  = keys(github_actions_variable.repo_variables)
  }
}
