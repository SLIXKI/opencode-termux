#!/usr/bin/env bash
#
# ============================================================
#  opencode-mobile installer  (Termux / Android)
# ============================================================
#  Installs the opencode AI coding agent on Android via Termux,
#  preconfigured with free models and an auto-memory system.
#
#  Run this inside Termux with:  bash install.sh
# ============================================================

# --- Directory this script lives in (name may contain spaces) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helpers ---
c_green=$'\033[1;32m'
c_yellow=$'\033[1;33m'
c_red=$'\033[1;31m'
c_bold=$'\033[1m'
c_reset=$'\033[0m'

ok()    { printf '%s  [OK] %s%s\n'    "$c_green"  "$*" "$c_reset"; }
skip()  { printf '%s  [SKIP] %s%s\n'  "$c_yellow" "$*" "$c_reset"; }
error() { printf '%s  [ERROR] %s%s\n' "$c_red"    "$*" "$c_reset"; }
info()  { printf '%s\n' "  $*"; }

step_header() { printf '\n%s==> %s%s\n' "$c_bold" "$*" "$c_reset"; }

copy_file() {
  local src="$1" dst="$2" label="$3"
  if cp "$src" "$dst" 2>/dev/null; then
    ok "$label"
  else
    error "could not copy $label"
  fi
}

# --- Check that curl works; repair Termux automatically if broken ---
# A partial upgrade can leave curl unable to run (missing-symbol errors).
# The fix is a full Termux upgrade, which we run automatically.
repair_curl() {
  info "curl is broken on this device (usually after a partial Termux upgrade)."
  info "Fixing it automatically by upgrading all of Termux's packages..."
  info "This can take a few minutes — please wait."
  apt update && apt full-upgrade -y
}

check_curl() {
  if command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1; then
    ok "curl is working"
    return 0
  fi
  if repair_curl && command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1; then
    ok "curl is fixed"
    return 0
  fi
  error "Could not fix curl automatically. In Termux run these two commands:"
  error "    apt update && apt full-upgrade -y"
  error "then re-run:  bash install.sh"
  exit 1
}

# True if the curl binary actually runs (loading its shared libraries).
curl_ok() {
  command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1
}

# --- Native Android build (fallback) helpers ---

# Resolve the download URL of the latest opencode-termux aarch64 zip.
native_zip_url() {
  local url manual_url
  # 1) Ask the GitHub API for the real (versioned) asset URL.
  #    The releases/latest/download/<name> shortcut cannot be used because the
  #    asset name includes the opencode version (e.g. opencode-1.17.9-...).
  url="$(curl -fsSL --retry 3 --max-time 30 \
        "https://api.github.com/repos/guysoft/opencode-termux/releases/latest" 2>/dev/null \
        | grep -o 'https://github.com/[^"]*android-aarch64\.zip' \
        | head -n1)"
  if [ -n "$url" ]; then
    printf '%s\n' "$url"
    return 0
  fi

  # 2) Known-good fallback for when the GitHub API is blocked or rate-limited.
  #    The repo bumps versions rarely; the API above normally resolves the newest.
  url="https://github.com/guysoft/opencode-termux/releases/download/v0.2.1/opencode-1.17.9-android-aarch64.zip"
  if curl -fsIL --max-time 20 "$url" >/dev/null 2>&1; then
    printf '%s\n' "$url"
    return 0
  fi

  # 3) Last resort — ask the user to paste the asset link from the releases page.
  if [ -t 0 ]; then
    printf '\n%s\n' "${c_yellow}Could not auto-find the opencode Android download.${c_reset}"
    info "Open this page in your phone's browser:"
    info "  https://github.com/guysoft/opencode-termux/releases/latest"
    info "Tap the file named 'opencode-<version>-android-aarch64.zip',"
    info "then Copy link. Paste it here and press Enter:"
    printf '%s' "${c_bold}    Zip URL: ${c_reset}"
    read -r manual_url
    manual_url="$(printf '%s' "$manual_url" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "$manual_url" ]; then
      printf '%s\n' "$manual_url"
      return 0
    fi
  fi
  return 1
}

# Install the native aarch64 Android build (the primary install path on Termux).
install_native() {
  info "Downloading the native opencode Android build (aarch64)..."

  pkg install -y curl unzip >/dev/null 2>&1 || true
  if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    error "curl/unzip could not be installed, so the native build cannot be downloaded"
    return 1
  fi

  local zip_url
  zip_url="$(native_zip_url)" || {
    error "could not resolve the opencode-termux download URL"
    return 1
  }

  local tmp
  tmp="$(mktemp -d)"

  # Belt-and-braces: if the package upgrade left curl broken, repair it
  # before the download instead of failing mid-way.
  if ! curl_ok; then
    info "curl is broken — repairing before the download..."
    repair_curl >/dev/null 2>&1 || true
  fi
  if ! curl_ok; then
    error "curl is still not working — the native build cannot be downloaded."
    error "In Termux run:  apt update && apt full-upgrade -y   then re-run:  bash install.sh"
    rm -rf "$tmp"
    return 1
  fi

  info "Downloading: $zip_url"
  if ! curl -L -f --retry 3 --progress-bar -o "$tmp/opencode.zip" "$zip_url"; then
    error "download failed — check your network and run the installer again"
    rm -rf "$tmp"
    return 1
  fi

  if ! (cd "$tmp" && unzip -o opencode.zip >/dev/null 2>&1); then
    error "could not unzip the downloaded file"
    rm -rf "$tmp"
    return 1
  fi

  local wrapper bin_file so f
  wrapper="$(find "$tmp" -type f -name opencode | head -n1)"
  bin_file="$(find "$tmp" -type f -name opencode.bin | head -n1)"

  if [ -z "$wrapper" ] || [ -z "$bin_file" ]; then
    error "opencode / opencode.bin not found inside the downloaded zip"
    rm -rf "$tmp"
    return 1
  fi

  mkdir -p "$PREFIX/bin" "$PREFIX/libexec/opencode" "$PREFIX/lib"

  cp "$wrapper" "$PREFIX/bin/opencode"
  chmod +x "$PREFIX/bin/opencode"
  cp "$bin_file" "$PREFIX/libexec/opencode/opencode.bin"
  chmod +x "$PREFIX/libexec/opencode/opencode.bin"
  ok "installed wrapper -> $PREFIX/bin/opencode"
  ok "installed binary -> $PREFIX/libexec/opencode/opencode.bin"

  for so in libtagfix.so libc++_shared.so libopentui.so; do
    f="$(find "$tmp" -type f -name "$so" | head -n1)"
    if [ -n "$f" ]; then
      cp "$f" "$PREFIX/lib/$so"
      ok "installed $so -> $PREFIX/lib/"
    else
      error "$so not found in the zip — the native build may not start"
    fi
  done

  rm -rf "$tmp"

  if command -v opencode >/dev/null 2>&1 && opencode --version >/dev/null 2>&1; then
    ok "native opencode is working ($(opencode --version 2>/dev/null | head -n1))"
    return 0
  fi
  error "the native binary is installed but does not run — restart Termux and try 'opencode'"
  return 1
}

# ------------------------------------------------------------
# Step 1 — banner
# ------------------------------------------------------------
printf '\n'
printf '%s\n' "${c_bold}==================================================${c_reset}"
printf '%s\n' "${c_bold}   opencode-mobile installer${c_reset}"
printf '%s\n' "   opencode AI coding agent for Android (Termux)"
printf '%s\n' "   Free models preconfigured + auto-memory system"
printf '%s\n' "   Brought to you by @FeaturisticLeaks X @slixki"
printf '%s\n' "${c_bold}==================================================${c_reset}"

# ------------------------------------------------------------
# Step 2 — Termux check
# ------------------------------------------------------------
step_header "Checking Termux environment"
if [ -z "${PREFIX:-}" ]; then
  if [ -d /data/data/com.termux ]; then
    PREFIX=/data/data/com.termux/files/usr
  else
    error "This script must run inside Termux on Android."
    info  "Install Termux from F-Droid, open it, then run:  bash install.sh"
    exit 1
  fi
fi
ok "Termux detected (PREFIX=$PREFIX)"

# ------------------------------------------------------------
# Step 3 — prerequisites first (from requirements.txt)
# ------------------------------------------------------------
step_header "Checking curl (fixes a broken Termux if needed)"
check_curl

step_header "Updating Termux packages"
if pkg update -y; then
  ok "package list updated"
else
  error "pkg update failed — continuing anyway"
fi
info "Checking for package upgrades (keeps library versions consistent)..."
if pkg upgrade -y; then
  ok "all packages are up to date"
else
  error "pkg upgrade had issues — continuing anyway (curl repair will step in if needed)"
fi

step_header "Installing prerequisites (from requirements.txt)"
if [ ! -f "$SCRIPT_DIR/requirements.txt" ]; then
  error "missing requirements.txt — extract the FULL 'opencode-mobile' release"
  error "folder (install.sh, requirements.txt and config/ side by side), then re-run."
  exit 1
fi

req_pkgs=""
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"   # drop any inline comment (everything after '#')
  line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  case "$line" in
    '') continue ;;
  esac
  req_pkgs="$req_pkgs $line"
done < "$SCRIPT_DIR/requirements.txt"

if [ -z "$req_pkgs" ]; then
  error "requirements.txt is empty — nothing to install"
else
  info "Installing:$req_pkgs"
  if pkg install -y $req_pkgs; then
    ok "all prerequisites installed"
  else
    error "could not install all prerequisites — continuing, some features may be missing"
  fi
fi

if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  ok "node $(node -v 2>/dev/null) with npm $(npm -v 2>/dev/null)"
else
  skip "node/npm not found — optional, not required by opencode"
fi
if curl_ok; then
  ok "curl is ready"
else
  info "curl broke during the package upgrade — repairing automatically..."
  if repair_curl && curl_ok; then
    ok "curl is ready (repaired)"
  else
    error "curl is not working — opencode cannot be downloaded. Re-run after fixing Termux."
  fi
fi

# ------------------------------------------------------------
# Step 4 — storage access (optional)
# ------------------------------------------------------------
step_header "Setting up shared storage (optional)"
if [ -d "$HOME/storage" ]; then
  ok "storage already set up — skipping"
elif command -v termux-setup-storage >/dev/null 2>&1; then
  info "A permission dialog will appear on screen — tap ALLOW."
  info "(If you dismiss it, opencode still works — this step is optional.)"
  if printf 'y\n' | termux-setup-storage >/dev/null 2>&1; then
    ok "storage access granted"
  else
    skip "storage setup was skipped — not required for opencode"
  fi
else
  skip "termux-setup-storage not found — skipping"
fi

# ------------------------------------------------------------
# Step 5 — install opencode (native Android build)
# ------------------------------------------------------------
step_header "Installing opencode"
opencode_ok=false
if command -v opencode >/dev/null 2>&1 && opencode --version >/dev/null 2>&1; then
  ok "opencode is already installed and working ($(opencode --version 2>/dev/null | head -n1))"
  opencode_ok=true
elif command -v opencode >/dev/null 2>&1; then
  error "opencode is installed but won't run (library/version problem)."
  info "Restart Termux, then try:  opencode --version"
else
  # The 'opencode-ai' npm package does not accept Android as a platform
  # (npm error EBADPLATFORM), so on Termux we install the native Android
  # build directly — faster and reliable.
  arch="$(uname -m 2>/dev/null)"
  pkg_arch="$(dpkg --print-architecture 2>/dev/null)"
  info "Device architecture: ${arch:-unknown} (packages: ${pkg_arch:-unknown})"
  # The opencode Android build is aarch64-only, so the reliable signal is the
  # package architecture. uname -m can lie on some emulators (reports aarch64
  # while the actual Termux packages are x86_64).
  case "${pkg_arch:-$arch}" in
    aarch64|arm64)
      if install_native; then
        opencode_ok=true
      else
        error "native build install failed — see the messages above"
        info "If the download URL could not be resolved, re-run the installer and"
        info "paste the zip link when asked, or grab it manually from:"
        info "  https://github.com/guysoft/opencode-termux/releases/latest"
      fi
      ;;
    *)
      error "opencode for Termux supports aarch64 (64-bit ARM) only."
      skip  "this device reports ${arch:-unknown} with ${pkg_arch:-unknown} packages."
      info  "The opencode Android build is aarch64-only — it cannot run on x86_64"
      info  "emulators (MuMu, GameLoop, etc.) or on 32-bit devices."
      info  "Install on a real ARM64 phone, or an ARM64 Android emulator."
      ;;
  esac
fi

# --- Stop here if opencode is not actually working, so we never leave the
#     phone half-configured (config, key and the AI shortcut all depend on it).
if [ "$opencode_ok" != true ]; then
  printf '\n'
  error "opencode is NOT installed — setup stopped before configuring anything."
  info  "Only the prerequisites above were installed."
  info  "Fix the problem shown above, then re-run:  bash install.sh"
  exit 1
fi

# ------------------------------------------------------------
# Step 6 — install config + memory files
# ------------------------------------------------------------
step_header "Installing opencode-mobile config and memory files"
mkdir -p "$HOME/.config/opencode" "$HOME/opencode"

if [ ! -d "$SCRIPT_DIR/config" ]; then
  error "missing config folder: $SCRIPT_DIR/config"
  info  "Extract the FULL 'opencode-mobile' release folder so that"
  info  "install.sh and the 'config' folder sit side by side, then re-run."
  exit 1
fi

copy_file "$SCRIPT_DIR/config/opencode.json"      "$HOME/.config/opencode/opencode.json"   "opencode.json       -> ~/.config/opencode/"
copy_file "$SCRIPT_DIR/config/AGENTS.md"          "$HOME/.config/opencode/AGENTS.md"       "AGENTS.md           -> ~/.config/opencode/"
copy_file "$SCRIPT_DIR/config/AGENTS.md"          "$HOME/opencode/AGENTS.md"               "AGENTS.md           -> ~/opencode/"
copy_file "$SCRIPT_DIR/config/Memory.template.md" "$HOME/opencode/Memory.template.md"      "Memory.template.md  -> ~/opencode/"

# ------------------------------------------------------------
# Step 7 — OpenCode API key (the only key you need)
# ------------------------------------------------------------
step_header "OpenCode API key (one-time, ~1 minute)"
info "opencode is preconfigured with free models — you just need your"
info "OpenCode key to unlock them."
info "Get a free key here (no card required):  https://opencode.ai/auth"
info "Sign in or register, tap 'API key', copy the key, then paste it below."

api_key=""
if [ -t 0 ]; then
  printf '\n%s' "${c_bold}    Paste your OpenCode API key and press Enter (Enter = skip): ${c_reset}"
  read -r api_key
else
  skip "no terminal detected — skipping the API key prompt"
fi
api_key="$(printf '%s' "$api_key" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

if [ -n "$api_key" ]; then
  if grep -q "^export OPENCODE_API_KEY=" "$HOME/.bashrc" 2>/dev/null; then
    skip "OPENCODE_API_KEY already in ~/.bashrc — left unchanged"
  else
    printf '\n# OpenCode API key - added by the opencode-mobile installer\n' >> "$HOME/.bashrc"
    printf 'export OPENCODE_API_KEY="%s"\n' "$api_key" >> "$HOME/.bashrc"
    ok "OPENCODE_API_KEY added to ~/.bashrc"
  fi
else
  skip "no key added — add it later inside opencode with /connect > OpenCode Zen"
fi

# ------------------------------------------------------------
# Step 8 — the 'AI' shortcut
# ------------------------------------------------------------
step_header "Adding the AI shortcut"
if grep -q "^AI()" "$HOME/.bashrc" 2>/dev/null; then
  skip "AI shortcut already in ~/.bashrc — left unchanged"
else
  cat >> "$HOME/.bashrc" <<'EOF'

# --- AI shortcut (opencode-mobile): type AI to open opencode ---
AI() {
  cd "$HOME/opencode" 2>/dev/null || true
  opencode
}
ai() { AI; }
EOF
  ok "type 'AI' (or 'ai') to open opencode"
fi

# ------------------------------------------------------------
# Step 9 — keyboard (⌨) toggle button in Termux's key row
# ------------------------------------------------------------
step_header "Adding a keyboard toggle button to Termux"
mkdir -p "$HOME/.termux"
props="$HOME/.termux/termux.properties"
# Only touch an ACTIVE extra-keys line (skip commented-out examples).
active_keys_line() {
  [ -f "$props" ] && grep "^[[:space:]]*extra-keys" "$props"
}

if active_keys_line | grep -q "KEYBOARD"; then
  skip "your Termux already has a keyboard (⌨) button — left unchanged"
elif active_keys_line >/dev/null; then
  # A custom key row already exists but has no ⌨ button: inject it as the
  # first button of the first row, keeping the user's other keys intact.
  cp "$props" "$props.opencode-backup" 2>/dev/null || true
  if sed -i "0,/^\([[:space:]]*extra-keys[[:space:]]*=[[:space:]]*\)\[\[/{s//\1[['KEYBOARD',/}" "$props" \
     && grep -q "KEYBOARD" "$props"; then
    ok "keyboard (⌨) button added to your existing key row"
    info "a backup was saved to ~/.termux/termux.properties.opencode-backup"
  else
    error "could not modify your existing extra-keys line automatically"
    info "Edit $props and add 'KEYBOARD' to the extra-keys row, then restart Termux."
  fi
else
  # No active key row yet: append our recommended row.
  cat >> "$props" <<'EOF'

# Added by opencode-mobile: a keyboard (⌨) toggle button in the key row
# Tap it inside opencode whenever the phone keyboard hides.
extra-keys = [['ESC','TAB','CTRL','ALT','KEYBOARD'],['LEFT','DOWN','UP','RIGHT','PGUP','PGDN','HOME','END']]
EOF
  ok "keyboard (⌨) button added to Termux's key row"
fi

termux-reload-settings >/dev/null 2>&1 || true
info "If the ⌨ button still does not appear, fully close Termux"
info "(swipe it away) and open it again — Termux reads this file on start."

# ------------------------------------------------------------
# Step 10 — success banner
# ------------------------------------------------------------
step_header "Installation complete"
printf '\n'
printf '%s\n' "${c_bold}  opencode-mobile is ready. Next:${c_reset}"
printf '%s\n' ""
printf '%s\n' "  1) Start a new Termux session (or run:  source ~/.bashrc)"
printf '%s\n' ""
printf '%s\n' "  2) Just type:  AI"
printf '%s\n' "     (that's it — opencode opens in your projects folder)"
printf '%s\n' ""
if [ -n "$api_key" ]; then
  printf '%s\n' "  Your OpenCode key is saved — the free models are ready to use."
else
  printf '%s\n' "  No key was added yet. Inside opencode type /connect, pick"
  printf '%s\n' "  OpenCode Zen, and paste your key from https://opencode.ai/auth"
fi
printf '%s\n' ""
printf '%s\n' "  If the phone keyboard hides in opencode: tap the ⌨ button in the"
printf '%s\n' "  key row (bottom of screen) — it was added during install."
printf '%s\n' ""
printf '%s\n' "  If a model error appears: press /models and pick another free model."
printf '%s\n' ""
printf '%s\n' "  Free models: OpenCode Zen (https://opencode.ai/auth) — 7 free models"
printf '%s\n' "  Google Gemini (https://aistudio.google.com/app/apikey) — optional free"
printf '%s\n' "  OpenRouter (https://openrouter.ai) — optional free alternative"
printf '%s\n' ""
printf '%s\n' "  Brought to you by @FeaturisticLeaks X @slixki"
printf '\n'
ok "Install finished — happy coding!"

# ============================================================
# UNINSTALL — to remove opencode-mobile completely, run:
#
#   rm -rf ~/.config/opencode ~/opencode
#   rm -f "$PREFIX/bin/opencode"
#   rm -rf "$PREFIX/libexec/opencode"
#   rm -f "$PREFIX/lib/libtagfix.so" "$PREFIX/lib/libc++_shared.so" "$PREFIX/lib/libopentui.so"
#
#   Then remove the AI shortcut and API key from ~/.bashrc:
#   nano ~/.bashrc   # delete the 'AI()' function and the
#                    # 'OPENCODE_API_KEY' export line
# ============================================================
