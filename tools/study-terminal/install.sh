#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
user_home_dir="$(getent passwd "$(id -u)" | cut -d: -f6)"
INSTALL_DIR="$user_home_dir/.local/bin"
link_path="$INSTALL_DIR/study"

mkdir -p "$INSTALL_DIR"
ln -sfn "$SCRIPT_DIR/study" "$link_path"

printf '[study] installed: %s -> %s\n' "$link_path" "$SCRIPT_DIR/study"
printf '[study] run: study\n'
