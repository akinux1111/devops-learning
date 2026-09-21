# 수동 SSM 실습용 네트워크 기반

이 Terraform 구성은 다음 네트워크 리소스만 생성합니다.

- VPC 1개
- public subnet 1개
- Internet Gateway 1개
- `0.0.0.0/0` 인터넷 경로가 있는 route table과 subnet 연결

Security Group, IAM Role, Instance Profile 및 EC2는 생성하지 않습니다. 해당 리소스는 SSM 실습에서 직접 만듭니다.

## 실행

```bash
cd infrastructure/aws-linux-lab/foundation
make plan AWS_PROFILE=akinux
make apply AWS_PROFILE=akinux CONFIRM=manual-ssm-foundation
make output AWS_PROFILE=akinux
```

`plan`은 리소스를 만들지 않습니다. `apply`는 AWS 네트워크 리소스를 생성하지만 이 구성 자체에는 EC2, NAT Gateway, public IPv4가 없어 일반적인 시간당 고정 비용이 없습니다.

## 제거 순서

웹 콘솔에서 직접 만든 EC2와 Security Group을 먼저 제거해야 VPC를 삭제할 수 있습니다. IAM Role과 Instance Profile도 수동 실습 정리 단계에서 별도로 제거합니다.

```bash
make destroy-plan AWS_PROFILE=akinux
make destroy AWS_PROFILE=akinux CONFIRM=destroy-manual-ssm-foundation
```
