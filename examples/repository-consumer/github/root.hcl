locals {
  github_owner = get_env("GITHUB_OWNER", get_env("EXAMPLE_GITHUB_OWNER", "your-org"))
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
variable "github_owner" {
  description = "GitHub organization or user owner."
  type        = string
}

provider "github" {
  owner = var.github_owner
}
EOF2
}

inputs = {
  github_owner = local.github_owner
}
