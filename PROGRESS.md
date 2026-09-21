# 학습 진행 기록

학습을 진행할 때 날짜별로 완료한 내용과 다음 할 일을 기록합니다.

## 현재 상태

| 섹션 | 주제 | 상태 | 최근 업데이트 |
|---|---|---|---|
| Linux | 현업 장애 대응 로드맵 및 시스템 기준선 | 진행 중 | 2026-09-21 |
| Kubernetes | 로컬 다중 노드 장애 실습 | 예정 | 2026-09-21 |

상태는 `예정`, `진행 중`, `복습 필요`, `완료` 중 하나로 기록합니다.

## 학습 로그

### 2026-09-21

- 학습 저장소 생성
- Linux 및 Kubernetes 기본 섹션 구성
- 복사·붙여넣기 없이 실습 출력을 확인하는 학습 터미널 공유 유틸 추가
- 실제 터미널 기록은 Git 저장소 밖의 `/tmp/devops-learning-terminal/`에만 보관하도록 구성
- 어디서든 `study` 명령으로 학습 셸을 실행할 수 있도록 로컬 명령 등록 기능 추가
- 이전 임시 기록 자동 삭제 및 세션별 1 MiB 순환 제한 적용
- 다른 PC에서도 학습 방식을 자동 복원하는 `AGENTS.md`와 저장소 전용 Codex 스킬 추가
- 현업 Linux·Kubernetes 장애 대응 학습 로드맵 작성
- EKS는 Linux 및 로컬 Kubernetes 장애 대응 이후 Terraform으로 진행하기로 결정
- 현재 WSL2가 실제 Linux 커널·systemd·cgroup v2를 사용함을 확인하고 실습 범위의 한계를 문서화
- 실습 환경을 WSL2, 독립 EC2 Linux 노드 2대, 로컬 Kubernetes, EKS로 분리
- 서울 리전, SSM 전용 접속, 외부 인바운드 미개방 방식의 AWS Linux 실습 Terraform/Makefile 작성
- Terraform AWS provider v6.66.0 초기화 및 validate 성공
- AWS `akinux` 프로필로 15개 리소스 생성 plan 검증 완료(2 add nodes, 전체 15 add, 변경·삭제 없음)
- 다음 할 일: 비용 승인 후 저장된 plan apply 및 SSM 접속 확인
