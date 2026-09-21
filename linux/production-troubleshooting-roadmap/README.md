# 현업 Linux·Kubernetes 장애 대응 학습 로드맵

## 이 학습은 무엇을 위한 것인가

이 과정의 목표는 명령어와 로그 경로를 단순 암기하는 것이 아니라, 실제 장애 상황에서 다음 과정을 스스로 수행할 수 있는 엔지니어가 되는 것입니다.

```text
증상 파악 → 영향 범위 확인 → 계층 분리 → 가설 수립
→ 증거 수집 → 원인 확인 → 안전한 복구 → 재발 방지
```

최종적으로 다음 질문에 근거를 들어 답할 수 있어야 합니다.

- 애플리케이션 문제인가, 운영체제 문제인가, 네트워크 문제인가?
- 프로세스가 죽었는가, 살아 있지만 응답하지 않는가?
- 포트가 열리지 않았는가, 경로가 차단됐는가, 연결 후 애플리케이션이 실패하는가?
- 한 서버만 문제인가, 여러 노드 또는 전체 서비스 문제인가?
- 어떤 로그와 메트릭이 가설을 지지하거나 반박하는가?
- 지금 복구하는 방법과 다시 발생하지 않게 하는 방법은 무엇인가?

## 실습 환경을 어떻게 나누는가

이 저장소를 사용하는 현재 환경은 WSL2이며, 실제 확인 결과 Linux `6.6.87.2-microsoft-standard-WSL2` 커널, systemd PID 1, cgroup v2를 사용합니다. WSL2에는 실제 Linux 커널이 없다는 설명은 맞지 않습니다. 다만 Microsoft가 WSL용으로 제공하는 커널과 관리형 가상 네트워크를 사용하므로 실제 EC2 또는 베어메탈 서버와 완전히 같지도 않습니다.

각 환경의 역할을 다음처럼 분리합니다.

| 환경 | 주 학습 내용 | 한계 |
|---|---|---|
| WSL2 | 셸, 파일, 프로세스, 텍스트 검색, 기초 systemd/journal, 관측 명령 숙련 | 실제 부팅·하드웨어·EC2 네트워크·노드 장애 재현에 한계 |
| 독립 EC2 Linux 노드 2대 | 실제 systemd, 커널·디스크·메모리, 노드 간 TCP, 라우팅, Security Group 장애 | Kubernetes 계층 없음 |
| 로컬 다중 노드 Kubernetes | Pod·Service·DNS·스케줄링·일반 CNI 개념 | AWS VPC CNI, IAM, Security Group 동작 없음 |
| EKS managed node group | kubelet, Pod/Node 통신, VPC CNI, IAM, AWS 네트워크 장애 | 관리형 control plane 호스트에 직접 로그인 불가 |
| EKS CloudWatch 로그 | API server, audit, authenticator, controller manager, scheduler | 명시적으로 활성화해야 하며 로그 비용 발생 |

WSL에서 배운 조사 명령을 버리는 것이 아니라, 동일한 조사법을 EC2와 EKS 워커 노드에서 다시 적용하며 환경 차이를 비교합니다.

## EKS 하나로 시작하지 않는 이유

EKS는 Linux와 Kubernetes 장애 대응을 처음 배우기에는 추상화 계층이 많습니다. 한 번에 다음 요소들이 함께 등장합니다.

- Linux 프로세스·서비스·커널
- 컨테이너 런타임과 kubelet
- Kubernetes Pod·Service·DNS·스케줄링
- Amazon VPC·라우팅·보안 그룹·NACL
- Amazon VPC CNI
- IAM과 Kubernetes RBAC
- Terraform 상태와 AWS 리소스 수명주기

기초 없이 EKS부터 시작하면 장애 원인이 어느 계층에 있는지 구분하기 어렵습니다. 또한 EKS는 표준 지원 버전 기준 클러스터 제어 영역에 시간당 요금이 발생하고, 워커 노드·EBS·공인 IPv4·데이터 전송 비용은 별도입니다.

따라서 다음 순서로 진행합니다.

1. WSL2에서 안전한 관측 명령과 로그 탐색 습득
2. Terraform으로 독립 EC2 Linux 노드 2대를 만들고 실제 서버·TCP 장애 재현
3. 로컬 다중 노드 Kubernetes에서 Pod·Service·DNS·노드 장애 재현
4. Terraform과 AWS 네트워크 구조를 심화 학습
5. 짧게 생성하고 반드시 제거하는 EKS 장애 실습

EKS는 필요합니다. 다만 일반 Linux 서버 장애를 EKS 하나에 억지로 넣지 않고, **독립 EC2 실습과 EKS 실습의 목적을 분리**합니다.

## Terraform 실습 코드 구조

AWS 실습 코드는 다음 구조로 관리할 예정입니다.

```text
infrastructure/
├── aws-linux-lab/       # 실제 Linux 노드 2대와 노드 간 TCP 장애 실습
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── Makefile
└── eks-lab/             # EKS managed node group 및 VPC CNI 장애 실습
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── terraform.tfvars.example
    └── Makefile
```

두 Makefile은 최소한 다음 안전 흐름을 제공합니다.

```text
make init       Terraform 초기화
make fmt        코드 정리
make validate   문법과 구성 검증
make plan       실제 변경 전 검토
make apply      비용 발생 리소스 생성
make destroy    실습 리소스 제거
make check      잔존 리소스와 상태 확인
```

원격 Terraform state, AWS 리전, 허용 비용, EC2 접근 방식, EKS 노드 수를 결정한 뒤 코드를 구현합니다. 비밀 값, 계정 ID, 실제 `tfvars`, state 파일은 GitHub에 올리지 않습니다. AWS 생성 작업은 코드 작성과 달리 비용과 외부 상태 변경을 일으키므로 `make apply` 직전에 계획과 예상 리소스를 확인합니다.

## 로그 경로를 전부 외워야 하는가

전부 외울 필요도 없고, 전부 외우는 것도 현실적으로 불가능합니다. 로그 위치는 배포판, 서비스 버전, 설치 방식, systemd 설정, 컨테이너 런타임과 애플리케이션 설정에 따라 달라집니다.

대신 다음 탐색 순서를 익힙니다.

1. 서비스 이름과 실행 방식을 확인합니다.
2. systemd 서비스라면 `journalctl`을 먼저 확인합니다.
3. 서비스 유닛과 실행 인수를 보고 설정 파일 위치를 찾습니다.
4. 프로세스가 열고 있는 파일과 파일 디스크립터를 확인합니다.
5. `/var/log`에서 최근 변경된 관련 파일을 찾습니다.
6. 로그 로테이션과 보존 정책을 확인합니다.
7. 컨테이너라면 호스트 파일보다 컨테이너·Pod 로그 경로로 전환합니다.

자주 접하는 위치는 다음과 같지만, 이것을 고정된 정답으로 간주하지 않습니다.

| 범주 | 우선 확인 위치/방법 |
|---|---|
| systemd 서비스 | `journalctl -u <service>` |
| 시스템 부팅·커널 | `journalctl -b`, `journalctl -k`, `dmesg` |
| 전통적인 시스템 로그 | `/var/log/syslog`, `/var/log/messages` |
| 인증 | `/var/log/auth.log`, `/var/log/secure` |
| 웹 서버 | `/var/log/nginx/`, `/var/log/httpd/` 등 서비스 설정에 지정된 위치 |
| 애플리케이션 | systemd journal, 애플리케이션 설정, 표준 출력 또는 전용 로그 디렉터리 |
| 컨테이너 | `docker logs`, `crictl logs` 또는 런타임 설정 |
| Kubernetes 워크로드 | `kubectl logs`, `kubectl describe`, Events |
| Kubernetes 노드 | `journalctl -u kubelet`, 컨테이너 런타임과 CNI 로그 |

### 로그 위치를 찾아내는 대표 명령

```bash
systemctl status <service> --no-pager
systemctl cat <service>
systemctl show <service> -p ExecStart -p FragmentPath
journalctl -u <service> --since '15 minutes ago' --no-pager
find /var/log -type f -mmin -15 -printf '%TY-%Tm-%Td %TH:%TM %p\n' 2>/dev/null
lsof -p <PID> 2>/dev/null
ls -l /proc/<PID>/fd 2>/dev/null
```

실습에서는 긴 로그 전체를 읽지 않고 시간, 서비스, 우선순위, 키워드로 범위를 줄입니다.

```bash
journalctl -u <service> --since '10 minutes ago' -p warning..alert --no-pager
grep -nEi 'error|fail|timeout|refused|denied' <log-file> | tail -n 50
tail -n 100 <log-file>
tail -F <log-file>
```

## TCP 통신 문제를 조사하는 순서

TCP 장애는 무작정 `ping`부터 실행하는 대신 계층별로 확인합니다.

### 1. 로컬 상태

```bash
ip -br address
ip route
ip route get <destination-ip>
ss -lntp
ss -ntp
```

확인할 내용:

- 올바른 IP가 인터페이스에 설정됐는가?
- 목적지로 갈 라우팅 경로가 있는가?
- 서버 프로세스가 예상 IP와 포트에서 LISTEN 중인가?
- 연결이 `SYN-SENT`, `ESTAB`, `TIME-WAIT` 등 어떤 상태인가?

### 2. 이름 해석과 애플리케이션 연결

```bash
getent hosts <hostname>
nc -vz -w 3 <host> <port>
curl -v --connect-timeout 3 http://<host>:<port>/
```

`ping` 성공은 TCP 포트 성공을 보장하지 않으며, `ping` 실패도 TCP 실패를 항상 의미하지 않습니다. ICMP가 별도로 차단될 수 있기 때문입니다.

### 3. 경로·필터·패킷

```bash
tracepath <destination-ip>
sudo nft list ruleset
sudo tcpdump -ni any host <destination-ip> and port <port>
```

패킷 캡처에서는 다음을 구분합니다.

- SYN이 출발하지 않음: 로컬 애플리케이션·라우팅·방화벽 가능성
- SYN은 출발하지만 응답 없음: 중간 경로·보안 정책·상대 호스트 가능성
- RST 수신: 목적지 도달은 했지만 포트 미수신 또는 적극적 거부 가능성
- 3-way handshake 후 실패: TCP보다 상위 프로토콜·인증·애플리케이션 가능성

## Kubernetes와 EKS에서의 노드 간 통신

“노드 간 통신 문제”를 다음 흐름으로 더 작게 나눕니다.

```text
Node ↔ Node
Pod ↔ Pod
Pod ↔ Service
Pod ↔ DNS
Node ↔ Kubernetes API
Pod/Node ↔ 외부 서비스
```

Kubernetes 단계에서는 다음 증거를 함께 봅니다.

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get svc,endpoints,endpointslices -A
kubectl describe node <node>
kubectl describe pod <pod> -n <namespace>
kubectl get events -A --sort-by=.lastTimestamp
kubectl logs <pod> -n <namespace> --since=10m
```

노드에 접근할 수 있을 때는 `kubelet`, 컨테이너 런타임, CNI, 라우팅과 방화벽을 조사합니다. 관리형 환경에서는 `kubectl debug node/<node>` 같은 방법도 사용합니다. EKS 단계에서는 여기에 VPC 라우팅, 보안 그룹, NACL, ENI/IP 고갈, VPC CNI 상태를 추가합니다.

## 단계별 학습 과정

### 1단계: Linux 관측의 기본

목표: 정상 상태를 설명하고 이상 상태를 발견합니다.

- 셸, 경로, 파일 검색과 텍스트 검색
- 프로세스와 부모·자식 관계
- CPU, 메모리, 디스크, inode
- 열린 파일과 파일 디스크립터
- 사용자, 권한, `sudo`
- systemd 서비스와 부팅 과정
- journal과 전통적인 로그 파일

대표 도구:

```text
ps, top, uptime, free, vmstat, pidstat
df, du, findmnt, lsblk, lsof
systemctl, journalctl, dmesg
find, grep, rg, awk, sed, sort, uniq, less, tail
```

장애 실습:

- 서비스 중지 및 자동 재시작 실패
- 잘못된 설정 파일
- 권한 오류
- 디스크 공간 또는 inode 부족
- 메모리 압박과 OOM 흔적
- 높은 CPU를 사용하는 프로세스

### 2단계: Linux 네트워크와 TCP

목표: 연결 실패 지점을 계층별로 좁힙니다.

- IP, 서브넷, 게이트웨이, 라우팅
- DNS 이름 해석
- TCP 3-way handshake와 연결 상태
- LISTEN 주소와 포트
- 방화벽과 NAT 기초
- 패킷 캡처

대표 도구:

```text
ip, ss, getent, dig, nc, curl
tracepath, tcpdump, nft, conntrack
```

장애 실습:

- 잘못된 바인드 주소
- 닫힌 포트와 connection refused
- 응답 없는 포트와 timeout
- 잘못된 DNS 결과
- 라우팅 누락
- 방화벽 차단
- 서버는 연결됐지만 HTTP가 실패하는 경우

### 3단계: 반복 가능한 Linux 장애 대응

목표: 명령어가 아니라 표준 조사 절차를 만듭니다.

- 장애 시작 시간과 변경 사항 확인
- 영향 범위와 우선순위 결정
- 로그·메트릭·프로세스·네트워크 증거 연결
- 임시 복구와 근본 해결 분리
- 장애 타임라인과 사후 분석 작성

결과물:

- 서비스 장애 체크리스트
- TCP 장애 체크리스트
- 로그 탐색 체크리스트
- 짧은 장애 보고서 템플릿

### 4단계: 로컬 다중 노드 Kubernetes

목표: AWS 비용 없이 Kubernetes 계층의 장애를 반복 실습합니다.

- Pod, Deployment, Service, EndpointSlice, DNS
- 스케줄링과 리소스 부족
- readiness/liveness probe
- kubelet과 컨테이너 런타임
- CNI와 Pod 네트워크
- 다중 노드 간 Pod 통신

장애 실습:

- 잘못된 Service selector
- readiness 실패로 Endpoint 제외
- 잘못된 포트와 targetPort
- CoreDNS 문제
- NetworkPolicy 차단
- 특정 노드의 kubelet 또는 CNI 문제
- 노드 drain과 Pod 재배치

### 5단계: Terraform과 AWS 기초

목표: EKS를 만들기 전에 클라우드 네트워크와 IaC를 설명합니다.

- Terraform state, plan, apply, destroy
- 변수, 출력, 모듈과 의존 관계
- VPC, public/private subnet, route table
- Internet/NAT Gateway
- Security Group과 NACL 차이
- IAM role과 최소 권한
- 비용 태그와 삭제 검증

### 6단계: Terraform 기반 EKS

목표: 로컬에서 익힌 조사 절차를 AWS 고유 계층까지 확장합니다.

- VPC와 EKS control plane
- managed node group
- CoreDNS, kube-proxy, VPC CNI add-on
- IAM과 Kubernetes 접근 제어
- CloudWatch control plane/node 로그
- 노드·Pod IP와 ENI
- Terraform으로 생성 및 완전 삭제

EKS 실습은 필요한 시간에만 생성하고 매 실습 뒤 `terraform destroy` 및 AWS 리소스 잔존 여부를 확인합니다.

### 7단계: 종합 장애 훈련

목표: 원인을 미리 알려주지 않은 장애를 독립적으로 해결합니다.

예시 시나리오:

1. 서비스 접속 지연
2. 특정 노드의 Pod만 외부 연결 실패
3. DNS는 되지만 TCP timeout
4. TCP 연결은 되지만 HTTP 503
5. 디스크 부족으로 서비스 재시작 실패
6. OOM으로 반복 재시작
7. 잘못된 Security Group 또는 route table
8. VPC CNI IP 할당 실패
9. kubelet 장애로 Node NotReady
10. Terraform 변경 후 일부 리소스 불일치

각 실습은 다음 형식으로 기록합니다.

```text
증상 / 영향 범위 / 최초 가설 / 실행 명령 / 관찰 증거
원인 / 복구 / 검증 / 재발 방지 / 새로 배운 점
```

## 현업에서 먼저 확인하는 공통 체크리스트

1. 장애 발생 시각과 최근 변경 사항을 확인합니다.
2. 한 사용자·한 Pod·한 노드·한 AZ·전체 서비스 중 영향 범위를 정합니다.
3. CPU·메모리·디스크·inode·프로세스·포트를 빠르게 확인합니다.
4. 서비스 상태와 해당 시간 범위의 로그를 확인합니다.
5. DNS → route → LISTEN → TCP 연결 → 상위 프로토콜 순으로 검사합니다.
6. 여러 증거의 시간대를 맞춰 하나의 타임라인을 만듭니다.
7. 변경 전에 현재 상태를 남기고, 가장 작은 복구 조치를 선택합니다.
8. 복구 후 사용자 관점과 시스템 관점에서 모두 검증합니다.
9. 원인과 재발 방지 조치를 문서화합니다.

## 학습 운영 방식

- Codex가 한 번에 관련 명령 3~5개와 확인 목적을 제시합니다.
- 사용자는 `study` 셸에서 실행하고 `했어`라고만 알립니다.
- Codex가 새 출력만 확인하여 가설과 다음 조사 단계를 안내합니다.
- 정답을 먼저 알려주기보다 관찰 결과로 원인을 좁히게 합니다.
- 한 주제가 끝나면 이론, 명령어, 실제 결과, 실수와 해결법을 문서화합니다.
- 의미 있는 단위가 끝날 때 `PROGRESS.md`를 갱신하고 GitHub에 커밋·푸시합니다.

## 첫 학습

첫 번째 주제는 **Linux 시스템의 정상 상태 파악과 증거 수집**입니다.

처음부터 장애를 만들기 전에 현재 시스템에서 다음을 설명할 수 있게 합니다.

- 어떤 배포판과 커널을 사용하는가?
- systemd가 PID 1인가?
- 현재 부팅 시간과 부하 상태는 어떤가?
- CPU, 메모리, 디스크, inode에 여유가 있는가?
- 주요 네트워크 인터페이스와 기본 경로는 무엇인가?
- 현재 실패한 systemd 서비스가 있는가?
- 최근 경고 이상 시스템 로그가 있는가?

이 기준선을 남긴 뒤 작은 서비스 장애부터 재현합니다.

## 공식 참고 자료

- [Microsoft WSL1과 WSL2 비교 및 Linux 커널 설명](https://learn.microsoft.com/en-us/windows/wsl/wsl2-about)
- [WSL의 systemd 지원](https://learn.microsoft.com/en-us/windows/wsl/systemd)
- [Amazon EKS 요금](https://aws.amazon.com/eks/pricing/)
- [Amazon EKS 학습 및 Terraform 워크숍 안내](https://docs.aws.amazon.com/eks/latest/userguide/learn-eks.html)
- [EKS managed node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [EKS control plane 로그를 CloudWatch로 전송](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)
- [Kubernetes 클러스터 문제 해결](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
- [kubectl로 노드 디버깅](https://kubernetes.io/docs/tasks/debug/debug-cluster/kubectl-node-debug/)
