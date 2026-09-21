#!/usr/bin/env bash
set -euo pipefail

STUDY_RUNTIME_DIR="/tmp/devops-learning-terminal"
mkdir -p "$STUDY_RUNTIME_DIR"
chmod 700 "$STUDY_RUNTIME_DIR"

timestamp="$(date '+%Y%m%d-%H%M%S')"
log_file="$STUDY_RUNTIME_DIR/session-$timestamp.terminal-record"
current_file="$STUDY_RUNTIME_DIR/current"

printf '%s\n' "$log_file" > "$current_file"
chmod 600 "$current_file"
: > "$log_file"
: > "$log_file.cursor"
chmod 600 "$log_file" "$log_file.cursor"

printf '[study] recording started\n'
printf '[study] log: %s\n' "$log_file"
printf '[study] type exit to finish; do not enter secrets in this session\n'

script -q -f "$log_file"

printf '[study] recording finished\n'

