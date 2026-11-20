#!/usr/bin/env bash
# Create a Nextcloud account with a storage quota.
# Usage: sudo ./add-nextcloud-user.sh <username> ["Display Name"] ["20 GB"]
source "$(dirname "$0")/lib.sh"
require_root

[[ $# -ge 1 ]] || die "Usage: sudo $0 <username> [\"Display Name\"] [\"20 GB\"]"
USERNAME=$1
DISPLAY_NAME=${2:-$1}
QUOTA=${3:-20 GB}

read -rsp "Password for $USERNAME (10+ characters): " PASS; echo
read -rsp "Repeat the password: " PASS2; echo
[[ $PASS == "$PASS2" ]] || die "Passwords do not match"

docker exec -u www-data -e OC_PASS="$PASS" nextcloud \
  php occ user:add --password-from-env --display-name "$DISPLAY_NAME" "$USERNAME"
docker exec -u www-data nextcloud php occ user:setting "$USERNAME" files quota "$QUOTA"

ok "Created '$USERNAME' with a $QUOTA quota. Ask them to change the password after the first login."
