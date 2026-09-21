SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

AWS_PROFILE ?= default
AWS_REGION ?= ap-northeast-2
TF ?= terraform
PLAN_FILE ?= foundation.tfplan
CONFIRM ?=

export AWS_PROFILE
export AWS_REGION
export AWS_DEFAULT_REGION := $(AWS_REGION)
export TF_VAR_aws_region := $(AWS_REGION)
export TF_CLI_CONFIG_FILE := $(CURDIR)/terraform-cli.tfrc

.PHONY: help preflight init fmt validate plan apply output destroy-plan destroy clean

help: ## Show foundation commands.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target> AWS_PROFILE=<profile>\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

preflight: ## Verify tools and AWS identity without creating resources.
	@command -v $(TF) >/dev/null
	@command -v aws >/dev/null
	@aws sts get-caller-identity >/dev/null
	@printf 'AWS identity verified (profile=%s, region=%s)\n' "$(AWS_PROFILE)" "$(AWS_REGION)"

init: ## Initialize Terraform providers.
	$(TF) init

fmt: ## Format Terraform files.
	$(TF) fmt -recursive

validate: init fmt ## Validate the foundation configuration.
	$(TF) validate

plan: validate preflight ## Save a plan containing only network foundation resources.
	$(TF) plan -out=$(PLAN_FILE)

apply: ## Create the network foundation. Requires CONFIRM=manual-ssm-foundation.
	@test "$(CONFIRM)" = "manual-ssm-foundation" || { echo 'Refusing: run make apply CONFIRM=manual-ssm-foundation'; exit 2; }
	@test -f "$(PLAN_FILE)" || { echo 'Missing saved plan: run make plan first'; exit 2; }
	$(TF) apply $(PLAN_FILE)

output: ## Print IDs needed for the manual console exercise.
	$(TF) output

destroy-plan: preflight ## Preview foundation deletion; delete manual resources first.
	$(TF) plan -destroy

destroy: ## Delete the foundation after manual resources. Requires CONFIRM=destroy-manual-ssm-foundation.
	@test "$(CONFIRM)" = "destroy-manual-ssm-foundation" || { echo 'Refusing: run make destroy CONFIRM=destroy-manual-ssm-foundation'; exit 2; }
	$(TF) destroy

clean: ## Remove only the generated saved plan.
	rm -f -- $(PLAN_FILE)
