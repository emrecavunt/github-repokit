# Define the default target
.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Show help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Dependencies

TERRAGRUNT_CMD ?= terragrunt
TERRAFORM_CMD ?= terraform
TFLINT ?= tflint
TRIVY ?= trivy

# Run $(2) when binary $(1) is on PATH; $(3) is the skip noun.
define run-optional-tool
	@if command -v $(1) >/dev/null 2>&1; then \
		$(2); \
	else \
		echo "$(1) is not installed. Skipping $(3)."; \
	fi
endef

##@ Development

.PHONY: show
show: ## Show key Make variables
	@echo "TERRAGRUNT_CMD: $(TERRAGRUNT_CMD)"
	@echo "TERRAFORM_CMD: $(TERRAFORM_CMD)"

.PHONY: fmt
fmt: ## Format Terraform and Terragrunt files
	@echo "Formatting Terragrunt files..."
	@$(TERRAGRUNT_CMD) hcl format
	@echo "Formatting Terraform files..."
	@$(TERRAFORM_CMD) fmt -recursive

.PHONY: validate
validate: ## Validate Terraform and Terragrunt configurations
	@echo "Validating Terragrunt files..."
	@$(TERRAGRUNT_CMD) hcl validate --all --inputs

.PHONY: lint
lint: ## Run TFLint when available
	$(call run-optional-tool,$(TFLINT),$(TFLINT) --recursive,lint)

.PHONY: scan
scan: ## Run Trivy config scan when available
	$(call run-optional-tool,$(TRIVY),$(TRIVY) config .,scan)

.PHONY: tg-init
tg-init: ## Initialize Terragrunt and Terraform configurations
	$(TERRAGRUNT_CMD) init --all --non-interactive

.PHONY: tg-plan
tg-plan: ## Plan the Terraform configuration
	$(TERRAGRUNT_CMD) plan --all --non-interactive

.PHONY: tg-import-repo-settings
tg-import-repo-settings: ## Import existing repository settings resource (set REPO_NAME)
	@if [ -z "$(REPO_NAME)" ]; then \
		echo "Usage: make tg-import-repo-settings REPO_NAME=<repo-name>"; \
		exit 1; \
	fi
	cd repository && $(TERRAGRUNT_CMD) import "github_repository.settings[0]" "$(REPO_NAME)"

.PHONY: apply
apply: ## Apply the Terraform configuration
	$(TERRAGRUNT_CMD) apply --all --non-interactive --auto-approve

.PHONY: check
check: fmt validate lint scan ## Run format, validate, lint, and scan

.PHONY: all
all: ## Apply all Terraform configurations
	$(TERRAGRUNT_CMD) run --all --non-interactive apply --experiment cli-redesign

##@ Release Management
