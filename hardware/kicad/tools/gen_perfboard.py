"""Build the perfboard layout (piper-watch.kicad_pcb) for the Level 2 board - run with KiCad's Python:

    "C:\\Program Files\\KiCad\\10.0\\bin\\python.exe" hardware/kicad/tools/gen_perfboard.py

The 70 x 50 board is drawn as perfboard: parts sit on the 2.54 mm hole grid exactly where they go
on the real board (top view, back of the case at the top), and the hand-soldered wires are tracks
laid by a small grid router - straight runs and right angles along the hole rows, like real wire.

    B.Cu (copper colour)  bare solid wire on the underside - heavy runs (0.6 mm) and short links
    F.Cu (red)            INSULATED wire, also on the underside, where a run must cross another

Nets and footprints come from gen_schematics.py, and each footprint is linked to its schematic
symbol, so "Update PCB from Schematic" and DRC's schematic parity check both work. Like the
schematic generator, this is a first draft: once edited in KiCad, the .kicad_pcb is the source.
"""
import heapq
import os
import sys

import pcbnew

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_schematics as gs  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "piper-watch.kicad_pcb")
FPLIB = r"C:\Program Files\KiCad\10.0\share\kicad\footprints"

BX, BY, BW, BH = 100.0, 100.0, 70.0, 50.0           # board outline (mm)
NI, NJ = 24, 18                                     # 24 x 18 holes on a 70 x 50 board
GX0 = BX + (BW - (NI - 1) * 2.54) / 2               # hole (0, 0)
GY0 = BY + (BH - (NJ - 1) * 2.54) / 2
MOUNT = [(BX + 2, BY + 2), (BX + 68, BY + 2), (BX + 2, BY + 48), (BX + 68, BY + 48)]   # 66 x 46
HEAVY, LIGHT = 0.6, 0.3
STAR = (11, 5)                                     # the board ground point (a solder joint, drawn as a via)


def G(i, j):
    return (GX0 + 2.54 * i, GY0 + 2.54 * j)


def V(p):
    return pcbnew.VECTOR2I(pcbnew.FromMM(p[0]), pcbnew.FromMM(p[1]))


# ref: (grid hole of pad 1, rotation in degrees) - matches the board as built: J6, J1, J3 along the
# back edge (screw openings facing it), J4 and J5 down the left edge, the driver in the middle
PLACE = {
    "J6": ((5, 2), 180), "J1": ((11, 2), 180), "J3": ((21, 2), 180),   # left to right: J6 5V GND 19V, J1 + -, J3 A2 A1 B1 B2
    "J5": ((0, 5), 0), "J4": ((0, 9), 0),    # J5 (Hall) right under J6's 5V, then J4
    # driver right under J3 and C1, power row on top: VS GND A2 A1 B1 B2 VIO GND (left to right),
    # so the four coil wires go straight up to J3 in order; logic row (EN .. DIR) underneath
    "U1": ((21, 9), 270),
    "C1": ((14, 7), 90),                         # C1: + right above VS, - above it
    "R1": ((2, 16), 0), "R2": ((9, 16), 0),
}

# connections in routing order: (net, heavy?, pad, pad) - pads as "REF.PIN" or "STAR"; a new
# connection may land on any wire already laid for its net
ROUTES = [
    ("/Level 2 drive/MOT_A2", True, "U1.6", "J3.4"), ("/Level 2 drive/MOT_A1", True, "U1.5", "J3.3"),
    ("/Level 2 drive/MOT_B1", True, "U1.4", "J3.2"), ("/Level 2 drive/MOT_B2", True, "U1.3", "J3.1"),
    ("+19V_SW", True, "J1.2", "U1.8"), ("+19V_SW", True, "C1.1", "U1.8"), ("+19V_SW", True, "J6.1", "J1.2"),
    ("GND", True, "J1.1", "STAR"), ("GND", True, "STAR", "U1.7"), ("GND", True, "C1.2", "STAR"),
    ("GND", True, "J6.2", "STAR"),
    ("/Level 2 drive/STEP", False, "J4.1", "U1.15"), ("/Level 2 drive/DIR", False, "J4.2", "U1.16"),
    ("/Level 2 drive/EN", False, "J4.3", "U1.9"), ("/Level 2 drive/EN", False, "R2.2", "U1.9"),
    ("/Level 2 drive/HALL", False, "J5.3", "J4.4"), ("/Level 2 drive/HALL", False, "R1.2", "J4.4"),
    ("/Level 2 drive/+3V3", False, "J4.5", "U1.2"), ("/Level 2 drive/+3V3", False, "U1.10", "U1.2"),
    ("/Level 2 drive/+3V3", False, "U1.11", "U1.10"), ("/Level 2 drive/+3V3", False, "R1.1", "J4.5"),
    ("/Level 2 drive/+3V3", False, "R2.1", "J4.5"),
    ("GND", False, "U1.1", "STAR"),
    ("+5V", False, "J6.3", "J5.1"),
    ("GND", False, "J5.2", "STAR"), ("GND", False, "J4.6", "STAR"),
]


def schematic_parts():
    """{ref: part dict with its sheet} for the on-board parts."""
    out = {}
    for sh in gs.SHEETS:
        for p in sh["parts"]:
            if p["ref"] in gs.FOOTPRINTS:
                out[p["ref"]] = dict(p, sheet=sh)
    return out


def net_name(sheet, net):
    return net if net in gs.GLOBAL else "/%s/%s" % (sheet["name"], net)


def main():
    gs.main()                                       # (re)write the schematic with the same UUIDs
    board = pcbnew.CreateEmptyBoard() if hasattr(pcbnew, "CreateEmptyBoard") else pcbnew.BOARD()
    parts = schematic_parts()
    nets = {}

    def netinfo(name):
        if name not in nets:
            ni = pcbnew.NETINFO_ITEM(board, name)
            board.Add(ni)
            nets[name] = ni
        return nets[name]

    # outline + mounting holes
    for a, b in [((BX, BY), (BX + BW, BY)), ((BX + BW, BY), (BX + BW, BY + BH)),
                 ((BX + BW, BY + BH), (BX, BY + BH)), ((BX, BY + BH), (BX, BY))]:
        s = pcbnew.PCB_SHAPE(board)
        s.SetShape(pcbnew.SHAPE_T_SEGMENT)
        s.SetStart(V(a))
        s.SetEnd(V(b))
        s.SetLayer(pcbnew.Edge_Cuts)
        s.SetWidth(pcbnew.FromMM(0.1))
        board.Add(s)
    for k, m in enumerate(MOUNT):
        fp = pcbnew.FootprintLoad(FPLIB + r"\MountingHole.pretty", "MountingHole_2.7mm_M2.5")
        fp.SetReference("H%d" % (k + 1))
        fp.SetPosition(V(m))
        fp.SetAttributes(fp.GetAttributes() | pcbnew.FP_BOARD_ONLY | pcbnew.FP_EXCLUDE_FROM_BOM | pcbnew.FP_EXCLUDE_FROM_POS_FILES)
        board.Add(fp)

    # the perfboard's holes, drawn on the user layer so the grid shows
    for i in range(NI):
        for j in range(NJ):
            c = pcbnew.PCB_SHAPE(board)
            c.SetShape(pcbnew.SHAPE_T_CIRCLE)
            c.SetCenter(V(G(i, j)))
            c.SetEnd(V((G(i, j)[0] + 0.5, G(i, j)[1])))
            c.SetLayer(pcbnew.Dwgs_User)
            c.SetWidth(pcbnew.FromMM(0.1))
            board.Add(c)

    # footprints
    pads = {}                                       # "REF.PIN" -> (grid i, j, net)
    root = gs.uid("root")
    for ref, (hole, rot) in PLACE.items():
        p = parts[ref]
        lib, name = gs.FOOTPRINTS[ref].split(":")
        fp = pcbnew.FootprintLoad(os.path.join(FPLIB, lib + ".pretty"), name)
        fp.SetFPIDAsString(gs.FOOTPRINTS[ref])
        fp.SetReference(ref)
        fp.SetValue(p["value"])
        fp.SetPosition(V(G(*hole)))
        fp.SetOrientationDegrees(rot)
        fp.SetPath(pcbnew.KIID_PATH("/%s/%s" % (gs.uid("sheet/" + p["sheet"]["file"]), gs.uid("sym/" + ref))))
        fp.SetSheetname(p["sheet"]["name"])
        fp.SetSheetfile(p["sheet"]["file"])
        board.Add(fp)
        for pad in fp.Pads():
            num = pad.GetNumber()
            net = p["nets"].get(num)
            pos = pad.GetPosition()
            gi = round((pcbnew.ToMM(pos.x) - GX0) / 2.54)
            gj = round((pcbnew.ToMM(pos.y) - GY0) / 2.54)
            if net:
                nn = net_name(p["sheet"], net)
                pad.SetNet(netinfo(nn))
                pads["%s.%s" % (ref, num)] = (gi, gj, nn)
            else:                                   # a no-connect pin: KiCad's name for its net
                pin_name = gs.symbol_def(p["lib_id"])[1][num][1]
                pad.SetNet(netinfo("unconnected-(%s-%s-Pad%s)" % (ref, pin_name, num)))
                pads["%s.%s" % (ref, num)] = (gi, gj, None)
    pads["STAR"] = (STAR[0], STAR[1], "GND")
    tp = pcbnew.FootprintLoad(FPLIB + r"\TestPoint.pretty", "TestPoint_THTPad_D2.0mm_Drill1.0mm")
    tp.SetReference("GP1")
    tp.Reference().SetVisible(False)
    tp.SetValue("board ground point")
    tp.SetPosition(V(G(*STAR)))
    tp.SetAttributes(tp.GetAttributes() | pcbnew.FP_BOARD_ONLY | pcbnew.FP_EXCLUDE_FROM_BOM | pcbnew.FP_EXCLUDE_FROM_POS_FILES)
    for pad in tp.Pads():
        pad.SetNet(netinfo("GND"))
    for item in list(tp.GraphicalItems()):          # just a solder spot: no courtyard
        if item.GetLayer() in (pcbnew.F_CrtYd, pcbnew.B_CrtYd):
            tp.Remove(item)
    board.Add(tp)

    # ---- grid router ----------------------------------------------------------------------------
    pad_at = {(gi, gj): n for gi, gj, n in pads.values()}
    # B.Cu = bare wire; F.Cu, In1.Cu, In2.Cu = insulated wire. Insulated wires can cross each other
    # on a real board, so they get three layers to keep KiCad's checks happy
    board.SetCopperLayerCount(4)
    LAYERS = [pcbnew.B_Cu, pcbnew.F_Cu, pcbnew.In1_Cu, pcbnew.In2_Cu]
    used = {L: {} for L in LAYERS}                  # layer -> {(i, j): net}
    edges = {}                                      # frozenset({cell, cell}) -> net, on ANY layer: two
                                                    #   wires may cross, never run along the same holes
    tree = {}                                       # net -> set of (i, j) on its wires/pads

    def free(layer, a, b, net):
        if not (0 <= b[0] < NI and 0 <= b[1] < NJ):
            return False
        if pad_at.get(b, net) != net:               # another net's pad (or an unused pad)
            return False
        if used[layer].get(b, net) != net:
            return False
        if edges.get(frozenset((a, b)), net) != net:
            return False
        return True

    def route(net, a_cell, targets, layer):
        start = a_cell
        dist = {(start, None): 0}
        pq = [(0, start, None, [start])]
        while pq:
            cost, cell, d, path = heapq.heappop(pq)
            if cell in targets and cell != start:
                return cost, path
            for dd in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nb = (cell[0] + dd[0], cell[1] + dd[1])
                if not free(layer, cell, nb, net):
                    continue
                edge = nb[0] in (0, NI - 1) or nb[1] in (0, NJ - 1)
                c = cost + 1 + (3 if d is not None and d != dd else 0) + (6 if edge else 0)
                if c < dist.get((nb, dd), 1e9):
                    dist[(nb, dd)] = c
                    heapq.heappush(pq, (c, nb, dd, path + [nb]))
        return None

    import random

    def lay(order):
        """Route the connections in this order; returns (score, [(path, layer, net, heavy)]) or None."""
        used.update({L: {} for L in LAYERS})
        edges.clear()
        islands = {}                                # net -> [{"pads", B_Cu, F_Cu}] connected groups
        laid, score = [], 0

        def island(net, cell):
            for isl in islands.setdefault(net, []):
                if cell in isl["pads"]:
                    return isl
            isl = {"pads": {cell}}
            isl.update({L: set() for L in LAYERS})
            islands[net].append(isl)
            return isl
        for net, heavy, a, b in order:
            ai, aj, an = pads[a]
            bi, bj, bn = pads[b]
            assert an == net and bn == net, (a, b, an, bn, net)
            padcells = {(c[0], c[1]) for c in pads.values() if c[2] == net}
            ia, ib = island(net, (ai, aj)), island(net, (bi, bj))
            if ia is ib:
                continue
            best = None
            ins = 6 if heavy else 1
            for layer, penalty in ((pcbnew.B_Cu, 0), (pcbnew.F_Cu, ins), (pcbnew.In1_Cu, ins + 0.5), (pcbnew.In2_Cu, ins + 1)):
                # land on the far end's group: one of its pads, or its wire on the SAME layer
                # (bare and insulated wires only join at pads)
                targets = ib["pads"] | ib[layer]
                r = route(net, (ai, aj), targets, layer)
                if r and (best is None or r[0] + penalty < best[0]):
                    best = (r[0] + penalty, r[1], layer)
            if best is None:
                return None
            cost, path, layer = best
            score += cost
            for c in path:
                used[layer][c] = net
            for c0, c1 in zip(path, path[1:]):
                edges[frozenset((c0, c1))] = net
            ia["pads"] |= ib["pads"] | (set(path) & padcells)
            for L in LAYERS:
                ia[L] |= ib[L]
            ia[layer] |= set(path)
            islands[net].remove(ib)
            for other in list(islands[net]):            # the path may have touched a third group's pad
                if other is not ia and other["pads"] & set(path):
                    ia["pads"] |= other["pads"]
                    for L in LAYERS:
                        ia[L] |= other[L]
                    islands[net].remove(other)
            laid.append((path, layer, net, heavy))
        return score, laid

    heavy_routes = [r for r in ROUTES if r[1]]
    light_routes = [r for r in ROUTES if not r[1]]
    rng = random.Random(1)
    best, best_order = None, None
    for attempt in range(400):
        order = light_routes if attempt == 0 else rng.sample(light_routes, len(light_routes))
        r = lay(heavy_routes + order)
        if r and (best is None or r[0] < best[0]):
            best, best_order = r, order
    if best is None:
        raise RuntimeError("no complete routing found")
    # local search: move one connection to another place in the order while the total improves
    improved = True
    while improved:
        improved = False
        for k in range(len(best_order)):
            for pos in range(len(best_order)):
                if pos == k:
                    continue
                order = best_order[:k] + best_order[k + 1:]
                order.insert(pos, best_order[k])
                r = lay(heavy_routes + order)
                if r and r[0] < best[0]:
                    best, best_order, improved = r, order, True
                    break
    print("routing score", best[0])
    joints = {}
    for path, layer, net, heavy in best[1]:
        joints.setdefault((net, layer), set()).update({path[0], path[-1]})
    for path, layer, net, heavy in best[1]:
        js = joints[(net, layer)]
        # merge straight runs into single tracks
        corners = [path[0]] + [path[k] for k in range(1, len(path) - 1)
                               if (path[k][0] - path[k - 1][0], path[k][1] - path[k - 1][1]) !=
                               (path[k + 1][0] - path[k][0], path[k + 1][1] - path[k][1]) or path[k] in js] + [path[-1]]
        for p0, p1 in zip(corners, corners[1:]):
            t = pcbnew.PCB_TRACK(board)
            t.SetStart(V(G(*p0)))
            t.SetEnd(V(G(*p1)))
            t.SetWidth(pcbnew.FromMM(HEAVY if heavy else LIGHT))
            t.SetLayer(layer)
            t.SetNet(netinfo(net))
            board.Add(t)

    # notes
    for k, line in enumerate(["Piper-Watch Level 2 perfboard (70 x 50) - top view, back of the case at the top",
                              "copper = bare solid wire underneath (heavy 0.6 = 19 V, GND, motor); red = insulated wire underneath",
                              "via at the middle-left = the board ground point; screw openings of J6 J1 J3 face the back edge"]):
        tx = pcbnew.PCB_TEXT(board)
        tx.SetText(line)
        tx.SetPosition(V((BX, BY + BH + 4 + 2.5 * k)))
        tx.SetLayer(pcbnew.Cmts_User)
        tx.SetTextSize(V((1.2, 1.2)))
        tx.SetHorizJustify(pcbnew.GR_TEXT_H_ALIGN_LEFT)
        board.Add(tx)

    ds = board.GetDesignSettings()
    ds.m_TrackMinWidth = pcbnew.FromMM(0.2)
    pcbnew.SaveBoard(OUT, board)
    print("written", os.path.normpath(OUT), "-", sum(1 for _ in board.GetTracks()), "tracks/vias")


if __name__ == "__main__":
    main()
