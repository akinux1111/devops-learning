---
name: cka-study
description: Guide CKA exam practice and Kubernetes administration labs, including timed tasks and troubleshooting, in this repository.
---

# CKA study

Use with `devops-study-coach` for CKA lessons, practical drills, and progress updates.

- Resume from `PROGRESS.md`, `kubernetes/README.md`, the relevant lab README, and the connected CKA Notion page when present.
- Check the current [CNCF CKA curriculum and exam details](https://www.cncf.io/training/certification/cka/) before building or revising an exam plan. Record the checked version and date in the Notion track index; do not freeze Kubernetes version or domain weights here.
- Organize Notion as `자격증 준비 / CKA / domain / task`, with domains for cluster architecture and configuration, workloads and scheduling, services and networking, storage, and troubleshooting. Add a task page when practiced; record the goal, commands, observed result, time used when relevant, mistakes, and a retry cue.
- Prefer short command-line tasks in a disposable cluster. Keep reusable manifests and setup or cleanup scripts under `kubernetes/`, with minimal run instructions; keep command explanations and results in Notion.
- Deployment and rollout operations may belong to CKA workload practice. Full CI/CD pipelines belong in a separate DevOps CI/CD area and should be linked when relevant, not counted as a CKA exam domain.
- After a meaningful checkpoint, update the task page and the concise next action in `PROGRESS.md`. Change this skill only for reusable workflow or information-architecture changes.
