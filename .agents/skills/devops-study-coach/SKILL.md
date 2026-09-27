---
name: devops-study-coach
description: Guide hands-on Linux, Kubernetes, and DevOps study sessions, inspect study-terminal output without copy-paste, maintain detailed lesson notes in Notion, and keep GitHub focused on executable labs and concise progress records.
---

# DevOps Study Coach

Continue the user's learning from repository state and leave a useful, reviewable record.

## Resume context

1. Read `PROGRESS.md`, the relevant section `README.md`, and the linked Notion lesson when available.
2. For SAA, CKA, or 리눅스마스터 1급 work, also use the matching repository skill. Treat its track structure as a guide, and read current progress and exam facts from their sources.
3. Identify the next unfinished item. If the user has not chosen a topic, propose one small next step based on the recorded sequence rather than asking for a broad restatement.
4. Ensure `study` is available. If not, run `./tools/study-terminal/install.sh` and verify `study help`.

## Run a lesson

- Explain the immediate concept briefly, then give a practical batch of roughly 3–5 related commands.
- Explain destructive, privileged, or externally mutating commands before asking the user to run them. Prefer read-only discovery first.
- Put the unit's theory, practice steps, expected observations, and completion criteria in the connected Notion lesson before asking the user to work from it. Ask the user to run `study`, execute the batch, and reply `완료` (or an equivalent short completion signal). Do not request pasted output.
- After that signal, run `study read-new`. Inspect only the new bounded output. Use targeted follow-up commands when the bounded output is insufficient; do not dump entire logs into context.
- Correct misunderstandings from observable results and verify the completion criteria. Ask whether to move to the next section after a completed unit; do not advance solely because the user sent a completion signal.
- Let the user end the study shell with `Ctrl+D` or `:study-stop`. Temporary output cleanup and rotation are handled by the utility; use `study clear` immediately if sensitive output is suspected.

## Document learning

After a meaningful lesson checkpoint:

1. Create or update the detailed lesson in Notion when the relevant page and connection are available.
2. Capture learning goals, concise theory, commands with explanations, observed results, troubleshooting, and a short review checklist in that Notion lesson.
3. Exclude raw transcripts, secrets, machine-specific noise, and redundant command output.
4. Keep GitHub topic Markdown limited to code usage, safety instructions, a Notion lesson link, and information required to run the lab. Update `PROGRESS.md` concisely with status and the next action.
5. Validate changed repository files, then create a focused commit and push to `origin/main` when available.
6. If Notion is unavailable, do not recreate the full lesson in GitHub. Record only the minimal progress needed to resume and report that detailed documentation remains pending.

Update a skill when the repeatable workflow or study taxonomy changes. Put session progress, corrections, observed results, target dates, and current exam versions in Notion and `PROGRESS.md`, so later sessions read fresh state without rewriting skill instructions for every lesson.

## Information architecture

- Notion is the canonical source for detailed lesson notes, console walkthroughs, observations, and troubleshooting.
- GitHub is the canonical source for executable lab code, minimal run and cleanup instructions, and concise progress state.
- Link from Notion to the relevant GitHub code and from the repository README to the Notion lesson. Do not duplicate the full lesson across both systems.

## Privacy and efficiency

- Never read or commit more terminal output than needed for the current exercise.
- Shape potentially noisy commands with filters such as resource selectors, `head`, `tail`, or focused formatting.
- Never intentionally print credentials or broad secret-bearing environment/configuration data.
- The study utility records command output, not typed command text, stores it outside the repository, removes the prior session at the next start, and caps the current record at 1 MiB.
