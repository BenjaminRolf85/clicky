# AGENTS.md — ECHO by Echomotion

## Was ist ECHO?

**ECHO** ist ein macOS-nativer KI-Companion von Echomotion GmbH. Die App schwebt als rundes Echomotion-Logo neben dem Mauszeiger und reagiert auf Sprachbefehle via Push-to-Talk.

ECHO sieht den Screen des Nutzers, hört seine Stimme und antwortet mit einer KI-generierten Sprachantwort — in Echtzeit, always-on, ohne separate App-Fenster.

---

## Technischer Stack

| Komponente | Technologie | Zweck |
|---|---|---|
| **App** | Swift / SwiftUI / macOS 14.2+ | Native Menu-Bar-App |
| **Spracheingabe** | AssemblyAI Streaming | Voice-to-Text (WebSocket) |
| **KI** | Anthropic Claude (claude-sonnet-4-6) | Antwortgenerierung mit Screen-Kontext |
| **Sprachausgabe** | ElevenLabs TTS | Text-to-Speech |
| **Proxy** | Cloudflare Worker (`echo-proxy`) | API-Keys serverseitig, nie im App-Bundle |
| **Screen Capture** | ScreenCaptureKit (macOS) | Screenshots aller Monitore |
| **Hotkeys** | CGEvent Tap | Globale Tastenkombinationen |

---

## Hotkeys

| Kombination | Modus |
|---|---|
| **Ctrl + Option** (halten) | Screen-aware: Screenshot wird mitgeschickt |
| **Shift + Option** (halten) | Voice-only: kein Screenshot, schneller, privater |

---

## Handoff-Trigger (Sprachbefehle)

Wenn der Transkript mit einem dieser Trigger beginnt, wird die Aufgabe **nicht** an Claude geschickt, sondern an das jeweilige lokale CLI-Tool:

| Trigger | Tool |
|---|---|
| `nimm openclaw [aufgabe]` | OpenClaw CLI → HAILY (Echomotion KI-Agent) |
| `nimm codex [aufgabe]` | Codex CLI |
| `nimm claude code [aufgabe]` | Claude Code CLI |
| `use openclaw/codex/claude code ...` | (englische Varianten) |

---

## Cloudflare Worker

**URL:** `https://echo-proxy.benjamin-3ed.workers.dev`

**Routen:**
- `POST /chat` → Anthropic Claude API
- `POST /tts` → ElevenLabs TTS
- `POST /transcribe-token` → AssemblyAI temporärer Token

**Secrets (auf Cloudflare gesetzt):**
- `ANTHROPIC_API_KEY`
- `ELEVENLABS_API_KEY`
- `ELEVENLABS_VOICE_ID`
- `ASSEMBLYAI_API_KEY`

---

## OpenClaw Verbindung (lokaler Handoff)

### Was ist OpenClaw?
OpenClaw ist der KI-Agent-Server von Echomotion, der auf dem VPS läuft. **HAILY** ist der primäre Agent und handhabt Sales, Emails, CRM und alle Aufgaben für Echomotion.

### Verbindungsdaten
```
Gateway:  ws://76.13.140.46:41513
Token:    CmFT7vobJQlmxkzEZPLXX9uz69VoAJ3j
Session:  main
```

### Setup auf dem Mac (einmalig)

**1. OpenClaw CLI installieren** (falls nicht vorhanden):
```bash
npm install -g openclaw
```

**2. .env neben ECHO.app erstellen:**
```bash
ECHO_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "ECHO.app" -type d 2>/dev/null | head -1)
ECHO_DIR=$(dirname "$ECHO_APP")

cat > "$ECHO_DIR/.env" << 'EOF'
OPENCLAW_COMMAND=openclaw
OPENCLAW_GATEWAY_URL=ws://76.13.140.46:41513
OPENCLAW_GATEWAY_TOKEN=CmFT7vobJQlmxkzEZPLXX9uz69VoAJ3j
OPENCLAW_SESSION_KEY=main
OPENCLAW_TIMEOUT_SECONDS=120
EOF

echo "✅ .env erstellt in: $ECHO_DIR"
```

**3. Verbindung testen:**
```bash
openclaw chat --session main \
  --gateway-url ws://76.13.140.46:41513 \
  --gateway-token CmFT7vobJQlmxkzEZPLXX9uz69VoAJ3j \
  --message "Hallo HAILY, Verbindungstest von ECHO" \
  --no-input
```

### Was passiert beim Handoff?

Wenn Ben sagt `nimm openclaw [aufgabe]`, schickt ECHO folgendes an HAILY:

```
[ECHO Handoff]
Quelle: ECHO by Echomotion — KI-Companion App auf Bens Mac
Nutzer: Benjamin Lange (CEO, Echomotion GmbH)
Modus: Sprachbefehl via Push-to-Talk
App: ECHO v1.0 — macOS Voice Assistant mit Screen-Awareness
Zweck: Ben hat per Sprache eine Aufgabe an HAILY delegiert.
HAILY soll die Aufgabe direkt ausführen und das Ergebnis zurückgeben.

Aufgabe von Ben: [was Ben gesagt hat]
```

HAILY führt die Aufgabe aus (Email schreiben, CRM updaten, Recherche, etc.) und gibt das Ergebnis zurück. ECHO liest es vor.

---

## SOUL.md Persönlichkeit

Eine `SOUL.md` Datei neben `ECHO.app` definiert die Persönlichkeit des Assistenten. Sie wird in den Claude System-Prompt injiziert. Ohne SOUL.md läuft ECHO mit der Standard-Echomotion-Persönlichkeit.

Aktuelle SOUL.md:
- Name: ECHO
- Sprache: Deutsch (default) / Englisch (technische Begriffe)
- Stil: Direkt, schnell, lösungsorientiert
- Keine Lobhudelei, keine langen Einleitungen

---

## Repo-Struktur

```
ECHO/
├── leanring-buddy/          # Xcode App Target
│   ├── CompanionManager.swift        # Zentrale State-Verwaltung
│   ├── HandoffClient.swift           # CLI-Handoffs (OpenClaw, Codex, Claude Code)
│   ├── EchoLogoCursor.swift          # Floating Logo-Cursor
│   ├── SOULConfiguration.swift       # SOUL.md Persönlichkeit
│   ├── ElevenLabsTTSClient.swift     # TTS via Worker
│   ├── AssemblyAIStreamingProvider.swift  # Voice-to-Text
│   └── ...
├── worker/
│   └── src/index.ts         # Cloudflare Worker (API-Proxy)
├── SOUL.md                  # Persönlichkeitsdatei
├── .env.example             # Handoff-Konfiguration Template
└── AGENTS.md                # Diese Datei
```

---

## Bekannte Einschränkungen

- App läuft nur auf macOS 14.2+ (ScreenCaptureKit requirement)
- Xcode 16+ für den Build
- OpenClaw Handoff-Ergebnis wird als Text vorgelesen (max. 300 Zeichen TTS)
- ElevenLabs Voice ID: `kPzsL2i3teMYv0FxEYQ6` (änderbar in Cloudflare Secrets)
- Keine persistente Sitzung zwischen App-Neustarts

---

## Entwicklung & Contribution

Alle Commits gehen über `echobot26` (HAILY's GitHub-Account) mit Write-Access auf `BenjaminRolf85/clicky`.

Für Code-Änderungen: Push direkt auf `main` oder via PR aus Fork `echobot26/clicky`.

*Echomotion GmbH | www.echomotion.ai | ECHO v1.0*
