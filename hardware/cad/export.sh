#!/usr/bin/env bash
# Render every printable part in parts/ to out/<name>.3mf (Bambu Studio opens 3MF/STL).
#   ./export.sh            all parts
#   ./export.sh ls_gauge   just one
set -euo pipefail
cd "$(dirname "$0")"

# Find OpenSCAD (Linux/macOS PATH, or the Windows installs)
OPENSCAD=$(command -v openscad || true)
for p in "/c/Program Files/OpenSCAD (Nightly)/openscad.com" "/c/Program Files/OpenSCAD/openscad.com"          "/c/Program Files (x86)/OpenSCAD/openscad.com"; do
    [ -z "$OPENSCAD" ] && [ -x "$p" ] && OPENSCAD="$p"
done
[ -z "$OPENSCAD" ] && { echo "OpenSCAD not found"; exit 1; }

# Manifold (fast) exists only in development snapshots; the 2021.01 release uses CGAL
BACKEND=()
"$OPENSCAD" --help 2>&1 | grep -q -- "--backend" && BACKEND=(--backend=Manifold)

mkdir -p out
parts=("$@")
[ ${#parts[@]} -eq 0 ] && parts=($(cd parts && ls *.scad | sed 's/\.scad$//'))
for p in "${parts[@]}"; do
    echo "rendering $p"
    "$OPENSCAD" "${BACKEND[@]}" -o "out/$p.3mf" "parts/$p.scad"
done
