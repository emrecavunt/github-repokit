variable "service_account_project_id" {
  description = "Project id where the Terraform apply service account is created."
  type        = string
}

variable "service_account_id" {
  description = "Service account id for Terraform apply identity."
  type        = string
}

variable "service_account_display_name" {
  description = "Display name for Terraform apply service account."
  type        = string
}

variable "github_repository" {
  description = "Primary GitHub repository in owner/repo format allowed to impersonate the service account. Deprecated in favor of github_repositories."
  type        = string
  default     = ""

  validation {
    condition     = var.github_repository == "" || can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be empty or owner/repo using letters, digits, dot, underscore, and hyphen."
  }
}

variable "github_repositories" {
  description = "Set of GitHub repositories in owner/repo format allowed to impersonate the service account."
  type        = set(string)
  default     = []

  validation {
    condition     = length(compact(concat([var.github_repository], tolist(var.github_repositories)))) > 0
    error_message = "At least one trusted repository must be provided via github_repository or github_repositories."
  }

  validation {
    condition = alltrue([
      for repo in var.github_repositories :
      can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", repo))
    ])
    error_message = "Each github_repositories value must be owner/repo using letters, digits, dot, underscore, and hyphen."
  }
}

variable "workload_identity_pool_name" {
  description = "Existing workload identity pool full resource name (projects/<number>/locations/global/workloadIdentityPools/<pool>). Required when create_project_wif_provider=false."
  type        = string
  default     = ""
}

variable "workload_identity_provider_name" {
  description = "Existing workload identity provider full resource name used by GitHub Actions auth. Required when create_project_wif_provider=false."
  type        = string
  default     = ""

  validation {
    condition = var.create_project_wif_provider || (
      length(trim(var.workload_identity_pool_name)) > 0 &&
      length(trim(var.workload_identity_provider_name)) > 0
    )
    error_message = "workload_identity_pool_name and workload_identity_provider_name must be set when create_project_wif_provider=false."
  }
}

variable "create_project_wif_provider" {
  description = "Whether to create a dedicated GitHub Workload Identity Pool + Provider in service_account_project_id."
  type        = bool
  default     = false
}

variable "workload_identity_pool_id" {
  description = "Workload identity pool ID when create_project_wif_provider=true."
  type        = string
  default     = "github"
}

variable "workload_identity_provider_id" {
  description = "Workload identity provider ID when create_project_wif_provider=true."
  type        = string
  default     = "github"
}

variable "github_owner" {
  description = "GitHub organization or user expected in OIDC claims when create_project_wif_provider=true."
  type        = string
  default     = ""

  validation {
    condition     = var.github_owner == "" || can(regex("^[A-Za-z0-9._-]+$", var.github_owner))
    error_message = "github_owner must be empty or a GitHub login using letters, digits, dot, underscore, and hyphen."
  }
}

variable "github_provider_attribute_condition" {
  description = "Optional OIDC provider attribute condition override when create_project_wif_provider=true. When null, the default matches github_owner and the trusted repository list."
  type        = string
  default     = null
  nullable    = true
}

variable "target_project_roles" {
  description = "Map of project_id => list of roles granted to the Terraform apply service account."
  type        = map(list(string))
}
