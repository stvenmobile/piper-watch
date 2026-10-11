"""Draw the perfboard wiring, and list its wires - all from the board file:

    py -3 hardware/kicad/tools/plot_perfboard.py

    perfboard_wiring.png / .pdf          TOP view (parts side up), wires drawn as if seen through
    perfboard_wiring_bottom.png / .pdf   BOTTOM view (turned over left-to-right, back of the case
                                         still at the top): the side you solder the wires on
    ../wiring.md                         the wire list between its <!-- wires:start/end --> markers

Reads piper-watch.kicad_pcb through KiCad's own Python (pads, tracks and parts exactly as saved,
including hand edits), then draws it with matplotlib: the hole grid, part outlines, every pad
labelled with its pin, wires coloured by net (thick = heavy wire, dotted stripe = insulated).
"""
import re
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
NET_COLOURS = {"+19V_SW": "#d62828", "+5V": "#ffffff", "GND": "#1a1a1a", "+3V3": "#f28c28",
               "STEP": "#1f6fd1", "DIR": "#2a9d3a", "EN": "#8e44ad", "HALL": "#8b5a2b",
               "MOT_A1": "#22b8c8", "MOT_A2": "#0e7c86", "MOT_B1": "#ff6fae", "MOT_B2": "#b8336a"}
NET_NAMES = [("+19V_SW", "19 V (switched)"), ("GND", "GND"), ("+5V", "5 V (Hall)"), ("+3V3", "3V3 (from the ESP32)"),
             ("STEP", "STEP"), ("DIR", "DIR"), ("EN", "EN"), ("HALL", "HALL"),
             ("MOT_A2", "coil A2"), ("MOT_A1", "coil A1"), ("MOT_B1", "coil B1"), ("MOT_B2", "coil B2")]
PCB = os.path.join(HERE, "..", "piper-watch.kicad_pcb")
OUT = os.path.join(HERE, "..", "perfboard_wiring")          # + .png / .pdf (vector: prints sharp at any size)
WIRING_MD = os.path.join(HERE, "..", "..", "wiring.md")
VIEWS = {                                                     # notes: short lines, no wider than the board
    "top": {"suffix": "", "title": "Piper-Watch Level 2 perfboard (70 x 50) - TOP VIEW", "notes": [
        "TOP VIEW - parts side up, back of the case at the top.",
        "Wires are soldered on the UNDERSIDE, but drawn as if seen through the board.",
        "Thick = heavy wire (19 V, GND, motor).",
        "Dotted stripe = INSULATED wire (it crosses another run); the rest can be bare.",
        "Grey pads are not connected.  TMC2209 square pad = pin 1 (GND).",
        "J6 / J1 / J3: the screw openings face the back edge.",
        "The same board seen from the solder side: perfboard_wiring_bottom.pdf"]},
    "bottom": {"suffix": "_bottom", "title": "Piper-Watch Level 2 perfboard (70 x 50) - BOTTOM VIEW (solder side)", "notes": [
        "BOTTOM VIEW - the solder side: the board turned over left-to-right,",
        "  so the back of the case is still at the top. Wire it as you see it here.",
        "Parts are on the other side (dashed outlines); J4 / J5 are now on the RIGHT.",
        "Thick = heavy wire (19 V, GND, motor).",
        "Dotted stripe = INSULATED wire (it crosses another run); the rest can be bare.",
        "Grey pads are not connected.  TMC2209 square pad = pin 1 (GND).",
        "The same board from the parts side: perfboard_wiring.pdf"]},
}
KICAD_PY = r"C:\Program Files\KiCad\10.0\bin\python.exe"

DUMP = r'''
import json, sys, pcbnew
sys.path.insert(0, %r)
import gen_schematics as gs
names = {}
for sh in gs.SHEETS:
    for p in sh["parts"]:
        for num, pin in gs.symbol_def(p["lib_id"])[1].items():
            names["%%s.%%s" %% (p["ref"], num)] = pin[1]
b = pcbnew.LoadBoard(%r)
mm = pcbnew.ToMM
out = {"pads": [], "tracks": [], "parts": [], "edge": None}
bb = b.GetBoardEdgesBoundingBox()
out["edge"] = [mm(bb.GetLeft()), mm(bb.GetTop()), mm(bb.GetRight()), mm(bb.GetBottom())]
for fp in b.GetFootprints():
    ref = fp.GetReference()
    cy = fp.GetCourtyard(pcbnew.F_CrtYd)
    box = cy.BBox() if cy.OutlineCount() else fp.GetBoundingBox(False)
    out["parts"].append({"ref": ref, "value": fp.GetValue(), "hole": fp.GetAttributes() & pcbnew.FP_BOARD_ONLY != 0,
                         "box": [mm(box.GetLeft()), mm(box.GetTop()), mm(box.GetRight()), mm(box.GetBottom())],
                         "lib": fp.GetFPIDAsString()})
    for pad in fp.Pads():
        p = pad.GetPosition()
        key = "%%s.%%s" %% (ref, pad.GetNumber())
        out["pads"].append({"ref": ref, "num": pad.GetNumber(), "x": mm(p.x), "y": mm(p.y), "net": pad.GetNetname(),
                            "name": names.get(key, ""), "square": pad.GetShape() in (pcbnew.PAD_SHAPE_RECT, pcbnew.PAD_SHAPE_ROUNDRECT)})
for t in b.GetTracks():
    if t.GetClass() != "PCB_TRACK":
        continue
    out["tracks"].append({"a": [mm(t.GetStart().x), mm(t.GetStart().y)], "b": [mm(t.GetEnd().x), mm(t.GetEnd().y)],
                          "w": mm(t.GetWidth()), "layer": b.GetLayerName(t.GetLayer()), "net": t.GetNetname()})
json.dump(out, open(sys.argv[1], "w"))
'''


def load() -> dict:
    tmp = tempfile.mkdtemp()
    script, data = os.path.join(tmp, "dump.py"), os.path.join(tmp, "board.json")
    open(script, "w").write(DUMP % (HERE, os.path.abspath(PCB)))
    subprocess.run([KICAD_PY, script, data], check=True)
    return json.load(open(data))


def mirrored(d: dict) -> dict:
    """The board turned over left-to-right (seen from the solder side)."""
    x0, _, x1, _ = d["edge"]
    fx = lambda x: x0 + x1 - x
    m = json.loads(json.dumps(d))
    for p in m["pads"]:
        p["x"] = fx(p["x"])
    for t in m["tracks"]:
        t["a"][0], t["b"][0] = fx(t["a"][0]), fx(t["b"][0])
    for p in m["parts"]:
        l, t, r, b = p["box"]
        p["box"] = [fx(r), t, fx(l), b]
    return m


def main():
    d = load()
    draw(d, "top")
    draw(mirrored(d), "bottom")
    update_wiring_md(wire_list(d))


def draw(d: dict, view: str):
    v = VIEWS[view]
    NOTES = v["notes"]
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Circle, FancyBboxPatch, Rectangle

    x0, y0, x1, y1 = d["edge"]
    fig, ax = plt.subplots(figsize=(15, 11.5), dpi=130)
    ax.set_xlim(x0 - 6, x1 + 6)
    y_notes = y1 + 3                                         # notes, then the parts, then the wire colours
    y_parts = y_notes + 2.4 * len(NOTES) + 1.5
    y_nets = y_parts + 2.2 * 5 + 1.5
    ax.set_ylim(y_nets + 2.4 * 3 + 1, y0 - 9)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.add_patch(Rectangle((x0, y0), x1 - x0, y1 - y0, fc="#f3e9c6", ec="#8a7a4a", lw=1.5, zorder=0))
    # hole grid
    holes = sorted({(round(p["x"], 2), round(p["y"], 2)) for p in d["pads"]})
    gx = min(h[0] for h in holes) % 2.54
    gy = min(h[1] for h in holes) % 2.54
    import math
    xs = [gx + 2.54 * k for k in range(math.ceil((x0 - gx) / 2.54), math.floor((x1 - gx) / 2.54) + 1)]
    ys = [gy + 2.54 * k for k in range(math.ceil((y0 - gy) / 2.54), math.floor((y1 - gy) / 2.54) + 1)]
    for x in xs:
        for y in ys:
            if x0 + 1.2 < x < x1 - 1.2 and y0 + 1.2 < y < y1 - 1.2:
                ax.add_patch(Circle((x, y), 0.45, fc="#d8c99a", ec="#b9a36a", lw=0.4, zorder=1))
    # parts
    legend = []
    for p in sorted(d["parts"], key=lambda q: q["ref"]):
        l, t, r, b = p["box"]
        if p["hole"]:
            if p["ref"].startswith("H"):
                ax.add_patch(Circle(((l + r) / 2, (t + b) / 2), 1.35, fc="white", ec="#555", lw=1, zorder=2))
            continue
        ax.add_patch(FancyBboxPatch((l, t), r - l, b - t, boxstyle="round,pad=0,rounding_size=0.8",
                                    fc="#ffffff55", ec="#3b6ea5", lw=1.2, ls="--", zorder=2))
        ax.text(l + 0.3, t + 0.3, p["ref"], fontsize=8, color="#1f4e79", zorder=6, va="top", ha="left", fontweight="bold")
        legend.append("%s  %s" % (p["ref"], p["value"]))
    # wires, coloured by net; insulated ones (F.Cu) get a dotted stripe and are drawn on top
    for insulated in (False, True):
        for t in d["tracks"]:
            if (t["layer"] != "B.Cu") != insulated:
                continue
            net = t["net"].split("/")[-1]
            colour = NET_COLOURS.get(net, "#999999")
            lw = 5.0 if t["w"] >= 0.5 else 3.0
            xs, ys = [t["a"][0], t["b"][0]], [t["a"][1], t["b"][1]]
            ax.plot(xs, ys, color="#333333", lw=lw + 1.4, solid_capstyle="round", zorder=3)
            ax.plot(xs, ys, color=colour, lw=lw, solid_capstyle="round", zorder=4)
            if insulated:
                ax.plot(xs, ys, color="#555555" if net in ("+5V",) else "#ffffff", lw=0.9, ls=(0, (1.5, 2.5)), zorder=4.5)
    # pads + pin labels
    for p in d["pads"]:
        if p["ref"].startswith("H"):
            continue
        fc = "#ffd34d" if p["net"] and not p["net"].startswith("unconnected") else "#cfcfcf"
        if p["square"]:
            ax.add_patch(Rectangle((p["x"] - 0.85, p["y"] - 0.85), 1.7, 1.7, fc=fc, ec="#333", lw=0.8, zorder=5))
        else:
            ax.add_patch(Circle((p["x"], p["y"]), 0.85, fc=fc, ec="#333", lw=0.8, zorder=5))
        label = p["name"] if p["name"] and not p["name"].startswith("Pin_") else ""
        if p["ref"] == "GP1":
            label = "GND point"
        if not label:
            label = p["net"].split("/")[-1] if p["net"] and not p["net"].startswith("unconnected") else ""
        if p["ref"] in ("J1", "J3", "J6"):
            ax.text(p["x"], p["y"] - 1.6, label, fontsize=7, ha="center", va="bottom", zorder=6, color="#222")
        elif p["ref"] in ("J4", "J5"):                 # beside the header, on the board-edge side
            left = p["x"] < (x0 + x1) / 2
            ax.text(p["x"] + (-1.4 if left else 1.4), p["y"], label, fontsize=7, ha="right" if left else "left",
                    va="center", zorder=6, color="#222")
        elif p["ref"] == "U1":                     # label each pin on the inside of its row/column
            u = [q for q in d["pads"] if q["ref"] == "U1"]
            cx, cy = sum(q["x"] for q in u) / 16, sum(q["y"] for q in u) / 16
            if max(q["x"] for q in u) - min(q["x"] for q in u) < max(q["y"] for q in u) - min(q["y"] for q in u):
                left = p["x"] < cx                         # columns: text beside the pad, toward the middle
                ax.text(p["x"] + (1.2 if left else -1.2), p["y"], label, fontsize=7, ha="left" if left else "right",
                        va="center", zorder=6, color="#222")
            else:
                above = p["y"] < cy
                ax.text(p["x"], p["y"] + (1.4 if above else -1.4), label, fontsize=6.5, ha="center",
                        va="top" if above else "bottom", zorder=6, color="#222", rotation=90)
        elif p["ref"] in ("C1", "C2"):
            ax.text(p["x"] + 1.2, p["y"], "+" if p["num"] == "1" else "-", fontsize=9, ha="left", va="center", zorder=6, fontweight="bold")
        elif p["ref"] == "GP1":
            ax.text(p["x"], p["y"] + 1.3, label, fontsize=6.5, ha="center", va="top", zorder=6)
    for k, line in enumerate(NOTES):
        ax.text(x0, y_notes + 2.4 * k, line, fontsize=8.5, va="top")
    for k, (net, name) in enumerate(NET_NAMES):
        lx, ly = x0 + (k % 4) * 17.5, y_nets + (k // 4) * 2.4
        ax.plot([lx, lx + 3], [ly, ly], color="#333333", lw=5.2, solid_capstyle="round")
        ax.plot([lx, lx + 3], [ly, ly], color=NET_COLOURS[net], lw=3.8, solid_capstyle="round")
        ax.text(lx + 4.2, ly, name, fontsize=8, va="center")
    if view == "bottom":                                     # the parts' "left to right" is seen from the parts side
        legend = [l.replace("left to right on the board", "right to left from this side")
                  .replace("left to right", "right to left from this side") for l in legend]
    for k, line in enumerate(legend):
        ax.text(x0 + (k % 2) * 36, y_parts + (k // 2) * 2.2, line, fontsize=8, va="top", color="#1f4e79")
    ax.text(x0, y0 - 6.5, v["title"], fontsize=12, fontweight="bold", va="top")
    for ext in ("png", "pdf"):
        fig.savefig(f"{OUT}{v['suffix']}.{ext}", bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("written", os.path.normpath(f"{OUT}{v['suffix']}") + ".png / .pdf")


# ---- the wire list: each separate piece of wire, and the pads it joins ---------------------------------
def pad_label(p: dict) -> str:
    if p["ref"] == "GP1":
        return "GND point"
    name = p["name"] if p["name"] and not p["name"].startswith("Pin_") else ""
    if p["ref"] in ("C1", "C2"):
        return f"{p['ref']} {'+' if p['num'] == '1' else '-'}"
    if p["ref"] in ("R1", "R2"):
        return f"{p['ref']} (pin {p['num']})"
    if not name:
        name = p["net"].split("/")[-1].replace("MOT_", "")
        name = {"+19V_SW": "19V", "+5V": "5V", "+3V3": "3V3", "GND": "GND"}.get(name, name)
    return f"{p['ref']} {name}"


def _on_segment(pt, a, b, tol=0.3) -> bool:     # tol: within the pad (C1 sits 0.08 off the grid)
    (px, py), (ax_, ay), (bx, by) = pt, a, b
    if abs((bx - ax_) * (py - ay) - (by - ay) * (px - ax_)) > tol * max(1.0, abs(bx - ax_) + abs(by - ay)):
        return False
    return min(ax_, bx) - tol <= px <= max(ax_, bx) + tol and min(ay, by) - tol <= py <= max(ay, by) + tol


def wire_list(d: dict) -> list[dict]:
    """One entry per separate piece of wire: its net, bare or insulated, heavy or light, and the
    pads it touches (a piece may branch). Pieces on different layers are different wires."""
    key = lambda pt: (round(pt[0], 2), round(pt[1], 2))
    groups = {}
    for t in d["tracks"]:
        groups.setdefault((t["net"], t["layer"]), []).append(t)
    out = []
    for (net, layer), tracks in groups.items():
        parent = list(range(len(tracks)))

        def find(i):
            while parent[i] != i:
                parent[i] = parent[parent[i]]
                i = parent[i]
            return i
        ends = {}
        for i, t in enumerate(tracks):
            for pt in (key(t["a"]), key(t["b"])):
                ends.setdefault(pt, []).append(i)
        for idx in ends.values():
            for j in idx[1:]:
                parent[find(j)] = find(idx[0])
        pieces = {}
        for i, t in enumerate(tracks):
            pieces.setdefault(find(i), []).append(t)
        for segs in pieces.values():
            pads = [p for p in d["pads"] if p["net"] == net and any(_on_segment((p["x"], p["y"]), t["a"], t["b"]) for t in segs)]
            length = sum(((t["a"][0] - t["b"][0]) ** 2 + (t["a"][1] - t["b"][1]) ** 2) ** 0.5 for t in segs)
            out.append({"net": net.split("/")[-1], "insulated": layer != "B.Cu", "heavy": max(t["w"] for t in segs) >= 0.5,
                        "pads": [pad_label(p) for p in sorted(pads, key=lambda p: (p["y"], p["x"]))],
                        "length_mm": round(length)})
    order = [n for n, _ in NET_NAMES]
    out.sort(key=lambda w: (not w["heavy"], order.index(w["net"]) if w["net"] in order else 99, w["pads"]))
    return out


def update_wiring_md(wires: list[dict]):
    names = dict(NET_NAMES)
    rows = ["| # | Net (colour in the pictures) | Wire | Joins | Length |", "|---|---|---|---|---|"]
    for i, w in enumerate(wires, 1):
        kind = ("heavy" if w["heavy"] else "light") + (", **insulated**" if w["insulated"] else ", bare")
        rows.append(f"| {i} | {names.get(w['net'], w['net'])} | {kind} | {' · '.join(w['pads'])} | ~{w['length_mm']} mm |")
    block = "\n".join(["<!-- wires:start (generated by hardware/kicad/tools/plot_perfboard.py - don't edit by hand) -->",
                       *rows, "<!-- wires:end -->"])
    md = open(WIRING_MD, encoding="utf-8").read()
    new = re.sub(r"<!-- wires:start.*?<!-- wires:end -->", lambda _: block, md, flags=re.S)
    if new == md and "<!-- wires:start" not in md:
        raise SystemExit("wiring.md has no <!-- wires:start --> ... <!-- wires:end --> markers")
    open(WIRING_MD, "w", encoding="utf-8", newline="").write(new)
    print(f"wiring.md: {len(wires)} wires listed")


if __name__ == "__main__":
    main()
