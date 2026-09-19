# opencode-mobile — maintainer notes

> **Brought to you by @FeaturisticLeaks X @slixki**
> Package version: **2.0.0** · Last updated: 2026-09-19
> User-facing docs: `README.md` (repo root), `INSTALL.txt`, `GUIDE.md`
> Error reference: `docs/TROUBLESHOOTING.md`

Internal handoff notes. Not part of the distributed zip — users never see this.

---

## Status

**v2.0.0 — shipped.** Supersedes v1.3.

The change that forced this release: the OpenCode Zen gateway raised its minimum
client version to **1.18.0**, and the only Termux build this package used
(`guysoft/opencode-termux` v0.2.1) is **opencode 1.17.9**. Every user hit:

```
Error from provider (Console): OpenCode 1.18.0 or newer is required to use the free tier
```

There is no fix inside the old design — guysoft has not published a release since
2026-06-25 and its CI last ran 2026-07-21. So the install path was replaced.

---

## What changed in v2.0.0

### 1. New install source — this is the actual fix

| | v1.3 | v2.0.0 |
|---|---|---|
| Source | `guysoft/opencode-termux` zip | `bd-loser/opencode-bionic` `.deb` |
| opencode | 1.17.9 (June 2026) | **1.18.31** (tracks upstream automatically) |
| Size | 49.6 MB zip → ~180 MB installed | 34.8 MB `.deb` |
| Checksum | none | **SHA256SUMS verified** |
| Fallback | none | npm `opencode-termux` (official musl build) |
| Last release | 2026-06-25, stale | rebuilt every 12 h from upstream |

`bd-loser/opencode-bionic` (MIT, 12★) cross-compiles a patched Bun 1.4.2 for
Bionic and builds opencode from the upstream release tag, so the binary reports a
clean `1.18.31`. Its `watch-upstream.yml` polls upstream and re-releases
automatically — which is what keeps this package from going stale again.

The npm fallback (`C04-wq/opencode-termux`, MIT, 29★) repackages opencode's
**official** `linux-arm64-musl` build with a `patchelf`'d musl loader wired to
Termux's DNS. Rebuilt every 6 h, checksum-verified.

`guysoft` 1.17.9 is deliberately **not** a fallback: it is below the floor, so it
would reproduce the exact error being fixed. Better to fail loudly.

### 2. Version-string validation (the non-obvious part)

The free-tier gate parses the version out of the client `User-Agent` and requires
**plain semver**. Verified against `https://opencode.ai/zen/v1/responses`:

| `User-Agent` | Result |
|---|---|
| `opencode/1.18.31` | 200 ✅ |
| `opencode/1.18.31.r12.g88c6c7a` | 403 ❌ git-describe |
| `opencode/1.18.31-dev.f1aacaba` | 403 ❌ dev build |
| `opencode/1.18.4-8` | 403 ❌ packaging suffix |
| `opencode/1.17.9` | 403 ❌ too old |

So installing "something recent" is not enough. `install.sh` now:

- resolves through `/releases/latest`, which **excludes prereleases** — a `-dev.`
  build can never be selected by accident,
- refuses any tag matching `*-dev.*` or `*-*` outright,
- runs `opencode --version` and requires `^[0-9]+\.[0-9]+\.[0-9]+$` **and**
  `>= 1.18.0`,
- discards a source that fails validation and tries the next one.

There is a **second gate**: `x-opencode-session` must be a real opencode session
ID (`ses_` + 12 hex + 14 base62). Genuine opencode always produces these, so it
only affects people scripting the API directly. Upstream has said the free tier
is intentionally unavailable to third-party harnesses.

### 3. Model limits were wrong for all nine models

`config/opencode.json` declared `context: 131072, output: 8192` for every Zen
model. Real values (from the models.dev catalogue opencode itself consumes):

| Model | Was | Now |
|---|---|---|
| `deepseek-v4-flash-free` (default) | 131072 / 8192 | **200000 / 128000** |
| `nemotron-3-ultra-free` | 131072 / 8192 | **1000000 / 128000** |
| `north-mini-code-free` | 131072 / 8192 | 256000 / 64000 |
| `ling-3.0-flash-free` | 131072 / 8192 | 262144 / 32768 |
| `mimo-v2.5-free` | 131072 / 8192 | 200000 / 32000 |
| `laguna-s-2.1-free` | 131072 / 8192 | 256000 / 32000 |
| `big-pickle` | 131072 / 8192 | 200000 / 32000 |

Output was understated up to **16×**. opencode uses `limit.output` as the
max-tokens ceiling, so long file writes were being truncated mid-file — directly
harming the "generate a whole Android project" use case. It also uses
`limit.context` to trigger auto-compaction, so sessions compacted far too early.
That matters twice over: compaction is precisely where the September 2026
free-tier failures clustered.

Also added `nemotron-3.5-lightning-free` and `hy3-free` (currently free, were
missing), and changed `small_model` to `opencode/big-pickle` so background
summarisation does not compete with the main model's rate limit.

### 4. Dropped hardcoded Google/OpenRouter model IDs

The old config pinned `deepseek/deepseek-chat-v3-0324:free` and
`qwen/qwen-2.5-72b-instruct:free` — 2025-era OpenRouter listings, very likely
gone. Both providers are now configured with just an `apiKey`; opencode pulls
their full live catalogues from models.dev. Nothing to go stale.

### 5. `uninstall.sh` was unsafe

It ran `rm -rf "$HOME/opencode"` (every user project) with **no prompt and no
backup**, and with `$PREFIX` unset it ran `rm -rf /libexec/opencode` and
`rm -f /lib/libc++_shared.so` — real paths outside Termux. Then it printed
*"Your phone stays as it was; nothing else was touched."* False twice: it had
deleted all projects, **and** it left `~/.local/share/opencode/auth.json` behind,
so keys added via `/connect` survived.

Now: refuses to run outside Termux, keeps `~/opencode` by default and prompts
before deleting it, offers a tarball backup, archives config before removal,
asks separately about session history + saved keys, cleans up both the `.deb` and
the npm runtime, and strips the injected `KEYBOARD` token from a pre-existing
key row. The closing message states what was actually kept.

### 6. Keyboard (⌨) injection — the v1.3 fix was half a fix

v1.3 claimed to handle an existing `extra-keys` row. It only matched the two-row
`[[...]]` form. Tested against seven real configs, three failed:

| `termux.properties` | v1.3 | v2.0.0 |
|---|---|---|
| `extra-keys = ['ESC','TAB']` (one row — very common) | ❌ | ✅ |
| `extra-keys=['ESC','TAB']` (one row, no spaces) | ❌ | ✅ |
| tab-indented `extra-keys` | ❌ | ✅ |
| `extra-keys-style = dark` with no `extra-keys` | ❌ | ✅ |
| two-row `[[...]]` | ✅ | ✅ |
| already has `KEYBOARD` | ✅ | ✅ |

Two bugs: the sed pattern required `[[`, and `grep "^[[:space:]]*extra-keys"`
also matched **`extra-keys-style`**, routing those users into a branch that
always failed. Worse, the failure path did not fall back to appending a row —
so the user ended up with **no ⌨ button at all**, the exact symptom v1.3 was
meant to fix.

Now: the key is matched exactly, both row forms are handled, and if injection
still fails a row is **appended** instead (Java Properties takes the last value
for a duplicate key) so there is never a dead end. All nine scenarios verified.

### 7. The `AI` shortcut broke per-project memory

It did `cd "$HOME/opencode" && opencode` — the **parent** of every project. That
collapsed all projects into one opencode project root, so `Memory.md` landed at
`~/opencode/Memory.md` instead of per-project, and `/sessions` mixed everything
together. It also contradicted `GUIDE.md`, which told users to `cd myapp` first.

Now: `AI` opens opencode in the current directory (from `$HOME`, it goes to
`~/opencode`), and `AI myapp` creates/opens that project. Idempotent — re-running
the installer replaces the old definition rather than stacking a second one.

### 8. Rules no longer follow users into other repos

`config/AGENTS.md` is installed to `~/.config/opencode/AGENTS.md`, opencode's
**global** rules path, so it applied to every session on the phone — including
the AIDE/AndroidIDE projects `GUIDE.md` §8 encourages users to open. It mandated
creating `Memory.md` "on every meaningful step", which dropped files into other
people's git repos, and mandated the branding greeting on **every** message.

Now: memory writes are scoped to `~/opencode/` and explicitly forbidden elsewhere
without being asked; the greeting is once per session and must not leak into
code, commits or files; checkpoint-based memory updates instead of per-edit; and
the rules include real guidance for `FreeTierError` (do not retry-loop, switch
model, `/compact` early, mention the 1.18.0 floor).

Also removed the duplicate: the old config had both
`~/.config/opencode/AGENTS.md` *and* `instructions: ["~/opencode/AGENTS.md"]`
pointing at an identical second copy, so the same rules were injected into the
prompt twice. The installer deletes the stale `~/opencode/AGENTS.md`.

### 9. Documentation errors corrected

| Was | Now |
|---|---|
| "press `q` or Ctrl + C" to stop an answer (×2) | **Esc** — Ctrl+C exits opencode. The guide contradicted itself at line 527. |
| "Sign-up asks for billing details" | **No card, no billing details.** Contradicted "no card required" in three other files. |
| config at "`~/opencode` → `config/opencode.json`" | `~/.config/opencode/opencode.json` |
| "four free models … six more" | nine Zen free models + two optional providers |
| `/undo` = "undoes the last change" | also: **requires a git repository** |
| `requirements.txt`: "ssh keys are created during install" | no `ssh-keygen` exists anywhere; marked OPTIONAL |
| README `nodejs` vs requirements `nodejs-lts` | consistent |
| INSTALL.txt "3 minutes" vs README "10 minutes" | "a few minutes" |

Added: `/compact`, `/redo`, `/init`, `/export`, a `git init` step in the
walkthrough, and an explanation of why `limit` values must be accurate.

### 10. Repo hygiene

- **Root `README.md`** — there was none, so the GitHub landing page showed only a
  folder named `opencode for mobile`.
- **`LICENSE`** (MIT) — the package is explicitly redistributed, with no grant of
  rights before. Notes that downloaded binaries carry upstream licences.
- **`.gitignore`**, **`docs/TROUBLESHOOTING.md`**.
- **`build-package.sh`** — the zip was a hand-built duplicate of nine files with
  no build script; the regeneration rule existed only as prose describing a
  Windows PowerShell/.NET recipe. Now generated on any POSIX system, with a
  `--check` mode that fails on drift.
- Executable bits set on all three scripts (were `644`, so `./install.sh` failed).
- Legacy `guysoft` artifacts (`$PREFIX/libexec/opencode`, three `.so` files,
  ~180 MB) are purged on upgrade instead of being left to shadow the new binary.

### 11. Installer robustness

Added: SHA-256 verification · `curl -C -` resume with a persistent cache dir
(`~/.cache/opencode-mobile`) · free-space check · full log to
`~/opencode-mobile-install.log` · `PACKAGE_VERSION` stamp · API-key replacement
instead of appending duplicates · `chmod 600 ~/.bashrc` · `/dev/tty` for all
prompts so `curl | bash` cannot swallow the script into a `read` · non-interactive
mode · env overrides for source, version and key.

---

## Key facts for resuming

### Distribution
```bash
curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
```
`install.sh` is **self-contained by necessity** — piped into bash, it cannot read
sibling files, so `config/` is embedded as heredocs between
`# ==== BEGIN GENERATED EMBEDDED CONFIG ====` markers. **`config/` is the source
of truth**; regenerate with `./build-package.sh`, verify with
`./build-package.sh --check`. Never hand-edit the embedded block.

### Env overrides
`OPENCODE_VERSION` · `OPENCODE_SOURCE=auto|bionic|npm` · `OPENCODE_API_KEY` ·
`OPENCODE_MOBILE_YES=1` · `OPENCODE_MOBILE_NO_KEYBOARD=1` ·
`OPENCODE_MOBILE_DELETE_PROJECTS=1` / `_DELETE_DATA=1` (uninstall)

### Upstream
- opencode: `anomalyco/opencode` — v1.18.31 at time of writing; **v2 announced**
- Bionic builds: `bd-loser/opencode-bionic` — stable + daily `-dev.` prereleases
- musl repackaging: `C04-wq/opencode-termux` — npm, 6-hourly
- Original cross-compile: `guysoft/opencode-termux` — **stale at 1.17.9**
- Zen free tier floor: **1.18.0**, clean semver in `User-Agent`, valid `ses_` session ID
- Live free-model list: `https://opencode.ai/zen/v1/models`
- Free-tier key (no card): `https://opencode.ai/auth`

### Known upstream instability (September 2026)
`anomalyco/opencode#49433` (45 comments) — a wave of `FreeTierError` on
**official** 1.18.30/1.18.31 across macOS/Linux/Windows. Clustered around
**auto-compaction**, often at ~70% of context; normal messages succeeded while
compaction failed and then poisoned the session. Partly fixed server-side within
hours, but #49918 and #49944 were filed afterwards. Also reported: custom primary
agents failing where built-in `build`/`plan` succeed, and denied tool permissions
as a deterministic trigger.

This is **not** something the package can fix, so the config and rules are tuned
to reduce exposure: correct (larger) context limits mean fewer compactions, and
`AGENTS.md` tells the agent not to retry-loop and to suggest `/compact` early or
`/new`.

---

## Verification performed

- `bash -n` on `install.sh`, `uninstall.sh`, `build-package.sh`
- `config/opencode.json` parses as JSON; embedded heredocs byte-match `config/`
- Version gate against 16 real-world strings, including every rejected form above
- `ver_ge` numeric edge cases (`1.18.9` vs `1.18.10`, `1.8.0` vs `1.10.0`)
- Keyboard injection across **9** `termux.properties` scenarios (v1.3 failed 3)
- `.bashrc` rewrite: old v1.3 shortcut replaced, and **3 consecutive runs** leave
  exactly one `AI()` definition and one marker
- `AI()` behaviour from `$HOME`, from inside a project, and with an argument
- `uninstall.sh`: refuses with `$PREFIX` unset; non-interactive run keeps
  projects and keys, backs up config, removes the binary and the `KEYBOARD` token
- Live: both tag-resolution routes (GitHub API and web redirect) return
  `v1.18.31`; the `.deb` and `SHA256SUMS` assets exist
- Zip: prefix, forward slashes, required entries, extraction, and byte-identity
  of the extracted `install.sh`

**Not yet done:** an end-to-end run on a real ARM64 phone. That is the one gap
between "verified in sandbox" and "share widely" — same as it was for v1.3.

---

## Open items

- [ ] Device-test v2.0.0 on a real ARM64 phone (the only remaining blocker)
- [ ] Watch `bd-loser/opencode-bionic` — if it goes quiet, the npm fallback
      becomes primary; consider mirroring the `.deb` to this repo's own releases
- [ ] Consider a GitHub Action that runs `build-package.sh --check` on every push
- [ ] Consider re-publishing the zip as a GitHub Release asset instead of a
      committed binary, so `git clone` stays small
- [ ] `apiKey: "{env:OPENCODE_API_KEY}"` resolves to an empty string when the key
      is skipped; verify on-device that this does not shadow a `/connect`
      credential stored in `auth.json` (left as-is because v1.2 was device-verified
      with it)
- [ ] Repo is named `opencode-termux`, colliding with the upstream project it
      depends on; the product is `opencode-mobile`. Worth renaming.
- [ ] The folder `opencode for mobile/` still has a space in its name
