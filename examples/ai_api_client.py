"""Call your self-hosted AI from any computer on your Tailscale network.

Setup:
    pip install openai
    export AI_SERVER_URL="http://<server-tailscale-ip>:3000/api"
    export AI_API_KEY="sk-..."          # Open WebUI > Settings > Account > API Keys

Run:
    python ai_api_client.py "Explain Docker volumes in two sentences"
"""

import os
import sys

from openai import OpenAI

client = OpenAI(
    base_url=os.environ["AI_SERVER_URL"],
    api_key=os.environ["AI_API_KEY"],
)


def list_models() -> list[str]:
    return [m.id for m in client.models.list().data]


def ask(prompt: str, model: str = "llama3.2:3b") -> None:
    """Stream the answer token by token, like a chat interface."""
    stream = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        stream=True,
    )
    for chunk in stream:
        if chunk.choices and chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print()


if __name__ == "__main__":
    print("Available models:", ", ".join(list_models()))
    ask(" ".join(sys.argv[1:]) or "Say hello from my home server!")
