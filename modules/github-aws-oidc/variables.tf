variable "additional_policy_arns" {
  description = "Existing IAM policy ARNs attached to the GitHub Actions role for permissions beyond secrets read."
  type        = list(string)
  default     = []
}

variable "allowed_environments" {
  description = "GitHub environment names allowed to assume the role. When empty, each trusted repository may assume the role from any job (repo:owner/repo:*)."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for environment in var.allowed_environments :
      trimspace(environment) != ""
    ])
    error_message = "allowed_environments cannot contain empty values."
  }
}

variable "create_oidc_provider" {
  description = "When true, create the account-level GitHub OIDC provider. Set false and pass oidc_provider_arn to reuse an existing provider."
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "GitHub organization or user login used to validate trusted repository names."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.github_owner))
    error_message = "github_owner must be a GitHub login using letters, digits, dot, underscore, and hyphen."
  }
}

variable "github_repositories" {
  description = "Set of GitHub repositories in owner/repo format allowed to assume the role."
  type        = set(string)

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "github_repositories must contain at least one owner/repo value."
  }

  validation {
    condition = alltrue([
      for repo in var.github_repositories :
      can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", repo))
    ])
    error_message = "Each github_repositories value must be owner/repo using letters, digits, dot, underscore, and hyphen."
  }

  validation {
    condition = alltrue([
      for repo in var.github_repositories :
      startswith(repo, "${var.github_owner}/")
    ])
    error_message = "Each github_repositories value must start with github_owner/."
  }
}

variable "kms_key_arns" {
  description = "KMS key ARNs the role may use to decrypt Secrets Manager or SSM values. Leave empty when secrets use the AWS-managed key."
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the assumed role."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "oidc_audiences" {
  description = "OIDC audiences allowed to assume the role. aws-actions/configure-aws-credentials sends sts.amazonaws.com."
  type        = list(string)
  default     = ["sts.amazonaws.com"]

  validation {
    condition     = length(var.oidc_audiences) > 0
    error_message = "oidc_audiences must contain at least one audience."
  }
}

variable "oidc_provider_arn" {
  description = "Existing IAM OIDC provider ARN. Required when create_oidc_provider is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_oidc_provider || length(trimspace(var.oidc_provider_arn)) > 0
    error_message = "oidc_provider_arn must be set when create_oidc_provider is false."
  }
}

variable "oidc_thumbprints" {
  description = "Optional SHA-1 thumbprints for the GitHub OIDC provider. When empty, thumbprints are taken from the live GitHub certificate chain."
  type        = list(string)
  default     = []
}

variable "role_description" {
  description = "Human-readable description stored on the IAM role assumed by GitHub Actions."
  type        = string
  default     = "GitHub Actions OIDC role for reading AWS secrets."
}

variable "role_name" {
  description = "IAM role name assumed by GitHub Actions via OIDC."
  type        = string
}

variable "secretsmanager_secret_arns" {
  description = "Secrets Manager secret ARNs the role may read. Supports a trailing * for prefix matches."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "SSM Parameter Store ARNs the role may read. Supports a trailing * for prefix matches."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the IAM role and, when created, the OIDC provider."
  type        = map(string)
  default     = {}
}
