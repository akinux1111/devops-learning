#!/usr/bin/env bash
set -euo pipefail

tfvars=${1:-terraform.tfvars}
for command_name in aws terraform make; do
  command -v "$command_name" >/dev/null || { echo "ERROR: $command_name 명령이 없습니다."; exit 1; }
done

test -f "$tfvars" || { echo "ERROR: terraform.tfvars가 없습니다. 예제 파일을 복사하세요."; exit 1; }
echo "Terraform: $(terraform version -json | sed -n 's/.*\"terraform_version\":\"\([^\"]*\)\".*/\1/p')"
echo "AWS CLI: $(aws --version 2>&1)"
echo "현재 AWS 자격 증명:"
aws sts get-caller-identity --output table
echo "반드시 위 Account가 실습용 계정인지 확인하세요."
