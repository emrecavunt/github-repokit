locals {
  example_project_id = get_env("EXAMPLE_GCP_PROJECT_ID", "your-gcp-project")
  region             = get_env("EXAMPLE_GCP_REGION", "europe-west1")
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_parent_terragrunt_dir()}/.terragrunt-state/${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF2
provider "google" {
  project = var.example_project_id
  region  = var.example_region
}

variable "example_project_id" {
  type = string
}

variable "example_region" {
  type = string
}
EOF2
}

inputs = {
  example_project_id = local.example_project_id
  example_region     = local.region
}
