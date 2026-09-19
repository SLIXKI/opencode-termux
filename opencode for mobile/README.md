# opencode-mobile

Run the **opencode** AI coding agent on your Android phone. Free models. One line
to install.

> **Brought to you by @FeaturisticLeaks X @slixki**

> ⚡ **New here? Read `INSTALL.txt` first — it's the whole guide on one page.**
> 🛠 **Getting an error? See `docs/TROUBLESHOOTING.md` in the repository.**

---

## Install — one line

Open **Termux**, paste this single line, press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
```

That is the entire install — prerequisites, the latest opencode, free models, the
memory system, the `AI` shortcut and the ⌨ keyboard button. It takes a few
minutes. Re-running the same line **updates** everything; it is safe to repeat.

Then close Termux completely, reopen it, and type:

```bash
AI
```

## Uninstall — one line

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/uninstall.sh | bash
```

It asks before deleting anything, and **keeps your projects** unless you say
otherwise.

---

## Fixing "OpenCode 1.18.0 or newer is required"

```
Error from provider (Console): OpenCode 1.18.0 or newer is required to use the free tier
```

Your opencode is older than the free tier now allows. Run the one-line installer
again — it installs the latest stable version, then **checks the version string
the binary actually reports** and rejects builds the free tier would refuse.

That last part matters. The gateway reads the version from the client's
`User-Agent` and requires a plain release number, so builds like
`1.18.31-dev.f1aacaba` or `1.18.4-8` are rejected *even though the code is new
enough*. This installer refuses to install those. Full details, including the
September 2026 upstream compaction incident, are in `docs/TROUBLESHOOTING.md`.

---

## What you need

- An Android phone — **64-bit ARM (ARM64 / aarch64)**. Most phones made since ~2018.
- **Termux from F-Droid** — <https://f-droid.org/packages/com.termux/>.
  The Google Play version is outdated and will not work.
- About 250 MB of free storage, and an internet connection.

> ⚠️ **Which devices work:** opencode for Termux is **aarch64-only**. It does
> **not** run on x86_64 Android emulators (MuMu, GameLoop, BlueStacks) or on
> 32-bit devices. The installer detects this before downloading anything and
> stops with a clear message.

No computer, no coding experience, no paid subscriptions.

---

## Free models

Nine free OpenCode Zen models are pre-configured — **no key and no card
required**. Default is `opencode/deepseek-v4-flash-free`. When one is
rate-limited, press `/models` and switch:

`deepseek-v4-flash-free` · `big-pickle` · `mimo-v2.5-free` ·
`nemotron-3-ultra-free` (1M context) · `nemotron-3.5-lightning-free` ·
`north-mini-code-free` · `ling-3.0-flash-free` · `laguna-s-2.1-free` · `hy3-free`

Adding a free key from <https://opencode.ai/auth> raises your rate limits.
Google Gemini and OpenRouter free tiers work too as backups — export
`GEMINI_API_KEY` or `OPENROUTER_API_KEY` and their catalogues appear automatically.

The free roster **rotates without notice**; this list is a snapshot from
2026-09-19. Live list: `https://opencode.ai/zen/v1/models`.

---

## The five things worth knowing

| | |
|---|---|
| **`AI`** | opens opencode in the current folder. **`AI myapp`** creates and opens that project. |
| **Esc** | stops a running answer. Not `q`, not Ctrl+C (that exits). |
| **`/compact`** | summarises the chat. Do it early — long sessions on a phone are where errors appear. |
| **`git init`** | run once in a new project. Without it `/undo` and `/redo` do nothing. |
| **`Memory.md`** | kept up to date in every project under `~/opencode/`, so you can resume days later. |

---

## Common problems

| Problem | Fix |
|---|---|
| `1.18.0 or newer is required` | Re-run the one-line installer, then fully restart Termux. |
| `free tier can only be used from within OpenCode` | Switch model with `/models`; on long chats `/new` for a fresh session. May be an upstream incident — see troubleshooting. |
| Rate limit / quota exceeded | `/models` → pick another free model. Nothing is lost. |
| Commands got jumbled (`-ypkg`, `unzipunzip`) | Type **one command per line**, pressing Enter after each. |
| `command not found: AI` | Close Termux completely and reopen, or `source ~/.bashrc`. |
| No ⌨ keyboard button | Long-press the screen → **More** → **Extra keys**, then restart Termux. |
| Keyboard hides inside opencode | Tap **⌨** in the key row, or `termux-ime toggle` after `pkg install termux-api`. |
| opencode is slow | Free models can pause on the first reply. `/models` → a lighter one. Phones also throttle when hot. |
| Download keeps failing | Just re-run — the installer resumes partial downloads. |

Full list, plus what to include when asking for help: `docs/TROUBLESHOOTING.md`.
The installer writes a log to `~/opencode-mobile-install.log`.

---

## Offline install (no internet for the one-liner)

If you were sent the zip instead:

1. Install Termux from F-Droid.
2. Put the zip in your phone's **Downloads**.
3. In Termux, one command per line:
   ```bash
   termux-setup-storage
   cd ~/storage/downloads
   unzip -o opencode-mobile-v2.0.0.zip
   cd opencode-mobile
   bash install.sh
   ```

The zip creates a folder named `opencode-mobile` with everything inside it.

---

## What's in this folder

- `INSTALL.txt` — the one-page guide
- `GUIDE.md` — the full beginner's guide to opencode
- `install.sh` / `uninstall.sh` — generated from the repository root; identical
  to what the one-liner runs
- `config/` — free-model config, agent rules, memory template
- `requirements.txt` — the prerequisites, with what each one is for

The canonical, self-contained installer lives at the **repository root**. The
copies here are regenerated by `build-package.sh` so the two can never drift.

---

New to opencode? Read **GUIDE.md**.

**Brought to you by @FeaturisticLeaks X @slixki**
