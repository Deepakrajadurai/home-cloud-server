#!/usr/bin/env bash
# Phase 6: prepare and permanently mount the external drive.
# Safety: refuses to touch any disk that has a mounted filesystem
# (so the system SSD can never be formatted by mistake) and asks you
# to type the partition name before formatting.
source "$(dirname "$0")/lib.sh"
require_root

MOUNT_POINT=${MOUNT_POINT:-/mnt/hdd}

lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
echo
read -rp "Partition to use for $MOUNT_POINT (e.g. /dev/sda1): " PART
[[ -b $PART ]] || die "$PART is not a block device"

if [[ $(findmnt -no TARGET "$PART" || true) == "$MOUNT_POINT" ]]; then
  ok "$PART is already mounted at $MOUNT_POINT, nothing to do"
  exit 0
fi

PARENT=$(lsblk -no PKNAME "$PART" | head -n1)
[[ -n $PARENT ]] || die "Could not find the disk that $PART belongs to"
DISK="/dev/$PARENT"
if lsblk -nro MOUNTPOINTS "$DISK" | grep -q .; then
  die "$DISK has mounted filesystems (system disk, or still mounted elsewhere). Refusing. Unmount it first if it is really the external drive."
fi

FSTYPE=$(lsblk -no FSTYPE "$PART" | head -n1)
if [[ $FSTYPE != ext4 ]]; then
  warn "$PART is '${FSTYPE:-unformatted}'. It must be formatted as ext4."
  warn "FORMATTING ERASES EVERYTHING ON $PART."
  read -rp "Type $PART again to confirm formatting: " CONFIRM
  [[ $CONFIRM == "$PART" ]] || die "Confirmation did not match, nothing changed"
  mkfs.ext4 -F -L hdd-storage "$PART"
else
  info "$PART is already ext4, keeping its contents"
fi

mkdir -p "$MOUNT_POINT"
UUID=$(blkid -s UUID -o value "$PART")
if ! grep -q "UUID=$UUID" /etc/fstab; then
  cp /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
  # nofail: the server still boots if the drive is unplugged
  echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail,x-systemd.device-timeout=10 0 2" >> /etc/fstab
fi
systemctl daemon-reload
mount -a

mountpoint -q "$MOUNT_POINT" || die "Mount failed, check: sudo dmesg | tail -30"
df -h "$MOUNT_POINT"
ok "External drive mounted at $MOUNT_POINT and will mount on every boot"
