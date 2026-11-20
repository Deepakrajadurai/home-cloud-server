#!/usr/bin/env bash
# Phase 7: Nextcloud + PostgreSQL in Docker.
source "$(dirname "$0")/lib.sh"
require_root

DIR="$REPO_ROOT/compose/nextcloud"
ENV="$DIR/.env"
ensure_env "$ENV"

APP_DIR=$(env_get APP_DIR "$ENV")
CONFIG_DIR=$(env_get CONFIG_DIR "$ENV")
DB_DIR=$(env_get DB_DIR "$ENV")
DATA_DIR=$(env_get DATA_DIR "$ENV")
SERVER_ADDRESS=$(env_get SERVER_ADDRESS "$ENV")
PORT=$(env_get NEXTCLOUD_PORT "$ENV"); PORT=${PORT:-8080}

# Guard against writing user files to the SSD when the HDD is not mounted
if [[ $DATA_DIR == /mnt/* ]]; then
  MP=$(df --output=target "$(existing_parent "$DATA_DIR")" | tail -n1)
  [[ $MP != / ]] || die "$DATA_DIR would land on the system disk. Mount the external drive first (06-setup-storage.sh)."
fi

mkdir -p "$APP_DIR" "$CONFIG_DIR" "$DB_DIR" "$DATA_DIR"
chown 33:33 "$DATA_DIR"   # www-data inside the container

info "Starting Nextcloud"
(cd "$DIR" && compose up -d)

info "Waiting for the first-time installation (can take a few minutes)"
for _ in $(seq 1 60); do
  if docker exec -u www-data nextcloud php occ status --output=json 2>/dev/null | grep -q '"installed":true'; then
    break
  fi
  sleep 5
done
docker exec -u www-data nextcloud php occ status --output=json | grep -q '"installed":true' \
  || die "Nextcloud did not finish installing. Check: docker logs nextcloud"

docker exec -u www-data nextcloud php occ config:system:set trusted_domains 1 --value="$SERVER_ADDRESS"
docker exec -u www-data nextcloud php occ config:system:set overwrite.cli.url --value="http://${SERVER_ADDRESS}:${PORT}"

ok "Nextcloud is running at http://${SERVER_ADDRESS}:${PORT}"
