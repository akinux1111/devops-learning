# SSM Session Manager: 이론, 수동 구성, 장애 진단

> 학습 순서는 **이론 전체 이해 → 직접 구성 → 장애 주입과 진단**이다. 각 항목의 CLI와 웹 콘솔은 같은 AWS 작업을 수행하는 두 인터페이스다. 처음에는 웹 콘솔로 만들고 CLI로 검증하며, 반복할 때는 반대로 진행한다.

## 학습 목표

- SSH와 SSM Session Manager의 접속 구조 차이를 설명할 수 있다.
- EC2용 IAM Role과 접속 사용자용 IAM 권한을 구분할 수 있다.
- SSM Agent의 실행 상태, 로그, 네트워크 연결을 명령어로 확인할 수 있다.
- 웹 콘솔과 AWS CLI에서 세션을 시작하고 접속 실패 지점을 순서대로 진단할 수 있다.

## 교재 구성

1. [1부: 이론](#1부-이론)
2. [2부: 수동 구성 실습](#2부-수동-구성-실습)
3. [3부: 장애 주입과 진단](#3부-장애-주입과-진단)

## 1부: 이론

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

<details>
<summary>CLI로 SSM 관리 노드 확인</summary>

```bash
aws ssm describe-instance-information \
  --region ap-northeast-2 \
  --profile akinux \
  --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Version:AgentVersion}' \
  --output table
```

인프라 생성 전이라면 빈 결과가 정상이다.

</details>

<details>
<summary>웹 콘솔로 SSM 관리 노드 확인</summary>

서울 리전에서 **Systems Manager → Node Management → Managed nodes**로 이동한다. 인프라 생성 전이라면 목록이 비어 있는 것이 정상이다.

</details>

## IAM Policy, Role, Instance Profile 구분

- **Policy**: 무엇을 할 수 있는지 정의한 권한 문서
- **Role**: 누가 그 권한을 임시로 맡을 수 있는지 정의한 AWS 신원
- **Trust policy**: EC2 서비스가 해당 Role을 맡도록 허용하는 신뢰 정책
- **Instance Profile**: IAM Role을 EC2에 실제로 연결하는 컨테이너
- **사용자 권한**: 사람이 `StartSession`을 호출할 권한으로, EC2 Role과 별개

<details>
<summary>CLI로 IAM 관계 확인</summary>

```bash
aws iam get-role --role-name devops-study-ssm-role --profile akinux
aws iam list-attached-role-policies \
  --role-name devops-study-ssm-role \
  --profile akinux
aws iam get-instance-profile \
  --instance-profile-name devops-study-ssm-profile \
  --profile akinux
```

직접 생성하기 전의 `NoSuchEntity`는 예상한 결과다.

</details>

<details>
<summary>웹 콘솔로 IAM 관계 확인</summary>

**IAM → Roles → devops-study-ssm-role**에서 trusted service가 EC2인지, 권한에 `AmazonSSMManagedInstanceCore`가 있는지 확인한다. 콘솔은 EC2용 Role 생성 시 Instance Profile 처리를 함께 해주므로 CLI보다 관계가 덜 드러난다.

</details>

## Agent와 네트워크 이론

Amazon Linux 2023 공식 AMI에는 Agent가 기본 설치되어 있지만, 설치됨·실행 중·부팅 시 자동 시작·AWS 등록 완료는 각각 다른 상태다. Security Group은 stateful이며 Agent가 outbound 연결을 시작하므로 SSM용 inbound 포트는 없다.

필수 경로는 다음과 같다.

```text
EC2 private IP
→ EC2 public IPv4 변환
→ Internet Gateway
→ ssm / ssmmessages endpoint TCP 443
```

<details>
<summary>Linux CLI로 Agent 확인</summary>

```bash
rpm -q amazon-ssm-agent
sudo systemctl is-active amazon-ssm-agent
sudo systemctl is-enabled amazon-ssm-agent
sudo systemctl status amazon-ssm-agent --no-pager
sudo journalctl -u amazon-ssm-agent -n 50 --no-pager
```

</details>

<details>
<summary>CLI로 Security Group과 route 확인</summary>

```bash
aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --profile akinux
aws ec2 describe-route-tables \
  --route-table-ids <route-table-id> \
  --profile akinux
```

</details>

<details>
<summary>웹 콘솔로 네트워크 확인</summary>

**EC2 → 인스턴스 → 보안**에서 inbound가 비었는지와 outbound를 확인한다. **VPC → Route tables**에서 `0.0.0.0/0 → igw-...`를 확인하고 EC2에 public IPv4가 있는지 확인한다.

</details>

## 비용과 감사 로그

EC2에서 Session Manager 자체를 사용하는 데 추가 세션 요금은 없다. EC2, EBS, public IPv4와 선택적으로 사용하는 CloudWatch Logs, S3, KMS, Interface VPC Endpoint 비용은 별도다. 세션 로깅을 설정하지 않으면 명령 내용이 자동으로 장기 보관되는 것은 아니다.

## 2부: 수동 구성 실습

> **중요:** 현재 Terraform을 그대로 적용하면 Role, Instance Profile, Security Group, EC2가 모두 자동 생성된다. 아래 수동 학습을 하려면 실제 `apply` 전에 Terraform을 네트워크 기반만 생성하는 모드와 완성형 자동 구성 모드로 분리해야 한다.

각 단계에서는 웹 콘솔과 CLI 중 하나만 생성 수단으로 사용하고, 다른 하나는 결과 검증에 사용한다.

### 0단계: 기반 네트워크 준비

한 줄 설명: Terraform으로 VPC, subnet, Internet Gateway, route table까지만 준비한다.

```bash
cd infrastructure/aws-linux-lab
make plan AWS_PROFILE=akinux
```

리팩터링 후 plan에는 IAM, Security Group, EC2가 없어야 한다.

### 1단계: Security Group 직접 생성

한 줄 설명: inbound가 비어 있고 outbound가 허용된 Security Group을 직접 만든다.

<details>
<summary>CLI로 생성하고 확인</summary>

```bash
aws ec2 create-security-group \
  --group-name devops-study-ssm-sg \
  --description "SSM lab: no public inbound" \
  --vpc-id <vpc-id> \
  --region ap-northeast-2 \
  --profile akinux

aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --query 'SecurityGroups[0].{Inbound:IpPermissions,Outbound:IpPermissionsEgress}' \
  --profile akinux
```

</details>

<details>
<summary>웹 콘솔로 생성하고 확인</summary>

**EC2 → Security Groups → Create security group**에서 대상 VPC를 선택한다. inbound는 추가하지 않고 학습 첫 단계에서는 기본 outbound를 유지한다.

</details>

정상 판정: inbound가 빈 배열이어도 이후 SSM 접속이 가능해야 한다.

### 2단계: EC2용 IAM Role 직접 생성

한 줄 설명: EC2가 맡을 Role을 만들고 노드용 SSM 정책을 연결한다.

<details>
<summary>CLI로 생성하고 확인</summary>

```bash
aws iam create-role \
  --role-name devops-study-ssm-role \
  --assume-role-policy-document file://ec2-trust-policy.json \
  --profile akinux

aws iam attach-role-policy \
  --role-name devops-study-ssm-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
  --profile akinux

aws iam list-attached-role-policies \
  --role-name devops-study-ssm-role \
  --profile akinux
```

</details>

<details>
<summary>웹 콘솔로 생성하고 확인</summary>

**IAM → Roles → Create role**에서 AWS service와 EC2 use case를 선택하고 `AmazonSSMManagedInstanceCore`를 연결한다.

</details>

### 3단계: Instance Profile 직접 생성

한 줄 설명: Role을 EC2에 장착할 수 있도록 Instance Profile에 넣는다.

```bash
aws iam create-instance-profile \
  --instance-profile-name devops-study-ssm-profile \
  --profile akinux
aws iam add-role-to-instance-profile \
  --instance-profile-name devops-study-ssm-profile \
  --role-name devops-study-ssm-role \
  --profile akinux
aws iam get-instance-profile \
  --instance-profile-name devops-study-ssm-profile \
  --query 'InstanceProfile.Roles[].RoleName' \
  --output table \
  --profile akinux
```

웹 콘솔에서 EC2 use case로 Role을 만들면 Instance Profile이 함께 처리된다. 이 차이를 설명할 수 있어야 한다.

### 4단계: Role 없이 EC2 생성

한 줄 설명: 의도적으로 Instance Profile을 비워 두고 SSM 등록 실패를 관찰한다.

웹 콘솔에서는 EC2 시작 과정의 **Advanced details → IAM instance profile**을 비워 둔다. CLI에서는 `run-instances`에 `--iam-instance-profile`을 넣지 않는다.

```bash
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].{State:State.Name,Profile:IamInstanceProfile,PublicIp:PublicIpAddress}' \
  --profile akinux
aws ssm describe-instance-information \
  --filters Key=InstanceIds,Values=<instance-id> \
  --profile akinux
```

정상 관찰: EC2는 running이고 public IP가 있지만 Profile이 비어 있고 SSM 결과가 없다.

### 5단계: 실행 중인 EC2에 Instance Profile 연결

한 줄 설명: 서버를 재생성하지 않고 Profile을 연결하여 SSM 등록 변화를 본다.

<details>
<summary>CLI로 연결</summary>

```bash
aws ec2 associate-iam-instance-profile \
  --instance-id <instance-id> \
  --iam-instance-profile Name=devops-study-ssm-profile \
  --region ap-northeast-2 \
  --profile akinux
```

</details>

<details>
<summary>웹 콘솔로 연결</summary>

**EC2 → 인스턴스 → 작업 → 보안 → IAM 역할 수정**에서 만든 Role을 선택한다.

</details>

등록 상태를 확인한다.

```bash
aws ssm describe-instance-information \
  --filters Key=InstanceIds,Values=<instance-id> \
  --query 'InstanceInformationList[].{Ping:PingStatus,Version:AgentVersion}' \
  --profile akinux
```

즉시 Online이 아니면 IAM 전파를 잠시 기다린 뒤 Role 정책 → Agent → 네트워크 순서로 조사한다.

### 6단계: 웹 콘솔과 CLI로 접속

CLI:

```bash
aws ssm start-session \
  --target <instance-id> \
  --region ap-northeast-2 \
  --profile akinux
```

웹 콘솔: **EC2 → 인스턴스 → 연결 → Session Manager → 연결**

접속 후 한 명령씩 실행하고 의미를 확인한다.

```bash
whoami
hostnamectl
sudo systemctl is-active amazon-ssm-agent
sudo systemctl is-enabled amazon-ssm-agent
sudo journalctl -u amazon-ssm-agent -n 30 --no-pager
sudo ss -lntp
```

SSM용 listening port가 없어도 정상이다. Agent는 inbound 서버가 아니라 outbound 연결을 만든다.

## 3부: 장애 주입과 진단

### 장애 A: Instance Profile 제거

예상 증상: 새 세션이 실패하고 노드가 Offline으로 바뀐다. AWS에서 association과 `PingStatus`를 확인한 뒤 Profile을 다시 연결한다.

### 장애 B: Security Group outbound 차단

예상 증상: Agent가 AWS endpoint에 연결하지 못하고 timeout을 기록한다. 기존 세션도 끊길 수 있으므로 복구 절차를 먼저 준비한다.

```bash
sudo journalctl -u amazon-ssm-agent --since '-10 min' --no-pager
sudo grep -Ei 'timeout|connect|error' \
  /var/log/amazon/ssm/amazon-ssm-agent.log | tail -n 30
```

### 장애 C: Agent 중지

Agent를 그냥 중지하면 SSM으로 다시 들어와 시작할 수 없다. 자동 복구를 먼저 예약한다.

```bash
sudo systemd-run --unit=ssm-auto-recover \
  --on-active=2m /usr/bin/systemctl start amazon-ssm-agent
sudo systemctl stop amazon-ssm-agent
```

2분 뒤 `PingStatus`와 journal에서 회복을 확인한다.

### 공통 진단 순서

1. EC2 상태와 status check
2. EC2에 연결된 Instance Profile
3. Role의 `AmazonSSMManagedInstanceCore`
4. Agent 설치·실행·활성화 상태
5. DNS, route, TCP 443 outbound
6. 접속 사용자의 `StartSession` 권한
7. systemd와 Agent 로그

## 다음 준비 작업

- [ ] Terraform을 네트워크 기반 모드와 완성형 자동 구성 모드로 분리
- [ ] CLI용 `ec2-trust-policy.json` 추가
- [ ] 수동 생성 리소스의 안전한 정리 명령 추가
- [ ] 실제 apply 전 비용과 생성 목록 재확인

## 부록: 명령어 빠른 참조

아래 내용은 이론과 단계별 실습을 마친 뒤 사용하는 빠른 참조다. 처음 학습할 때는 위의 순서를 따른다.

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
