locals {
  github_owner = get_env("GITHUB_OWNER", "your-org")
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
  contents  = <<PROVIDER
variable "github_owner" {
  type = string
}

provider "github" {
  owner = var.github_owner
}
PROVIDER
}

inputs = {
  github_owner = local.github_owner
}
