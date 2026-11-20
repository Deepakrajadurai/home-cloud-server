#!/usr/bin/env bash
# Phase 4: NVIDIA driver (+ optional CUDA toolkit).
# Picks the newest non-transitional driver package available, or the one
# set in NVIDIA_DRIVER (e.g. NVIDIA_DRIVER=nvidia-driver-595).
source "$(dirname "$0")/lib.sh"
require_root

lspci | grep -qi nvidia || die "No NVIDIA GPU detected"

DRIVER=${NVIDIA_DRIVER:-}
if [[ -z $DRIVER ]]; then
  DRIVER=$(apt-cache search --names-only '^nvidia-driver-[0-9]+$' \
    | grep -vi transitional | awk '{print $1}' | sort -V | tail -n1)
fi
[[ -n $DRIVER ]] || die "No NVIDIA driver package found. List them with: apt-cache search nvidia-driver"

info "Installing $DRIVER"
warn "If Secure Boot is on, you will be asked for a MOK password. Remember it, you need it after the reboot."
apt-get install -y "$DRIVER"

# Ollama ships its own CUDA runtime, so the toolkit is only needed
# if you want to compile CUDA code yourself. Skip with INSTALL_CUDA_TOOLKIT=0.
if [[ ${INSTALL_CUDA_TOOLKIT:-1} == 1 ]]; then
  info "Installing the CUDA toolkit from the Ubuntu repositories"
  apt-get install -y nvidia-cuda-toolkit
fi

ok "Done. Reboot now (sudo reboot), choose 'Enroll MOK' on the blue screen, then check with: nvidia-smi"
