# opencode-mobile

> **Brought to you by @FeaturisticLeaks X @slixki**
> Last updated: 2026-08-01
> Companion logs: `opencode-mobile-PROGRESS.md` (full session history)

---

## ✅ Status: SHIPPING READY (v1.3)

**`opencode-mobile-v1.3.zip`** on Desktop is the final, QA-passed package (9 files, folder-prefixed).
v1.2 was confirmed working on the user's real ARM64 phone. The v1.3 fixes are **sandbox-verified but NOT yet device-tested** — the one remaining step before sharing widely.

---

## 📦 What to share (2 files, both on Desktop)

1. **`opencode-mobile-v1.3.zip`** — the complete package (9 files)
2. **`INSTALL.txt`** — the one-page guide (share alongside the zip)

Old zips (v1.0, v1.1, v1.2) deleted from Desktop.

---

## 🗂 Package structure (working folder: `Desktop\opencode for mobile\`)

| File | Job |
|---|---|
| `INSTALL.txt` | One-page install guide (extract → navigate → `bash install.sh`) |
| `install.sh` | Fully-automatic installer |
| `uninstall.sh` | One-command uninstaller (now also undoes the ⌨ keyboard change) |
| `requirements.txt` | Prerequisites (curl unzip git ripgrep openssh nodejs-lts) |
| `config/opencode.json` | Free models + default model = `opencode/deepseek-v4-flash-free` |
| `config/AGENTS.md` | opencode rules + REQUIRED greeting line |
| `config/Memory.template.md` | Memory-file template |
| `README.md` | Full step-by-step (includes device-support warning) |
| `GUIDE.md` | Complete beginner's guide |

---

## ✅ Everything fixed in v1.3

1. **Keyboard (⌨) toggle bug** — old Step9 skipped adding the button when `~/.termux/termux.properties` already had an `extra-keys` line. Now **injects `KEYBOARD`** as the first button of an existing row (GNU sed first-match replace), keeps the user's keys, saves a backup (`termux.properties.opencode-backup`). Fresh installs get the full default row.
2. **Zip folder structure** — entries were flat (files dumped loose into `~/storage/downloads`, so `cd opencode-mobile` failed). Rebuilt with a top-level `opencode-mobile/` prefix on all 9 entries.
3. **curl auto-repair** — a prerequisite `pkg install` can upgrade curl+libngtcp2 and break curl (missing-symbol class). `repair_curl()` (`apt update && apt full-upgrade -y`) now auto-runs at **3 points**: initial `check_curl`, post-prerequisite re-check, and pre-download in `install_native()`.
4. **`pkg upgrade -y` added to prerequisites** — reconciles stale package sets (the real cause of the emulator's curl breakage). Guarded; `repair_curl` backstops.
5. **Arch guard** — keys off `dpkg --print-architecture` (uname -m lies on some emulators). Non-aarch64 → clear skip message, no wasted 52MB download.
6. **Success banner gated on `opencode_ok`** — if opencode isn't actually working, setup stops cleanly BEFORE config/key/AI-shortcut and exits 1 (no half-configured phone).
7. **`install_native` returns 1** on verify-failure (was faking success).
8. **Uninstaller completeness** — restores `termux.properties.opencode-backup` or removes the appended keyboard block.

---

## 📱 Device support (decision confirmed by user, 2026-08-01)

| Device | Behavior |
|---|---|
| **Real ARM64 phone** (aarch64) | ✅ Full support — native build installs and runs (proven in v1.2) |
| **x86_64 Android emulators** (MuMu, GameLoop, BlueStacks) | ⏭ Clean skip: "cannot run on x86_64 emulators — use a real ARM64 phone or ARM64 emulator" |
| **32-bit devices** | ⏭ Same clean skip |

**Why:** opencode (anomalyco/opencode) is a **Bun-compiled app** (`bun build --compile`). Bun has no Android support, so `guysoft/opencode-termux` cross-compiled the whole Bun runtime + WebKit/JavaScriptCore engine from source — **aarch64 only**. Official opencode releases (v1.18.10) ship only linux-x64 + linux-arm64; **no 32-bit builds exist anywhere**, and Termux 32-bit is EOL.

---

## 🧠 Key facts for resuming

### The user flow (what recipients do)
1. Install Termux from F-Droid (NOT Play Store).
2. `termux-setup-storage` → tap ALLOW.
3. Put zip in Downloads.
4. `cd ~/storage/downloads` → `unzip -o opencode-mobile-v1.3.zip` → `cd opencode-mobile` → `bash install.sh`
5. Paste free OpenCode key from https://opencode.ai/auth (Enter = skip, add later with `/connect`).
6. Reopen Termux → type `AI`.

### Installer steps (all automatic)
Banner → Termux check (PREFIX) → `check_curl` (auto-repairs broken curl) → `pkg update` + `pkg upgrade` → prerequisites from `requirements.txt` → storage (auto) → **install native aarch64 opencode** → copy config (opencode.json + AGENTS.md ×2 + Memory.template) → **OpenCode API key prompt** (saved as `OPENCODE_API_KEY` in `~/.bashrc`) → `AI` shortcut → **⌨ keyboard toggle** → success banner.

### Zip build rule (IMPORTANT)
Zip must use **forward slashes** AND a **top-level `opencode-mobile/` prefix** on every entry. PowerShell `Compress-Archive` breaks both (writes `\`, no prefix). Use .NET `System.IO.Compression.ZipArchive` with `"opencode-mobile/" + rel` entry names.

### Download URL resolution
GitHub API → known-good hardcoded URL → interactive paste fallback.
Hardcoded: `https://github.com/guysoft/opencode-termux/releases/download/v0.2.1/opencode-1.17.9-android-aarch64.zip` (~52MB)

### Installer idempotency
Re-running `install.sh` is safe: skips opencode re-download if working, skips existing `OPENCODE_API_KEY`, existing `AI()`, existing ⌨ button.

### Config / memory
- Default model: `opencode/deepseek-v4-flash-free` (OpenCode Zen free, 7 free models)
- **Zen free models (7)**: deepseek-v4-flash-free (default), mimo-v2.5-free, north-mini-code-free, nemotron-3-ultra-free, ling-3.0-flash-free, laguna-s-2.1-free, big-pickle. Authoritative list = `https://opencode.ai/zen/v1/models`. `-free` suffix is NOT a reliable free/paid indicator (big-pickle is free).
- Config opencode provider: `apiKey: "{env:OPENCODE_API_KEY}"`, `baseURL: "https://opencode.ai/zen/v1"`.
- Optional providers in config: Google Gemini (`GEMINI_API_KEY`), OpenRouter (`OPENROUTER_API_KEY`) — not prompted by installer, add manually.
- Memory system: `Memory.md` auto-created per project under `~/opencode/<project>/` from `~/opencode/Memory.template.md`; AGENTS.md requires the greeting "Brought to you by @FeaturisticLeaks X @slixki".
- **Uninstall warning:** `cd ~/storage/downloads/opencode-mobile && bash uninstall.sh` also deletes your `~/opencode` projects — back them up first if you care about them.
- Keyboard backup alternative: `termux-ime toggle` after `pkg install termux-api` also toggles the soft keyboard (the `KEYBOARD` macro = `onToggleSoftKeyboardRequest()` in termux-app source).

---

## 🔧 Known gotchas / troubleshooting

- **curl breaks mid-install** → auto-repaired (full-upgrade). If it still fails: `apt update && apt full-upgrade -y` manually, then re-run.
- **Commands jumbled** (`-ypkg`, `unzipunzip`) → user pasted multiple commands; tell them one per line.
- **"No command ai found"** → shortcut only loads in a fresh Termux session / after re-running installer. Expected, not a bug.
- **opencode installed but won't run** → restart Termux, try `opencode --version`.
- **On emulators** → opencode physically cannot run (aarch64-only). Don't test there; use the real ARM64 phone.

---

## 📌 What's left to do

- [ ] **Device-test v1.3 on the real phone** (transfer new zip, clean loose files in Downloads, `unzip -o`, `bash install.sh`, check ⌨ button + `AI`). This is the ONLY thing between "sandbox-verified" and "share widely."
- [ ] Optional: full prose review of `GUIDE.md` (installer already fully reviewed).
- [ ] Optional: hide API-key input with `read -s` (currently visible by design — hidden input hides paste errors).
- [ ] Optional: add "how to uninstall" to INSTALL.txt.
- [ ] Optional: add a small config so users can set their own model per project.
- [ ] Optional: add a changelog file to the package.

---

## 📝 Session history (what was fixed, version by version)

- **v1.0** — created package. Broken: npm EBADPLATFORM + native URL resolution failed on device.
- **v1.1** — native-only installer, fixed URL resolver (API → hardcoded → paste fallback), curl `--retry 3`, removed redundant ripgrep. Rebranded to **@FeaturisticLeaks X @slixki**.
- **v1.2** — fully automatic (no y/n), `requirements.txt`, OpenCode-key prompt (was Gemini), `AI` shortcut, default model → zen, added `uninstall.sh`, added **⌨ keyboard toggle**, INSTALL.txt guide. **CONFIRMED WORKING on device.**
- **v1.3** — **keyboard toggle bug fix**: Step9 skipped adding ⌨ if `termux.properties` already had an `extra-keys` line. Now injects `KEYBOARD` into the existing row (GNU sed `0,/re/` first-match replace, verified locally on 3 scenarios), backups to `$props.opencode-backup`. INSTALL.txt now references `opencode-mobile-v1.3.zip`.
- **v1.3 (round 2)** — **zip folder-structure fix**: entries were flat (files at zip root → unzipped loose into `~/storage/downloads`, `cd opencode-mobile` failed). Rebuilt with a top-level `opencode-mobile/` prefix on all 9 entries. INSTALL.txt updated: "5 steps" (was "4"), explains the zip creates the `opencode-mobile` folder, adds safe file-manager cleanup for loose files. Verified with a real test-extraction.
- **v1.3 (round 3)** — **curl auto-repair + arch guard**. Device test on an **x86_64 Android emulator**: `check_curl` passed, but prerequisites `pkg install` upgraded curl 8.12.1→8.21.0 + fresh libngtcp2 1.25.0 and **broke curl again** (missing-symbol class). Fix: `repair_curl()` (`apt update && apt full-upgrade -y`) auto-runs at the post-prerequisite check AND defensively before the download (`curl_ok()`). Discovered the `guysoft/opencode-termux` release is **aarch64-only**. Arch check now keys off `dpkg --print-architecture` (uname -m lies on some emulators: reported aarch64 while apt used x86_64) and **skips with a clear "cannot run on x86_64 emulators" message** instead of wasting a 52MB download.
- **v1.3 (QA pass, 2026-08-01)** — full review of all 9 files. Fixed: (1) **success banner lied** — said "ready, type AI" even when opencode never installed; now `opencode_ok` gates everything — setup stops cleanly BEFORE config/key/AI-shortcut and exits 1. (2) **`install_native` returned 0 even on verify failure** — now returns 1. (3) **`pkg update` alone left stale packages** (the actual cause of the emulator's curl breakage) — added `pkg upgrade -y` to prerequisites. (4) node check downgraded error→skip (node is optional). (5) **uninstall.sh now undoes the keyboard change** (restores backup or removes the appended block). Verified end-to-end: bash -n both scripts, 3 sandbox scenarios all exit correctly with no stray config, uninstaller undo tested both paths.

---

## 🔗 Links
- OpenCode key: https://opencode.ai/auth
- Termux (F-Droid): https://f-droid.org/packages/com.termux/
- Native build source: https://github.com/guysoft/opencode-termux/releases/latest
- Reference project: https://github.com/guysoft/opencode-termux
- opencode (the AI agent): https://github.com/anomalyco/opencode
