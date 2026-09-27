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
- Before a study unit starts, prepare its Notion page with separate `이론` and `실습` sections, specific steps, expected observations, and completion criteria. Teach AWS console navigation and interpretation first when a console workflow exists. Offer CLI as a second, purposeful path for inspection, repetition, verification, or automation; do not require CLI for every unit or require memorized long commands or JMESPath queries. If hands-on work is unnecessary, state that and give a concrete understanding check. Let the user work from Notion at their pace.
- When the user says `완료`, inspect their Notion observations and use `study read-new` only if they ran commands in `study`. Where useful, make targeted read-only AWS CLI calls to corroborate account state. A CLI read cannot prove which console actions the user took; assess their written observations and clarify uncertain steps. Check the unit criteria, guide and recheck any gaps, then mark the unit complete in Notion and `PROGRESS.md` only after evidence supports it. Ask whether to start the next section before preparing or assigning its work.
- Put reusable Terraform or scripts in the relevant `infrastructure/` lab. Keep detailed reasoning, console steps, observations, and error review in Notion. Link both ways where useful.
- Inspect an instructor example before running it; check current CLI or service behavior, resource cost, and cleanup. Adapt reusable exercises into original lab code when needed rather than executing the example blindly.
- After a meaningful checkpoint, update the topic page and the concise next action in `PROGRESS.md`. Change this skill only when the reusable study workflow or information architecture changes; current progress and exam facts belong in their sources.
