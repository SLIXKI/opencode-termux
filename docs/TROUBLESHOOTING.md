# Troubleshooting

Focused on the errors people actually hit with opencode on Android. General
beginner help lives in [`../opencode for mobile/GUIDE.md`](../opencode%20for%20mobile/GUIDE.md).

---

## "OpenCode 1.18.0 or newer is required to use the free tier"

```
Error from provider (Console): OpenCode 1.18.0 or newer is required to use the free tier
```

### What is happening

The OpenCode Zen gateway checks the **client version** before serving free-tier
models, and it has raised that floor over time (1.17.0, then 1.18.0). Older
clients are refused.

It does not read the version from your account — it parses it out of the HTTP
`User-Agent` header that opencode sends, which looks like:

```
opencode/1.18.31 ai-sdk/provider-utils/4.0.23 runtime/bun/1.4.0
```

### The part that catches people out

The version must be a **plain release number**. Community and development builds
are frequently new enough in code but still rejected, because their version
string is not clean semver. Verified behaviour against
`https://opencode.ai/zen/v1/responses`:

| `User-Agent` | HTTP |
|---|---|
| `opencode/1.18.31` | 200 ✅ |
| `opencode/1.18.29` | 200 ✅ |
| `OpenCode/1.18.31` | 200 ✅ (case-insensitive) |
| `opencode/1.18.31.r12.g88c6c7a` | 403 ❌ git-describe |
| `opencode/1.18.31-dev.f1aacaba` | 403 ❌ dev build |
| `opencode/1.18.4-8` | 403 ❌ packaging suffix |
| `opencode/0.0.0` | 426 ❌ |
| `opencode/latest` | 403 ❌ not a version |
| `curl/8.7.1` | 403 ❌ not opencode |

This is why `install.sh` does not stop at "did it install". It runs
`opencode --version` and requires the result to match `^[0-9]+\.[0-9]+\.[0-9]+$`
**and** be ≥ 1.18.0. A build that fails either test is discarded and the next
source is tried.

**Never install a `-dev.` build** expecting the free tier to work. If you pin a
version with `OPENCODE_VERSION`, pin a clean release like `1.18.31`.

### There is a second gate

The free tier also requires `x-opencode-session` to be a real opencode session
ID — the form `ses_` + 12 hex chars + 14 base62 chars. Genuine opencode always
generates these, so this only matters if you are calling the API from your own
script or a different agent. Upstream has stated the free tier is not intended
for third-party harnesses:

> "We've been tightening our logic to fight abuse. You cannot use the free tier
> in other harnesses (this is only a limitation for the free tier nothing else)."

Paid models and other providers (Anthropic, Google, OpenRouter) have no such
restriction.

### Fix it

```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
```

Then **close Termux completely** (swipe it away) and reopen it, so the new
binary and your updated `~/.bashrc` are both picked up. Confirm with:

```bash
opencode --version    # must print a clean X.Y.Z, >= 1.18.0
which opencode
```

If `opencode --version` still prints something old, a stale binary is shadowing
the new one — check `which -a opencode` and remove the older path.

---

## "OpenCode's free tier can only be used from within OpenCode"

Same gate, different wording — you get a 403 `FreeTierError`. Two usual causes:

1. **A non-release version string** (see the table above).
2. **A known upstream incident.** In September 2026 a large number of users on
   *official* builds (1.18.30, 1.18.31, desktop and CLI, macOS/Linux/Windows)
   hit this simultaneously. It clustered around **context compaction**: normal
   messages succeeded, then compaction failed and every later request in that
   session failed too. Several users reported it triggering at roughly **70% of
   the context window**, and it was fixed server-side within a few hours.

   If every model fails at once for everyone, it is probably not your phone.
   Wait a while, then start a **fresh session** with `/new` — a poisoned session
   often keeps failing after the server is fixed.

### Reduce how often you hit it

- **Fix your model limits.** If `limit.context` in `opencode.json` is smaller
  than the model's real window, opencode compacts far too early — and
  compaction is exactly where this error bites. The config in this repo now uses
  the real values (200K–1M depending on model). An older release declared
  131072 for everything.
- **`/compact` early and deliberately**, while the session is still small,
  instead of waiting for auto-compaction at 70%.
- **`/new` between tasks.** Long-running sessions on a free tier are the worst
  case.
- **Switch models** with `/models` — the free roster has several options and
  their limits are independent.
- **Avoid custom agents for free-tier work.** There are reproducible reports of
  a custom primary agent failing on the first request while the built-in `build`
  and `plan` agents succeed in the same session.
- **Denied tool permissions** have also been reported as a deterministic
  trigger. If you added a `permission` block to your config, try removing it.

---

## Rate limits, quotas, and whether you need a key

Free models are free in money but not unlimited. Expect "rate limit reached" or
"quota exceeded" if you send a burst of messages.

- The free tier works **anonymously** — `Authorization: Bearer public` is
  accepted — so a key is not strictly required.
- A free account key raises your limits. Get one without a card at
  **https://opencode.ai/auth**. **No billing details are needed** for the free
  models. (An older version of our guide said sign-up asks for billing details;
  that was wrong.)
- Adding balance to a Zen account improves free-tier rate limits, but is
  entirely optional.
- During free periods the provider may use your conversation data to improve
  models. NVIDIA's free endpoints are explicitly "trial use only — do not
  submit personal or confidential data". Do not paste secrets into a free model.

When limited: `/models` → pick another free model → continue. Nothing is lost.

---

## The free model roster changes

Which models are free rotates with no schedule and no notice. Models that were
free have been withdrawn, and the `-free` suffix is **not** a reliable indicator
(`big-pickle` is free without it).

If a model in `/models` errors with a billing message, it has probably stopped
being free. Pick another. The authoritative live list is:

```
https://opencode.ai/zen/v1/models
```

The nine models pre-configured here are a snapshot from **2026-09-19**. To pick
up changes, edit `config/opencode.json` and re-run the installer — or delete the
`limit` blocks entirely so opencode takes live values from its model catalogue.

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
| Everything is slow | thermal throttling, or a big model on a phone | close other apps, remove the case, or `/models` → a lighter model |
| opencode installed but will not run | stale shell or a broken library set | fully restart Termux, then `opencode --version` |

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

Not `q`, and not Ctrl+C — Ctrl+C exits opencode. (An older version of our guide
said otherwise; that was wrong.)
