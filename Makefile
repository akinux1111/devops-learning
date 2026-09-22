SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

AWS_PROFILE ?= akinux
AWS_REGION ?= ap-northeast-2

FOUNDATION_DIR := infrastructure/aws-linux-lab/foundation
LAB_DIR := infrastructure/aws-linux-lab
OPS_JOB_DIR := infrastructure/aws-ops-job-lab

.PHONY: help foundation-plan foundation-up foundation-output foundation-down-plan foundation-down lab-plan lab-up lab-output lab-status lab-node-1 lab-node-2 lab-down-plan lab-down lab-check 00-up 00-check 00-down 01-up 01-check 01-down 02-up 02-check 02-test 02-down 03-up 03-check 03-test 03-down 04-up 04-check 04-test 04-down 05-up 05-check 05-test 05-down 06-up 06-check 06-test 06-down

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

00-up 00-check 00-down: ## 공고 실습 공통 환경을 준비·확인·정리합니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

01-up 01-check 01-down: ## EC2·VPC·ALB/NLB·S3·IAM·Route53 운영 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

02-up 02-check 02-test 02-down: ## CloudWatch와 Application Event 대응 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

03-up 03-check 03-test 03-down: ## Linux 서버 장애와 dump 분석 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

04-up 04-check 04-test 04-down: ## 로그 수집·S3·Athena 분석 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

05-up 05-check 05-test 05-down: ## EC2·EBS·S3 비용 최적화 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)

06-up 06-check 06-test 06-down: ## 종합 장애 대응과 재발 방지 실습입니다.
	$(MAKE) -C $(OPS_JOB_DIR) $@ AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION)
