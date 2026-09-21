# DevOps Learning Repository Instructions

## Purpose

This repository is the canonical source for executable lab code and minimal run instructions. Notion is the canonical source for detailed lesson notes when the connected learning page exists. Continue from both sources instead of asking the user to restate prior agreements.

## Working agreements

- Read `PROGRESS.md` and the relevant section index before starting or resuming a lesson.
- Use the `devops-study-coach` repository skill for lessons, exercises, terminal-result review, progress updates, or study documentation.
- Keep explanations in Korean unless the user requests another language. Preserve English commands and official technical terms where useful.
- Teach in small practical batches. Do not overload a lesson with unrelated material.
- Keep detailed theory, console walkthroughs, observations, and troubleshooting in Notion. Keep GitHub focused on executable lab code, short README instructions, and links to the relevant Notion lesson. Do not duplicate the full lesson in GitHub Markdown.

## Safety and records

- Never commit raw terminal recordings. They belong only under `/tmp/devops-learning-terminal/` and are capped and rotated by the study utility.
- Do not ask the user to paste command output when `study read-new` can retrieve it.
- Avoid commands that print credentials, tokens, private keys, cookies, or broad environment dumps.
- Keep only useful, sanitized progress summaries and minimal operational instructions in tracked Markdown files.
- Preserve user changes and keep commits focused on the completed lesson or repository tooling.

## Repository workflow

- If the `study` command is unavailable, run `./tools/study-terminal/install.sh` and verify it with `study help`.
- After a meaningful completed lesson, update the detailed Notion lesson and concise `PROGRESS.md`. Change GitHub Markdown only when code usage, safety instructions, or links changed. Run appropriate checks, commit, and push code or repository-instruction changes to `origin/main` when authentication and the remote are available.
- If pushing is unavailable, keep the commit local and clearly report the remaining action.
