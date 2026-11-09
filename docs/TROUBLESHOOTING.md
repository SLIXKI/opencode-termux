# Troubleshooting

Focused on the errors people actually hit with opencode on Android. General
beginner help lives in [`../opencode for mobile/GUIDE.md`](../opencode%20for%20mobile/GUIDE.md).

---

## The free models don't appear in `/models`, or every request fails

Since OpenCode 2, the `opencode` provider is **absent** from the model catalog
until you sign in. If `/models` shows nothing from OpenCode, or every request
to a free model fails:

1. Sign up (free) at **https://opencode.ai/console/signup**.
2. Paste the key when the installer asks, or run `/connect` → **OpenCode**
   inside opencode, or `export OPENCODE_API_KEY=sk-...` in `~/.bashrc`.
3. Run `/models` again — the free models should now be listed.

The anonymous free tier is gone. Requests from v1 clients or without a
Console connection are refused.

---

## "OpenCode 1.18.0 or newer is required to use the free tier" (HTTP 426)

Or the sibling message:

```
Error from provider (Console): OpenCode's free tier can only be used from within OpenCode
```

### What is happening

OpenCode **v1 no longer supports free models**. Upstream pinned the status in
[issue #59387](https://github.com/anomalyco/opencode/issues/59387): most free-tier
reports come from OpenCode v1 (0.x / 1.x, e.g. Desktop or CLI 1.19.x), v1 only
receives fixes for critical bugs, and updating to v2 fixed it for many people.

The error message is misleading — the gateway moved on to v2. The historical
floor (1.17.0, then 1.18.0) is documented below because the version-string
rules still apply to any gate like this.

### The part that still matters: plain release versions

The free tier reads the client version from the `User-Agent` header and
requires a **plain release number**. Community and development builds are
frequently new enough in code but still rejected, because their version string
is not clean semver:

| `User-Agent` | Result (historical v1 gate) |
|---|---|
| `opencode/1.18.31` | ✅ accepted |
| `opencode/1.18.31.r12.g88c6c7a` | ❌ git-describe |
| `opencode/1.18.31-dev.f1aacaba` | ❌ dev build |
| `opencode/1.18.4-8` | ❌ packaging suffix |
| `opencode/0.0.0` | ❌ |
| `opencode/latest` | ❌ not a version |

This is why `install.sh` does not stop at "did it install". It runs
`opencode --version` and requires the result to match `^[0-9]+\.[0-9]+\.[0-9]+$`
**and** be ≥ 2.0.0. A build that fails either test is discarded and the next
source is tried. Dev builds are never installed.

**Never install a `-dev.` build** expecting the free tier to work. If you pin a
version with `OPENCODE_VERSION`, pin a clean release like `2.2.6`.

### There is a second gate

The free tier also requires the session to be a genuine opencode session —
the request is signed with session IDs only the real client generates.
Third-party harnesses calling the API directly are refused by design. Upstream
has stated:

> "We've been tightening our logic to fight abuse. You cannot use the free tier
> in other harnesses (this is only a limitation for the free tier nothing else)."

Paid models and other providers (Anthropic, Google, OpenRouter) have no such
restriction.

### Fix it

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
```

Then **close Termux completely** (swipe it away) and reopen it. Confirm with:

```bash
opencode --version    # must print a clean X.Y.Z, >= 2.0.0
which opencode
```

If you had the npm package `opencode-termux` installed, the installer removes
it — it shipped v1 only, and it can shadow the v2 binary on `PATH`.

If `opencode --version` still prints something old, a stale binary is shadowing
the new one — check `which -a opencode` and remove the older path.

---

## Free tier errors mid-session (compaction)

In September 2026 a large number of users hit free-tier failures **during
context compaction** on official builds (1.18.30, 1.18.31, desktop and CLI,
macOS/Linux/Windows): normal messages succeeded, then compaction failed and
every later request in that session failed too. It clustered at roughly 70% of
the context window and was fixed server-side within hours.

If you still see this on a current v2 release:

- **`/new`** to start a fresh session — a poisoned session often keeps failing
  after the server is fixed.
- **`/compact` early and deliberately**, before the context fills, instead of
  waiting for auto-compaction.
- **`/models`** → pick another free model; their quotas are independent.

---

## Rate limits, quotas, and whether you need a key

Free models are free in money but not unlimited. Expect "rate limit reached"
or "quota exceeded" if you send a burst of messages.

- You need a **free OpenCode Console account** — sign up at
  <https://opencode.ai/console/signup>. The old anonymous free tier is gone.
- Free models cost nothing; you will not be charged without adding billing.
- [OpenCode Go](https://opencode.ai/console/go) is a subscription with higher
  limits — optional, not required.
- During free periods the provider may use your conversations to improve
  models; this varies per model (see the privacy notes on the Console models
  page). NVIDIA's free endpoints are explicitly "trial use only — do not
  submit personal or confidential data".

When limited: `/models` → pick another free model → continue. Nothing is lost.

---

## The free model roster changes

Which models are free rotates with no schedule and no notice. `Pulse Alpha
Free` was deprecated on 2026-11-06, `DeepSeek V4 Flash` on 2026-10-26, and
models configured in earlier releases of this package (`mimo-v2.5-free`,
`ling-3.0-flash-free`, `laguna-s-2.1-free`, `hy3-free`,
`north-mini-code-free`) are gone from the free roster.

If a model in `/models` errors with a billing message, it has probably stopped
being free. Pick another. This package intentionally **does not hard-code the
roster in your config** — opencode pulls the live catalogue, so re-running the
installer updates the client, not the model list.

Verified free roster snapshot (2026-11-09):

`deepseek-v4.1-flash-free` · `big-pickle` · `glm-5.3-flash-free` ·
`mimo-v2.6-flash-free` · `nemotron-3-ultra-free` ·
`nemotron-3.5-lightning-free` · `nemotron-3.5-super-vl-free` · `iceman-free` ·
`flint-40b-free` · `beam-free` · `inkling-2-small-free` ·
`crouton-alpha-free` · `longcat-2.5-free`

(`jev-1.13-free` exists too, but it is a structured-output evaluation model,
not a coding model, so it is not listed here. Region availability differs —
see the [Console models page](https://opencode.ai/docs/console/models).)

The authoritative live list is inside opencode itself (`/models`), driven by
the Console catalog.

---

## Termux and install problems

| Symptom | Cause | Fix |
|---|---|---|
| `curl: (6) Could not resolve host` | Termux's DNS after a partial upgrade | `pkg install resolv-conf` then re-run the installer |
| curl fails with a missing-symbol error | partial upgrade left curl against old libraries | `apt update && apt full-upgrade -y` (the installer does this automatically) |
| Errors like `-ypkg` or `unzipunzip` | several commands pasted at once | type **one command per line**, pressing Enter after each |
| `command not found: AI` | shortcut only loads in a new shell | close Termux fully and reopen, or `source ~/.bashrc` |
| No ⌨ button in the key row | extra-keys row not enabled | long-press the screen → **More** → **Extra keys**; then fully restart Termux |
| Keyboard hides inside opencode | Android behaviour for full-screen terminal apps | tap **⌨** in the key row, or `termux-ime toggle` after `pkg install termux-api` |
| `Unsupported architecture` | x86_64 emulator or 32-bit device | not supported — use a real ARM64 phone |
| Download keeps failing | flaky mobile network | just re-run; the installer resumes partial downloads with `curl -C -` |
| `checksum mismatch` | corrupt or tampered download | the installer deletes it and refuses to install — re-run |
| `dpkg` fails to install the `.deb` | broken or very old dpkg | the installer automatically falls back to the raw binary from the same release |
| Everything is slow | thermal throttling, or a big model on a phone | close other apps, remove the case, or `/models` → a lighter model |
| opencode installed but will not run | stale shell or a broken library set | fully restart Termux, then `opencode --version` |
| npm `opencode-termux` still on PATH | stale v1 fallback from an older install | the installer removes it automatically; or `npm uninstall -g opencode-termux` |

### Getting help

The installer writes a full log:

```bash
cat ~/opencode-mobile-install.log
```

Include that, plus `opencode --version` and `dpkg --print-architecture`, when
asking for help.

---

## `/undo` does nothing

`/undo` and `/redo` are **git-backed**. They only work inside a git repository.
A project created with plain `mkdir` has no history to revert to.

```bash
cd ~/opencode/myapp
git init
git add -A && git commit -m "start"
```

The agent rules shipped with this package now run `git init` for new projects
under `~/opencode/` automatically.

---

## Interrupting a response

Press **Esc**.

Not `q`, and not Ctrl+C — Ctrl+C exits opencode.
