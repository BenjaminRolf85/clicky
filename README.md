# ECHO — by Echomotion

> An AI companion that lives next to your cursor. It sees your screen, hears your voice, and delivers answers in real time.

ECHO is Echomotion's macOS-native AI assistant — always on, always watching, always ready. Built on top of [farzaa/clicky](https://github.com/farzaa/clicky) with Echomotion branding, SOUL.md personality, and handoff support for local AI tools.

---

## Features

- **Always-on cursor companion** — lives in your menu bar, drives to on-screen targets
- **Screen awareness** — captures all screens, sends them to the AI for context-aware answers
- **Voice input** — push-to-talk via a global hotkey
- **TTS playback** — responses spoken aloud via ElevenLabs
- **SOUL.md personality** — customise ECHO's persona by editing `SOUL.md` next to the app
- **Local tool handoffs** — say `nimm codex`, `nimm claude code`, or `nimm openclaw` to route tasks to local CLI tools

---

## Handoff Triggers

| Voice command | Routes to |
|---|---|
| `nimm codex …` | Local Codex CLI |
| `nimm claude code …` | Local Claude Code CLI |
| `nimm openclaw …` | Local OpenClaw CLI |
| English: `use codex/claude code/openclaw …` | Same |

Configure paths and timeouts in `.env` next to the app (see `.env.example`).

---

## Setup

### Requirements

- macOS 14.2+
- Xcode 16+
- Node.js 18+ (for the Cloudflare Worker)
- A [Cloudflare](https://cloudflare.com) account (free tier)
- API keys: [Anthropic](https://console.anthropic.com), [AssemblyAI](https://www.assemblyai.com), [ElevenLabs](https://elevenlabs.io)

### Worker (API proxy)

```bash
cd worker
npm install
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put ASSEMBLYAI_API_KEY
npx wrangler secret put ELEVENLABS_API_KEY
npx wrangler deploy
```

Copy the worker URL into Xcode → `WORKER_BASE_URL` build setting.

### Build

Open `leanring-buddy.xcodeproj` in Xcode, set your Team, build & run.

---

## Personality (SOUL.md)

Place a `SOUL.md` file next to `ECHO.app` to customise the AI's persona.
The file content is injected into the system prompt automatically.
Delete it to revert to the default ECHO persona.

---

## Credits

Built on [farzaa/clicky](https://github.com/farzaa/clicky) by Farza Majeed (MIT).
Handoff architecture inspired by [Arnie936/zippy-windows](https://github.com/Arnie936/zippy-windows).

Echomotion edition by [Echomotion GmbH](https://www.echomotion.ai) — AI Consulting, Munich.
