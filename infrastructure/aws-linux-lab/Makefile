SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

AWS_PROFILE ?= default
AWS_REGION ?= ap-northeast-2
TF ?= terraform
PLAN_FILE ?= lab.tfplan
CONFIRM ?=

export AWS_PROFILE
export AWS_REGION
export AWS_DEFAULT_REGION := $(AWS_REGION)
export TF_VAR_aws_region := $(AWS_REGION)
export TF_CLI_CONFIG_FILE := $(CURDIR)/terraform-cli.tfrc

.PHONY: help preflight init fmt validate plan apply output status node-1 node-2 destroy-plan destroy check clean

help: ## Show available lab commands.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target> AWS_PROFILE=<profile>\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

preflight: ## Verify local tools and the active AWS identity without creating resources.
	@command -v $(TF) >/dev/null
	@command -v aws >/dev/null
	@command -v session-manager-plugin >/dev/null
	@command -v jq >/dev/null
	@aws sts get-caller-identity >/dev/null
	@printf 'AWS identity verified (profile=%s, region=%s)\n' "$(AWS_PROFILE)" "$(AWS_REGION)"

init: ## Initialize Terraform providers without creating resources.
	$(TF) init

fmt: ## Format Terraform configuration.
	$(TF) fmt -recursive

validate: init fmt ## Validate Terraform configuration.
	$(TF) validate

plan: validate preflight ## Create a reviewable saved plan; no resources are created.
	$(TF) plan -out=$(PLAN_FILE)

apply: ## Apply the saved plan (cost starts). Requires CONFIRM=aws-linux-lab.
	@test "$(CONFIRM)" = "aws-linux-lab" || { echo 'Refusing: run make apply CONFIRM=aws-linux-lab'; exit 2; }
	@test -f "$(PLAN_FILE)" || { echo 'Missing saved plan: run make plan first'; exit 2; }
	$(TF) apply $(PLAN_FILE)

output: ## Show Terraform outputs.
	$(TF) output

status: ## Show lab EC2 and SSM status.
	@aws ec2 describe-instances --filters Name=tag:Project,Values=devops-learning Name=tag:Environment,Values=lab Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,Id:InstanceId,State:State.Name,PrivateIp:PrivateIpAddress,Type:InstanceType}' --output table
	@aws ssm describe-instance-information --filters Key=tag:Project,Values=devops-learning --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Platform:PlatformName,Version:PlatformVersion}' --output table

node-1: ## Open an SSM session to node 1.
	@aws ssm start-session --target "$$($(TF) output -json node_ids | jq -r '.[0]')"

node-2: ## Open an SSM session to node 2.
	@aws ssm start-session --target "$$($(TF) output -json node_ids | jq -r '.[1]')"

destroy-plan: preflight ## Preview all resources that Terraform will destroy.
	$(TF) plan -destroy

destroy: ## Destroy the lab. Requires CONFIRM=destroy-aws-linux-lab.
	@test "$(CONFIRM)" = "destroy-aws-linux-lab" || { echo 'Refusing: run make destroy CONFIRM=destroy-aws-linux-lab'; exit 2; }
	$(TF) destroy

check: ## Check for remaining tagged EC2 instances after destroy.
	@aws ec2 describe-instances --filters Name=tag:Project,Values=devops-learning Name=tag:Environment,Values=lab Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,Id:InstanceId,State:State.Name}' --output table

clean: ## Remove only local generated plan files.
	rm -f -- $(PLAN_FILE)
