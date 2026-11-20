# User Guide

## Connecting your own devices

1. Install **Tailscale** and log in with the same account as the server.
2. Nextcloud is at `http://<server-tailscale-ip>:8080` and the AI at `http://<server-tailscale-ip>:3000`.

Chats and files live on the server, so they look the same on every device. On a phone, the browser's **Add to Home screen** option makes the AI feel like an app.

**Apps.** Use the Nextcloud mobile app or the Nextcloud desktop client (for automatic folder sync like Google Drive) with `http://<server-tailscale-ip>:8080` as the server address. The app warns that the connection is not HTTPS. That is fine here, because Tailscale already encrypts the traffic.

## Onboarding a friend

Distance does not matter. Friends abroad connect exactly like local devices.

**On the server owner's side**

1. In the Tailscale admin console, open the `...` menu of the server, choose **Share**, and send the invite link.
2. Make sure the access policy limits shared users to ports 8080 and 3000 (see the Setup Guide).
3. Create their Nextcloud account with a quota.
   ```bash
   sudo ./scripts/add-nextcloud-user.sh alex "Alex" "20 GB"
   ```
4. Create their AI account in **Admin Panel > Users** with the role **User**, or approve their own sign-up from the pending list.

**On the friend's side**

1. Install Tailscale, sign up with their **own** account, and accept the invite.
2. Keep Tailscale switched on, then open the two addresses above or use the Nextcloud app.
3. Change the passwords after the first login.

## Privacy

Users cannot see each other's files or chats. As the server owner you technically have access to everything stored on the disks, which is true of any cloud service. In Open WebUI, `ENABLE_ADMIN_CHAT_ACCESS=false` stops the admin from reading other users' chats in the interface.

## Using the AI from code

1. **Admin Panel > Settings > General.** Enable API Keys (admin, once).
2. **Settings > Account > API Keys.** Create a key (each user).

The API is OpenAI-compatible. With curl:

```bash
curl http://<server-tailscale-ip>:3000/api/chat/completions \
  -H "Authorization: Bearer $AI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "messages": [{"role": "user", "content": "Hello"}]}'
```

List the available models with `GET /api/models`. A complete Python example is in [`examples/ai_api_client.py`](../examples/ai_api_client.py).

## Branded models

Under **Workspace > Models > New Model**, pick a base model, give it your own name and a system prompt (for example a coding helper built on `qwen2.5-coder:3b`). Users then choose your branded model instead of the raw model name.

## Which model to use

| Task | Model |
|---|---|
| Quick everyday chat | `llama3.2:3b` |
| Better quality, other languages | `gemma3:4b` or `qwen3:4b` |
| Code | `qwen2.5-coder:3b` |
| Maths and logic | `deepseek-r1:1.5b` or `qwen3:4b` |
| Questions about an uploaded image | `gemma3:4b` |
