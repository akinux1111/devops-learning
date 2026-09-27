---
name: saa-study
description: Guide AWS Solutions Architect Associate study, architecture decisions, and related AWS labs in this repository.
---

# SAA study

Use with `devops-study-coach` for SAA lessons, exam preparation, and progress updates.

- Resume from `PROGRESS.md`, `infrastructure/README.md`, the relevant lab README, and the connected SAA Notion page when present. Do not infer completion from a folder or an old note.
- Check the current [AWS SAA exam guide](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03.html) before building or revising an exam plan. Record the checked exam code and date in the Notion track index; do not freeze domain weights or service lists in this skill.
- Follow the connected Notion `AWS SAA / 강의 순서 학습` index when the user studies with Stephane Maarek's course. Read only the current section of the locally downloaded slides and relevant example code, then check time-sensitive facts against current AWS documentation. Record section progress in Notion and `PROGRESS.md`.
- The instructor's original PDF and ZIP belong in ignored `course-materials/saa-stephane/` for personal study. Use the [instructor's download page](https://courses.datacumulus.com/downloads/certified-solutions-architect-pn9/) if the local files are absent or stale. Do not commit or copy the original course materials into GitHub or Notion; write original explanations and labs instead.
- Organize Notion as `자격증 준비 / AWS SAA / area / topic`, with areas for compute, networking, storage, databases, security and operations, containers, and architecture decisions. Make a topic page when that topic is studied; link existing AWS operations lessons instead of copying them.
- For each topic, explain the underlying idea and why the service or design exists, then its behavior, constraints, and tradeoffs with a concrete example. Check understanding and clarify confusion before using exam-style or architecture questions.
- When video viewing is inconvenient, turn a small portion of the current course slides into an original, coherent text lesson with diagrams or examples where useful. Use practical observation when it helps the concept. Introduce a short scenario only after the explanation and any needed lab; do not make question drills the main teaching method. Use the course video selectively for gaps.
- Put reusable Terraform or scripts in the relevant `infrastructure/` lab. Keep detailed reasoning, console steps, observations, and error review in Notion. Link both ways where useful.
- Inspect an instructor example before running it; check current CLI or service behavior, resource cost, and cleanup. Adapt reusable exercises into original lab code when needed rather than executing the example blindly.
- After a meaningful checkpoint, update the topic page and the concise next action in `PROGRESS.md`. Change this skill only when the reusable study workflow or information architecture changes; current progress and exam facts belong in their sources.
