locals {
  github_owner = get_env("GITHUB_OWNER", "emrecavunt")

  # State backend is opt-in remote: local (default) | s3 | gcs.
  # s3 and gcs require TG_STATE_BUCKET; the bucket must already exist.
  state_backend    = get_env("TG_STATE_BACKEND", "local")
  state_bucket     = get_env("TG_STATE_BUCKET", "")
  state_prefix     = get_env("TG_STATE_PREFIX", "github-repokit/bootstrap/github")
  state_aws_region = get_env("TG_STATE_AWS_REGION", get_env("AWS_REGION", "eu-west-1"))
  state_lock_table = get_env("TG_STATE_DYNAMODB_TABLE", "")
}

remote_state {
  backend = local.state_backend
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = merge(
    local.state_backend == "local" ? {
      path = "${get_parent_terragrunt_dir()}/.terragrunt-state/${path_relative_to_include()}/terraform.tfstate"
    } : {},
    local.state_backend == "s3" ? {
      bucket  = local.state_bucket
      key     = "${local.state_prefix}/${path_relative_to_include()}/terraform.tfstate"
      region  = local.state_aws_region
      encrypt = true
    } : {},
    local.state_backend == "s3" && local.state_lock_table != "" ? {
      dynamodb_table = local.state_lock_table
    } : {},
    local.state_backend == "gcs" ? {
      bucket = local.state_bucket
      prefix = "${local.state_prefix}/${path_relative_to_include()}"
    } : {},
  )
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "github_owner" {
  description = "GitHub organization or user that owns the repository."
  type        = string
}

provider "github" {
  owner = var.github_owner
}
EOF
}

inputs = {
  github_owner = local.github_owner
}
