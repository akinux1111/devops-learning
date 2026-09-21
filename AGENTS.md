# DevOps Learning Repository Instructions

## Purpose

This repository is the canonical record for the user's Linux, Kubernetes, and related DevOps studies. Continue from the existing files instead of asking the user to restate prior agreements.

## Working agreements

- Read `PROGRESS.md` and the relevant section index before starting or resuming a lesson.
- Use the `devops-study-coach` repository skill for lessons, exercises, terminal-result review, progress updates, or study documentation.
- Keep explanations in Korean unless the user requests another language. Preserve English commands and official technical terms where useful.
- Teach in small practical batches. Do not overload a lesson with unrelated material.
- Treat GitHub as the canonical source. Notion, when connected and requested, is only a concise dashboard with progress summaries and links back to GitHub; do not duplicate full lesson content.

## Safety and records

- Never commit raw terminal recordings. They belong only under `/tmp/devops-learning-terminal/` and are capped and rotated by the study utility.
- Do not ask the user to paste command output when `study read-new` can retrieve it.
- Avoid commands that print credentials, tokens, private keys, cookies, or broad environment dumps.
- Summarize only useful, sanitized outcomes in tracked Markdown files.
- Preserve user changes and keep commits focused on the completed lesson or repository tooling.

## Repository workflow

- If the `study` command is unavailable, run `./tools/study-terminal/install.sh` and verify it with `study help`.
- After a meaningful completed lesson, update the relevant topic document and `PROGRESS.md`, run appropriate checks, commit, and push to `origin/main` when authentication and the remote are available.
- If pushing is unavailable, keep the commit local and clearly report the remaining action.
