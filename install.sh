#!/usr/bin/env bash
#
# ══════════════════════════════════════════════════════════════════
#  opencode-mobile  —  one-line installer for Android / Termux
# ══════════════════════════════════════════════════════════════════
#
#  THE ONE LINE (paste into Termux, press Enter):
#
#    curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash
#
#  Installs opencode v2 (latest stable), its prerequisites, the
#  free-model config, the memory system, the `AI` shortcut and the Termux
#  keyboard (⌨) toggle button. Safe to re-run; it updates in place.
#
#  Note: OpenCode v1 no longer supports free models (upstream, Oct 2026),
#  so this installer requires v2.
#
#  Brought to you by @FeaturisticLeaks X @slixki
#
# ── Environment overrides (all optional) ─────────────────────────
#   OPENCODE_VERSION=2.2.6     pin an exact opencode version
#   OPENCODE_SOURCE=auto       auto | bionic | binary   (default auto)
#   OPENCODE_API_KEY=sk-...    supply your Console key non-interactively
#   OPENCODE_MOBILE_YES=1        never prompt (assume default answers)
#   OPENCODE_MOBILE_NO_KEYBOARD=1  do not touch termux.properties
# ──────────────────────────────────────────────────────────────────

PACKAGE_VERSION="3.0.0"
MIN_OPENCODE="2.0.0"   # v1 no longer supports free models (upstream: v2 fixes it)
BIONIC_REPO="bd-loser/opencode-bionic"

# Never `set -e`: every failure below is handled explicitly, and a bare
# exit in the middle would leave the phone half-configured.
set -uo pipefail

# ── Logging ──────────────────────────────────────────────────────
LOG_FILE="${OPENCODE_MOBILE_LOG:-$HOME/opencode-mobile-install.log}"
: >"$LOG_FILE" 2>/dev/null || LOG_FILE=/dev/null

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true; }

c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'
c_b=$'\033[1m';    c_d=$'\033[2m';     c_x=$'\033[0m'

ok()    { printf '%s  [ OK ] %s%s\n'    "$c_g" "$*" "$c_x"; log "[ok] $*"; }
skip()  { printf '%s  [skip] %s%s\n'    "$c_y" "$*" "$c_x"; log "[skip] $*"; }
warn()  { printf '%s  [warn] %s%s\n'    "$c_y" "$*" "$c_x"; log "[warn] $*"; }
fail()  { printf '%s  [FAIL] %s%s\n'    "$c_r" "$*" "$c_x"; log "[fail] $*"; }
info()  { printf '         %s\n' "$*"; log "[..] $*"; }
step()  { printf '\n%s==> %s%s\n' "$c_b" "$*" "$c_x"; log "=== $* ==="; }

die() { fail "$*"; printf '\n%sFull log: %s%s\n' "$c_d" "$LOG_FILE" "$c_x"; exit 1; }

# ── TTY handling ─────────────────────────────────────────────────
# When invoked as `curl ... | bash`, stdin IS the script, so any bare
# `read` would swallow the rest of the installer. Everything interactive
# goes through /dev/tty instead.
TTY_IN=""
if [ -r /dev/tty ] && [ -w /dev/tty ]; then TTY_IN=/dev/tty; fi

have_tty() { [ -n "$TTY_IN" ]; }

# ask <prompt> <default>  -> echoes the answer
ask() {
  local prompt="$1" default="${2:-}" reply=""
  if [ "${OPENCODE_MOBILE_YES:-0}" = "1" ] || ! have_tty; then
    printf '%s\n' "$default"; return 0
  fi
  printf '%s' "${c_b}    $prompt ${c_d}[$default]${c_x}${c_b}: ${c_x}" >&2
  IFS= read -r reply <"$TTY_IN" || reply=""
  reply="$(printf '%s' "$reply" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  printf '%s\n' "${reply:-$default}"
}

# ── Version helpers (pure bash, no sort -V dependency) ───────────
# ver_ge A B  -> true if A >= B
ver_ge() {
  local IFS=. i x y
  local a=($1) b=($2)
  for ((i = 0; i < ${#b[@]}; i++)); do
    x="${a[i]:-0}"; y="${b[i]:-0}"
    x="${x//[^0-9]/}"; y="${y//[^0-9]/}"
    ((10#${x:-0} > 10#${y:-0})) && return 0
    ((10#${x:-0} < 10#${y:-0})) && return 1
  done
  return 0
}

# A clean release version is exactly X.Y.Z. The free tier reads the client
# version out of the User-Agent header and REJECTS anything that is not a
# plain release string — `2.2.6-dev.f1aacaba`, `2.2.6.r12.g88c6c7a` and
# `2.2.7-8` all fail with a FreeTierError even though the code is new
# enough. So we validate the string, not just the number.
is_clean_semver() { printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; }

# ══════════════════════════════════════════════════════════════════
#  Banner
# ══════════════════════════════════════════════════════════════════
printf '\n'
printf '%s\n' "${c_b}════════════════════════════════════════════════${c_x}"
printf '%s\n' "${c_b}   opencode-mobile  v${PACKAGE_VERSION}${c_x}"
printf '%s\n'   "   opencode AI coding agent for Android (Termux)"
printf '%s\n'   "   Latest stable opencode + free models + memory"
printf '%s\n'   "   Brought to you by @FeaturisticLeaks X @slixki"
printf '%s\n' "${c_b}════════════════════════════════════════════════${c_x}"
log "install.sh v$PACKAGE_VERSION started"

# ══════════════════════════════════════════════════════════════════
#  1. Environment checks
# ══════════════════════════════════════════════════════════════════
step "1/9  Checking your device"

if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-/nonexistent}" ]; then
  if [ -d /data/data/com.termux/files/usr ]; then
    PREFIX=/data/data/com.termux/files/usr
  else
    die "This installer runs only inside Termux on Android.
         Install Termux from F-Droid (NOT Google Play), open it, then re-run:
         curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash"
  fi
fi
ok "Termux detected  ($PREFIX)"

# Architecture: trust dpkg, not `uname -m`. Some Android emulators report
# aarch64 from uname while their package set is actually x86_64.
pkg_arch="$(dpkg --print-architecture 2>/dev/null || true)"
[ -z "$pkg_arch" ] && pkg_arch="$(uname -m 2>/dev/null || true)"
case "$pkg_arch" in
  aarch64|arm64) ok "Architecture: $pkg_arch (supported)" ;;
  *)
    die "Unsupported architecture: ${pkg_arch:-unknown}
         opencode for Termux is built for aarch64 (64-bit ARM) only.
         It cannot run on x86_64 emulators (MuMu, GameLoop, BlueStacks)
         or on 32-bit devices. Use a real ARM64 phone."
    ;;
esac

# Rough space check: ~35 MB download + ~180 MB installed.
if command -v df >/dev/null 2>&1; then
  free_kb="$(df -Pk "$PREFIX" 2>/dev/null | awk 'NR==2 {print $4}')"
  if [ -n "${free_kb:-}" ] && [ "$free_kb" -lt 400000 ] 2>/dev/null; then
    warn "Only $((free_kb / 1024)) MB free — opencode needs about 250 MB."
    info "Free up space if the install fails later."
  else
    ok "Free space: $(( ${free_kb:-0} / 1024 )) MB"
  fi
fi

# ── curl must actually run. A partial Termux upgrade can leave it
#    unable to load its libraries (missing-symbol errors).
curl_ok() { command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1; }

repair_curl() {
  warn "curl is broken (usually after a partial Termux upgrade). Repairing..."
  info "This runs a full package upgrade and can take a few minutes."
  apt update >>"$LOG_FILE" 2>&1
  apt full-upgrade -y >>"$LOG_FILE" 2>&1
}

if curl_ok; then
  ok "curl works"
else
  command -v curl >/dev/null 2>&1 || pkg install -y curl >>"$LOG_FILE" 2>&1
  if curl_ok; then ok "curl installed"; else
    repair_curl
    curl_ok || die "curl could not be repaired. Run manually:
         apt update && apt full-upgrade -y
       then re-run this installer."
    ok "curl repaired"
  fi
fi

# ══════════════════════════════════════════════════════════════════
#  2. Prerequisites
# ══════════════════════════════════════════════════════════════════
step "2/9  Installing prerequisites"

info "Refreshing package lists..."
pkg update -y >>"$LOG_FILE" 2>&1 && ok "package list updated" || warn "pkg update had issues (continuing)"

# ripgrep  — opencode's grep tool needs it
# git      — /undo and /redo are git-backed, so projects need it
# curl, ca-certificates, coreutils, tar, unzip — download + verify + extract
# nodejs-lts — not needed by opencode itself; kept for npm-based project tooling
# openssh    — git over ssh (optional)
PREREQS="curl ca-certificates coreutils tar unzip git ripgrep nodejs-lts openssh"
info "Installing: $PREREQS"
if pkg install -y $PREREQS >>"$LOG_FILE" 2>&1; then
  ok "prerequisites installed"
else
  warn "some prerequisites failed — continuing (details in the log)"
fi

# A package upgrade can break curl again; re-check before we depend on it.
if curl_ok; then
  ok "curl still works"
else
  repair_curl
  curl_ok || die "curl broke during the upgrade and could not be repaired."
  ok "curl repaired"
fi

command -v sha256sum >/dev/null 2>&1 && ok "sha256sum available (downloads will be verified)" \
                                     || warn "sha256sum missing — checksum verification will be skipped"

# Shared storage (optional; only needed for AIDE/AndroidIDE projects).
if [ -d "$HOME/storage" ]; then
  ok "shared storage already available"
elif command -v termux-setup-storage >/dev/null 2>&1; then
  info "A permission dialog may appear — tap ALLOW. (Optional; safe to skip.)"
  printf 'y\n' | termux-setup-storage >/dev/null 2>&1
  [ -d "$HOME/storage" ] && ok "shared storage granted" || skip "shared storage not granted (optional)"
else
  skip "termux-setup-storage not available (optional)"
fi

# ══════════════════════════════════════════════════════════════════
#  3. Install opencode
# ══════════════════════════════════════════════════════════════════
step "3/9  Installing opencode v2 (latest stable)"

CACHE="$HOME/.cache/opencode-mobile"
mkdir -p "$CACHE"

# Extract a clean X.Y.Z from `opencode --version`. Accepts a bare version
# ("2.2.6") and the two common prefixed forms ("opencode 2.2.6",
# "opencode v2.2.6", "opencode/2.2.6"). Anything carrying a prerelease or
# build suffix ("2.2.6-dev.abc", "2.2.6 (dc2ffcf8)") yields nothing usable,
# which version_acceptable() then rejects — the free tier refuses those.
opencode_version() {
  local line rest
  line="$(opencode --version 2>/dev/null | head -n1 | tr -d '\r')"
  # trim leading/trailing whitespace
  line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
  # strip a leading 'v'
  line="${line#v}"
  case "$line" in
    *.*.*) : ;;                 # has at least X.Y.Z shape; validate strictly later
    *) return 1 ;;
  esac
  case "$line" in
    *[[:space:]]*|*/*)
      # take the last whitespace/slash-separated token
      rest="${line##*[[:space:]/]}"
      rest="${rest#v}"
      printf '%s' "$rest" ;;
    *) printf '%s' "$line" ;;
  esac
}

# Accept only a clean release string that is >= MIN_OPENCODE.
version_acceptable() {
  local v="$1"
  [ -n "$v" ] || return 1
  if ! is_clean_semver "$v"; then
    warn "version string '$v' is not a plain release number."
    info "The free tier reads the version from the client User-Agent and"
    info "rejects dev/git-suffixed builds, so this one would still fail."
    return 1
  fi
  if ! ver_ge "$v" "$MIN_OPENCODE"; then
    warn "opencode $v is older than $MIN_OPENCODE."
    info "OpenCode v1 no longer supports free models — v2 is required."
    return 1
  fi
  return 0
}

# Remove leftovers from the old guysoft/opencode-termux layout (a ~180 MB binary
# under $PREFIX/libexec plus three .so files) and from the retired npm
# fallback (opencode-termux — v1-only, and v1 no longer supports free models).
# Without this they waste storage or shadow the v2 binary on PATH.
#
# Only ever called AFTER a new opencode has been installed AND validated.
# Purging first would mean a failed download leaves the user with no opencode at
# all, rather than the older build they started with.
purge_legacy_native() {
  local removed=false
  if [ -e "$PREFIX/libexec/opencode/opencode.bin" ]; then
    info "Removing the previous native build (frees ~180 MB)..."
    rm -rf "$PREFIX/libexec/opencode" 2>/dev/null
    rm -f  "$PREFIX/lib/libtagfix.so" "$PREFIX/lib/libc++_shared.so" \
           "$PREFIX/lib/libopentui.so" 2>/dev/null
    ok "previous native build removed"; removed=true
  fi
  if command -v npm >/dev/null 2>&1 \
     && npm ls -g --depth=0 2>/dev/null | grep -q 'opencode-termux'; then
    info "Removing the retired npm package 'opencode-termux' (v1 — no free models)..."
    if npm uninstall -g opencode-termux >>"$LOG_FILE" 2>&1; then
      ok "retired npm package removed"; removed=true
    else
      warn "could not remove 'opencode-termux' — remove it by hand: npm uninstall -g opencode-termux"
    fi
  fi
  [ "$removed" = false ] && return 0
}

# ── Source A: bd-loser/opencode-bionic — native Bionic .deb, built from
#    the upstream release tag, so it reports a clean semver. Preferred.
resolve_bionic_tag() {
  local tag=""
  if [ -n "${OPENCODE_VERSION:-}" ]; then
    printf 'v%s\n' "${OPENCODE_VERSION#v}"; return 0
  fi
  # /releases/latest excludes prereleases, so this can never return a -dev build.
  tag="$(curl -fsSL --max-time 25 \
        "https://api.github.com/repos/$BIONIC_REPO/releases/latest" 2>/dev/null \
        | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
        | head -n1 | sed 's/.*"\([^"]*\)"$/\1/')"
  if [ -z "$tag" ]; then
    # api.github.com is blocked on some networks; follow the web redirect.
    tag="$(curl -fsSI --max-time 25 -o /dev/null -w '%{redirect_url}' \
          "https://github.com/$BIONIC_REPO/releases/latest" 2>/dev/null \
          | grep -oE '/tag/v[^/?]+' | sed 's|/tag/||')"
  fi
  [ -n "$tag" ] && printf '%s\n' "$tag"
}

install_from_bionic() {
  local tag ver deb url base
  tag="$(resolve_bionic_tag)" || { fail "could not resolve a release tag"; return 1; }
  [ -n "$tag" ] || { fail "could not resolve a release tag"; return 1; }
  ver="${tag#v}"

  case "$ver" in
    *-dev.*|*-*)
      fail "refusing dev/prerelease build '$ver' — its version string is rejected by the free tier."
      return 1 ;;
  esac

  info "opencode $ver from $BIONIC_REPO (native Bionic build)"
  deb="opencode_${ver}_aarch64.deb"
  base="https://github.com/$BIONIC_REPO/releases/download/$tag"
  url="$base/$deb"

  # -C - resumes a partial download; the cache dir survives re-runs, which
  # matters a lot on a flaky mobile connection with a 35 MB file.
  info "Downloading $deb..."
  if ! curl -fL --retry 3 --retry-delay 2 -C - --progress-bar \
        -o "$CACHE/$deb" "$url" >>"$LOG_FILE" 2>&1; then
    rm -f "$CACHE/$deb"
    fail "download failed ($url)"
    return 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    info "Verifying SHA-256..."
    if curl -fsSL --retry 2 --max-time 30 -o "$CACHE/SHA256SUMS" "$base/SHA256SUMS" 2>>"$LOG_FILE"; then
      if ( cd "$CACHE" && sha256sum -c --ignore-missing SHA256SUMS 2>&1 | grep -F "$deb" | grep -q OK ); then
        ok "checksum verified"
      else
        rm -f "$CACHE/$deb"
        fail "checksum mismatch — refusing to install a corrupt download"
        return 1
      fi
    else
      warn "could not fetch SHA256SUMS — installing without verification"
    fi
  fi

  info "Installing with dpkg..."
  if ! dpkg -i "$CACHE/$deb" >>"$LOG_FILE" 2>&1; then
    # Older releases were zstd-compressed; Termux's dpkg may need the binary.
    if head -c 200 "$CACHE/$deb" 2>/dev/null | tr -d '\0' | grep -q 'tar.zst'; then
      info "archive is zstd-compressed — installing zstd and retrying"
      pkg install -y zstd >>"$LOG_FILE" 2>&1
      dpkg -i "$CACHE/$deb" >>"$LOG_FILE" 2>&1 || { fail "dpkg install failed"; return 1; }
    else
      fail "dpkg install failed (see log)"
      return 1
    fi
  fi
  hash -r 2>/dev/null
  command -v opencode >/dev/null 2>&1 || { fail "opencode not on PATH after install"; return 1; }
  ok "installed to $(command -v opencode)"
}

# ── Source B: the same release, raw ELF binary. ──────────────────
# The .deb ships exactly one file — usr/bin/opencode, a statically
# self-contained Bionic binary — so if dpkg is broken we can place that
# same file in $PREFIX/bin and get a byte-identical result. Checksum
# verified against the same SHA256SUMS.
install_from_bionic_binary() {
  local tag ver url base
  tag="$(resolve_bionic_tag)" || { fail "could not resolve a release tag"; return 1; }
  [ -n "$tag" ] || { fail "could not resolve a release tag"; return 1; }
  ver="${tag#v}"

  case "$ver" in
    *-dev.*|*-*)
      fail "refusing dev/prerelease build '$ver' — its version string is rejected by the free tier."
      return 1 ;;
  esac

  base="https://github.com/$BIONIC_REPO/releases/download/$tag"
  url="$base/opencode"
  info "opencode $ver from $BIONIC_REPO (raw binary — used when dpkg fails)"

  info "Downloading the raw binary (~200 MB)..."
  # Saved under the asset's own name so sha256sum -c can verify it against
  # SHA256SUMS, exactly like the .deb path does.
  if ! curl -fL --retry 3 --retry-delay 2 -C - --progress-bar \
        -o "$CACHE/opencode" "$url" >>"$LOG_FILE" 2>&1; then
    rm -f "$CACHE/opencode"
    fail "download failed ($url)"
    return 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    info "Verifying SHA-256..."
    if curl -fsSL --retry 2 --max-time 30 -o "$CACHE/SHA256SUMS" "$base/SHA256SUMS" 2>>"$LOG_FILE"; then
      # SHA256SUMS also lists the .deb, which is not in the cache —
      # sha256sum's --ignore-missing skips absent files by design.
      if ( cd "$CACHE" && sha256sum -c --ignore-missing SHA256SUMS 2>&1 | grep -E '^opencode: OK' >/dev/null ); then
        ok "checksum verified"
      else
        rm -f "$CACHE/opencode"
        fail "checksum mismatch — refusing to install a corrupt download"
        return 1
      fi
    else
      warn "could not fetch SHA256SUMS — installing without verification"
    fi
  fi

  chmod 755 "$CACHE/opencode"
  if ! "$CACHE/opencode" --version >/dev/null 2>&1; then
    rm -f "$CACHE/opencode"
    fail "the downloaded binary did not run"
    return 1
  fi
  mv "$CACHE/opencode" "$PREFIX/bin/opencode" || { rm -f "$CACHE/opencode"; fail "could not write $PREFIX/bin/opencode"; return 1; }
  hash -r 2>/dev/null
  command -v opencode >/dev/null 2>&1 || { fail "opencode not on PATH after install"; return 1; }
  ok "installed to $PREFIX/bin/opencode (not tracked by dpkg)"
}

installed_ok=false
source_used=""
want="${OPENCODE_SOURCE:-auto}"

try_source() {
  local name="$1"; shift
  info "── trying source: $name"
  if "$@"; then
    local v; v="$(opencode_version)"
    if version_acceptable "$v"; then
      ok "opencode $v is installed and satisfies the free tier (>= $MIN_OPENCODE)"
      installed_ok=true; source_used="$name"; return 0
    fi
    warn "source '$name' produced an unusable version ('$v')"
  else
    fail "source '$name' did not succeed"
  fi
  return 1
}

# If a good opencode is already present, do not reinstall — just confirm.
if command -v opencode >/dev/null 2>&1; then
  cur="$(opencode_version)"
  if version_acceptable "$cur"; then
    ok "opencode $cur already installed and up to date"
    installed_ok=true; source_used="existing"
  else
    warn "existing opencode ('$cur') will not work with the free tier — replacing it"
  fi
fi

if [ "$installed_ok" != true ]; then
  case "$want" in
    bionic) try_source "bionic-deb" install_from_bionic ;;
    binary) try_source "bionic-binary" install_from_bionic_binary ;;
    npm)
      warn "OPENCODE_SOURCE=npm was removed — the npm package (opencode-termux) is v1-only, and v1 no longer supports free models."
      info "Using the Bionic sources instead."
      try_source "bionic-deb" install_from_bionic \
        || try_source "bionic-binary" install_from_bionic_binary ;;
    auto)
      try_source "bionic-deb" install_from_bionic \
        || try_source "bionic-binary" install_from_bionic_binary
      ;;
    *) warn "unknown OPENCODE_SOURCE='$want' — using auto";
       try_source "bionic-deb" install_from_bionic || try_source "bionic-binary" install_from_bionic_binary ;;
  esac
fi

# A new opencode is installed and validated, so the old native build's orphaned
# files can now be reclaimed safely.
if [ "$installed_ok" = true ] && [ "$source_used" != "existing" ]; then
  purge_legacy_native
fi

if [ "$installed_ok" != true ]; then
  printf '\n'
  fail "Could not install opencode $MIN_OPENCODE or newer."
  info  "Both sources failed (the .deb and the raw binary). This is usually a network problem."
  info  ""
  info  "Try again — the installer resumes partial downloads:"
  info  "    curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash"
  info  ""
  info  "Or download the .deb by hand from the release page, then install it:"
  info  "    https://github.com/$BIONIC_REPO/releases/latest"
  info  "    dpkg -i opencode_*_aarch64.deb"
  info  ""
  info  "Note: the npm package 'opencode-termux' is NOT used as a fallback —"
  info  "it ships v1, and v1 no longer supports free models."
  die "See $LOG_FILE for details."
fi

# ══════════════════════════════════════════════════════════════════
#  4. Config, rules and memory template
# ══════════════════════════════════════════════════════════════════
step "4/9  Writing config, rules and memory template"

mkdir -p "$HOME/.config/opencode" "$HOME/opencode"

# ==== BEGIN GENERATED EMBEDDED CONFIG ====
# Generated from config/ by build-package.sh — do not edit by hand.
# config/ is the single source of truth; install.sh embeds a copy because
# it is piped straight into bash and cannot read sibling files.
write_opencode_json() {
cat >"$1" <<'__OC_JSON__'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/deepseek-v4.1-flash-free",
  "agents": {
    "title": {
      "model": "opencode/big-pickle"
    }
  }
}
__OC_JSON__
}

write_agents_md() {
cat >"$1" <<'__OC_AGENTS__'
# opencode-mobile — Global Rules

You are running **opencode on Android (Termux)** via the opencode-mobile package.
Keep answers short and mobile-friendly, and always protect the user's work.

## Greeting (once per session)

At the start of a **new** session only, the first line you output must be exactly:

> Brought to you by @FeaturisticLeaks X @slixki

Then one short friendly sentence asking what they want to build. Do **not** repeat
the greeting later in the same session, and do not add it to code, commit
messages, files you create, or `Memory.md`.

## Memory system

Scope: **only for projects under `~/opencode/`.**

1. On first entering a project folder under `~/opencode/`, if `Memory.md` does not
   exist, create it from `~/opencode/Memory.template.md` (fill in project name/goal).
2. Update `Memory.md` at natural checkpoints — after completing a task, making a
   decision, or before the session ends. Not after every single edit; batching
   keeps token use low on a phone.
3. Append dated entries. Never delete history.
4. Keep each entry to a few lines: what changed, why, files touched, what's next.

**Outside `~/opencode/`** (e.g. `~/storage/shared/AppProjects/...`, an AndroidIDE
project, or any existing git repo): do **not** create `Memory.md` unless the user
explicitly asks. Those are other people's project trees — adding files can pollute
a repository and get committed by accident.

## If a provider or model error appears

The free OpenCode models are limited-time and rate-limited, and the free roster
rotates. When you see a provider/Console error, "free", "rate limit", or
"quota exceeded":

1. Do **not** retry the same request in a loop — it will keep failing.
2. Tell the user to press `/models` and pick a different free model
   (e.g. `opencode/deepseek-v4.1-flash-free`, `opencode/big-pickle`,
   `opencode/glm-5.3-flash-free`).
3. If every free model fails, mention that **OpenCode v1 no longer supports
   free models** — a v2 client connected to an OpenCode Console account (or
   with `OPENCODE_API_KEY` set) is required. Re-running the one-line installer
   updates opencode to the latest v2.
4. Long sessions fail most often during **compaction**. Suggest `/compact` early,
   or `/new` to start a fresh session, rather than letting context fill up.

## Working style

- Prefer small, concrete edits over big rewrites.
- Run commands to verify your changes when you can.
- Keep output short — this is a phone screen. No walls of text.
- When starting a new project under `~/opencode/`, run `git init` and commit as
  you go. `/undo` and `/redo` only work inside a git repository.
__OC_AGENTS__
}

write_memory_template() {
cat >"$1" <<'__OC_MEMORY__'
# Memory — <Project Name>

> Managed by opencode. This is your project's memory — edit it freely.

## Project
- **Goal:** what are we building?
- **Last worked:** YYYY-MM-DD

## Progress Log
- YYYY-MM-DD: what happened

## Decisions
- choice made — why

## Next Steps
- what to do next time

## Open Questions
- anything unresolved
__OC_MEMORY__
}
# ==== END GENERATED EMBEDDED CONFIG ====

cfg="$HOME/.config/opencode/opencode.json"
tmp_cfg="$(mktemp 2>/dev/null || printf '%s' "$CACHE/opencode.json.tmp")"
write_opencode_json "$tmp_cfg"
if [ -f "$cfg" ]; then
  if cmp -s "$cfg" "$tmp_cfg" 2>/dev/null; then
    rm -f "$tmp_cfg"
    skip "opencode.json already up to date"
  else
    # Prune old backups first so re-runs don't accumulate unbounded files
    # Keep the 2 most recent; the new one will make it 3 at most.
    if ls "$cfg".bak.* >/dev/null 2>&1; then
      ls -t "$cfg".bak.* 2>/dev/null | tail -n +3 | xargs rm -f 2>/dev/null || true
    fi
    cp "$cfg" "$cfg.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null \
      && info "your existing opencode.json was backed up"
    mv "$tmp_cfg" "$cfg" && ok "opencode.json      -> ~/.config/opencode/"
  fi
else
  mv "$tmp_cfg" "$cfg" && ok "opencode.json      -> ~/.config/opencode/"
fi
write_agents_md "$HOME/.config/opencode/AGENTS.md" && ok "AGENTS.md          -> ~/.config/opencode/"
write_memory_template "$HOME/opencode/Memory.template.md" && ok "Memory.template.md -> ~/opencode/"

# The old package also dropped a second AGENTS.md in ~/opencode and pointed
# `instructions` at it. opencode already loads ~/.config/opencode/AGENTS.md
# globally, so that injected the same rules twice. Remove the duplicate.
if [ -f "$HOME/opencode/AGENTS.md" ] && grep -q "opencode-mobile — Global Rules" "$HOME/opencode/AGENTS.md" 2>/dev/null; then
  rm -f "$HOME/opencode/AGENTS.md" && info "removed the duplicate ~/opencode/AGENTS.md"
fi

# ══════════════════════════════════════════════════════════════════
#  5. OpenCode Console account (free — needed for the free models)
# ══════════════════════════════════════════════════════════════════
step "5/9  OpenCode Console key (free)"

info "Since OpenCode 2, the built-in OpenCode provider needs a free Console"
info "account — anonymous access is gone. Sign up (free) and copy an API key:"
info "  https://opencode.ai/console/signup"
info "Without a key the free models will not appear in /models."

api_key="${OPENCODE_API_KEY:-}"
if [ -z "$api_key" ] && have_tty && [ "${OPENCODE_MOBILE_YES:-0}" != "1" ]; then
  printf '\n%s' "${c_b}    Paste your OpenCode key, or press Enter to skip: ${c_x}"
  IFS= read -r api_key <"$TTY_IN" || api_key=""
fi
api_key="$(printf '%s' "$api_key" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

if [ -n "$api_key" ]; then
  # Replace any previous key rather than appending a second export. Matches both
  # the current and the v1.3-era comment wording so re-running never stacks.
  sed -i '/^# OpenCode API key/d; /^export OPENCODE_API_KEY=/d' "$HOME/.bashrc" 2>/dev/null
  {
    printf '\n# OpenCode API key (opencode-mobile)\n'
    printf 'export OPENCODE_API_KEY="%s"\n' "$api_key"
  } >>"$HOME/.bashrc"
  chmod 600 "$HOME/.bashrc" 2>/dev/null
  ok "OPENCODE_API_KEY saved to ~/.bashrc"
else
  skip "no key added — add one later with /connect (the free models need it)"
fi

# ══════════════════════════════════════════════════════════════════
#  6. The AI shortcut
# ══════════════════════════════════════════════════════════════════
step "6/9  Adding the AI shortcut"

# Replaces the old shortcut, which always cd'd to ~/opencode (the PARENT of
# every project). That collapsed all projects into one opencode project root
# and broke per-project memory and /sessions. Now:
#   AI          -> stay in the current project; from $HOME go to ~/opencode
#   AI myapp    -> create/enter ~/opencode/myapp
sed -i '/^# --- AI shortcut (opencode-mobile)/,/^ai() { AI; }$/d' "$HOME/.bashrc" 2>/dev/null

cat >>"$HOME/.bashrc" <<'SHORTCUT_EOF'

# --- AI shortcut (opencode-mobile): type AI to open opencode ---
AI() {
  local dir="$PWD"
  if [ -n "${1:-}" ]; then
    dir="$HOME/opencode/$1"
    mkdir -p "$dir"
  elif [ "$PWD" = "$HOME" ] || [ "$PWD" = "$HOME/opencode" ]; then
    dir="$HOME/opencode"
  fi
  cd "$dir" 2>/dev/null || cd "$HOME/opencode" 2>/dev/null || true
  opencode
}
ai() { AI; }
SHORTCUT_EOF

# Replacing blocks across re-runs can leave runs of blank lines behind.
# `cat -s` squeezes them without touching any real content.
if [ -f "$HOME/.bashrc" ] && command -v cat >/dev/null 2>&1; then
  cat -s "$HOME/.bashrc" >"$HOME/.bashrc.oc.tmp" 2>/dev/null \
    && mv "$HOME/.bashrc.oc.tmp" "$HOME/.bashrc" 2>/dev/null \
    && chmod 600 "$HOME/.bashrc" 2>/dev/null
  rm -f "$HOME/.bashrc.oc.tmp" 2>/dev/null
fi
ok "type 'AI' to open opencode  —  'AI myapp' opens/creates that project"

# ══════════════════════════════════════════════════════════════════
#  7. Termux keyboard (⌨) toggle button
# ══════════════════════════════════════════════════════════════════
step "7/9  Adding the keyboard (⌨) toggle button"

if [ "${OPENCODE_MOBILE_NO_KEYBOARD:-0}" = "1" ]; then
  skip "OPENCODE_MOBILE_NO_KEYBOARD=1 — leaving termux.properties alone"
else
  mkdir -p "$HOME/.termux"
  props="$HOME/.termux/termux.properties"
  touch "$props" 2>/dev/null

  # Match the `extra-keys` key exactly. The old pattern also matched
  # `extra-keys-style`, which sent users down a branch that always failed.
  active_line="$(grep -E '^[[:space:]]*extra-keys[[:space:]]*=' "$props" 2>/dev/null | head -n1)"

  inject_keyboard() {
    # Two-row form  extra-keys = [[...]]  and one-row form  extra-keys = [...]
    # are both handled; the old installer only handled the two-row form, so the
    # very common one-row config failed and left the user with no ⌨ button.
    local tmp="$props.tmp.$$"
    if printf '%s\n' "$active_line" | grep -q '\[\['; then
      sed "s/^\([[:space:]]*extra-keys[[:space:]]*=[[:space:]]*\)\[\[/\1[['KEYBOARD',/" \
          "$props" >"$tmp" 2>/dev/null
    else
      sed "s/^\([[:space:]]*extra-keys[[:space:]]*=[[:space:]]*\)\[/\1['KEYBOARD',/" \
          "$props" >"$tmp" 2>/dev/null
    fi
    if [ -s "$tmp" ] && grep -q "KEYBOARD" "$tmp"; then
      cp "$props" "$props.opencode-backup" 2>/dev/null
      mv "$tmp" "$props"
      return 0
    fi
    rm -f "$tmp"
    return 1
  }

  if printf '%s' "$active_line" | grep -q "KEYBOARD"; then
    skip "your key row already has a ⌨ button"
  elif [ -n "$active_line" ]; then
    if inject_keyboard; then
      ok "⌨ button added to your existing key row"
      info "backup: ~/.termux/termux.properties.opencode-backup"
    else
      # Never leave the user without a ⌨ button: append our row instead. Java
      # Properties takes the last value for a duplicate key, so this wins.
      cp "$props" "$props.opencode-backup" 2>/dev/null
      cat >>"$props" <<'KEYS_EOF'

# Added by opencode-mobile: keyboard (⌨) toggle in the key row
extra-keys = [['KEYBOARD','ESC','TAB','CTRL','ALT'],['LEFT','DOWN','UP','RIGHT','PGUP','PGDN','HOME','END']]
KEYS_EOF
      warn "could not edit your extra-keys line, so a new row was appended"
      info "your original is saved at ~/.termux/termux.properties.opencode-backup"
    fi
  else
    cat >>"$props" <<'KEYS_EOF'

# Added by opencode-mobile: keyboard (⌨) toggle in the key row
# Tap it inside opencode whenever the phone keyboard hides.
extra-keys = [['KEYBOARD','ESC','TAB','CTRL','ALT'],['LEFT','DOWN','UP','RIGHT','PGUP','PGDN','HOME','END']]
KEYS_EOF
    ok "⌨ button added to Termux's key row"
  fi

  termux-reload-settings >/dev/null 2>&1 || true
  info "If ⌨ does not appear: long-press the screen -> More -> Extra keys,"
  info "or fully close Termux (swipe away) and reopen it."
fi

# ══════════════════════════════════════════════════════════════════
#  8. Verify
# ══════════════════════════════════════════════════════════════════
step "8/9  Verifying the installation"

final_v="$(opencode_version)"
if command -v opencode >/dev/null 2>&1 && [ -n "$final_v" ]; then
  ok "opencode $final_v  ($(command -v opencode))"
  if is_clean_semver "$final_v" && ver_ge "$final_v" "$MIN_OPENCODE"; then
    ok "meets the free-tier requirement (>= $MIN_OPENCODE, clean release version)"
  else
    warn "'$final_v' may still be rejected by the free tier"
  fi
else
  fail "opencode did not run — restart Termux and try: opencode --version"
fi

[ -f "$HOME/.config/opencode/opencode.json" ] && ok "config in place"
grep -q '^AI()' "$HOME/.bashrc" 2>/dev/null    && ok "AI shortcut in ~/.bashrc"
command -v rg >/dev/null 2>&1                  && ok "ripgrep available"

# ══════════════════════════════════════════════════════════════════
#  9. Done
# ══════════════════════════════════════════════════════════════════
step "9/9  Finished"
printf '\n'
printf '%s\n' "${c_b}  opencode-mobile is ready.${c_x}"
printf '\n'
printf '%s\n' "  1) Close Termux and reopen it  (or run:  source ~/.bashrc)"
printf '%s\n' "  2) Type:  ${c_b}AI${c_x}"
printf '%s\n' "     ${c_d}AI myapp  -> opens or creates ~/opencode/myapp${c_x}"
printf '%s\n' "  3) Ask for what you want in plain English."
printf '\n'
printf '%s\n' "  ${c_b}If the free models do not appear in /models:${c_x}"
printf '%s\n' "    - sign up at https://opencode.ai/console/signup (free) and paste your key"
printf '%s\n' "      (inside opencode: /connect -> OpenCode), or re-run this installer"
printf '%s\n' "    - press /models and pick another free model"
printf '%s\n' "    - on long chats press /compact early, or /new for a fresh session"
printf '%s\n' "    - re-run this one line to update opencode again"
printf '\n'
if [ -z "$api_key" ]; then
  printf '%s\n' "  No key pasted — sign up at https://opencode.ai/console/signup and run /connect"
  printf '%s\n' "  inside opencode to enable the free models."
  printf '\n'
fi
printf '%s\n' "  Installed: opencode $final_v  via $source_used"
printf '%s\n' "  Log:       $LOG_FILE"
printf '\n'
printf '%s\n' "  ${c_b}Brought to you by @FeaturisticLeaks X @slixki${c_x}"
printf '\n'
ok "Install finished — happy coding!"
log "completed successfully"
exit 0
