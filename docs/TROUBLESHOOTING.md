# Troubleshooting

Every problem below actually happened while building this server.

## Installation

### Installer says "Block probing did not discover any disks"
The BIOS SATA mode was `RAID On`, which hides the NVMe drive from Linux. Set **SATA Operation** to **AHCI** in the BIOS.

### `/` is only about 100 GB on a 512 GB disk
The installer leaves most of the LVM volume group unused. Run `sudo lvextend -l +100%FREE -r /dev/ubuntu-vg/ubuntu-lv`.

## Networking

### No network after install, and `nmtui` or `nmcli` not found
Ubuntu Server uses **netplan** with systemd-networkd, not NetworkManager. Plug in Ethernet first, then configure WiFi with `scripts/setup-wifi.sh`.

### Netplan reports a YAML error
Netplan is strict about indentation. The helper script writes the file for you. Check your WiFi interface name with `ip link | grep wl` (it was `wlp0s20f3` here, not the name that was first guessed).

### Server went offline for two weeks
The laptop was going to sleep. `01-base-setup.sh` now makes it ignore the lid and masks all sleep targets. Also disable **key expiry** for the server in Tailscale, otherwise it is logged out after 180 days.

### `tailscale status` on a client shows the server as offline
Someone needs physical access. Check power, the Ethernet cable or WiFi, and run `sudo tailscale status` on the server.

## Tailscale

### Tailscale apt repository returns 404
The official repository had no packages yet for the new release codename (`resolute`). Install the snap with `sudo snap install tailscale`.

## NVIDIA and CUDA

### `nvidia-driver-545` not found, `ubuntu-drivers autoinstall` not a command
Old driver versions are not packaged for new releases, and the `ubuntu-drivers` syntax changed. List what exists with `apt-cache search nvidia-driver` and install the newest one that is not marked *transitional*. `04-install-nvidia.sh` does this automatically.

### Blue "Configuring Secure Boot" screen during driver install
Expected with Secure Boot on. Set a password, then after reboot choose **Enroll MOK** on the server's own screen and enter it.

### CUDA repository `.deb` for an older Ubuntu fails, and SSH drops mid-install
Use `nvidia-cuda-toolkit` from the Ubuntu repositories instead. It is optional anyway, because Ollama ships its own CUDA runtime. Run long installs inside `tmux`.

## Docker and Nextcloud

### `apt install nextcloud-server` fails
That package does not exist. Nextcloud runs in Docker here.

### `permission denied while trying to connect to the docker API`
Your user was just added to the `docker` group. Log out and back in, or use `sudo` for now.

### Warning that the attribute `version` is obsolete
Compose v2 ignores it. Delete the `version:` line.

### "Access through untrusted domain"
Add the address you use to Nextcloud's trusted domains.
```bash
sudo docker exec -u www-data nextcloud php occ config:system:set trusted_domains 1 --value="<server-tailscale-ip>"
```

### `occ user:create` or `--admin-user` not found
The command is `user:add`, and the password is passed through the `OC_PASS` environment variable. Use `scripts/add-nextcloud-user.sh`.

### Password rejected
Nextcloud requires at least 10 characters and rejects passwords found in breach lists.

## External drive

### Drive shows in `lsusb` but not in `lsblk`, with repeated USB resets
`dmesg` showed `Maybe the USB cable is bad?` and repeated resets on one port, while another port worked fine. Use a port directly on the laptop, a different cable, or a powered hub for a spinning HDD. If `dmesg` shows `uas` errors instead, force the compatible USB mode for that drive.
```bash
echo "options usb-storage quirks=<vendor>:<product>:u" | sudo tee /etc/modprobe.d/usb-hdd.conf
sudo update-initramfs -u && sudo reboot
```
Get `<vendor>:<product>` from `lsusb`.

### Mounting the drive hid existing files
Mounting over a non-empty folder hides its contents. Mount the drive at a new, empty path (`/mnt/hdd`) and move data with `rsync -aHAX` while the containers are stopped.

## AI

### Open WebUI does not answer on port 3000 right after starting
On the first start it downloads an embedding model from Hugging Face before opening the port. Watch with `sudo docker logs -f open-webui 2>&1 | grep -v httpx` and wait.

### "nomic-embed-text does not support chat"
It is an embedding model used for document search. Hide it from the model list, or set it as the embedding model under **Admin Panel > Settings > Documents**.

### Some models are slow or think out loud for a long time
`qwen3` and `deepseek-r1` are reasoning models. Add `/no_think` to `qwen3` prompts, or use `llama3.2:3b` for quick chat. Run `ollama ps` while a model answers. If it shows a CPU/GPU split, the model is too big for 4 GB of VRAM. Turning off automatic title and tag generation in Open WebUI also reduces GPU load.
