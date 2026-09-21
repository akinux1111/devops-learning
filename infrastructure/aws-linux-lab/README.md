# AWS Linux 장애 대응 실습 환경

실제 Linux 커널과 systemd가 동작하는 Amazon Linux 2023 EC2 노드 2대로 서버 및 TCP 장애 대응을 학습합니다.

이 디렉터리는 `tfenv` 사용 시 Terraform `1.10.4`를 선택하도록 `.terraform-version`을 포함합니다. Terraform 요구 버전은 `1.10` 이상입니다.

`terraform-cli.tfrc`는 사용자 홈의 오래된 provider 캐시나 암시적 로컬 미러에 영향받지 않고 HashiCorp Registry에서 provider를 직접 받도록 이 실습에만 적용됩니다. Makefile이 이 설정을 자동으로 사용합니다.

## 무엇을 생성하는가

- 서울 리전 VPC 1개
- 서로 다른 Availability Zone의 public subnet 2개
- Internet Gateway와 route table
- Amazon Linux 2023 `t3.micro` EC2 노드 2개
- SSM Session Manager 접속용 IAM role과 instance profile
- 외부 인바운드 규칙이 없는 Security Group
- 노드 사이의 통신만 허용하는 내부 규칙
- 암호화된 8 GiB gp3 루트 볼륨
- 추가 CPU 크레딧 요금을 막는 T3 `standard` 크레딧 모드

public subnet과 public IP는 NAT Gateway 비용 없이 SSM 및 패키지 저장소에 outbound 접속하기 위한 학습용 선택입니다. Security Group에는 외부 인바운드 규칙이 없으며 SSH 키도 만들지 않습니다.

## 비용과 안전 원칙

`terraform plan`까지는 EC2를 만들지 않습니다. `make apply`부터 EC2, EBS 및 관련 AWS 사용료가 발생합니다.

- `Project=devops-learning`, `Environment=lab`, `AutoDelete=true` 태그 적용
- `make apply`는 확인 문자열 필수
- 실습이 끝나면 `make destroy` 실행
- 이후 `make check`로 남은 실행·중지 인스턴스 확인
- 로컬 state와 실제 변수 파일은 `.gitignore`로 제외

중지된 EC2도 EBS 비용이 남으므로 장기간 보관하지 말고 실습 단위로 제거합니다.

2026-09-22 AWS Price List API의 서울 리전 단가 기준 예상치는 다음과 같습니다.

| 항목 | 계산 | 24시간 예상 |
|---|---:|---:|
| EC2 `t3.micro` 2대 | `$0.013 × 2 × 24` | `$0.624` |
| public IPv4 2개 | `$0.005 × 2 × 24` | `$0.240` |
| gp3 8 GiB 2개 | `$0.0912/GB-month × 16 ÷ 30` | 약 `$0.049` |
| 합계 | 데이터 전송·세금 제외 | 약 `$0.913/day` |

노드 사이의 대량 AZ 간 트래픽, 인터넷 데이터 전송, 세금은 별도입니다. 일반 명령어·TCP 장애 실습의 트래픽은 작지만 대용량 파일 전송 실습 전에는 별도로 계산합니다.

## 최초 준비

실제 변수 파일은 GitHub에 올리지 않습니다.

```bash
cd infrastructure/aws-linux-lab
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`의 `owner`를 자신의 식별자로 수정합니다. AWS 자격증명은 파일에 쓰지 않고 기존 AWS CLI profile을 사용합니다.

## 안전한 실행 순서

아래의 `<profile>`은 로컬 AWS CLI profile 이름으로 바꿉니다.

```bash
make preflight AWS_PROFILE=<profile>
make init AWS_PROFILE=<profile>
make validate AWS_PROFILE=<profile>
make plan AWS_PROFILE=<profile>
```

plan에서 생성될 리소스를 검토한 후에만 적용합니다.

```bash
make apply AWS_PROFILE=<profile> CONFIRM=aws-linux-lab
make status AWS_PROFILE=<profile>
```

## 노드 접속

```bash
make node-1 AWS_PROFILE=<profile>
make node-2 AWS_PROFILE=<profile>
```

노드 사이 실습에는 `terraform output node_private_ips`로 확인한 private IP를 사용합니다.

## 반드시 제거하기

```bash
make destroy-plan AWS_PROFILE=<profile>
make destroy AWS_PROFILE=<profile> CONFIRM=destroy-aws-linux-lab
make check AWS_PROFILE=<profile>
```

## 이 환경에서 진행할 장애 실습

1. `systemctl`과 `journalctl`로 서비스 상태 및 실패 원인 분석
2. `ss`, `nc`, `curl`로 LISTEN·refused·timeout 구분
3. `ip route get`과 `tracepath`로 네트워크 경로 확인
4. `tcpdump`로 SYN, SYN-ACK, RST 관찰
5. Security Group 규칙 변경 전후 비교
6. 디스크·inode·메모리·CPU 장애와 커널 로그 확인
7. SSM Agent와 실제 시스템 로그 위치 탐색

## 공식 참고 자료

- [최신 Amazon Linux AMI를 SSM public parameter로 참조](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami-parameter-store.html)
- [SSM Agent가 사전 설치된 AMI](https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html)
- [Systems Manager 인스턴스 권한](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html)
