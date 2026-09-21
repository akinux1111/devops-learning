# DevOps Learning

Linux와 Kubernetes를 중심으로 학습 내용, 명령어, 실습 결과를 누적하는 저장소입니다.

## 학습 섹션

- [Linux](linux/README.md)
- [Kubernetes](kubernetes/README.md)
- [전체 진행 기록](PROGRESS.md)
- [학습 터미널 공유 유틸](tools/study-terminal/README.md)

## 다른 PC에서 이어서 학습하기

```bash
git clone https://github.com/akinux1111/devops-learning.git
cd devops-learning
./tools/study-terminal/install.sh
codex
```

저장소 루트의 `AGENTS.md`와 `.agents/skills/devops-study-coach/`가 학습 방식, 진행 기록, 터미널 출력 확인, 문서화 규칙을 Codex에 제공합니다. 새 PC에서는 저장소 안에서 Codex를 시작한 뒤 `학습 이어서 하자`라고 말하면 됩니다.

GitHub Markdown을 상세 학습 기록의 단일 원본으로 사용합니다. Notion을 연결하는 경우에는 전체 내용을 복제하지 않고 진도·다음 할 일·GitHub 링크만 담는 요약 대시보드로 사용합니다.

## 기록 원칙

각 주제는 다음 내용을 포함합니다.

1. 학습 목표
2. 핵심 이론
3. 주요 명령어와 옵션
4. 직접 실행할 실습
5. 실행 결과 및 문제 해결 기록
6. 복습 체크리스트

새 주제를 시작할 때 [`templates/topic-template.md`](templates/topic-template.md)를 복사해 사용합니다.

## 디렉터리 구조

```text
.
├── linux/          # Linux 이론 및 실습
├── kubernetes/     # Kubernetes 이론 및 실습
├── templates/      # 새 학습 주제용 문서 템플릿
├── tools/          # 학습 보조 유틸리티
├── .agents/        # 저장소 전용 Codex 학습 스킬
├── AGENTS.md       # Codex가 자동으로 읽는 저장소 운영 규칙
└── PROGRESS.md     # 전체 학습 진행 상황
```
