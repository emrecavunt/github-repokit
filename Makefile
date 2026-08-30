# Define the default target
.DEFAULT_GOAL := all
Version := v0.1.0

##@ General

.PHONY: help
help: ## Show help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Dependencies

# Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

# Tool Binaries
TERRAGRUNT_CMD ?= terragrunt
TERRAFORM_CMD ?= terraform
TFLINT ?= tflint
TRIVY ?= trivy
RECURSIVE_FLAG ?= --terragrunt-include-dir-root --terragrunt-include-external-dependencies
TERRAGRUNT_DIR ?= bootstrap/github

# Tool Versions
TERRAGRUNT_VERSION ?= 0.81.10
TERRAFORM_VERSION ?= v1.12.2

##@ Development

.PHONY: show
show: ## Show key Make variables
	@echo "Version: $(Version)"
	@echo "LOCALBIN: $(LOCALBIN)"
	@echo "TERRAGRUNT_CMD: $(TERRAGRUNT_CMD)"
	@echo "TERRAFORM_CMD: $(TERRAFORM_CMD)"
	@echo "TERRAGRUNT_DIR: $(TERRAGRUNT_DIR)"
	@echo "RECURSIVE_FLAG: $(RECURSIVE_FLAG)"
	@echo "TERRAGRUNT_VERSION: $(TERRAGRUNT_VERSION)"
	@echo "TERRAFORM_VERSION: $(TERRAFORM_VERSION)"

.PHONY: fmt
fmt: ## Format Terraform and Terragrunt files
	@echo "Formatting Terragrunt files..."
	@$(TERRAGRUNT_CMD) hcl format
	@echo "Formatting Terraform files..."
	@$(TERRAFORM_CMD) fmt -recursive

.PHONY: validate
validate: ## Validate Terraform and Terragrunt configurations
	@echo "Validating Terragrunt files..."
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) hcl validate --all --inputs; \
	else \
		echo "No $(TERRAGRUNT_DIR)/ stack found. Skipping Terragrunt runtime validation."; \
	fi
	@echo "Validating Terraform modules..."
	@for module in modules/*; do \
		if [ -d "$$module" ]; then \
			echo " - $$module"; \
			(cd "$$module" && $(TERRAFORM_CMD) validate) || exit 1; \
		fi; \
	done

.PHONY: lint
lint: ## Run TFLint when available
	@if command -v $(TFLINT) >/dev/null 2>&1; then \
		echo "Running TFLint..."; \
		$(TFLINT) --recursive; \
	else \
		echo "tflint is not installed. Skipping lint."; \
	fi

.PHONY: scan
scan: ## Run Trivy config scan when available
	@if command -v $(TRIVY) >/dev/null 2>&1; then \
		echo "Running Trivy config scan..."; \
		$(TRIVY) config .; \
	else \
		echo "trivy is not installed. Skipping scan."; \
	fi

.PHONY: tg-init
tg-init: ## Initialize Terragrunt and Terraform configurations
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) init --all --non-interactive; \
	else \
		echo "No $(TERRAGRUNT_DIR)/ stack found. Nothing to initialize."; \
	fi

.PHONY: tg-plan
tg-plan: ## Plan the Terraform configuration
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) plan --all --non-interactive; \
	else \
		echo "No $(TERRAGRUNT_DIR)/ stack found. Nothing to plan."; \
	fi

.PHONY: tg-import-repo-settings
tg-import-repo-settings: ## Import existing repository settings resource (set REPO_NAME)
	@if [ -z "$(REPO_NAME)" ]; then \
		echo "Usage: make tg-import-repo-settings REPO_NAME=<repo-name>"; \
		exit 1; \
	fi
	@if [ -d "$(TERRAGRUNT_DIR)/repository" ]; then \
		cd $(TERRAGRUNT_DIR)/repository && $(TERRAGRUNT_CMD) import "github_repository.settings[0]" "$(REPO_NAME)"; \
	else \
		echo "No $(TERRAGRUNT_DIR)/repository stack found. Nothing to import."; \
	fi

.PHONY: apply
apply: ## Apply the Terraform configuration
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) apply --all --non-interactive --auto-approve; \
	else \
		echo "No $(TERRAGRUNT_DIR)/ stack found. Nothing to apply."; \
	fi

# Run all checks
.PHONY: check
check: fmt validate lint scan ## Run format, validate, lint, and scan

.PHONY: all
all: ## Apply all Terraform configurations (or run checks if no live stack exists)
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) run --all --non-interactive apply --experiment cli-redesign; \
	else \
		$(MAKE) check; \
	fi

##@ Release Management
