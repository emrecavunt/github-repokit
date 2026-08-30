.DEFAULT_GOAL := help

.PHONY: help fmt validate tg-init tg-plan apply tg-import-repo-settings

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

fmt: ## Format Terraform and Terragrunt files
	terragrunt hcl format
	terraform fmt -recursive

validate: ## Validate the Terragrunt stack
	terragrunt hcl validate --all --inputs

tg-init: ## Initialize the GitHub Terragrunt stacks
	terragrunt run --all init --non-interactive

tg-plan: ## Plan the GitHub stacks
	terragrunt run --all plan --non-interactive

apply: ## Apply the GitHub stacks
	terragrunt run --all apply --non-interactive --no-auto-approve

tg-import-repo-settings: ## Import existing github_repository.settings[0] (set REPO_NAME)
	@if [ -z "$(REPO_NAME)" ]; then \
		echo "Usage: make tg-import-repo-settings REPO_NAME=<repo-name>"; \
		exit 1; \
	fi
	cd repository && terragrunt import "github_repository.settings[0]" "$(REPO_NAME)"
