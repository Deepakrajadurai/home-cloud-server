#!/usr/bin/env bash
# Phase 2: Tailscale VPN.
# The snap is used because Tailscale's apt repo had no packages for
# Ubuntu 26.04 ("resolute") at the time of setup.
source "$(dirname "$0")/lib.sh"
require_root

if ! command -v tailscale >/dev/null 2>&1; then
  info "Installing Tailscale"
  snap install tailscale
fi

info "Bringing Tailscale up. Open the printed link on another device to log in."
tailscale up

ok "Tailscale IP: $(tailscale ip -4)"
warn "In the Tailscale admin console, disable key expiry for this machine so it never gets logged out."
