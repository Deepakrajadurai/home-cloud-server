#!/usr/bin/env bash
# Phase 8: Open WebUI (branded chat + OpenAI-compatible API) on top of Ollama.
source "$(dirname "$0")/lib.sh"
require_root

DIR="$REPO_ROOT/compose/open-webui"
ENV="$DIR/.env"
ensure_env "$ENV"
PORT=$(env_get PORT "$ENV"); PORT=${PORT:-3000}

systemctl is-active --quiet ollama || die "Ollama is not running. Run 05-install-ollama.sh first."

info "Starting Open WebUI"
(cd "$DIR" && compose up -d)

info "Allowing port $PORT over Tailscale only"
ufw allow in on tailscale0 to any port "$PORT" proto tcp

info "Waiting for startup. The first start downloads an embedding model and can take 5+ minutes."
for _ in $(seq 1 120); do
  curl -fsS -o /dev/null "http://127.0.0.1:${PORT}" && break
  sleep 5
done
curl -fsS -o /dev/null "http://127.0.0.1:${PORT}" \
  || die "Open WebUI is not answering yet. Watch progress with: docker logs -f open-webui"

ok "Open WebUI is running at http://$(tailscale ip -4 2>/dev/null || echo SERVER_IP):${PORT}"
warn "Sign up right away. The first account becomes the admin."
