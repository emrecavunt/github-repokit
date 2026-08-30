locals {
  project_id = get_env("GCP_PROJECT_ID", "your-gcp-project")
  region     = get_env("GCP_REGION", "europe-west1")

  state_backend    = get_env("TG_STATE_BACKEND", "local")
  state_bucket     = get_env("TG_STATE_BUCKET", "")
  state_prefix     = get_env("TG_STATE_PREFIX", "bootstrap/gcp")
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
  contents  = <<EOF2
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}
EOF2
}

inputs = {
  gcp_project_id = local.project_id
  gcp_region     = local.region
}
