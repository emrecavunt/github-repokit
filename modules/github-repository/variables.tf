variable "repo_name" {
  description = "Repository name to manage."
  type        = string
}

variable "teams" {
  description = "Team access definitions keyed by an arbitrary name."
  type = map(object({
    slug       = string
    permission = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for team in values(var.teams) :
      contains(["read", "pull", "triage", "write", "push", "maintain", "admin"], lower(team.permission))
    ])
    error_message = "teams[*].permission must be one of read, pull, triage, write, push, maintain, admin."
  }
}

variable "users" {
  description = "User collaborator access definitions keyed by an arbitrary name."
  type = map(object({
    username   = string
    permission = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for user in values(var.users) :
      contains(["read", "pull", "triage", "write", "push", "maintain", "admin"], lower(user.permission))
    ])
    error_message = "users[*].permission must be one of read, pull, triage, write, push, maintain, admin."
  }
}

variable "branch_protection_rules" {
  description = "Branch protection definitions keyed by an arbitrary name. Pattern should be an exact branch name for v3 protection."
  type = map(object({
    pattern                         = string
    enforce_admins                  = optional(bool, true)
    require_signed_commits          = optional(bool, true)
    dismiss_stale_reviews           = optional(bool, true)
    require_conversation_resolution = optional(bool, true)
    restrict_push_access            = optional(bool, false)
    push_restrictions_teams         = optional(list(string), [])
    push_restrictions_users         = optional(list(string), [])
    push_restrictions_apps          = optional(list(string), [])
    require_code_owner_reviews      = optional(bool, true)
    required_approving_review_count = optional(number, 1)
    required_status_checks          = optional(bool, true)
    required_status_check_contexts  = optional(list(string), [])
    strict_status_checks            = optional(bool, true)
  }))
  default = {}
}

variable "codeowners" {
  description = "CODEOWNERS entries keyed by file pattern."
  type        = map(list(string))
  default     = {}
}

variable "codeowners_branch" {
  description = "Branch where CODEOWNERS file is managed."
  type        = string
  default     = "main"
}

variable "codeowners_file_path" {
  description = "Path for CODEOWNERS file in repository."
  type        = string
  default     = ".github/CODEOWNERS"
}

variable "codeowners_commit_message" {
  description = "Commit message used to write CODEOWNERS."
  type        = string
  default     = "chore: manage CODEOWNERS via terraform"
}

variable "manage_repository_settings" {
  description = "Whether to manage repository-level settings via github_repository resource."
  type        = bool
  default     = false
}

variable "import_existing_repository" {
  description = "When managing settings, import github_repository.settings[0] by repo_name if it is not already in state. Default true because most consumers adopt an existing repository. Set false only to create a new repository."
  type        = bool
  default     = true
}

variable "archive_on_destroy" {
  description = "When managing settings, archive the GitHub repository if this stack is destroyed."
  type        = bool
  default     = true
}

variable "delete_branch_on_merge" {
  description = "Automatically delete head branches after pull requests are merged."
  type        = bool
  default     = false
}

variable "description" {
  description = "Description of the repository."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "Repository visibility: public, private, or internal."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "visibility must be one of public, private, internal."
  }
}

variable "homepage_url" {
  description = "Optional homepage URL shown on the GitHub repository page."
  type        = string
  default     = ""
}

variable "topics" {
  description = "GitHub repository topics."
  type        = list(string)
  default     = []
}

variable "has_issues" {
  description = "Whether GitHub Issues are enabled."
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Whether the GitHub Wiki is enabled."
  type        = bool
  default     = false
}

variable "vulnerability_alerts" {
  description = "Whether Dependabot vulnerability alerts are enabled."
  type        = bool
  default     = true
}

variable "github_environments" {
  description = "GitHub environments to manage for the repository."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for environment in var.github_environments : trimspace(environment) != ""])
    error_message = "github_environments cannot contain empty values."
  }
}

variable "github_environment_configs" {
  description = "Per-environment GitHub configuration. When set, this overrides legacy github_environments/github_actions_variables for matching environment names. Set protected = true to restrict deploys to protected branches (typically main)."
  type = map(object({
    variables           = optional(map(string), {})
    can_admins_bypass   = optional(bool, false)
    prevent_self_review = optional(bool, true)
    reviewer_team_ids   = optional(list(number), [])
    reviewer_user_ids   = optional(list(number), [])
    protected           = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for environment in keys(var.github_environment_configs) :
      trimspace(environment) != ""
    ])
    error_message = "github_environment_configs keys cannot be empty."
  }
}

variable "github_actions_variables" {
  description = "GitHub Actions variables to set (fan-out to each configured environment and optionally to repository scope)."
  type        = map(string)
  default     = {}
}

variable "write_repository_actions_variables" {
  description = "Whether to also write repository-scoped GitHub Actions variables."
  type        = bool
  default     = false
}
