#!/usr/bin/env bash
# Quick status overview of every component. Run with sudo.
source "$(dirname "$0")/lib.sh"

section() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

section "Tailscale"
tailscale status 2>/dev/null | head -n 5 || warn "Tailscale not running"

section "Containers"
docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || warn "Docker not reachable (try sudo)"

section "Services"
for url in "Nextcloud|http://127.0.0.1:8080/status.php" "Open WebUI|http://127.0.0.1:3000" "Ollama|http://127.0.0.1:11434"; do
  name=${url%%|*}; addr=${url#*|}
  if curl -fsS -o /dev/null --max-time 5 "$addr"; then ok "$name"; else warn "$name not answering"; fi
done

section "GPU"
nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null \
  || warn "nvidia-smi not available"
ollama ps 2>/dev/null || true

section "Disks"
df -h / /mnt/hdd 2>/dev/null || df -h /
mountpoint -q /mnt/hdd || warn "/mnt/hdd is not mounted"

section "Memory"
free -h
