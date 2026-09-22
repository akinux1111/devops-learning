#!/usr/bin/env bash
set -euo pipefail

number=${1:?lab number required}
action=${2:?action required}
tfvars=${3:?tfvars required}

case "$number" in
  01) dir="labs/01-core-services" ;;
  02) dir="labs/02-monitoring-events" ;;
  03) dir="labs/03-linux-dump" ;;
  04) dir="labs/04-logs-athena" ;;
  05) dir="labs/05-cost-optimization" ;;
  06) dir="labs/06-incident-response" ;;
  *) echo "unknown lab: $number"; exit 1 ;;
esac

terraform -chdir="$dir" output

if [[ "$action" == "check" ]]; then
  terraform -chdir="$dir" plan -refresh-only -detailed-exitcode -var-file="$tfvars" || code=$?
  if [[ "${code:-0}" == "2" ]]; then
    echo "AWS 실제 상태와 state 사이에 변경이 있습니다. 위 refresh-only 결과를 확인하세요."
    exit 2
  fi
  exit "${code:-0}"
fi

case "$number" in
  02|06)
    instance_id=$(terraform -chdir="$dir" output -raw instance_id)
    aws ssm send-command --instance-ids "$instance_id" --document-name AWS-RunShellScript \
      --parameters 'commands=["for i in 1 2; do timeout 180 yes > /dev/null & done; wait"]' --output table
    echo "CloudWatch Alarm 상태 변화를 관찰하세요."
    ;;
  03)
    instance_id=$(terraform -chdir="$dir" output -raw instance_id)
    aws ssm send-command --instance-ids "$instance_id" --document-name AWS-RunShellScript \
      --parameters 'commands=["ulimit -c unlimited; cd /opt/dump-lab; ./crash || true; sudo gdb -batch -ex bt ./crash core* 2>/dev/null || true; jcmd $(pgrep -f ThreadLab | head -1) Thread.print | head -80"]' --output table
    ;;
  04)
    workgroup=$(terraform -chdir="$dir" output -raw workgroup)
    database=$(terraform -chdir="$dir" output -raw database)
    output=$(terraform -chdir="$dir" output -raw query_output)
    aws athena start-query-execution --work-group "$workgroup" --query-execution-context Database="$database" \
      --result-configuration OutputLocation="$output" --query-string 'SELECT status, count(*) AS count FROM access_logs GROUP BY status ORDER BY count DESC' --output table
    ;;
  05)
    echo "AWS Cost Explorer의 Rightsizing Recommendations와 현재 EC2/EBS/S3 설정을 비교해 기록하세요."
    aws ec2 describe-volumes --filters Name=tag:Lab,Values=05 --query 'Volumes[].{Id:VolumeId,Type:VolumeType,Size:Size,State:State}' --output table
    ;;
  01)
    echo "01은 장애 발생 없이 운영 상태 확인이 목적입니다. make 01-check를 사용하세요."
    ;;
esac
