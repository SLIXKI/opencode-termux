#!/usr/bin/env bash
#
# ============================================================
#  opencode-mobile uninstaller
# ============================================================
#  Removes opencode and everything opencode-mobile installed:
#    - the native opencode build
#    - the config / memory files
#    - your projects under ~/opencode  (DELETED)
#    - the 'AI' shortcut and API key from ~/.bashrc
#
#  Run inside Termux with:  bash uninstall.sh
# ============================================================

echo ""
echo "  Removing opencode-mobile..."

# 1) Native opencode build
rm -f  "$PREFIX/bin/opencode"
rm -rf "$PREFIX/libexec/opencode"
rm -f  "$PREFIX/lib/libtagfix.so" "$PREFIX/lib/libc++_shared.so" "$PREFIX/lib/libopentui.so"

# 2) Config + memory files (and your projects — they are under ~/opencode)
rm -rf "$HOME/.config/opencode"
rm -rf "$HOME/opencode"

# 3) The 'AI' shortcut in ~/.bashrc
sed -i '/# --- AI shortcut/,/^}/d'  "$HOME/.bashrc" 2>/dev/null
sed -i '/^ai() { AI; }/d'           "$HOME/.bashrc" 2>/dev/null

# 4) The API key line in ~/.bashrc
sed -i '/# OpenCode API key/d'      "$HOME/.bashrc" 2>/dev/null
sed -i '/^export OPENCODE_API_KEY=/d' "$HOME/.bashrc" 2>/dev/null

# 5) Undo the keyboard (⌨) toggle the installer added to Termux's key row
props="$HOME/.termux/termux.properties"
if [ -f "$props.opencode-backup" ]; then
  mv "$props.opencode-backup" "$props"
  echo "  Restored your original termux.properties (keyboard change undone)."
else
  sed -i '/# Added by opencode-mobile: a keyboard/,+2d' "$props" 2>/dev/null
fi

echo "  Done — opencode-mobile was removed."
echo "  Your phone stays as it was; nothing else was touched."
echo "  Brought to you by @FeaturisticLeaks X @slixki"
echo ""
