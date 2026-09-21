#!/usr/bin/env bash

# Completion helpers for the custom read-eval loop. The current command line
# is used in memory only and is never written to the study output log.

_study_completion_candidates() {
  local line="$1"
  local point="$2"
  local left
  local first_word
  local current_word

  left="${line:0:point}"
  first_word="${left%%[[:space:]]*}"
  current_word="${left##*[[:space:]]}"

  if [[ "$first_word" == "aws" ]] && command -v aws_completer >/dev/null 2>&1; then
    COMP_LINE="$line" COMP_POINT="$point" aws_completer 2>/dev/null
    return
  fi

  if [[ "$first_word" == "make" && "$left" == *[[:space:]]* ]]; then
    make -qp 2>/dev/null \
      | awk -F: '/^[A-Za-z0-9][^$#\/\t=]*:([^=]|$)/ {print $1}' \
      | sort -u \
      | while IFS= read -r target; do
          [[ "$target" == "$current_word"* ]] && printf '%s\n' "$target"
        done
    return
  fi

  if [[ "$left" != *[[:space:]]* ]]; then
    compgen -c -- "$current_word"
  else
    compgen -f -- "$current_word"
  fi
}

_study_longest_common_prefix() {
  local prefix="$1"
  shift
  local candidate

  for candidate in "$@"; do
    while [[ -n "$prefix" && "$candidate" != "$prefix"* ]]; do
      prefix="${prefix%?}"
    done
  done
  printf '%s' "$prefix"
}

_study_complete() {
  local left
  local current_word
  local word_start
  local common_prefix
  local -a candidates=()

  mapfile -t candidates < <(
    _study_completion_candidates "$READLINE_LINE" "$READLINE_POINT" \
      | sed '/^[[:space:]]*$/d'
  )
  ((${#candidates[@]} == 0)) && return

  left="${READLINE_LINE:0:READLINE_POINT}"
  current_word="${left##*[[:space:]]}"
  word_start=$((READLINE_POINT - ${#current_word}))

  if ((${#candidates[@]} == 1)); then
    READLINE_LINE="${READLINE_LINE:0:word_start}${candidates[0]} ${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((word_start + ${#candidates[0]} + 1))
    return
  fi

  common_prefix="$(_study_longest_common_prefix "${candidates[@]}")"
  if ((${#common_prefix} > ${#current_word})); then
    READLINE_LINE="${READLINE_LINE:0:word_start}${common_prefix}${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((word_start + ${#common_prefix}))
    return
  fi

  printf '\n'
  printf '%s\n' "${candidates[@]}" | column 2>/dev/null || printf '%s\n' "${candidates[@]}"
}
