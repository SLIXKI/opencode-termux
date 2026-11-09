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
4. installs the **latest stable OpenCode v2** and verifies its SHA-256 checksum,
5. **verifies the version string the binary reports** (see below),
6. writes a minimal `opencode.json`, the agent rules and the memory template,
7. optionally saves your free OpenCode Console key,
8. adds the `AI` shortcut and a **⌨ keyboard-toggle button** to Termux.

Then close Termux, reopen it, and type:

```bash
AI
```

Re-running the same line **updates** opencode in place — it is safe to repeat.
If you still have OpenCode v1 from an older release of this package, the
update replaces it with v2 (your `opencode.json` is backed up first).

### Uninstall — one line

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/uninstall.sh | bash
```

It asks before deleting anything. Your projects under `~/opencode` are **kept by
default**, and your config is archived to a `.tar.gz` before removal.

---

## Why OpenCode v2 matters

OpenCode **v1 no longer supports free models**. Per the upstream maintainers
([issue #59387](https://github.com/anomalyco/opencode/issues/59387)): most
"free usage limit reached" / "1.18.0 or newer is required" reports come from
v1 (0.x / 1.x) clients, and updating to v2 fixed it for most people. v1 now
only receives fixes for critical bugs.

So this installer requires **v2** (currently `2.2.6`) and refuses to install
anything older than `2.0.0`. The version check from earlier releases remains,
because the free tier still reads the client version out of the request
`User-Agent` and demands a **plain release number**:

| Version string | Result |
|---|---|
| `2.2.6` | ✅ accepted |
| `2.2.6-dev.f1aacaba` | ❌ rejected |
| `2.2.6.r12.g88c6c7a` | ❌ rejected (git-describe) |
| `2.2.6-8` | ❌ rejected (packaging suffix) |
| `1.19.5` | ❌ rejected (v1 — no free models) |

This installer does not just install *something recent* — it validates the
version string the binary actually reports, then tells you what it found. See
`docs/TROUBLESHOOTING.md` for the full picture.

> Historical note: earlier releases of this repo documented the
> `OpenCode 1.18.0 or newer is required to use the free tier` (HTTP 426) and
> `OpenCode's free tier can only be used from within OpenCode` (HTTP 403)
> errors. Those errors still appear from stale v1 builds. The fix is the same
> one line above — it now installs v2.

---

## You need a free OpenCode Console account

Since OpenCode 2, the anonymous free tier is gone. Signed out, the `opencode`
provider is **absent** from `/models` until you sign in. A free account is
enough:

1. Sign up (free) at **https://opencode.ai/console/signup**
2. Copy an API key from the Console, then either paste it when the installer
   asks, or run `/connect` inside opencode afterwards.

You can also export it yourself: `export OPENCODE_API_KEY=sk-...` (the
installer offers to add this to `~/.bashrc`).

The free models are limited-time offers and rate-limited. If you want higher
limits, [OpenCode Go](https://opencode.ai/console/go) is a subscription that
includes them — entirely optional.

---

## Where opencode comes from

opencode does not publish an Android build. Bun (its runtime) has no official
Android support, so aarch64/Bionic builds are community-maintained. This
installer tries them in order and stops at the first one that passes the
version check:

| Order | Source | What it is |
|---|---|---|
| 1 | [`bd-loser/opencode-bionic`](https://github.com/bd-loser/opencode-bionic) `.deb` | Native Bionic build with a patched Bun, shipped as a Termux `.deb` with `SHA256SUMS`. Built from the upstream release tag, so it reports a clean version. Rebuilt automatically as upstream releases. |
| 2 | [`bd-loser/opencode-bionic`](https://github.com/bd-loser/opencode-bionic) raw binary | The exact same binary the `.deb` ships (the `.deb` contains nothing else), installed straight into `$PREFIX/bin` when `dpkg` is broken. Also checksum-verified against `SHA256SUMS`. |

Both carry upstream's MIT licence. The npm package `opencode-termux` (used as
the fallback in earlier releases) is **no longer offered** — it ships v1, and
v1 no longer supports free models. If you have it installed, the installer
removes it so it cannot shadow the v2 binary.

Force a source or pin a version if you need to:

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh \
  | OPENCODE_SOURCE=binary bash                    # use the raw binary, skip dpkg
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh \
  | OPENCODE_VERSION=2.2.6 bash                    # pin an exact version
```

All overrides: `OPENCODE_VERSION`, `OPENCODE_SOURCE` (`auto|bionic|binary`),
`OPENCODE_API_KEY`, `OPENCODE_MOBILE_YES=1`, `OPENCODE_MOBILE_NO_KEYBOARD=1`.

---

## Free models

The default model is `opencode/deepseek-v4.1-flash-free`. As of **2026-11** the
free roster on OpenCode Console includes:

`deepseek-v4.1-flash-free` · `big-pickle` · `glm-5.3-flash-free` ·
`mimo-v2.6-flash-free` · `nemotron-3-ultra-free` ·
`nemotron-3.5-lightning-free` · `nemotron-3.5-super-vl-free` · `iceman-free` ·
`flint-40b-free` · `beam-free` · `inkling-2-small-free` ·
`crouton-alpha-free` · `longcat-2.5-free`

Press `/models` inside opencode to switch. Availability and regions vary (e.g.
`crouton-alpha-free`, `beam-free` and `inkling-2-small-free` are not offered
in some countries; `longcat-2.5-free` is hosted in China and capped at 100
requests/day), and the roster **rotates without notice** — if a model errors,
pick another.

This package no longer hard-codes the roster into your config. opencode pulls
the live model catalogue itself, so the config cannot go stale between your
installs. Context and output limits come from that catalogue as well. The
earlier approach (a hand-maintained list with fixed limits) is why earlier
releases referenced models that no longer exist.

> ⚠️ Free models are free in money but may be logged or used to improve the
> models (this varies by model and is documented per model on the Console).
> Do **not** paste secrets or personal data into a free model.

Optional extra providers: just run `/connect` inside opencode — OpenRouter,
Google, Anthropic and others are built in. No manual config needed.

---

## Using it

| You type | What happens |
|---|---|
| `AI` | Opens opencode in your current project (from `$HOME`, opens `~/opencode`) |
| `AI myapp` | Creates/opens `~/opencode/myapp` and starts opencode there |
| `/models` | Switch AI model |
| `/connect` | Add or change an API key / sign in |
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
- A **free OpenCode Console account** — <https://opencode.ai/console/signup>
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
  opencode.json           model defaults + agent rules source
  AGENTS.md               global agent rules
  Memory.template.md      per-project memory template
build-package.sh        regenerates the offline zip + verifies nothing drifted
docs/
  TROUBLESHOOTING.md      free-model errors, in detail
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
- [C04-wq/opencode-termux](https://github.com/C04-wq/opencode-termux) — musl repackaging (fallback ≤ v2.0.0, retired)
- [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) — the original cross-compile that made this possible
- [Termux](https://termux.dev)

## License

MIT — see [LICENSE](LICENSE). The opencode builds it installs carry their own
upstream licences.

---

**Brought to you by @FeaturisticLeaks X @slixki**
