SHELL := /bin/bash
TFVARS := $(CURDIR)/terraform.tfvars
TFVARS_EXAMPLE := $(CURDIR)/terraform.tfvars.example

.PHONY: help ensure-config 00-up 00-check 00-down fmt validate \
	01-up 01-check 01-down \
	02-up 02-check 02-test 02-down \
	03-up 03-check 03-test 03-down \
	04-up 04-check 04-test 04-down \
	05-up 05-check 05-test 05-down \
	06-up 06-check 06-test 06-down

help:
	@echo "사용법: make <번호>-up|check|test|down"
	@echo "처음에는 cp terraform.tfvars.example terraform.tfvars && make 00-check"

ensure-config:
	@if [[ ! -f "$(TFVARS)" ]]; then \
		cp "$(TFVARS_EXAMPLE)" "$(TFVARS)"; \
		echo "기본 설정으로 terraform.tfvars를 생성했습니다."; \
	fi

00-up: 00-check
	@echo "공통 준비 완료 (AWS 리소스는 생성하지 않음)"

00-check: ensure-config
	@./scripts/preflight.sh "$(TFVARS)"

00-down:
	@echo "00 단계에는 삭제할 AWS 리소스가 없습니다."

fmt:
	@terraform fmt -recursive

validate:
	@for dir in labs/*; do terraform -chdir="$$dir" init -backend=false -input=false >/dev/null && terraform -chdir="$$dir" validate; done

define LAB_TARGETS
$(1)-up: 00-check
	@terraform -chdir=labs/$(1)-$(2) init
	@terraform -chdir=labs/$(1)-$(2) apply -var-file="$(TFVARS)"

$(1)-check:
	@./scripts/lab.sh $(1) check "$(TFVARS)"

$(1)-test:
	@./scripts/lab.sh $(1) test "$(TFVARS)"

$(1)-down:
	@terraform -chdir=labs/$(1)-$(2) destroy -var-file="$(TFVARS)"
endef

$(eval $(call LAB_TARGETS,01,core-services))
$(eval $(call LAB_TARGETS,02,monitoring-events))
$(eval $(call LAB_TARGETS,03,linux-dump))
$(eval $(call LAB_TARGETS,04,logs-athena))
$(eval $(call LAB_TARGETS,05,cost-optimization))
$(eval $(call LAB_TARGETS,06,incident-response))
