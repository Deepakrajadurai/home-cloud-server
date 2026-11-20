# Setup Guide

The full build, from a bare laptop to running services. Run commands on the server unless stated otherwise.

## 0. Before you start

You need the server laptop, a USB stick of at least 8 GB with the Ubuntu Server ISO (written with Rufus or balenaEtcher), an Ethernet cable for the first boot, and a free Tailscale account.

## 1. BIOS settings (Dell G3, press F2 at boot)

- **Boot Sequence.** Put the USB stick first.
- **SATA Operation.** Change from `RAID On` to **`AHCI`**. Without this the installer reports *"Block probing did not discover any disks"*.
- **Secure Boot** can stay on. You will enroll a key when the NVIDIA driver is installed.

## 2. Install Ubuntu Server

- Network screen. Plug in Ethernet, or choose *Continue without network* and set it up later.
- Storage. Use the entire disk with LVM. The installer only gives `/` about 100 GB, which step 3 fixes.
- Profile. Choose a username and a server name such as `home-server`.
- **Enable OpenSSH server.**

## 3. Use the whole SSD

```bash
sudo lvextend -l +100%FREE -r /dev/ubuntu-vg/ubuntu-lv
df -h /
```

## 4. Network

Ethernet works out of the box. For WiFi, run the helper, which writes valid netplan YAML for you.

```bash
git clone https://github.com/<your-username>/home-cloud-server.git
cd home-cloud-server
sudo ./scripts/setup-wifi.sh
```

## 5. Base system and Tailscale

```bash
sudo ./scripts/01-base-setup.sh
sudo ./scripts/02-install-tailscale.sh
```

Open the printed login link on another device. Then, in the [Tailscale admin console](https://login.tailscale.com/admin/machines), open the `...` menu of the server and choose **Disable key expiry**.

From now on you can work over SSH from your laptop (with Tailscale on).

```bash
ssh <user>@<server-tailscale-ip>
```

Use `tmux` for long installs so a dropped connection does not stop them.

## 6. Docker

```bash
sudo ./scripts/03-install-docker.sh
exit   # log out and back in for the docker group to apply
```

## 7. NVIDIA driver

```bash
sudo ./scripts/04-install-nvidia.sh
sudo reboot
```

With Secure Boot on, a blue **MOK management** screen appears on the server's own display after the reboot. Choose **Enroll MOK**, continue, enter the password you set during installation, and reboot. Then check with `nvidia-smi`.

## 8. Ollama and models

```bash
sudo ./scripts/05-install-ollama.sh
ollama run llama3.2:3b "hello"
ollama ps   # PROCESSOR should show 100% GPU
```

Edit `config/ollama-models.txt` to change which models are downloaded.

## 9. External drive

Plug the drive into a port directly on the laptop, then run the script. It refuses to touch the system disk and asks for confirmation before formatting.

```bash
sudo ./scripts/06-setup-storage.sh
```

## 10. Nextcloud

```bash
cp compose/nextcloud/.env.example compose/nextcloud/.env
nano compose/nextcloud/.env      # set the Tailscale IP and strong passwords
sudo ./scripts/07-deploy-nextcloud.sh
```

## 11. Open WebUI

```bash
cp compose/open-webui/.env.example compose/open-webui/.env
nano compose/open-webui/.env     # set WEBUI_NAME and WEBUI_SECRET_KEY (openssl rand -hex 32)
sudo ./scripts/08-deploy-open-webui.sh
```

Open `http://<server-tailscale-ip>:3000` and **sign up immediately**, because the first account becomes the admin. Recommended settings in the Admin Panel follow.

- **Settings > General.** Enable API Keys.
- **Settings > Interface.** Turn off automatic title, tag and follow-up generation to save GPU time.
- **Settings > Models.** Hide `nomic-embed-text`, which is an embedding model and cannot chat.

Some Open WebUI settings are read from the environment only on the very first start. After that, change them in the Admin Panel.

## 12. Tailscale access policy

In the admin console, open **Access controls > Policies**. Edit the default rule so its source is `autogroup:member`, and add a rule from `autogroup:shared` to the server's IP on ports `tcp:8080` and `tcp:3000`. The JSON version is in [`config/tailscale/policy.hujson.example`](../config/tailscale/policy.hujson.example).

## 13. Verify

```bash
sudo ./scripts/health-check.sh
```
