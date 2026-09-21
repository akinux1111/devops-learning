# AWS 실습 인프라

현업 장애 대응 학습을 위한 일회성 AWS 환경입니다.

## 실습 환경

- [`aws-linux-lab/`](aws-linux-lab/README.md): EC2 Linux 노드 2대로 systemd, 로그, 커널, TCP, 라우팅과 Security Group 장애를 학습합니다.
- `eks-lab/`: Linux 및 로컬 Kubernetes 단계를 마친 뒤 추가합니다.

각 환경은 Terraform 코드와 Makefile을 사용합니다. `plan`까지는 AWS 리소스를 만들지 않지만 `apply`부터 비용이 발생합니다. 실습이 끝나면 반드시 `destroy`와 잔존 리소스 확인을 수행합니다.
