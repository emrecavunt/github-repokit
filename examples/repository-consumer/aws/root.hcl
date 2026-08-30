locals {
  aws_region = get_env("EXAMPLE_AWS_REGION", "eu-west-1")
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
provider "aws" {
  region = var.example_aws_region
}

variable "example_aws_region" {
  type = string
}
EOF2
}

inputs = {
  example_aws_region = local.aws_region
}
