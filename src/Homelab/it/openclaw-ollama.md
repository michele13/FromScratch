Ho tutto il necessario. Ora scrivo la guida completa.

---

# Guida completa: OpenClaw su LXC Proxmox + Telegram + Ollama locale

## Scelta del modello locale per l'HP 240G8

Prima di iniziare, risolviamo la domanda più importante. Il tuo HP 240G8 ha un **i5-1035G1** (Ice Lake, 4 core/8 thread) e **16 GB di RAM**, senza GPU dedicata — tutto gira su CPU con iGPU Intel UHD, non supportata da Ollama per inferenza GPU.

**Cosa puoi girare realisticamente:**

Con 16 GB di RAM sei nel sweet spot: i modelli da 7B–9B offrono un ottimo rapporto qualità/velocità. La regola pratica: un modello da 7B con quantizzazione Q4 richiede circa 4–5 GB, uno da 8B circa 5–6 GB — lascia sempre 2–4 GB al sistema operativo.

Dovrai però considerare che siamo **CPU-only**: su un i5-1035G1 aspettati 3–8 token/sec su modelli 7–8B, che è lento ma funzionale per un assistente testuale.

**Raccomandazioni in ordine di preferenza:**

| Modello | Dimensione su disco | RAM necessaria | Note |
|---|---|---|---|
| **`qwen3:8b-q4_K_M`** | ~5 GB | ~6 GB | Migliore instruction-following, ottimo per tool use |
| **`llama3.1:8b-q4_K_M`** | ~4.7 GB | ~6 GB | Più popolare, ecosistema ampio |
| **`gemma3:9b-q4_K_M`** | ~6 GB | ~7 GB | Buon ragionamento |
| **`mistral:7b-q4_K_M`** | ~4.1 GB | ~5 GB | Più veloce, meno capace |

Qwen3 7B/8B ha il punteggio HumanEval più alto tra i modelli sotto gli 8B parametri ed è ottimo per l'uso con tool e agenti. **Partiamo con `qwen3:8b` come scelta principale.**

---

## Prerequisiti

- Proxmox VE installato e funzionante
- Template Debian 12 o Ubuntu 22.04 scaricato in Proxmox
- Un account Telegram
- Il tuo Telegram User ID numerico (lo trovi al passo 3)

---

## PARTE 1 — Creare il container LXC

### 1.1 Crea il container in Proxmox

Dalla UI di Proxmox → **Create CT**:

| Campo | Valore consigliato |
|---|---|
| CT ID | es. `110` |
| Hostname | `openclaw` |
| Template | `debian-12-standard` |
| Disk | 20 GB (i modelli Ollama occupano spazio) |
| CPU | 4 core |
| RAM | 8192 MB (lascia il resto al sistema host) |
| Swap | 2048 MB |
| Network | DHCP o IP fisso sulla tua LAN |
| Unprivileged | ✅ Sì |

> **Nota sicurezza:** usa un container unprivileged. Non serve `nesting: 1` per questo setup.

### 1.2 Avvia il container e fai l'update iniziale

```bash
# Dal nodo Proxmox, entra nella shell del CT
pct enter 110

# Update e upgrade
apt update && apt full-upgrade -y

# Pacchetti essenziali
apt install -y curl wget git ca-certificates gnupg2 unzip sudo ufw fail2ban zstd
```

### 1.3 Crea un utente dedicato (non usare root)

```bash
useradd -m -s /bin/bash openclaw
usermod -aG sudo openclaw

# Imposta una password sicura
passwd openclaw

# Lavora da qui in avanti come utente openclaw
su - openclaw
```

---

## PARTE 2 — Installare Ollama

### 2.1 Installa Ollama

```bash
# Scarica e verifica prima di eseguire
curl -fsSL https://ollama.com/install.sh -o /tmp/ollama_install.sh
# Controlla il contenuto se vuoi essere cauto:
# less /tmp/ollama_install.sh
bash /tmp/ollama_install.sh
```

### 2.2 Configura Ollama come servizio systemd (solo localhost)

Per sicurezza, Ollama deve ascoltare **solo su 127.0.0.1**, non su tutta la rete:

```bash
# Crea l'override systemd
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

Verifica che sia attivo:

```bash
systemctl status ollama
curl http://127.0.0.1:11434/api/tags
```

### 2.3 Scarica il modello

```bash
ollama pull qwen3:8b
# Alternativa più veloce da scaricare:
# ollama pull mistral:7b
```

Verifica:

```bash
ollama list
# Testa una risposta
ollama run qwen3:8b "Rispondi in italiano: di cosa ti occupi?"
```

Il primo avvio è lento (caricamento modello in RAM). Le risposte successive saranno più rapide finché il modello è in cache.

---

## PARTE 3 — Installare Node.js e OpenClaw

### 3.1 Installa Node.js 24 (versione raccomandata)

OpenClaw richiede Node 24 (raccomandato) oppure Node 22 LTS (22.14+) come versione di compatibilità.

```bash
# Aggiungi il repository NodeSource per Node 24
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# Verifica versione
node --version  # deve mostrare v24.x.x
npm --version
```

### 3.2 Installa OpenClaw

```bash
# Installa globalmente come utente openclaw
npm install -g openclaw@latest

# Verifica
openclaw --version
```

---

## PARTE 4 — Configurare il bot Telegram

### 4.1 Crea il bot con BotFather

Apri Telegram e scrivi a **@BotFather** (verifica che il nome sia esattamente quello). Esegui `/newbot`, segui i prompt e salva il token.

Hai già il nickname `@PixelMike_bot` — puoi usarlo qui se non è ancora stato associato a nessun progetto, oppure crearne uno nuovo.

### 4.2 Trova il tuo Telegram User ID numerico

Il metodo più sicuro (senza bot di terze parti): manda un DM al tuo bot, poi esegui `openclaw logs --follow` e leggi il campo `from.id`.

In alternativa, prima di avviare OpenClaw, puoi usare l'API direttamente:

```bash
curl "https://api.telegram.org/bot<IL_TUO_TOKEN>/getUpdates"
# Manda un messaggio al bot da Telegram, poi rilancia il curl
# Cerca "from": {"id": XXXXXXXX} nel JSON
```

Segna questo numero: lo chiameremo `YOUR_TG_USER_ID`.

---

## PARTE 5 — Configurare OpenClaw

### 5.1 Esegui l'onboarding guidato

```bash
openclaw onboard --install-daemon
```

Il wizard ti chiederà:
- Provider LLM → scegli **Ollama / OpenAI-compatible**
- URL endpoint → `http://127.0.0.1:11434`
- Model name → `qwen3:8b`
- Channel → scegli **Telegram**
- Bot token → incolla il token di BotFather

### 5.2 Configura manualmente `~/.openclaw/openclaw.json`

Dopo l'onboarding, sostituisci (o crea) il file di configurazione con questo template sicuro:

```json
{
  "providers": {
    "ollama": {
      "type": "openai-compatible",
      "baseUrl": "http://127.0.0.1:11434/v1",
      "defaultModel": "qwen3:8b"
    }
  },
  "agents": {
    "defaults": {
      "provider": "ollama",
      "model": "qwen3:8b"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "IL_TUO_TOKEN_QUI",
      "dmPolicy": "allowlist",
      "allowFrom": ["YOUR_TG_USER_ID"],
      "groups": {},
      "streaming": "partial",
      "linkPreview": false
    }
  },
  "tools": {
    "exec": {
      "enabled": true
    },
    "web_search": {
      "enabled": false
    },
    "web_fetch": {
      "enabled": false
    }
  }
}
```

> **Perché `dmPolicy: "allowlist"` con il tuo ID numerico?** Per bot a utente singolo, preferisci `dmPolicy: "allowlist"` con ID numerici espliciti in `allowFrom` — questo rende la policy di accesso durevole nella config invece di dipendere da approval precedenti.

---

## PARTE 6 — Configurare le Exec Approvals (il gate di sicurezza)

Questo è il punto cruciale: **ogni comando che il bot vuole eseguire deve prima chiedere il tuo consenso**.

### 6.1 Crea il file `~/.openclaw/exec-approvals.json`

```json
{
  "version": 1,
  "defaults": {
    "security": "deny",
    "ask": "always",
    "askFallback": "deny",
    "autoAllowSkills": false
  },
  "agents": {
    "main": {
      "security": "deny",
      "ask": "always",
      "askFallback": "deny",
      "autoAllowSkills": false
    }
  }
}
```

Con `exec` abilitato senza salvaguardie si consegna di fatto l'accesso root. Abilitare l'approval significa che ogni comando viene mostrato prima di eseguirlo, e gira solo dopo la tua conferma.

Il significato delle impostazioni chiave:
- `"security": "deny"` → nulla gira senza approvazione esplicita
- `"ask": "always"` → chiede sempre, anche per comandi già visti
- `"askFallback": "deny"` → se non riesci a rispondere (sei offline), il comando viene negato automaticamente

### 6.2 Come funziona l'approvazione da Telegram

La funzione `requireApproval` mette in pausa l'esecuzione del tool e mostra la richiesta via pulsanti Telegram, interazioni Discord, o con il comando `/approve` su qualsiasi canale.

Quando il bot vuole eseguire qualcosa, ti arriverà un messaggio Telegram tipo:

```
🔐 Exec Approval Required

Command: ls -la /home/openclaw
CWD: /home/openclaw
Agent: main

[✅ Approve] [❌ Deny]
```

Premi **Approve** per eseguire, **Deny** per bloccare. Se non rispondi entro il timeout, viene negato automaticamente.

---

## PARTE 7 — Hardening della sicurezza

### 7.1 Firewall con UFW nel container

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Permetti SSH solo dalla tua LAN (adatta la subnet)
sudo ufw allow from 192.168.1.0/24 to any port 22
# Blocca tutto il resto
sudo ufw enable
```

### 7.2 Fail2ban per SSH

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 7.3 Proteggere il token Telegram con una variabile d'ambiente

Invece di mettere il token in chiaro nel JSON, usa una env var:

```bash
# Aggiungi al file ~/.profile dell'utente openclaw
echo 'export TELEGRAM_BOT_TOKEN="IL_TUO_TOKEN"' >> ~/.profile
```

Poi nel `openclaw.json` rimuovi `botToken` — OpenClaw accetta il fallback `TELEGRAM_BOT_TOKEN=...` come variabile d'ambiente per l'account di default.

### 7.4 Permessi file

```bash
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/exec-approvals.json
```

### 7.5 Limita le risorse del container (in Proxmox)

Dalle impostazioni del CT in Proxmox, imposta:
- **CPU limit**: 400% (4 core al massimo)
- **Memory balloon**: disabilitato, RAM fissa a 8192 MB

Questo evita che Ollama monopolizzi le risorse dell'host quando gira un'inferenza pesante.

---

## PARTE 8 — Avviare tutto come servizio

### 8.1 Verifica che Ollama sia attivo

```bash
systemctl status ollama
```

### 8.2 Avvia il gateway OpenClaw come demone

```bash
# Il flag --install-daemon dell'onboarding dovrebbe aver già creato il servizio.
# Se non lo ha fatto, fallo manualmente:

sudo tee /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=openclaw
WorkingDirectory=/home/openclaw
EnvironmentFile=/home/openclaw/.openclaw/env
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Crea il file env per il token
mkdir -p /home/openclaw/.openclaw
echo "TELEGRAM_BOT_TOKEN=IL_TUO_TOKEN" > /home/openclaw/.openclaw/env
chmod 600 /home/openclaw/.openclaw/env

sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
```

### 8.3 Verifica che funzioni

```bash
journalctl -u openclaw -f
# Oppure:
openclaw logs --follow
```

---

## PARTE 9 — Primo pairing con Telegram

OpenClaw usa di default il pairing per Telegram. Avvia il gateway, poi dalla tua lista di approvazioni esegui:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODICE>
```

Il codice appare anche nei log e scade dopo 1 ora.

Manda un messaggio al tuo bot da Telegram — dovresti ricevere una risposta da `qwen3:8b`. Se gli chiedi di eseguire un comando, ti arriverà prima la richiesta di approvazione.

---

## Riepilogo architettura

```
[Telegram App] ←→ [Telegram Bot API] ←→ [OpenClaw Gateway]
                                              ↓ (tool use)
                                    [exec-approvals: DENY/ASK]
                                              ↓ (se approvato)
                                      [Shell sul container]
                                              
                                    [OpenClaw] → [Ollama API]
                                                  ↓
                                           [qwen3:8b su CPU]
```

---

## Note finali sulle performance

Con il tuo i5-1035G1 su CPU pura aspettati **4–7 token/sec** su `qwen3:8b` — abbastanza per un assistente testuale, ma non per conversazioni veloci. Se le risposte sono troppo lente, prova `mistral:7b` che è leggermente più piccolo e più veloce. Considera che Ollama tiene il modello caricato in RAM tra una richiesta e l'altra, quindi la latenza è principalmente il tempo di generazione, non il caricamento.