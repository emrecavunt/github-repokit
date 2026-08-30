locals {
  codeowners_lines = [
    for pattern, owners in var.codeowners :
    "${pattern} ${join(" ", owners)}"
  ]

  permission_aliases = {
    read  = "pull"
    write = "push"
  }

  normalized_teams = {
    for key, team in var.teams : key => merge(team, {
      permission = lookup(local.permission_aliases, lower(team.permission), lower(team.permission))
    })
  }

  normalized_users = {
    for key, user in var.users : key => merge(user, {
      permission = lookup(local.permission_aliases, lower(user.permission), lower(user.permission))
    })
  }

  normalized_github_environments = toset([for environment in var.github_environments : trimspace(environment)])

  legacy_environment_definitions = {
    for environment in local.normalized_github_environments : environment => {
      can_admins_bypass   = false
      prevent_self_review = true
      reviewer_team_ids   = []
      reviewer_user_ids   = []
      protected           = false
      variables           = var.github_actions_variables
    }
  }

  configured_environment_definitions = {
    for environment, config in var.github_environment_configs : trimspace(environment) => {
      can_admins_bypass   = try(config.can_admins_bypass, false)
      prevent_self_review = try(config.prevent_self_review, true)
      reviewer_team_ids   = try(config.reviewer_team_ids, [])
      reviewer_user_ids   = try(config.reviewer_user_ids, [])
      protected           = try(config.protected, false)
      variables           = try(config.variables, {})
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

data "github_team" "by_slug" {
  for_each = local.normalized_teams
  slug     = each.value.slug
}

resource "github_team_repository" "this" {
  for_each = local.normalized_teams

  team_id    = data.github_team.by_slug[each.key].id
  repository = var.repo_name
  permission = each.value.permission
}

resource "github_repository_collaborator" "this" {
  for_each = local.normalized_users

  repository = var.repo_name
  username   = each.value.username
  permission = each.value.permission
}

# Adopt an already-created GitHub repo instead of POSTing /orgs/.../repos
# (422 "name already exists"). No-op once the address is in state.
# Set import_existing_repository = false only when this stack should create
# a brand-new repository.
import {
  for_each = var.manage_repository_settings && var.import_existing_repository ? { this = var.repo_name } : {}
  to       = github_repository.settings[0]
  id       = each.value
}

resource "github_repository" "settings" {
  count = var.manage_repository_settings ? 1 : 0

  name                   = var.repo_name
  description            = var.description
  visibility             = var.visibility
  homepage_url           = var.homepage_url
  topics                 = var.topics
  has_issues             = var.has_issues
  has_wiki               = var.has_wiki
  vulnerability_alerts   = var.vulnerability_alerts
  delete_branch_on_merge = var.delete_branch_on_merge
  archive_on_destroy     = var.archive_on_destroy
}

resource "github_repository_environment" "this" {
  for_each = local.environment_definitions

  repository  = var.repo_name
  environment = each.key

  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review

  dynamic "reviewers" {
    for_each = length(each.value.reviewer_team_ids) > 0 || length(each.value.reviewer_user_ids) > 0 ? [1] : []

    content {
      teams = each.value.reviewer_team_ids
      users = each.value.reviewer_user_ids
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.protected ? [1] : []

    content {
      protected_branches     = true
      custom_branch_policies = false
    }
  }
}

resource "github_actions_environment_variable" "this" {
  for_each = local.actions_environment_variable_matrix

  repository    = var.repo_name
  environment   = each.value.environment
  variable_name = each.value.variable_name
  value         = each.value.value

  depends_on = [github_repository_environment.this]
}

resource "github_actions_variable" "repo_variables" {
  for_each = var.write_repository_actions_variables ? var.github_actions_variables : {}

  repository    = var.repo_name
  variable_name = each.key
  value         = each.value
}

resource "github_branch_protection_v3" "this" {
  for_each = var.branch_protection_rules

  repository                      = var.repo_name
  branch                          = each.value.pattern
  enforce_admins                  = each.value.enforce_admins
  require_signed_commits          = each.value.require_signed_commits
  require_conversation_resolution = each.value.require_conversation_resolution

  required_status_checks {
    strict = each.value.required_status_checks ? each.value.strict_status_checks : false
    checks = each.value.required_status_checks ? each.value.required_status_check_contexts : []
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = each.value.dismiss_stale_reviews
    require_code_owner_reviews      = each.value.require_code_owner_reviews
    required_approving_review_count = each.value.required_approving_review_count
  }

  dynamic "restrictions" {
    for_each = each.value.restrict_push_access ? [1] : []

    content {
      teams = each.value.push_restrictions_teams
      users = each.value.push_restrictions_users
      apps  = each.value.push_restrictions_apps
    }
  }
}

resource "github_repository_file" "codeowners" {
  count = length(var.codeowners) > 0 ? 1 : 0

  repository          = var.repo_name
  branch              = var.codeowners_branch
  file                = var.codeowners_file_path
  content             = "${join("\n", local.codeowners_lines)}\n"
  commit_message      = var.codeowners_commit_message
  overwrite_on_create = true
}
