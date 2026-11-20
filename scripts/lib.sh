#!/usr/bin/env bash
# Shared helpers, sourced by every script in this folder.
set -euo pipefail

# shellcheck disable=SC2034  # used by the scripts that source this file
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Run this script with sudo: sudo $0"
}

# The real (non-root) user who called sudo
target_user() { echo "${SUDO_USER:-$USER}"; }

# Docker Compose v2 plugin if available, otherwise the standalone binary
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  else
    docker-compose "$@"
  fi
}

# Read KEY from a .env file without executing it
env_get() {
  local key=$1 file=$2
  grep -E "^${key}=" "$file" | tail -n1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'
}

# Make sure a .env exists and contains no placeholder values
ensure_env() {
  local file=$1
  if [[ ! -f $file ]]; then
    cp "${file}.example" "$file"
    chmod 600 "$file"
    die "Created $file from the example. Edit it, replace every placeholder, then run this script again."
  fi
  chmod 600 "$file"
  if grep -qE 'change-me|100\.x\.y\.z' "$file"; then
    die "$file still contains placeholder values (change-me or 100.x.y.z). Edit it first."
  fi
}

# Closest existing parent of a path (used to check which disk it lands on)
existing_parent() {
  local p=$1
  while [[ ! -e $p ]]; do p=$(dirname "$p"); done
  echo "$p"
}
