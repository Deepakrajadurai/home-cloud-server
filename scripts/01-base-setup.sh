#!/usr/bin/env bash
# Phase 1: updates, essential tools, firewall, SSH hardening and "never sleep".
source "$(dirname "$0")/lib.sh"
require_root

info "Updating the system"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

info "Installing essential tools"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl wget git htop tmux vim rsync ufw ca-certificates \
  openssh-server wpasupplicant pciutils

info "Configuring the firewall (deny incoming, allow SSH)"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw --force enable

info "Hardening SSH (no root login)"
cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PermitRootLogin no
EOF
systemctl restart ssh

info "Keeping the laptop awake with the lid closed"
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/10-server.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
systemctl restart systemd-logind
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

ok "Base setup complete. A reboot is recommended if a new kernel was installed."
