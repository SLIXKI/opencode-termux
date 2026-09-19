#!/usr/bin/env bash
#
# ══════════════════════════════════════════════════════════════════
#  opencode-mobile  —  uninstaller
# ══════════════════════════════════════════════════════════════════
#
#  One line (Termux):
#
#    curl -fsSL https://raw.githubusercontent.com/SLIXKI/opencode-termux/main/uninstall.sh | bash
#
#  Options:
#    OPENCODE_MOBILE_YES=1        do not prompt (keeps projects by default)
#    OPENCODE_MOBILE_DELETE_PROJECTS=1   also delete ~/opencode
#    OPENCODE_MOBILE_DELETE_DATA=1       also delete sessions + saved keys
#
#  Brought to you by @FeaturisticLeaks X @slixki
# ──────────────────────────────────────────────────────────────────

set -uo pipefail

c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'; c_b=$'\033[1m'; c_x=$'\033[0m'
ok()   { printf '%s  [ OK ] %s%s\n' "$c_g" "$*" "$c_x"; }
warn() { printf '%s  [warn] %s%s\n' "$c_y" "$*" "$c_x"; }
info() { printf '         %s\n' "$*"; }

TTY_IN=""
if [ -r /dev/tty ] && [ -w /dev/tty ]; then TTY_IN=/dev/tty; fi

confirm() {  # confirm <question> <default y|n>
  local q="$1" def="${2:-n}" reply=""
  if [ "${OPENCODE_MOBILE_YES:-0}" = "1" ] || [ -z "$TTY_IN" ]; then
    [ "$def" = "y" ] && return 0 || return 1
  fi
  printf '%s' "${c_b}    $q ${c_x}${c_b}[y/N]: ${c_x}" >&2
  IFS= read -r reply <"$TTY_IN" || reply=""
  case "$(printf '%s' "$reply" | tr 'A-Z' 'a-z')" in y|yes) return 0 ;; *) return 1 ;; esac
}

printf '\n%s\n' "${c_b}  Removing opencode-mobile${c_x}"
printf '%s\n'   "  Brought to you by @FeaturisticLeaks X @slixki"
printf '\n'

# ── Guard ────────────────────────────────────────────────────────
# Without this, an empty $PREFIX turns `rm -rf "$PREFIX/libexec/opencode"`
# into `rm -rf /libexec/opencode` — a real directory on some systems.
if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-/nonexistent}" ]; then
  if [ -d /data/data/com.termux/files/usr ]; then
    PREFIX=/data/data/com.termux/files/usr
  else
    printf '%s\n' "${c_r}  Refusing to run: this does not look like Termux (\$PREFIX is unset).${c_x}"
    info  "Run it inside Termux, where opencode-mobile was installed."
    exit 1
  fi
fi

removed_something=false

# ── 1. The opencode binary ───────────────────────────────────────
if command -v dpkg >/dev/null 2>&1 && dpkg -s opencode >/dev/null 2>&1; then
  info "Removing the opencode package (dpkg)..."
  dpkg -r opencode >/dev/null 2>&1 && ok "opencode package removed" || warn "dpkg -r reported an issue"
  removed_something=true
fi

rm -f  "$PREFIX/bin/opencode" 2>/dev/null
rm -rf "$PREFIX/libexec/opencode" 2>/dev/null
rm -f  "$PREFIX/lib/libtagfix.so" "$PREFIX/lib/libc++_shared.so" \
       "$PREFIX/lib/libopentui.so" 2>/dev/null

# npm-based runtime (C04-wq/opencode-termux stores it in ~/.opencode)
if command -v npm >/dev/null 2>&1 && npm ls -g --depth=0 2>/dev/null | grep -q opencode-termux; then
  info "Removing the npm package 'opencode-termux'..."
  npm uninstall -g opencode-termux >/dev/null 2>&1 && ok "npm package removed" || warn "npm uninstall reported an issue"
  removed_something=true
fi
[ -d "$HOME/.opencode" ] && rm -rf "$HOME/.opencode" && ok "removed ~/.opencode runtime"

command -v opencode >/dev/null 2>&1 && warn "an opencode binary is still on PATH: $(command -v opencode)" \
                                    || ok "no opencode binary left on PATH"

# ── 2. Config (small; back it up rather than just deleting) ──────
if [ -d "$HOME/.config/opencode" ]; then
  bak="$HOME/opencode-config-backup-$(date +%Y%m%d%H%M%S).tar.gz"
  if tar -czf "$bak" -C "$HOME/.config" opencode >/dev/null 2>&1; then
    ok "config backed up to $bak"
  fi
  rm -rf "$HOME/.config/opencode" && ok "removed ~/.config/opencode"
  removed_something=true
fi

# ── 3. Projects under ~/opencode ─────────────────────────────────
# The old uninstaller deleted these unconditionally, with no prompt and no
# backup, while printing "nothing else was touched". Now: opt-in only.
if [ -d "$HOME/opencode" ]; then
  count="$(find "$HOME/opencode" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  printf '\n'
  warn "~/opencode contains your projects (${count:-0} folders)."
  delete_projects="${OPENCODE_MOBILE_DELETE_PROJECTS:-0}"
  if [ "$delete_projects" != "1" ]; then
    if confirm "Delete ~/opencode and EVERY project inside it?"; then delete_projects=1; fi
  fi
  if [ "$delete_projects" = "1" ]; then
    bak="$HOME/opencode-projects-backup-$(date +%Y%m%d%H%M%S).tar.gz"
    if confirm "Make a backup archive first? (recommended)"; then
      tar -czf "$bak" -C "$HOME" opencode >/dev/null 2>&1 \
        && ok "projects backed up to $bak" \
        || warn "backup failed — projects will be deleted anyway"
    fi
    rm -rf "$HOME/opencode" && ok "deleted ~/opencode"
  else
    ok "KEPT ~/opencode — your projects are untouched"
  fi
  removed_something=true
fi

# ── 4. Session history and saved API keys ────────────────────────
# /connect stores keys in ~/.local/share/opencode/auth.json. The old
# uninstaller left this behind while claiming a clean removal.
if [ -d "$HOME/.local/share/opencode" ]; then
  delete_data="${OPENCODE_MOBILE_DELETE_DATA:-0}"
  if [ "$delete_data" != "1" ]; then
    if confirm "Also delete opencode's session history and saved API keys (~/.local/share/opencode)?"; then
      delete_data=1
    fi
  fi
  if [ "$delete_data" = "1" ]; then
    rm -rf "$HOME/.local/share/opencode" && ok "removed session history and saved keys"
  else
    ok "KEPT ~/.local/share/opencode (session history + saved API keys)"
    info "delete it later with:  rm -rf ~/.local/share/opencode"
  fi
fi

# ── 5. ~/.bashrc: AI shortcut + API key ──────────────────────────
if [ -f "$HOME/.bashrc" ]; then
  cp "$HOME/.bashrc" "$HOME/.bashrc.opencode-uninstall.bak" 2>/dev/null
  # current marker and the v1.3-era marker
  sed -i '/^# --- AI shortcut (opencode-mobile)/,/^ai() { AI; }$/d' "$HOME/.bashrc" 2>/dev/null
  sed -i '/^# --- AI shortcut/,/^}$/d'                            "$HOME/.bashrc" 2>/dev/null
  sed -i '/^ai() { AI; }$/d'                                      "$HOME/.bashrc" 2>/dev/null
  sed -i '/^# OpenCode API key/d'                                 "$HOME/.bashrc" 2>/dev/null
  sed -i '/^export OPENCODE_API_KEY=/d'                           "$HOME/.bashrc" 2>/dev/null
  cat -s "$HOME/.bashrc" >"$HOME/.bashrc.tmp" 2>/dev/null && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  ok "cleaned ~/.bashrc (backup: ~/.bashrc.opencode-uninstall.bak)"
  removed_something=true
fi

# ── 6. Termux keyboard row ───────────────────────────────────────
props="$HOME/.termux/termux.properties"
if [ -f "$props.opencode-backup" ]; then
  mv "$props.opencode-backup" "$props" && ok "restored your original termux.properties"
elif [ -f "$props" ] && grep -q "Added by opencode-mobile" "$props" 2>/dev/null; then
  sed -i '/# Added by opencode-mobile/,+2d' "$props" 2>/dev/null
  ok "removed the keyboard row that the installer added"
elif [ -f "$props" ]; then
  # We injected KEYBOARD into a pre-existing row: strip just that token.
  if grep -Eq '^[[:space:]]*extra-keys[[:space:]]*=' "$props" 2>/dev/null; then
    cp "$props" "$props.opencode-uninstall.bak" 2>/dev/null
    sed -i "s/'KEYBOARD',//g; s/,'KEYBOARD'//g; s/'KEYBOARD'//g" "$props" 2>/dev/null
    ok "removed the ⌨ button from your key row (backup: $props.opencode-uninstall.bak)"
  fi
fi
command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings >/dev/null 2>&1

# ── 7. Installer leftovers ───────────────────────────────────────
rm -rf "$HOME/.cache/opencode-mobile" 2>/dev/null
rm -f  "$HOME/opencode-mobile-install.log" 2>/dev/null

printf '\n'
if [ "$removed_something" = true ]; then
  printf '%s\n' "${c_g}  Done — opencode-mobile was removed.${c_x}"
else
  printf '%s\n' "${c_y}  Nothing to remove — opencode-mobile was not installed here.${c_x}"
fi
printf '%s\n'   "  Your projects: $([ "${OPENCODE_MOBILE_DELETE_PROJECTS:-0}" = "1" ] && echo 'deleted (see above)' || echo 'kept unless you chose to delete them')"
printf '%s\n'   "  Prerequisite packages (git, ripgrep, nodejs, curl) were left installed;"
printf '%s\n'   "  remove any of them with:  pkg uninstall <name>"
printf '\n'
exit 0
