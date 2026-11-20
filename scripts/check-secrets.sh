#!/usr/bin/env bash
# Scan the repository for things that must never be pushed to GitHub.
# Run before every commit: ./scripts/check-secrets.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
scan() {
  local desc=$1; shift
  local hits
  hits=$(grep -rnIE "$@" --exclude-dir=.git --exclude=check-secrets.sh . 2>/dev/null || true)
  if [[ -n $hits ]]; then
    printf '\033[1;31m[!] %s\033[0m\n%s\n\n' "$desc" "$hits"
    fail=1
  fi
}

envs=$(find . -name '.env' -not -path './.git/*')
if [[ -n $envs ]]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    tracked=$(git ls-files -- $envs)
    [[ -n $tracked ]] && { printf '\033[1;31m[!] .env files are tracked by git:\033[0m\n%s\n\n' "$tracked"; fail=1; }
  fi
fi

scan "Real Tailscale IP addresses" '100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}'
scan "API keys" 'sk-[A-Za-z0-9_-]{20,}'
scan "Private keys" 'BEGIN [A-Z ]*PRIVATE KEY'
scan "Email addresses" '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z.]{2,}'
pw=$(grep -rnIE '(PASSWORD|PASS|SECRET|SECRET_KEY)[[:space:]]*=[[:space:]]*["'"'"']?[A-Za-z0-9!@#%^&*._-]{6,}' \
  --exclude-dir=.git --exclude=check-secrets.sh . 2>/dev/null | grep -vE 'change-me|\$\{|\$\(|\$[A-Z_]+' || true)
if [[ -n $pw ]]; then
  printf '\033[1;31m[!] Hard-coded passwords\033[0m\n%s\n\n' "$pw"
  fail=1
fi

if [[ $fail == 0 ]]; then
  printf '\033[1;32mNo secrets found.\033[0m\n'
else
  printf 'Fix the findings above before committing.\n'
fi
exit $fail
