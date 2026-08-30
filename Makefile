# Define the default target
.DEFAULT_GOAL := all
Version := v0.1.0

##@ General

.PHONY: help
help: ## List available targets
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
PYTHON ?= python3
RECURSIVE_FLAG ?= --terragrunt-include-dir-root --terragrunt-include-external-dependencies
TERRAGRUNT_DIR ?= bootstrap/github

# Tool Versions
TERRAGRUNT_VERSION ?= 0.81.10
TERRAFORM_VERSION ?= v1.12.2

# Run $(1) in TERRAGRUNT_DIR when that stack exists; otherwise print $(2).
define run-in-tg-dir
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(1); \
	else \
		echo "No $(TERRAGRUNT_DIR)/ stack found. $(2)"; \
	fi
endef

# Run $(3) when binary $(1) is on PATH; $(2) is the progress label, $(4) the skip noun.
define run-optional-tool
	@if command -v $(1) >/dev/null 2>&1; then \
		echo "Running $(2)..."; \
		$(3); \
	else \
		echo "$(1) is not installed. Skipping $(4)."; \
	fi
endef

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
validate: ## Validate each module and the Terragrunt stack
	@echo "Validating Terragrunt files..."
	$(call run-in-tg-dir,$(TERRAGRUNT_CMD) hcl validate --all --inputs,Skipping Terragrunt runtime validation.)
	@echo "Validating Terraform modules..."
	@for module in modules/*/; do \
		echo " - $$module"; \
		(cd "$$module" && $(TERRAFORM_CMD) validate) || exit 1; \
	done

.PHONY: lint
lint: ## Run TFLint when available
	$(call run-optional-tool,$(TFLINT),TFLint,$(TFLINT) --recursive,lint)

.PHONY: scan
scan: ## Run Trivy config scan when available
	$(call run-optional-tool,$(TRIVY),Trivy config scan,$(TRIVY) config .,scan)

.PHONY: plugin-check
plugin-check: ## Validate the agent plugin, marketplace catalog, and eval suites
	@echo "Checking plugin manifests and eval suites..."
	@$(PYTHON) tooling/plugin-check.py
	@$(PYTHON) tooling/skill-evals-check.py

.PHONY: tg-init
tg-init: ## Initialize the self-bootstrap Terragrunt stack
	$(call run-in-tg-dir,$(TERRAGRUNT_CMD) init --all --non-interactive,Nothing to initialize.)

.PHONY: tg-plan
tg-plan: ## Plan the self-bootstrap stack
	$(call run-in-tg-dir,$(TERRAGRUNT_CMD) plan --all --non-interactive,Nothing to plan.)

.PHONY: tg-import-repo-settings
tg-import-repo-settings: ## Import existing github_repository.settings[0] (set REPO_NAME)
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
apply: ## Apply the self-bootstrap stack
	$(call run-in-tg-dir,$(TERRAGRUNT_CMD) apply --all --non-interactive --auto-approve,Nothing to apply.)

# Run all checks
.PHONY: check
check: fmt validate lint scan plugin-check ## Format, validate, lint, scan, and plugin checks (what CI runs)

.PHONY: all
all: ## Apply the self-bootstrap stack, or run checks when no live stack exists
	@if [ -d "$(TERRAGRUNT_DIR)" ]; then \
		cd $(TERRAGRUNT_DIR) && $(TERRAGRUNT_CMD) run --all --non-interactive apply --experiment cli-redesign; \
	else \
		$(MAKE) check; \
	fi

##@ Release Management
