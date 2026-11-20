#!/usr/bin/env bash
# Phase 3: Docker and Docker Compose from the Ubuntu repositories.
source "$(dirname "$0")/lib.sh"
require_root

info "Installing Docker"
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-v2 \
  || DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose

systemctl enable --now docker

USER_NAME=$(target_user)
usermod -aG docker "$USER_NAME"

ok "Docker installed: $(docker --version)"
warn "Log out and back in so '$USER_NAME' can run docker without sudo."
