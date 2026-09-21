#!/usr/bin/env bash
set -euo pipefail

STUDY_RUNTIME_DIR="/tmp/devops-learning-terminal"
mkdir -p "$STUDY_RUNTIME_DIR"
chmod 700 "$STUDY_RUNTIME_DIR"

timestamp="$(date '+%Y%m%d-%H%M%S')"
log_file="$STUDY_RUNTIME_DIR/session-$timestamp.terminal-output"
current_file="$STUDY_RUNTIME_DIR/current"

printf '%s\n' "$log_file" > "$current_file"
chmod 600 "$current_file"
: > "$log_file"
: > "$log_file.cursor"
chmod 600 "$log_file" "$log_file.cursor"

printf '[study] recording started\n'
printf '[study] log: %s\n' "$log_file"
printf '[study] only command output is recorded; typed command text is not recorded\n'
printf '[study] type exit to finish; do not print secrets in this session\n'

run_and_record_output() {
  local command_text="$1"
  local pipe_dir
  local output_pipe
  local tee_pid
  local command_status

  pipe_dir="$(mktemp -d "$STUDY_RUNTIME_DIR/output.XXXXXX")"
  output_pipe="$pipe_dir/stream"
  mkfifo "$output_pipe"
  tee -a "$log_file" < "$output_pipe" &
  tee_pid=$!

  exec 3>&1 4>&2
  exec > "$output_pipe" 2>&1
  set +e
  eval "$command_text"
  command_status=$?
  set -e
  exec 1>&3 2>&4
  exec 3>&- 4>&-

  wait "$tee_pid"
  rm -f "$output_pipe"
  rmdir "$pipe_dir"
  return "$command_status"
}

while true; do
  if [[ -t 0 ]]; then
    IFS= read -e -r -p '[study]$ ' command_text || break
  else
    IFS= read -r command_text || break
  fi

  [[ -z "$command_text" ]] && continue
  [[ "$command_text" == "exit" ]] && break

  if run_and_record_output "$command_text"; then
    :
  else
    command_status=$?
    printf '[study] command exited with status %s\n' "$command_status" | tee -a "$log_file"
  fi
done

printf '[study] recording finished\n'
