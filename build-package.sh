#!/usr/bin/env bash
#
# ══════════════════════════════════════════════════════════════════
#  build-package.sh — maintainer tool
# ══════════════════════════════════════════════════════════════════
#
#  install.sh is piped straight into bash, so it must be self-contained:
#  it embeds a copy of everything in config/. That creates two copies of
#  the same content, which is exactly how the old package drifted out of
#  sync. This script removes that risk.
#
#  It does three things:
#    1. regenerates the embedded config block in install.sh from config/
#       (config/ is the single source of truth),
#    2. syncs install.sh, uninstall.sh and config/ into the offline
#       package folder,
#    3. rebuilds the distribution zip with a top-level `opencode-mobile/`
#       prefix and forward slashes, then verifies it by extracting it.
#
#  Usage:
#    ./build-package.sh            regenerate + rebuild the zip
#    ./build-package.sh --check    verify only; exit 1 if anything drifted
#
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PKG_DIR="opencode for mobile"
ZIP_PREFIX="opencode-mobile"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

c_g=$'\033[1;32m'; c_r=$'\033[1;31m'; c_y=$'\033[1;33m'; c_b=$'\033[1m'; c_x=$'\033[0m'
ok()   { printf '%s  [ OK ] %s%s\n' "$c_g" "$*" "$c_x"; }
fail() { printf '%s  [FAIL] %s%s\n' "$c_r" "$*" "$c_x"; }
info() { printf '         %s\n' "$*"; }

command -v python3 >/dev/null 2>&1 || { fail "python3 is required"; exit 1; }

VERSION="$(grep -m1 '^PACKAGE_VERSION=' install.sh | cut -d'"' -f2)"
[ -n "$VERSION" ] || { fail "could not read PACKAGE_VERSION from install.sh"; exit 1; }
ZIP_NAME="${ZIP_PREFIX}-v${VERSION}.zip"

printf '\n%s\n' "${c_b}opencode-mobile build — package v${VERSION}${c_x}"
[ "$CHECK_ONLY" = 1 ] && printf '%s\n' "${c_y}(check mode — nothing will be written)${c_x}"
printf '\n'

# ── 1. Regenerate / verify the embedded config block ─────────────
EMBED="$(python3 - "$VERSION" <<'PY'
import sys
files = [
    ("write_opencode_json",   "__OC_JSON__",   "config/opencode.json"),
    ("write_agents_md",       "__OC_AGENTS__", "config/AGENTS.md"),
    ("write_memory_template", "__OC_MEMORY__", "config/Memory.template.md"),
]
out = ["# ==== BEGIN GENERATED EMBEDDED CONFIG ====",
       "# Generated from config/ by build-package.sh — do not edit by hand.",
       "# config/ is the single source of truth; install.sh embeds a copy because",
       "# it is piped straight into bash and cannot read sibling files."]
for fn, delim, path in files:
    body = open(path, encoding="utf-8").read()
    assert delim not in body, f"{delim} appears inside {path}"
    body = body.rstrip("\n")
    out.append(f'{fn}() {{')
    out.append(f'cat >"$1" <<\'{delim}\'')
    out.append(body)
    out.append(delim)
    out.append('}')
    out.append('')
out.pop()  # drop the trailing blank between the last fn and the end marker
out.append("# ==== END GENERATED EMBEDDED CONFIG ====")
sys.stdout.write("\n".join(out) + "\n")
PY
)"

for f in config/opencode.json config/AGENTS.md config/Memory.template.md; do
  [ -f "$f" ] || { fail "missing source file: $f"; exit 1; }
done
python3 -c "import json;json.load(open('config/opencode.json'))" \
  || { fail "config/opencode.json is not valid JSON"; exit 1; }
ok "config/ sources are present and opencode.json parses"

CURRENT="$(awk '/^# ==== BEGIN GENERATED EMBEDDED CONFIG ====$/,/^# ==== END GENERATED EMBEDDED CONFIG ====$/' install.sh)"
EMBED_TMP="$(mktemp)"
printf '%s\n' "$EMBED" >"$EMBED_TMP"

if [ "$CURRENT" != "$EMBED" ]; then
  if [ "$CHECK_ONLY" = 1 ]; then
    fail "install.sh's embedded config differs from config/ — run ./build-package.sh"
    exit 1
  fi
  EMBED_TMP="$EMBED_TMP" python3 - <<'PY'
import os
new = open(os.environ["EMBED_TMP"], encoding="utf-8").read().rstrip("\n")
src = open("install.sh", encoding="utf-8").read()
b = "# ==== BEGIN GENERATED EMBEDDED CONFIG ===="
e = "# ==== END GENERATED EMBEDDED CONFIG ===="
assert b in src and e in src, "embedded-config markers missing from install.sh"
i, j = src.index(b), src.index(e) + len(e)
open("install.sh", "w", encoding="utf-8").write(src[:i] + new + src[j:])
PY
  ok "regenerated the embedded config block in install.sh"
else
  ok "embedded config already in sync with config/"
fi

bash -n install.sh   && ok "install.sh passes bash -n"
bash -n uninstall.sh && ok "uninstall.sh passes bash -n"

# ── 2. Sync the offline package folder ───────────────────────────
if [ "$CHECK_ONLY" = 1 ]; then
  drift=0
  for pair in "install.sh|$PKG_DIR/install.sh" "uninstall.sh|$PKG_DIR/uninstall.sh" \
              "config/opencode.json|$PKG_DIR/config/opencode.json" \
              "config/AGENTS.md|$PKG_DIR/config/AGENTS.md" \
              "config/Memory.template.md|$PKG_DIR/config/Memory.template.md"; do
    src="${pair%%|*}"; dst="${pair##*|}"
    if [ ! -f "$dst" ]; then fail "missing in package: $dst"; drift=1
    elif ! cmp -s "$src" "$dst"; then fail "package copy is stale: $dst"; drift=1; fi
  done
  [ "$drift" = 0 ] && ok "offline package copies are in sync" || exit 1
else
  mkdir -p "$PKG_DIR/config"
  cp install.sh uninstall.sh "$PKG_DIR/"
  cp config/opencode.json config/AGENTS.md config/Memory.template.md "$PKG_DIR/config/"
  chmod 755 "$PKG_DIR/install.sh" "$PKG_DIR/uninstall.sh"
  ok "synced install.sh, uninstall.sh and config/ into '$PKG_DIR/'"
fi
chmod 755 install.sh uninstall.sh build-package.sh

# ── 3. Build and verify the zip ──────────────────────────────────
if [ "$CHECK_ONLY" = 1 ]; then
  [ -f "$PKG_DIR/$ZIP_NAME" ] && ok "zip present: $PKG_DIR/$ZIP_NAME" \
    || { fail "expected zip not found: $PKG_DIR/$ZIP_NAME"; exit 1; }
else
  rm -f "$PKG_DIR"/*.zip
  PKG_DIR="$PKG_DIR" ZIP_NAME="$ZIP_NAME" ZIP_PREFIX="$ZIP_PREFIX" python3 <<'PY'
import os, zipfile
pkg, name, prefix = os.environ["PKG_DIR"], os.environ["ZIP_NAME"], os.environ["ZIP_PREFIX"]
entries = []
for dirpath, dirnames, filenames in os.walk(pkg):
    dirnames[:] = [d for d in dirnames if d not in (".build", "__pycache__")]
    for fn in sorted(filenames):
        if fn.endswith(".zip"):
            continue
        full = os.path.join(dirpath, fn)
        rel = os.path.relpath(full, pkg).replace(os.sep, "/")
        entries.append((full, f"{prefix}/{rel}"))
entries.sort(key=lambda t: t[1])
with zipfile.ZipFile(os.path.join(pkg, name), "w", zipfile.ZIP_DEFLATED) as z:
    for full, arc in entries:
        z.write(full, arc)
print(f"         wrote {len(entries)} entries")
PY
  ok "built $PKG_DIR/$ZIP_NAME"
fi

# Verify by extracting — the old package shipped a zip whose entries had no
# top-level folder, so files landed loose in Downloads and `cd opencode-mobile`
# failed for every recipient. Never trust a zip we did not unpack.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"; rm -f "$EMBED_TMP"' EXIT
python3 - "$PKG_DIR/$ZIP_NAME" "$TMP" <<'PY'
import sys, zipfile
zp, dest = sys.argv[1], sys.argv[2]
z = zipfile.ZipFile(zp)
bad = z.testzip()
assert bad is None, f"corrupt entry: {bad}"
names = z.namelist()
assert names, "zip is empty"
assert all("\\" not in n for n in names), "zip contains backslashes"
assert all(n.startswith("opencode-mobile/") for n in names), "entry missing the top-level prefix"
assert not any(n.endswith("/") for n in names), "zip should contain files only"
for required in ["install.sh", "uninstall.sh", "INSTALL.txt", "GUIDE.md", "README.md",
                 "requirements.txt", "config/opencode.json", "config/AGENTS.md",
                 "config/Memory.template.md"]:
    assert f"opencode-mobile/{required}" in names, f"missing from zip: {required}"
z.extractall(dest)
print(f"         {len(names)} entries, prefix + separators verified, extracted cleanly")
PY
ok "zip structure verified (prefix, separators, contents, extraction)"

# The extracted installer must match the repo one byte for byte.
cmp -s "$TMP/$ZIP_PREFIX/install.sh" install.sh \
  && ok "zip's install.sh is byte-identical to the repo's" \
  || { fail "zip's install.sh differs from the repo's"; exit 1; }

printf '\n%s\n' "${c_g}${c_b}  Package v${VERSION} is consistent.${c_x}"
printf '%s\n\n'   "  Share either the one-liner (preferred) or $PKG_DIR/$ZIP_NAME"
exit 0
