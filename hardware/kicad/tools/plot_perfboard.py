"""Draw the perfboard wiring as a picture (top view): perfboard_wiring.png next to the board file.

    py -3 hardware/kicad/tools/plot_perfboard.py

Reads piper-watch.kicad_pcb through KiCad's own Python (to get pads, tracks and parts exactly as
saved, including hand edits), then draws it with matplotlib: the hole grid, part outlines, every
pad labelled with its pin, bare wires in copper and insulated wires in red. The wires are on the
underside but drawn as seen from the top, so the picture matches the board in front of you.
"""
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
PNG = os.path.join(HERE, "..", "perfboard_wiring.png")
PDF = os.path.join(HERE, "..", "perfboard_wiring.pdf")     # vector: prints sharp at any size
NOTES = [                                                    # short lines: no wider than the board
    "TOP VIEW - back of the case at the top.",
    "Wires are soldered on the UNDERSIDE, but drawn as seen from the top.",
    "Thick = heavy wire (19 V, GND, motor).",
    "Dotted stripe = INSULATED wire (it crosses another run); the rest can be bare.",
    "Grey pads are not connected.  TMC2209 square pad = pin 1 (GND).",
    "J6 / J1 / J3: the screw openings face the back edge.",
]
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


def main():
    tmp = tempfile.mkdtemp()
    script, data = os.path.join(tmp, "dump.py"), os.path.join(tmp, "board.json")
    open(script, "w").write(DUMP % (HERE, os.path.abspath(PCB)))
    subprocess.run([KICAD_PY, script, data], check=True)
    d = json.load(open(data))

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
        elif p["ref"] in ("J4", "J5"):
            ax.text(p["x"] - 1.4, p["y"], label, fontsize=7, ha="right", va="center", zorder=6, color="#222")
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
    for k, line in enumerate(legend):
        ax.text(x0 + (k % 2) * 36, y_parts + (k // 2) * 2.2, line, fontsize=8, va="top", color="#1f4e79")
    ax.text(x0, y0 - 6.5, "Piper-Watch Level 2 perfboard (70 x 50)", fontsize=12, fontweight="bold", va="top")
    fig.savefig(PNG, bbox_inches="tight", facecolor="white")
    fig.savefig(PDF, bbox_inches="tight", facecolor="white")
    print("written", os.path.normpath(PNG), "and", os.path.normpath(PDF))


if __name__ == "__main__":
    main()
