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
#  Installs opencode (latest stable, >= 1.18.0), its prerequisites, the
#  free-model config, the memory system, the `AI` shortcut and the Termux
#  keyboard (⌨) toggle button. Safe to re-run; it updates in place.
#
#  Brought to you by @FeaturisticLeaks X @slixki
#
# ── Environment overrides (all optional) ─────────────────────────
#   OPENCODE_VERSION=1.18.31     pin an exact opencode version
#   OPENCODE_SOURCE=auto         auto | bionic | npm   (default auto)
#   OPENCODE_API_KEY=sk-...      supply the Zen key non-interactively
#   OPENCODE_MOBILE_YES=1        never prompt (assume default answers)
#   OPENCODE_MOBILE_NO_KEYBOARD=1  do not touch termux.properties
# ──────────────────────────────────────────────────────────────────

PACKAGE_VERSION="2.0.0"
MIN_OPENCODE="1.18.0"   # the Zen free tier rejects anything older
BIONIC_REPO="bd-loser/opencode-bionic"
NPM_FALLBACK_PKG="opencode-termux"

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

# A clean release version is exactly X.Y.Z. The Zen free-tier gate parses
# the version out of the client User-Agent and REJECTS anything that is
# not a plain release string — `1.18.31-dev.f1aacaba`, `1.18.31.r12.g88c6c7a`
# and `1.18.4-8` all fail with a FreeTierError even though the code is new
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
# nodejs-lts — optional, but enables the npm fallback source and general use
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
step "3/9  Installing opencode (latest stable)"

CACHE="$HOME/.cache/opencode-mobile"
mkdir -p "$CACHE"

opencode_version() { opencode --version 2>/dev/null | head -n1 | tr -d '\r'; }

# Accept only a clean release string that is >= MIN_OPENCODE.
version_acceptable() {
  local v="$1"
  [ -n "$v" ] || return 1
  if ! is_clean_semver "$v"; then
    warn "version string '$v' is not a plain release number."
    info "The Zen free tier reads the version from the client User-Agent and"
    info "rejects dev/git-suffixed builds, so this one would still fail."
    return 1
  fi
  if ! ver_ge "$v" "$MIN_OPENCODE"; then
    warn "opencode $v is older than $MIN_OPENCODE."
    info "The Zen free tier requires $MIN_OPENCODE or newer."
    return 1
  fi
  return 0
}

# Remove leftovers from the old guysoft/opencode-termux layout (a ~180 MB binary
# under $PREFIX/libexec plus three .so files). Without this they waste storage.
#
# Only ever called AFTER a new opencode has been installed AND validated.
# Purging first would mean a failed download leaves the user with no opencode at
# all, rather than the older build they started with.
purge_legacy_native() {
  [ -e "$PREFIX/libexec/opencode/opencode.bin" ] || return 0
  info "Removing the previous native build (frees ~180 MB)..."
  rm -rf "$PREFIX/libexec/opencode" 2>/dev/null
  rm -f  "$PREFIX/lib/libtagfix.so" "$PREFIX/lib/libc++_shared.so" \
         "$PREFIX/lib/libopentui.so" 2>/dev/null
  ok "previous native build removed"
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

# ── Source B: C04-wq/opencode-termux via npm — repackages the OFFICIAL
#    musl build with a patchelf'd loader. Heavier, but independent.
install_from_npm() {
  command -v npm >/dev/null 2>&1 || { fail "npm not available"; return 1; }
  info "Trying the npm package '$NPM_FALLBACK_PKG' (official musl build + Termux loader)..."
  npm install -g "$NPM_FALLBACK_PKG" >>"$LOG_FILE" 2>&1 || { fail "npm install failed"; return 1; }
  hash -r 2>/dev/null
  command -v opencode >/dev/null 2>&1 || { fail "opencode not on PATH after npm install"; return 1; }
  # First run provisions ~/.opencode (download + verify). Give it room.
  info "First run provisions the runtime — this may take a minute..."
  opencode --version >/dev/null 2>&1
  ok "installed via npm"
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
    npm)    try_source "npm-musl"  install_from_npm ;;
    auto)
      try_source "bionic-deb" install_from_bionic \
        || try_source "npm-musl" install_from_npm
      ;;
    *) warn "unknown OPENCODE_SOURCE='$want' — using auto"; 
       try_source "bionic-deb" install_from_bionic || try_source "npm-musl" install_from_npm ;;
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
  info  "Both sources failed. This is usually a network problem."
  info  ""
  info  "Try again — the installer resumes partial downloads:"
  info  "    curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/install.sh | bash"
  info  ""
  info  "Or install the fallback source by hand:"
  info  "    pkg install -y nodejs-lts && npm install -g $NPM_FALLBACK_PKG"
  info  ""
  info  "Note: the older guysoft/opencode-termux build (1.17.9) is NOT installed"
  info  "as a fallback, because it is below $MIN_OPENCODE and the free tier would"
  info  "reject it with the exact error you are trying to fix."
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
  "model": "opencode/deepseek-v4-flash-free",
  "small_model": "opencode/big-pickle",
  "provider": {
    "opencode": {
      "options": {
        "apiKey": "{env:OPENCODE_API_KEY}",
        "baseURL": "https://opencode.ai/zen/v1"
      },
      "models": {
        "deepseek-v4-flash-free": {
          "name": "DeepSeek V4 Flash (Zen free)",
          "limit": { "context": 200000, "output": 128000 }
        },
        "big-pickle": {
          "name": "Big Pickle (Zen free)",
          "limit": { "context": 200000, "output": 32000 }
        },
        "mimo-v2.5-free": {
          "name": "MiMo V2.5 (Zen free)",
          "limit": { "context": 200000, "output": 32000 }
        },
        "nemotron-3-ultra-free": {
          "name": "Nemotron 3 Ultra (Zen free)",
          "limit": { "context": 1000000, "output": 128000 }
        },
        "nemotron-3.5-lightning-free": {
          "name": "Nemotron 3.5 Lightning (Zen free)",
          "limit": { "context": 262144, "output": 262144 }
        },
        "north-mini-code-free": {
          "name": "North Mini Code (Zen free)",
          "limit": { "context": 256000, "output": 64000 }
        },
        "ling-3.0-flash-free": {
          "name": "Ling 3.0 Flash (Zen free)",
          "limit": { "context": 262144, "output": 32768 }
        },
        "laguna-s-2.1-free": {
          "name": "Laguna S 2.1 (Zen free)",
          "limit": { "context": 256000, "output": 32000 }
        },
        "hy3-free": {
          "name": "Hy3 (Zen free)",
          "limit": { "context": 190000, "output": 64000 }
        }
      }
    },
    "google": {
      "options": {
        "apiKey": "{env:GEMINI_API_KEY}"
      }
    },
    "openrouter": {
      "options": {
        "apiKey": "{env:OPENROUTER_API_KEY}"
      }
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

The free OpenCode Zen tier is gated and rate-limited, and the free roster rotates.
When you see `FreeTierError`, "free tier", "rate limit", or "quota exceeded":

1. Do **not** retry the same request in a loop — it will keep failing.
2. Tell the user to press `/models` and pick a different free model
   (e.g. `opencode/big-pickle`, `opencode/mimo-v2.5-free`).
3. If every free model fails, mention that the free tier requires opencode
   **1.18.0 or newer**, and that re-running the one-line installer updates it.
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
#  5. API key (optional — the free tier also works anonymously)
# ══════════════════════════════════════════════════════════════════
step "5/9  OpenCode API key (optional)"

info "The Zen free models work without a key, but a free account key raises"
info "your rate limits. Get one (no card required): https://opencode.ai/auth"

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
  skip "no key added — free models still work; add one later with /connect"
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
printf '%s\n' "  ${c_b}If you still see a free-tier error:${c_x}"
printf '%s\n' "    - press /models and pick another free model"
printf '%s\n' "    - on long chats press /compact early, or /new for a fresh session"
printf '%s\n' "    - re-run this one line to update opencode again"
printf '\n'
if [ -z "$api_key" ]; then
  printf '%s\n' "  Optional: add a free key for higher limits at https://opencode.ai/auth"
  printf '%s\n' "  (inside opencode: /connect -> OpenCode Zen)"
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
