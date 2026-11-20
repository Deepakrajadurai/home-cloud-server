#!/usr/bin/env bash
# Phase 5: Ollama plus the models listed in config/ollama-models.txt.
# Ollama listens on 127.0.0.1 only. It has no authentication, so
# Open WebUI is the only way in from the network.
source "$(dirname "$0")/lib.sh"
require_root

if ! command -v ollama >/dev/null 2>&1; then
  info "Installing Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi
systemctl enable --now ollama

MODELS_FILE="$REPO_ROOT/config/ollama-models.txt"
grep -vE '^[[:space:]]*(#|$)' "$MODELS_FILE" | while read -r model; do
  info "Pulling $model"
  ollama pull "$model" || warn "Could not pull $model, check the name on https://ollama.com/library"
done

ollama list
ok "Ollama ready. Test with: ollama run llama3.2:3b 'hello' && ollama ps  (PROCESSOR should say 100% GPU)"
