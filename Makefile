SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

AWS_PROFILE ?= akinux
AWS_REGION ?= ap-northeast-2

FOUNDATION_DIR := infrastructure/aws-linux-lab/foundation
LAB_DIR := infrastructure/aws-linux-lab

.PHONY: help foundation-plan foundation-up foundation-output foundation-down-plan foundation-down lab-plan lab-up lab-output lab-status lab-node-1 lab-node-2 lab-down-plan lab-down lab-check

help: ## 사용 가능한 실습 명령을 표시합니다.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target> [AWS_PROFILE=%s]\n\n", "$(AWS_PROFILE)"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

foundation-plan: ## 수동 SSM 실습용 네트워크 생성 계획만 확인합니다.
	$(MAKE) -C $(FOUNDATION_DIR) plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

foundation-up: ## 수동 SSM 실습용 네트워크만 생성합니다.
	$(MAKE) -C $(FOUNDATION_DIR) plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)
	$(MAKE) -C $(FOUNDATION_DIR) apply AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) CONFIRM=manual-ssm-foundation

foundation-output: ## 수동 생성에 필요한 VPC·subnet·route table ID를 표시합니다.
	$(MAKE) -C $(FOUNDATION_DIR) output AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

foundation-down-plan: ## 수동 리소스 정리 후 네트워크 삭제 계획을 확인합니다.
	$(MAKE) -C $(FOUNDATION_DIR) destroy-plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

foundation-down: ## 수동 리소스 정리 후 네트워크 기반을 삭제합니다.
	$(MAKE) -C $(FOUNDATION_DIR) destroy AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) CONFIRM=destroy-manual-ssm-foundation

lab-plan: ## EC2 2대 완성형 Linux 실습실 생성 계획만 확인합니다.
	$(MAKE) -C $(LAB_DIR) plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-up: ## 비용이 발생하는 완성형 Linux 실습실을 생성합니다.
	$(MAKE) -C $(LAB_DIR) plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)
	$(MAKE) -C $(LAB_DIR) apply AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) CONFIRM=aws-linux-lab

lab-output: ## 완성형 실습실 Terraform output을 표시합니다.
	$(MAKE) -C $(LAB_DIR) output AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-status: ## 완성형 EC2와 SSM 등록 상태를 확인합니다.
	$(MAKE) -C $(LAB_DIR) status AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-node-1: ## 완성형 실습실 node-1에 SSM으로 접속합니다.
	$(MAKE) -C $(LAB_DIR) node-1 AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-node-2: ## 완성형 실습실 node-2에 SSM으로 접속합니다.
	$(MAKE) -C $(LAB_DIR) node-2 AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-down-plan: ## 완성형 실습실 삭제 계획을 확인합니다.
	$(MAKE) -C $(LAB_DIR) destroy-plan AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

lab-down: ## 완성형 Linux 실습실을 삭제합니다.
	$(MAKE) -C $(LAB_DIR) destroy AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) CONFIRM=destroy-aws-linux-lab

lab-check: ## 삭제 후 남은 완성형 EC2가 있는지 확인합니다.
	$(MAKE) -C $(LAB_DIR) check AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)
