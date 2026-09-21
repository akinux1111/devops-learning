#!/usr/bin/env bash
set -euo pipefail

STUDY_RUNTIME_DIR="/tmp/devops-learning-terminal"
current_file="$STUDY_RUNTIME_DIR/current"

if [[ ! -f "$current_file" ]]; then
  printf '[study] no recorded session found; run start.sh first\n' >&2
  exit 1
fi
log_file="$(<"$current_file")"
cursor_file="$log_file.cursor"

if [[ ! -f "$log_file" ]]; then
  printf '[study] current log does not exist: %s\n' "$log_file" >&2
  exit 1
fi

current_size="$(wc -c < "$log_file")"
cursor=0
if [[ -s "$cursor_file" ]]; then
  cursor="$(<"$cursor_file")"
fi
if (( cursor > current_size )); then
  cursor=0
fi

unread_bytes=$((current_size - cursor))
if (( unread_bytes == 0 )); then
  printf '[study] no new output\n'
  exit 0
fi

scratch_file="$(mktemp "$STUDY_RUNTIME_DIR/unread.XXXXXX")"
trap 'rm -f "$scratch_file"' EXIT
tail -c "+$((cursor + 1))" "$log_file" > "$scratch_file"
printf '%s\n' "$current_size" > "$cursor_file"

strip_controls() {
  sed -E $'s/\x1B\[[0-9;?]*[ -\/]*[@-~]//g; s/\r$//'
}

if (( unread_bytes <= 32768 )); then
  strip_controls < "$scratch_file"
else
  printf '[study] large output: %s bytes; middle section omitted\n' "$unread_bytes"
  printf '%s\n' '--- beginning ---'
  head -c 8192 "$scratch_file" | strip_controls
  printf '\n%s\n' '--- omitted ---'
  tail -c 24576 "$scratch_file" | strip_controls
fi
