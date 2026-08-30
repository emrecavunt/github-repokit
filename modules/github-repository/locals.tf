locals {
  repository_owner = split("/", data.github_repository.current.full_name)[0]

  codeowners_lines = [
    for pattern, owners in var.codeowners :
    "${pattern} ${join(" ", owners)}"
  ]

  permission_aliases = {
    read  = "pull"
    write = "push"
  }

  normalized_teams = var.owner_is_organization ? {
    for key, team in var.teams : key => merge(team, {
      permission = lookup(local.permission_aliases, lower(team.permission), lower(team.permission))
    })
  } : {}

  normalized_users = {
    for key, user in var.users : key => merge(user, {
      permission = lookup(local.permission_aliases, lower(user.permission), lower(user.permission))
    })
    if lower(user.username) != lower(local.repository_owner)
  }

  configured_environment_definitions = {
    for environment, config in var.github_environment_configs : trimspace(environment) => {
      can_admins_bypass   = config.can_admins_bypass
      prevent_self_review = config.prevent_self_review
      reviewer_team_ids   = config.reviewer_team_ids
      reviewer_user_ids   = config.reviewer_user_ids
      protected           = config.protected
      variables           = config.variables
    }
  }

  legacy_environment_definitions = {
    for environment in toset([for name in var.github_environments : trimspace(name)]) : environment => {
      can_admins_bypass   = false
      prevent_self_review = true
      reviewer_team_ids   = []
      reviewer_user_ids   = []
      protected           = false
      variables           = var.github_actions_variables
    }
  }

  environment_definitions = merge(local.legacy_environment_definitions, local.configured_environment_definitions)

  actions_environment_variable_matrix = {
    for item in flatten([
      for environment, config in local.environment_definitions : [
        for variable_name, value in config.variables : {
          key           = "${environment}:${variable_name}"
          environment   = environment
          variable_name = variable_name
          value         = value
        }
      ]
    ]) : item.key => item
  }
}
