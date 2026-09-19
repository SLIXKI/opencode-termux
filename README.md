# opencode-mobile

Run the **opencode** AI coding agent on your Android phone — free models, one
line to install, and a memory system so you can leave a project and come back.

> **Brought to you by @FeaturisticLeaks X @slixki**

---

## Install — one line

Open **Termux** on your phone, paste this, press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
```

That is the whole install. It:

1. checks your device is Termux on **aarch64** (and tells you clearly if not),
2. repairs a broken `curl` and updates Termux packages,
3. installs prerequisites — `git`, `ripgrep`, `ca-certificates`, `coreutils`,
   `tar`, `unzip`, `nodejs-lts`, `openssh`,
4. installs the **latest stable opencode** and verifies its SHA-256 checksum,
5. **verifies the version satisfies the free tier** (see below),
6. writes the free-model config, the agent rules and the memory template,
7. optionally saves your free OpenCode key,
8. adds the `AI` shortcut and a **⌨ keyboard-toggle button** to Termux.

Then close Termux, reopen it, and type:

```bash
AI
```

Re-running the same line **updates** opencode in place — it is safe to repeat.

### Uninstall — one line

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/uninstall.sh | bash
```

It asks before deleting anything. Your projects under `~/opencode` are **kept by
default**, and your config is archived to a `.tar.gz` before removal.

---

## Why version 1.18.0 matters

If you see this:

```
Error from provider (Console): OpenCode 1.18.0 or newer is required to use the free tier
```

…it means the OpenCode Zen gateway raised its minimum client version. Builds
older than 1.18.0 are refused for **free-tier** models.

There is a second, less obvious condition. The gateway reads the client version
out of the request's `User-Agent` and requires a **plain release number**. These
are all new enough in code but still get rejected:

| Version string | Result |
|---|---|
| `1.18.31` | ✅ accepted |
| `1.18.31-dev.f1aacaba` | ❌ rejected |
| `1.18.31.r12.g88c6c7a` | ❌ rejected (git-describe) |
| `1.18.4-8` | ❌ rejected (packaging suffix) |
| `1.17.9` | ❌ rejected (too old) |

So this installer does not just install *something recent* — it **refuses dev
builds and validates the version string** the binary actually reports, then
tells you what it found. See `docs/TROUBLESHOOTING.md` for the full picture,
including the free-tier rate limits and the compaction failures reported
upstream in September 2026.

---

## Where opencode comes from

opencode does not publish an Android build. Bun (its runtime) has no official
Android support, so aarch64/Bionic builds are community-maintained. This
installer tries them in order and stops at the first one that passes the
version check:

| Order | Source | What it is |
|---|---|---|
| 1 | [`bd-loser/opencode-bionic`](https://github.com/bd-loser/opencode-bionic) | Native Bionic build with a patched Bun, shipped as a Termux `.deb` with `SHA256SUMS`. Built from the upstream release tag, so it reports a clean version. Rebuilt automatically as upstream releases. |
| 2 | [`opencode-termux` on npm](https://www.npmjs.com/package/opencode-termux) | Repackages opencode's **official** `linux-arm64-musl` build with a `patchelf`'d musl loader that uses Termux's DNS. |

Both are MIT-licensed. The older `guysoft/opencode-termux` build (opencode
1.17.9) is deliberately **not** used as a fallback — it is below 1.18.0, so it
would reproduce the exact error above.

Force a source or pin a version if you need to:

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh \
  | OPENCODE_SOURCE=npm bash                       # use the npm/musl build
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh \
  | OPENCODE_VERSION=1.18.31 bash                  # pin an exact version
```

All overrides: `OPENCODE_VERSION`, `OPENCODE_SOURCE` (`auto|bionic|npm`),
`OPENCODE_API_KEY`, `OPENCODE_MOBILE_YES=1`, `OPENCODE_MOBILE_NO_KEYBOARD=1`.

---

## Free models

The default model is `opencode/deepseek-v4-flash-free`. Nine free OpenCode Zen
models are pre-configured, so when one is rate-limited you can press `/models`
and switch in seconds:

`deepseek-v4-flash-free` · `big-pickle` · `mimo-v2.5-free` ·
`nemotron-3-ultra-free` · `nemotron-3.5-lightning-free` · `north-mini-code-free` ·
`ling-3.0-flash-free` · `laguna-s-2.1-free` · `hy3-free`

Context and output limits are set to each model's **real** values (up to 1M
context). An earlier release declared 131072/8192 for all of them, which made
opencode compact far too early and truncated long file writes.

A key is optional — the free tier works anonymously — but a free account key
raises your rate limits. Get one, no card required:
**https://opencode.ai/auth**

The free roster **rotates** without notice. If a model starts erroring, switch
models; the config is a snapshot dated 2026-09-19.

Optional extra providers are pre-wired but not required — export
`GEMINI_API_KEY` ([Google AI Studio](https://aistudio.google.com/app/apikey)) or
`OPENROUTER_API_KEY` ([OpenRouter](https://openrouter.ai)) and their full model
catalogues appear automatically.

---

## Using it

| You type | What happens |
|---|---|
| `AI` | Opens opencode in your current project (from `$HOME`, opens `~/opencode`) |
| `AI myapp` | Creates/opens `~/opencode/myapp` and starts opencode there |
| `/models` | Switch AI model |
| `/connect` | Add or change an API key |
| `/compact` | Summarise a long chat — do this **early** on a phone |
| `/new` | Fresh chat (your files and memory are untouched) |
| `/sessions` | Resume a previous chat |
| `/undo` | Undo the last change — **needs the project to be a git repo** |
| **Esc** | Interrupt a running answer (not `q`, not Ctrl+C) |

Every project under `~/opencode/` gets a `Memory.md` that opencode keeps
current, so you can close Termux and resume days later.

Full beginner walkthrough: **[`opencode for mobile/GUIDE.md`](opencode%20for%20mobile/GUIDE.md)**

---

## Requirements

- Android phone, **64-bit ARM (aarch64)** — most phones since ~2018
- **Termux from F-Droid** — <https://f-droid.org/packages/com.termux/>.
  The Google Play build is outdated and will not work.
- ~250 MB free storage, and an internet connection

x86_64 emulators (MuMu, GameLoop, BlueStacks) and 32-bit devices are **not**
supported — opencode is not built for them. The installer detects this before
downloading anything.

---

## Repository layout

```
install.sh              the one-line installer (self-contained; config embedded)
uninstall.sh            guarded uninstaller
config/                 readable source of truth for the embedded config
  opencode.json           free models + providers
  AGENTS.md               global agent rules
  Memory.template.md      per-project memory template
build-package.sh        regenerates the offline zip + verifies nothing drifted
docs/
  TROUBLESHOOTING.md      the free-tier gate, in detail
opencode for mobile/    the offline package (docs + generated zip)
```

`install.sh` must be self-contained because it is piped straight into `bash`,
so it embeds copies of everything in `config/`. `build-package.sh` regenerates
those embedded blocks from `config/` and fails if they disagree — the two can
never silently drift apart. Run `./build-package.sh --check` to verify.

---

## Credits

- [opencode](https://github.com/anomalyco/opencode) — the AI coding agent
- [bd-loser/opencode-bionic](https://github.com/bd-loser/opencode-bionic) — Bionic/aarch64 build
- [C04-wq/opencode-termux](https://github.com/C04-wq/opencode-termux) — musl repackaging
- [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) — the original cross-compile that made this possible
- [Termux](https://termux.dev)

## License

MIT — see [LICENSE](LICENSE). The opencode builds it installs carry their own
upstream licences.

---

**Brought to you by @FeaturisticLeaks X @slixki**
