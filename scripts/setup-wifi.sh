#!/usr/bin/env bash
# Configure WiFi with netplan, writing valid YAML for you (no indentation mistakes).
source "$(dirname "$0")/lib.sh"
require_root

IFACE=""
for dev in /sys/class/net/wl*; do [[ -e $dev ]] && { IFACE=$(basename "$dev"); break; }; done
[[ -n $IFACE ]] || die "No WiFi interface found (ip link | grep wl)"
info "WiFi interface: $IFACE"

read -rp "WiFi name (SSID): " SSID
read -rsp "WiFi password: " PASS; echo
[[ -n $SSID && -n $PASS ]] || die "SSID and password are required"

# YAML single-quoted strings escape ' as ''
yaml_quote() { local s=${1//\'/\'\'}; printf "'%s'" "$s"; }

CONF=/etc/netplan/60-wifi.yaml
cat > "$CONF" <<EOF
network:
  version: 2
  wifis:
    ${IFACE}:
      dhcp4: true
      optional: true
      access-points:
        $(yaml_quote "$SSID"):
          password: $(yaml_quote "$PASS")
EOF
chmod 600 "$CONF"

netplan generate || die "netplan rejected the config, check $CONF"
netplan apply
sleep 10

ip -4 addr show "$IFACE" | grep -q inet && ok "WiFi connected:" || warn "No IP yet, check with: ip addr show $IFACE"
ip -4 addr show "$IFACE" | grep inet || true
