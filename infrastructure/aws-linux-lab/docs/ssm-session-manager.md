# SSM Session Manager 접속 원리와 운영 점검

## 학습 목표

- SSH와 SSM Session Manager의 접속 구조 차이를 설명할 수 있다.
- EC2용 IAM Role과 접속 사용자용 IAM 권한을 구분할 수 있다.
- SSM Agent의 실행 상태, 로그, 네트워크 연결을 명령어로 확인할 수 있다.
- 웹 콘솔과 AWS CLI에서 세션을 시작하고 접속 실패 지점을 순서대로 진단할 수 있다.

## 한 문장으로 이해하기

SSM Session Manager는 내 PC가 EC2의 포트로 직접 접속하는 방식이 아니다. EC2 안의 SSM Agent와 내 PC가 각각 AWS Systems Manager 서비스에 outbound 연결하고, AWS가 인증된 양방향 세션을 중계한다.

```text
사용자 브라우저 또는 AWS CLI
          |
          | HTTPS 443, IAM 사용자 인증
          v
AWS Systems Manager / ssmmessages
          ^
          | HTTPS 443, EC2 Role 인증
          |
EC2의 amazon-ssm-agent
```

따라서 현재 실습 환경에는 SSH 키와 TCP 22 inbound 규칙이 없다. EC2의 public IP는 외부에서 들어오기 위한 입구가 아니라 NAT Gateway 없이 SSM 서비스와 패키지 저장소로 나가기 위한 인터넷 경로다.

## 접속이 성립하는 네 가지 조건

### 1. 노드에 SSM Agent가 설치되고 실행 중이어야 한다

Amazon Linux 2023 공식 AMI에는 SSM Agent가 기본 설치되어 있다. 이 실습의 `user_data`는 부팅할 때 서비스를 활성화하고 즉시 시작한다.

```bash
sudo systemctl enable --now amazon-ssm-agent
```

`enable`은 다음 부팅에도 자동 시작하도록 설정하고, `--now`는 지금 즉시 서비스도 시작한다.

### 2. EC2가 사용할 IAM 권한이 있어야 한다

EC2는 사람처럼 AWS access key를 파일에 저장하지 않는다. EC2에 연결한 **Instance Profile**을 통해 임시 자격증명을 받고, 그 안의 IAM Role 권한으로 SSM에 등록하고 메시지를 주고받는다.

현재 Terraform의 연결 관계는 다음과 같다.

```text
AmazonSSMManagedInstanceCore 정책
             |
             v
       IAM Role (ssm)
             |
             v
      Instance Profile (nodes)
             |
             v
          EC2 인스턴스
```

주요 Terraform 구성은 다음 역할을 한다.

```hcl
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nodes" {
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "node" {
  iam_instance_profile = aws_iam_instance_profile.nodes.name
}
```

여기서 EC2 Role은 **서버가 AWS에 요청할 권한**이다. 사용자가 서버에 접속할 권한과는 다르다.

### 3. 접속하는 사용자에게 Session Manager 권한이 있어야 한다

웹 콘솔 로그인 사용자 또는 AWS CLI profile의 IAM 주체에는 대상 노드에 대한 세션 시작 권한이 필요하다. 대표적으로 다음 작업이 관련된다.

- `ssm:StartSession`
- `ssm:ResumeSession`
- `ssm:TerminateSession`
- 세션 문서와 대상 노드를 조회하는 데 필요한 읽기 권한

운영 환경에서는 `Resource: "*"`로 넓게 허용하지 않고 인스턴스 ARN, 태그, Session document 등을 이용해 접속 대상을 제한한다. 이 권한은 `AmazonSSMManagedInstanceCore`를 사용자에게 붙이는 것과 별개다. `AmazonSSMManagedInstanceCore`는 노드용 정책이다.

### 4. EC2에서 AWS SSM endpoint로 나갈 수 있어야 한다

Agent는 리전의 Systems Manager endpoint와 `ssmmessages` endpoint에 TCP 443으로 연결한다. 현재 실습 환경은 다음 경로를 사용한다.

```text
EC2 private IP
→ EC2에 연결된 public IP 변환
→ Internet Gateway
→ AWS SSM public endpoint:443
```

이를 위해 public subnet의 기본 경로 `0.0.0.0/0 → Internet Gateway`, EC2 public IP, DNS, Security Group outbound가 필요하다. 서버에 inbound 포트를 열 필요는 없다.

사설 subnet에서는 public IP 대신 NAT Gateway 또는 Systems Manager용 Interface VPC Endpoint를 사용할 수 있다. Interface Endpoint는 시간 및 데이터 처리 비용이 발생한다.

## Terraform 적용 전 확인

다음 명령은 AWS 리소스를 만들지 않는다.

```bash
cd infrastructure/aws-linux-lab
make preflight AWS_PROFILE=akinux
make plan AWS_PROFILE=akinux
```

계획에서 다음 항목을 확인한다.

- EC2에 Instance Profile이 연결되는가
- Role에 `AmazonSSMManagedInstanceCore`가 연결되는가
- 외부 inbound 규칙이 없는가
- outbound와 Internet Gateway 경로가 있는가
- EC2가 public IP를 받는가

`make apply`부터 실제 리소스와 비용이 발생한다.

## 웹 콘솔에서 첫 접속

Terraform 적용 후 SSM Agent가 등록될 때까지 잠시 기다린 다음 진행한다.

1. AWS 콘솔의 리전을 서울 `ap-northeast-2`로 선택한다.
2. **EC2 → 인스턴스**에서 `devops-linux-lab-node-1`을 선택한다.
3. **연결(Connect) → Session Manager → 연결**을 선택한다.
4. 열린 셸에서 `whoami`, `hostname`, `pwd`를 확인한다.
5. `exit`로 원격 세션만 종료한다.

또는 **Systems Manager → Node Management → Session Manager**에서도 시작할 수 있다. 기본 Linux 세션은 보통 SSM이 관리하는 `ssm-user` 계정을 사용한다.

## CLI에서 접속

로컬 PC에는 AWS CLI와 Session Manager plugin이 필요하다.

```bash
aws --version
session-manager-plugin --version
aws sts get-caller-identity --profile akinux
```

실습 저장소의 단축 명령은 Terraform output에서 Instance ID를 찾아 세션을 연다.

```bash
cd infrastructure/aws-linux-lab
make node-1 AWS_PROFILE=akinux
```

원래 AWS CLI 명령 형태는 다음과 같다.

```bash
aws ssm start-session \
  --target <instance-id> \
  --region ap-northeast-2 \
  --profile akinux
```

Instance ID는 비밀 값은 아니지만 문서에는 실제 계정의 값을 기록하지 않는다.

## 접속 후 Agent와 OS 확인

```bash
whoami
hostnamectl
sudo systemctl status amazon-ssm-agent --no-pager
sudo systemctl is-enabled amazon-ssm-agent
sudo journalctl -u amazon-ssm-agent -n 50 --no-pager
```

| 명령어 | 확인하는 것 |
|---|---|
| `whoami` | 현재 원격 OS 사용자 |
| `hostnamectl` | 접속한 노드와 운영체제 정보 |
| `systemctl status` | Agent의 현재 실행 상태와 최근 오류 |
| `systemctl is-enabled` | 재부팅 후 자동 시작 여부 |
| `journalctl -u` | systemd에 기록된 Agent 로그 |

SSM Agent 자체 로그도 확인한다.

```bash
sudo tail -n 50 /var/log/amazon/ssm/amazon-ssm-agent.log
sudo tail -n 50 /var/log/amazon/ssm/errors.log
```

전체 파일을 무조건 출력하지 않고 최근 줄부터 확인한 뒤, 시간과 오류 키워드로 범위를 좁힌다.

```bash
sudo grep -Ei 'error|fail|denied|timeout' \
  /var/log/amazon/ssm/amazon-ssm-agent.log | tail -n 30
```

## AWS 측 등록 상태 확인

로컬 터미널에서 실행한다.

```bash
aws ssm describe-instance-information \
  --region ap-northeast-2 \
  --profile akinux \
  --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Version:AgentVersion}' \
  --output table
```

`PingStatus`가 `Online`이면 노드가 SSM에 등록되어 통신 중이라는 뜻이다. 저장소에서는 다음 명령으로 EC2 상태와 SSM 상태를 함께 본다.

```bash
make status AWS_PROFILE=akinux
```

## 접속 장애 진단 순서

Session Manager 목록에 노드가 나타나지 않을 때는 무작정 Security Group inbound를 열지 않는다. 다음 순서로 계층을 좁힌다.

1. **EC2 상태**: 인스턴스가 `running`이고 status check를 통과했는가
2. **IAM**: Instance Profile이 연결되고 Role에 노드용 SSM 정책이 있는가
3. **Agent**: 설치되어 실행 중이며 부팅 시 활성화되었는가
4. **네트워크**: DNS와 TCP 443 outbound, route table, Internet Gateway 또는 VPC Endpoint가 정상인가
5. **사용자 권한**: 현재 콘솔 사용자 또는 CLI profile에 `ssm:StartSession` 권한이 있는가
6. **로그**: Agent와 systemd 로그에 인증·DNS·timeout 오류가 있는가

자주 만나는 증상은 다음과 같다.

| 증상 | 유력한 원인 | 우선 확인 |
|---|---|---|
| Session Manager 대상에 없음 | Role, Agent 또는 outbound 문제 | Instance Profile과 `PingStatus` |
| `TargetNotConnected` | Agent가 아직 등록되지 않았거나 연결 끊김 | Agent 로그와 TCP 443 경로 |
| `AccessDeniedException` | 접속하는 사용자 권한 부족 | 현재 IAM 주체의 `ssm:StartSession` |
| CLI가 plugin을 찾지 못함 | 로컬 plugin 미설치 또는 PATH 문제 | `session-manager-plugin --version` |
| 웹 콘솔은 되지만 CLI는 실패 | 다른 IAM 주체·profile 또는 리전 사용 | `sts get-caller-identity`, `--region` |

Agent가 완전히 내려간 경우에는 그 Agent를 이용하는 Session Manager로 들어가 고칠 수 없다. EC2 console의 시스템 로그, user data, EC2 Serial Console 적용 가능 여부 또는 인스턴스 복구 절차처럼 별도의 복구 경로가 필요하다. 이것이 관리 접속 경로도 모니터링해야 하는 이유다.

## 보안과 비용

- EC2에서 Session Manager를 사용하는 기능 자체에는 추가 Session Manager 요금이 없다.
- public IPv4, EC2, EBS와 선택적으로 사용하는 CloudWatch Logs, S3, KMS, Interface VPC Endpoint 비용은 별도다.
- 세션 기록을 CloudWatch Logs나 S3로 보내지 않으면 명령 감사 로그가 자동으로 장기 보관되는 것은 아니다.
- 운영 환경에서는 세션 로깅, 최소 권한, 태그 기반 접근 제한, 접속 사유 기록과 로그 보존 정책을 함께 설계한다.
- 비밀번호, 토큰과 같은 민감 정보를 명령행이나 세션 로그에 남기지 않는다.

## 실습 체크리스트

- [ ] SSH와 SSM의 연결 방향 차이를 설명한다.
- [ ] EC2 Role과 사용자 IAM 권한의 차이를 설명한다.
- [ ] 웹 콘솔로 node-1에 접속한다.
- [ ] `systemctl`과 `journalctl`로 Agent 상태와 로그를 확인한다.
- [ ] 로컬 CLI로 같은 노드에 접속한다.
- [ ] AWS 측 `PingStatus=Online`을 확인한다.
- [ ] inbound 22번 규칙이 없다는 것을 확인한다.
- [ ] 실습 종료 후 Terraform 리소스를 제거하고 잔존 여부를 확인한다.

## 공식 참고 자료

- [AWS Session Manager 개요](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Session Manager용 인스턴스 권한](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-instance-profile.html)
- [SSM Agent 상태 확인 및 시작](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent-status-and-restart.html)
- [SSM Agent 문제 해결과 로그 위치](https://docs.aws.amazon.com/systems-manager/latest/userguide/troubleshooting-ssm-agent.html)
- [AWS CLI `ssm start-session`](https://docs.aws.amazon.com/cli/latest/reference/ssm/start-session.html)
- [AWS Systems Manager 요금](https://aws.amazon.com/systems-manager/pricing/)
