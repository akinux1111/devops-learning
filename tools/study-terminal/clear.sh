#!/usr/bin/env bash
set -euo pipefail

STUDY_RUNTIME_DIR="/tmp/devops-learning-terminal"

if [[ ! -d "$STUDY_RUNTIME_DIR" ]]; then
  printf '[study] no temporary records to remove\n'
  exit 0
fi

find "$STUDY_RUNTIME_DIR" -mindepth 1 -maxdepth 1 -type f -delete
printf '[study] temporary terminal records removed\n'
