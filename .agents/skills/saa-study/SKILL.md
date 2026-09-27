---
name: saa-study
description: Guide AWS Solutions Architect Associate study, architecture decisions, and related AWS labs in this repository.
---

# SAA study

Use with `devops-study-coach` for SAA lessons, exam preparation, and progress updates.

- Resume from `PROGRESS.md`, `infrastructure/README.md`, the relevant lab README, and the connected SAA Notion page when present. Do not infer completion from a folder or an old note.
- Check the current [AWS SAA exam guide](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03.html) before building or revising an exam plan. Record the checked exam code and date in the Notion track index; do not freeze domain weights or service lists in this skill.
- Organize Notion as `자격증 준비 / AWS SAA / area / topic`, with areas for compute, networking, storage, databases, security and operations, containers, and architecture decisions. Make a topic page when that topic is studied; link existing AWS operations lessons instead of copying them.
- For a service topic, teach its purpose, constraints, selection tradeoffs, and one small scenario. For an architecture question, compare viable service combinations and explain why one fits the stated requirements.
- Put reusable Terraform or scripts in the relevant `infrastructure/` lab. Keep detailed reasoning, console steps, observations, and error review in Notion. Link both ways where useful.
- After a meaningful checkpoint, update the topic page and the concise next action in `PROGRESS.md`. Change this skill only when the reusable study workflow or information architecture changes; current progress and exam facts belong in their sources.
