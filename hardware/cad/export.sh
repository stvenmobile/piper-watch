#!/usr/bin/env bash
# Render the printable parts to out/<name>.3mf (Bambu Studio opens 3MF).
#   ./export.sh                    every part below
#   ./export.sh base_turret_v4     just one (any name from the list)
# Most parts come out of one source file through its `part` variable, so the list maps each file name to
# its source and part ("-" = the file has no part switch).
set -euo pipefail
cd "$(dirname "$0")"

# Find OpenSCAD (Linux/macOS PATH, or the Windows installs)
OPENSCAD=$(command -v openscad || true)
for p in "/c/Program Files/OpenSCAD (Nightly)/openscad.com" "/c/Program Files/OpenSCAD/openscad.com" "/c/Program Files (x86)/OpenSCAD/openscad.com"; do
    [ -z "$OPENSCAD" ] && [ -x "$p" ] && OPENSCAD="$p"
done
[ -z "$OPENSCAD" ] && { echo "OpenSCAD not found"; exit 1; }

# Manifold (fast) exists only in development snapshots; the 2021.01 release uses CGAL
BACKEND=()
"$OPENSCAD" --help 2>&1 | grep -q -- "--backend" && BACKEND=(--backend=Manifold)

# out name                      source                                    part
PARTS="
base_tub_v4                     parts/base_v4.scad                        v4_tub
base_lid_v4                     parts/base_v4.scad                        v4_lid
base_skirt_v4                   parts/base_v4.scad                        v4_skirt
base_rail_shim_v4               parts/base_v4.scad                        v4_railshim
base_pan_strap_v4               parts/base_v4.scad                        v4_panstrap
base_hub_v4                     parts/base_v4.scad                        v4_hub
base_turret_v4                  parts/base_v4.scad                        v4_turret
base_strap_v4                   parts/base_v4.scad                        v4_strap
base_crank_v4                   parts/base_v4.scad                        v4_crank
base_cowl_v4                    parts/base_v4.scad                        v4_cowl
base_cover_v5                   parts/base_v4.scad                        v4_cover
base_ear_v5                     parts/base_v4.scad                        v4_ear
base_plug_v5                    parts/base_v4.scad                        v4_plug
base_head_front_v6              parts/head_v6.scad                        v6_front
base_head_back_v6               parts/head_v6.scad                        v6_back
base_head_straps_v6             parts/head_v6.scad                        v6_straps
base_axle_pin_v6                parts/head_v6.scad                        v6_pins
lens_flange                     parts/lens_flange.scad                    -
oled_washers_x4                 parts/oled_washers.scad                   -
prototype/tolerance_coupon      parts/prototype/tolerance_coupon.scad     -
prototype/fit_calibration       parts/prototype/fit_calibration.scad      -
prototype/adapter_hole_coupon   parts/prototype/adapter_hole_coupon.scad  -
"

mkdir -p out/prototype
found=0
while read -r name src part; do
    [ -z "$name" ] && continue
    if [ $# -gt 0 ]; then
        keep=0; for want in "$@"; do [ "$want" = "$name" ] && keep=1; done
        [ $keep -eq 0 ] && continue
    fi
    found=1
    echo "rendering $name  ($src, part $part)"
    if [ "$part" = "-" ]; then
        "$OPENSCAD" "${BACKEND[@]}" -o "out/$name.3mf" "$src"
    else
        "$OPENSCAD" "${BACKEND[@]}" -D "part=\"$part\"" -o "out/$name.3mf" "$src"
    fi
done <<< "$PARTS"
[ $found -eq 0 ] && { echo "no part called: $*"; exit 1; }
exit 0
