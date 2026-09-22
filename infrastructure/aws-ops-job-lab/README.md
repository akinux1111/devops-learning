# AWS 운영 직무 공고 실습

채용 공고에 나온 AWS 운영 업무를 Terraform과 Makefile로 직접 실행하는 실습입니다.

상세 이론과 단계별 기록은 [Notion의 AWS 운영 직무 공고 실습](https://app.notion.com/p/3e324c53756c819d9a64f6e748ad1732)에서 관리합니다.

## 안전 원칙

- 실습용 AWS 계정을 권장합니다.
- 기본 리전은 `ap-northeast-2`입니다.
- SSH(22)는 열지 않고 Systems Manager Session Manager를 사용합니다.
- NAT Gateway는 만들지 않습니다.
- ALB/NLB, EC2, EBS 등은 실행 중 비용이 발생하므로 실습 직후 `down`을 실행합니다.
- `make 00-check`에서 계정과 도구를 먼저 확인하십시오.

## 시작

```bash
cd ~/00-2609
make 00-up
make 01-up
make 01-check
make 01-down
```

`make 00-up`은 `terraform.tfvars`가 없으면 예제의 안전한 기본값으로 자동 생성한 뒤 도구와 AWS 계정을 확인합니다.

각 번호는 노션의 `00~06` 페이지와 대응합니다.

| 번호 | 공고 실습 | 명령 |
|---|---|---|
| 00 | 공통 준비 | `make 00-check` |
| 01 | 핵심 서비스 운영 | `make 01-up/check/down` |
| 02 | CloudWatch·Event 대응 | `make 02-up/check/test/down` |
| 03 | Linux 장애·Dump | `make 03-up/check/test/down` |
| 04 | 로그·S3·Athena | `make 04-up/check/test/down` |
| 05 | EC2·EBS·S3 최적화 | `make 05-up/check/test/down` |
| 06 | 종합 장애 대응 | `make 06-up/check/test/down` |

## 상태 파일

각 `labs/NN-*` 디렉터리가 독립적인 Terraform state를 사용합니다. 한 실습의 `down`은 다른 번호에 영향을 주지 않습니다.
