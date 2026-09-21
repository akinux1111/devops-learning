#!/usr/bin/env bash
set -euo pipefail

resolved_script="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$resolved_script")" && pwd)"
source "$SCRIPT_DIR/completion.sh"

STUDY_RUNTIME_DIR="/tmp/devops-learning-terminal"
MAX_LOG_BYTES=1048576
mkdir -p "$STUDY_RUNTIME_DIR"
chmod 700 "$STUDY_RUNTIME_DIR"

if [[ -t 0 ]]; then
  original_terminal_state="$(stty -g)"
  trap 'stty "$original_terminal_state"' EXIT
  stty echo
fi

# Keep only the current study session. The previous session has already had a
# chance to be inspected and is removed automatically at the next start.
find "$STUDY_RUNTIME_DIR" -mindepth 1 -maxdepth 1 -type f -delete

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
printf '[study] press Ctrl+D or type :study-stop to finish\n'
printf '[study] do not print secrets in this session\n'

if [[ -t 0 ]]; then
  set -o emacs
  bind -x '"\C-i":_study_complete'
fi

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

rotate_log_if_needed() {
  local current_size
  local trimmed_file

  current_size="$(wc -c < "$log_file")"
  if (( current_size > MAX_LOG_BYTES )); then
    trimmed_file="$(mktemp "$STUDY_RUNTIME_DIR/trimmed.XXXXXX")"
    tail -c "$MAX_LOG_BYTES" "$log_file" > "$trimmed_file"
    chmod 600 "$trimmed_file"
    mv -f "$trimmed_file" "$log_file"
    : > "$log_file.cursor"
    printf '[study] output log rotated at 1 MiB; oldest output discarded\n'
  fi
}

while true; do
  if [[ -t 0 ]]; then
    user_name="$(id -un)"
    host_name="$(hostname -s)"
    user_home_dir="$(getent passwd "$(id -u)" | cut -d: -f6)"
    display_dir="$PWD"
    if [[ "$display_dir" == "$user_home_dir" ]]; then
      display_dir='~'
    elif [[ "$display_dir" == "$user_home_dir/"* ]]; then
      display_dir="~/${display_dir#"$user_home_dir/"}"
    fi
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" || -n "${AWS_SESSION_TOKEN:-}" ]]; then
      aws_prompt_profile='env-keys!'
    else
      aws_prompt_profile="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-default}}"
    fi
    printf -v study_prompt $'\001\e[1;35m\002[study]\001\e[0m\002 \001\e[1;33m\002[aws:%s]\001\e[0m\002 \001\e[1;32m\002%s@%s:\001\e[1;34m\002%s\n\001\e[0m\002$ ' \
      "$aws_prompt_profile" "$user_name" "$host_name" "$display_dir"
    IFS= read -e -r -p "$study_prompt" command_text || break
  else
    IFS= read -r command_text || break
  fi

  [[ -z "$command_text" ]] && continue
  [[ "$command_text" == ":study-stop" ]] && break

  if run_and_record_output "$command_text"; then
    :
  else
    command_status=$?
    printf '[study] command exited with status %s\n' "$command_status" | tee -a "$log_file"
  fi
  rotate_log_if_needed
done

printf '[study] recording finished\n'
