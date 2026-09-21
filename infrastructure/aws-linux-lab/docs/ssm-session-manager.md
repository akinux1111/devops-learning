# SSM Session Manager 실습 안내

상세 이론, 웹 콘솔 절차, 단계별 관찰 결과와 장애 진단 기록은 Notion의 [SSM Session Manager 접속 원리와 운영 점검](https://www.notion.so/3e224c53756c8163a597e2b0e2cb79c7)을 단일 원본으로 사용합니다.

GitHub에는 실행 가능한 실습 코드와 최소 운영 안내만 유지합니다.

- [수동 실습용 foundation Terraform](../foundation/)
- [완성형 AWS Linux lab](../)
- [저장소 루트 Make 명령](../../../Makefile)

수동 실습용 네트워크는 저장소 루트에서 다음과 같이 생성합니다.

```bash
make foundation-up AWS_PROFILE=akinux
make foundation-output AWS_PROFILE=akinux
```

이 단계는 VPC, public subnet, Internet Gateway, route table만 생성하며 EC2, Security Group, IAM Role과 Instance Profile은 생성하지 않습니다.

실습이 끝나면 수동으로 만든 EC2와 Security Group을 먼저 제거한 뒤 foundation을 삭제합니다.

```bash
make foundation-down-plan AWS_PROFILE=akinux
make foundation-down AWS_PROFILE=akinux
```
