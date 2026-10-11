"""Generate the Piper-Watch wiring schematics (KiCad 9/10 format) from the netlists below.

    py -3 hardware/kicad/tools/gen_schematics.py

Writes hardware/kicad/: piper-watch.kicad_pro, piper-watch.kicad_sch (root), power.kicad_sch,
level2.kicad_sch, head.kicad_sch, piper-watch.kicad_sym (the module symbols) and sym-lib-table.

Every connection is a short wire stub + a net label on the pin, so the drawing can be rearranged
freely in KiCad without breaking anything. Nets in GLOBAL cross sheets (global labels); the rest
are local to their sheet. This is the first draft: after editing in KiCad, the KiCad files are the
source of truth - don't re-run this over hand edits.
"""
import math
import os
import uuid

import kisym

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PROJECT = "piper-watch"
LIB = "piper-watch"
G = 2.54
STUB = 2.54
GLOBAL = {"GND", "+19V", "+19V_FUSED", "+19V_SW", "+5V"}
TWO_PIN = {"Device:R", "Device:C_Polarized", "Device:Fuse"}


_seq = [0]


def uid(key=None):
    """Deterministic UUIDs, so re-running gives the same files and the PCB can refer to symbols."""
    if key is None:
        _seq[0] += 1
        key = "seq/%d" % _seq[0]
    return str(uuid.uuid5(uuid.NAMESPACE_URL, "piper-watch/" + key))


# footprints for the parts ON the perfboard; every other symbol is marked on_board no (harness parts)
FOOTPRINTS = {
    "J1": "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal",
    "J6": "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-3-5.08_1x03_P5.08mm_Horizontal",
    "J3": "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-4-5.08_1x04_P5.08mm_Horizontal",
    "J4": "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical",
    "J5": "Connector_PinHeader_2.54mm:PinHeader_1x03_P2.54mm_Vertical",
    "U1": "Module:Pololu_Breakout-16_15.2x20.3mm",
    "C1": "Capacitor_THT:CP_Radial_D8.0mm_P5.00mm",
    "C2": "Capacitor_THT:CP_Radial_D8.0mm_P5.00mm",
    "R1": "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal",
    "R2": "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal",
}


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def fmt(v):
    return ("%.4f" % v).rstrip("0").rstrip(".")


FONT = "(effects (font (size 1.27 1.27)))"
FONT_HIDE = "(effects (font (size 1.27 1.27)) (hide yes))"

# ---- custom module symbols ------------------------------------------------------------------------
# name: (reference prefix, description, left pins [(num, name)], right pins [(num, name)])
CUSTOM = {
    "TMC2209_Module": ("U", "BTT TMC2209 stepper driver module (StepStick), STEP/DIR mode; pins named as on the board",
                       [("1", "GND"), ("2", "VIO"), ("3", "B2"), ("4", "B1"), ("5", "A1"), ("6", "A2"), ("7", "GND"), ("8", "VS")],
                       [("16", "DIR"), ("15", "STEP"), ("14", "CLK"), ("13", "TX"), ("12", "RX"), ("11", "MS2"), ("10", "MS1"), ("9", "EN")]),
    "LM2596_Module": ("U", "LM2596S buck converter module (adjustable, set to 5.0 V)",
                      [("1", "IN+"), ("2", "IN-")], [("3", "OUT+"), ("4", "OUT-")]),
    "Barrier_Strip_2x2": ("TB", "2-circuit barrier terminal strip (M3.5 screws, spade lugs): two screws per circuit",
                          [("1", "1A"), ("3", "2A")], [("2", "1B"), ("4", "2B")]),
    "A3144": ("U", "A3144 Hall switch, TO-92 (open collector, needs a pull-up)",
              [("1", "VCC"), ("2", "GND")], [("3", "OUT")]),
    "ESP32-S3-DevKitC-1": ("U", "ESP32-S3-DevKitC-1 (ESP32-S3-N16R8): 2 x 22 headers. GPIO35-37 are used by the octal PSRAM",
                           [("1", "3V3"), ("2", "3V3"), ("3", "RST"), ("4", "GPIO4"), ("5", "GPIO5"), ("6", "GPIO6"), ("7", "GPIO7"),
                            ("8", "GPIO15"), ("9", "GPIO16"), ("10", "GPIO17"), ("11", "GPIO18"), ("12", "GPIO8"), ("13", "GPIO3"),
                            ("14", "GPIO46"), ("15", "GPIO9"), ("16", "GPIO10"), ("17", "GPIO11"), ("18", "GPIO12"), ("19", "GPIO13"),
                            ("20", "GPIO14"), ("21", "5V"), ("22", "GND")],
                           [("23", "GND"), ("24", "TX/GPIO43"), ("25", "RX/GPIO44"), ("26", "GPIO1"), ("27", "GPIO2"), ("28", "GPIO42"),
                            ("29", "GPIO41"), ("30", "GPIO40"), ("31", "GPIO39"), ("32", "GPIO38"), ("33", "GPIO37"), ("34", "GPIO36"),
                            ("35", "GPIO35"), ("36", "GPIO0"), ("37", "GPIO45"), ("38", "GPIO48"), ("39", "GPIO47"), ("40", "GPIO21"),
                            ("41", "GPIO20"), ("42", "GPIO19"), ("43", "GND"), ("44", "GND")]),
    "XIAO_ESP32S3": ("U", "Seeed Studio XIAO ESP32-S3",
                     [("1", "D0/GPIO1"), ("2", "D1/GPIO2"), ("3", "D2/GPIO3"), ("4", "D3/GPIO4"), ("5", "D4/GPIO5"), ("6", "D5/GPIO6"),
                      ("7", "D6/GPIO43")],
                     [("14", "5V"), ("13", "GND"), ("12", "3V3"), ("11", "D10/GPIO9"), ("10", "D9/GPIO8"), ("9", "D8/GPIO7"),
                      ("8", "D7/GPIO44")]),
    "GC9A01_Module": ("U", "1.28 in round 240 x 240 TFT, GC9A01, SPI (check the module's pin labels; BL may be absent)",
                      [("1", "VCC"), ("2", "GND"), ("3", "SCL"), ("4", "SDA")], [("5", "DC"), ("6", "CS"), ("7", "RST"), ("8", "BL")]),
    "SH1122_OLED": ("U", "2.08 in 256 x 64 OLED, SH1122, 4-wire SPI, 7-pin header (check VCC/GND order on arrival)",
                    [("1", "GND"), ("2", "VCC"), ("3", "SCL"), ("4", "SDA")], [("5", "RES"), ("6", "DC"), ("7", "CS")]),
}


def custom_symbol(name, prefixed):
    ref, desc, left, right = CUSTOM[name]
    n = max(len(left), len(right))
    ll = max((len(p[1]) for p in left), default=0)
    lr = max((len(p[1]) for p in right), default=0)
    w = max(10.16, math.ceil(((ll + lr) * 1.05 + 5) / (2 * G)) * 2 * G)   # ~1 mm per character at 1.27 mm text
    top = math.ceil((n - 1) / 2)
    y0 = (top + 1) * G
    y1 = (top - n) * G
    out = [f"(symbol {q(prefixed)} (pin_names (offset 1.016)) (exclude_from_sim no) (in_bom yes) (on_board yes)",
           f"(property \"Reference\" {q(ref)} (at 0 {fmt(y0 + 1.27)} 0) {FONT})",
           f"(property \"Value\" {q(name)} (at 0 {fmt(y1 - 1.27)} 0) {FONT})",
           f"(property \"Footprint\" \"\" (at 0 0 0) {FONT_HIDE})",
           f"(property \"Datasheet\" \"\" (at 0 0 0) {FONT_HIDE})",
           f"(property \"Description\" {q(desc)} (at 0 0 0) {FONT_HIDE})",
           f"(symbol {q(name + '_0_1')} (rectangle (start {fmt(-w / 2)} {fmt(y0)}) (end {fmt(w / 2)} {fmt(y1)}) "
           f"(stroke (width 0.254) (type default)) (fill (type background))))",
           f"(symbol {q(name + '_1_1')}"]
    for side, plist in ((-1, left), (1, right)):
        for i, (num, pname) in enumerate(plist):
            x = side * (w / 2 + G)
            y = (top - i) * G
            ang = 0 if side < 0 else 180
            out.append(f"(pin passive line (at {fmt(x)} {fmt(y)} {ang}) (length {G}) (name {q(pname)} {FONT}) (number {q(num)} {FONT}))")
    out.append("))")
    return "\n".join(out)


def symbol_def(lib_id):
    """Symbol text for lib_symbols (name prefixed with the library) and its pins."""
    lib, name = lib_id.split(":")
    if lib == LIB:
        text = custom_symbol(name, lib_id)
    else:
        text = kisym.lib_symbol(lib, name)
        text = text.replace(f'(symbol "{name}"', f'(symbol "{lib_id}"', 1)
    return text, {p[0]: p for p in kisym.pins(text)}


# ---- the netlists ----------------------------------------------------------------------------------
# part: (ref, lib_id, value, (x, y), {pin number: net or None = no-connect}, note)
def P(ref, lib_id, value, at, nets):
    return dict(ref=ref, lib_id=lib_id, value=value, at=at, nets=nets)


ESP_NC = {str(i): None for i in range(1, 45)}
ESP_NETS = dict(ESP_NC)
ESP_NETS.update({"1": "+3V3", "2": None, "4": "STEP", "5": "DIR", "6": "EN", "7": "HALL", "22": "GND", "23": "GND"})

SHEETS = [
    dict(file="power.kicad_sch", name="Power", paper="A4", title="Power: 19 V in, split block, panel fuse, switch, 5 V buck",
         notes=["19 V supply -> panel jack -> split block TB1 (on Level 2's floor). TB1's - side is the COMMON GROUND.",
                "The Jetson is fed straight from TB1: always on, never switched or fused here (the supply limits it).",
                "Head side: TB1 + -> panel fuse F1 (6 x 30 mm, 3 A slow-blow) -> rocker switch SW1 -> perfboard J1 (+19V_SW).",
                "Fuse holder: TB1 to its END contact, its SIDE contact to the switch (an unscrewed cap's exposed end is dead).",
                "U2 (LM2596 buck, on its own floor bosses) is fed from perfboard J6; set it to 5.0 V before connecting the Hall sensor."],
         parts=[P("J7", "Connector:Barrel_Jack", "19 V panel jack (5.5 x 2.1)", (40.64, 63.5), {"1": "+19V", "2": "GND"}),
                P("TB1", f"{LIB}:Barrier_Strip_2x2", "19 V split block", (93.98, 63.5), {"1": "+19V", "2": "+19V", "3": "GND", "4": "GND"}),
                P("J8", "Connector_Generic:Conn_01x02", "Jetson DC in (19 V)", (167.64, 101.6), {"1": "+19V", "2": "GND"}),
                P("F1", "Device:Fuse", "3 A slow-blow, 6 x 30 panel holder", (147.32, 55.88), {"1": "+19V", "2": "+19V_FUSED"}),
                P("SW1", "Switch:SW_SPST", "rocker XW-604B (head power)", (190.5, 50.8), {"1": "+19V_FUSED", "2": "+19V_SW"}),
                P("U2", f"{LIB}:LM2596_Module", "LM2596 buck -> 5.0 V", (241.3, 101.6), {"1": "+19V_SW", "2": "GND", "3": "+5V", "4": "GND"})]),
    dict(file="level2.kicad_sch", name="Level 2 drive", paper="A3", title="Level 2: perfboard (TMC2209), base ESP32-S3, Hall sensor, motor",
         notes=["PERFBOARD (70 x 50): screw terminals J1 (19 V in), J3 (motor), J6 (buck); pin headers J4 (ESP32), J5 (Hall) with Dupont housings.",
                "Heavy wire (20-22 AWG): 19 V, GND, motor. C1 sits right at U1's VS and the GND next to it; C2 (optional) at J1.",
                "U1 MS1 = MS2 = 3V3: 1/16 microstepping. CLK, TX, RX and DIAG unconnected. Set Vref ~0.7 V before connecting the motor.",
                "R2 (optional) holds EN high (motor off) while the ESP32 boots.",
                "Motor M1: 6-pin socket, pins 1+3 = coil A (red, blue) -> A1, A2; pins 4+6 = coil B (green, black) -> B1, B2; pins 2, 5 (centre taps) unused.",
                "U3 (base ESP32-S3) is powered by its USB cable from the Jetson - never also from the buck's 5 V.",
                "Hall U4 (A3144) on the motor bracket's pad: VCC from the 5 V buck, OUT pulled up to 3V3 by R1 (never to 5 V)."],
         parts=[P("J1", "Connector:Screw_Terminal_01x02", "19V in (switched, fused)", (63.5, 50.8), {"1": "+19V_SW", "2": "GND"}),
                P("J6", "Connector:Screw_Terminal_01x03", "to buck: 19V, GND, 5V", (63.5, 81.28), {"1": "+19V_SW", "2": "GND", "3": "+5V"}),
                P("J3", "Connector:Screw_Terminal_01x04", "motor: A1 A2 B1 B2", (63.5, 116.84), {"1": "MOT_A1", "2": "MOT_A2", "3": "MOT_B1", "4": "MOT_B2"}),
                P("J4", "Connector_Generic:Conn_01x06", "to ESP32: STEP DIR EN HALL 3V3 GND", (63.5, 160.02),
                  {"1": "STEP", "2": "DIR", "3": "EN", "4": "HALL", "5": "+3V3", "6": "GND"}),
                P("J5", "Connector_Generic:Conn_01x03", "to Hall: 5V GND OUT", (63.5, 203.2), {"1": "+5V", "2": "GND", "3": "HALL"}),
                P("U1", f"{LIB}:TMC2209_Module", "BTT TMC2209", (162.56, 106.68),
                  {"1": "GND", "2": "+3V3", "3": "MOT_B2", "4": "MOT_B1", "5": "MOT_A1", "6": "MOT_A2", "7": "GND", "8": "+19V_SW",
                   "16": "DIR", "15": "STEP", "14": None, "13": None, "12": None, "11": "+3V3", "10": "+3V3", "9": "EN"}),
                P("C1", "Device:C_Polarized", "100uF 50V (at U1 VS)", (124.46, 165.1), {"1": "+19V_SW", "2": "GND"}),
                P("C2", "Device:C_Polarized", "100uF 50V (opt., at J1)", (154.94, 165.1), {"1": "+19V_SW", "2": "GND"}),
                P("R1", "Device:R", "10k (Hall pull-up)", (185.42, 165.1), {"1": "+3V3", "2": "HALL"}),
                P("R2", "Device:R", "10k (opt., EN pull-up)", (215.9, 165.1), {"1": "+3V3", "2": "EN"}),
                P("U3", f"{LIB}:ESP32-S3-DevKitC-1", "ESP32-S3-DevKitC-1 N16R8", (299.72, 127.0), ESP_NETS),
                P("U4", f"{LIB}:A3144", "A3144 (homing)", (299.72, 210.82), {"1": "+5V", "2": "GND", "3": "HALL"}),
                P("M1", "Motor:Stepper_Motor_bipolar", "NEMA17 (42 x 33.4)", (378.46, 76.2),
                  {"1": "MOT_A1", "2": "MOT_A2", "3": "MOT_B1", "4": "MOT_B2"})]),
    dict(file="head.kicad_sch", name="Head", paper="A4", title="Head: XIAO ESP32-S3, two GC9A01 eyes, SH1122 mouth",
         notes=["The XIAO and the C920 camera each have their own USB cable to the Jetson, through the turntable's hollow.",
                "No Wi-Fi/BT: the XIAO's antenna stays unplugged. Displays run from the XIAO's 3V3 (~150-250 mA total).",
                "One SPI bus (SCL, SDA, DC, RST shared); a CS per display. 26-28 AWG silicone wire soldered straight to the pads.",
                "The eyes mount upside down: the firmware rotates their image 180 deg. D2 (GPIO3, strapping), D7, D9 free."],
         parts=[P("U5", f"{LIB}:XIAO_ESP32S3", "XIAO ESP32-S3", (78.74, 101.6),
                  {"1": "DC", "2": "RST", "3": None, "4": "CS_L", "5": "CS_R", "6": "CS_M", "7": "BL",
                   "14": None, "13": "GND_H", "12": "+3V3_H", "11": "MOSI", "10": None, "9": "SCK", "8": None}),
                P("U6", f"{LIB}:GC9A01_Module", "left eye GC9A01", (180.34, 63.5),
                  {"1": "+3V3_H", "2": "GND_H", "3": "SCK", "4": "MOSI", "5": "DC", "6": "CS_L", "7": "RST", "8": "BL"}),
                P("U7", f"{LIB}:GC9A01_Module", "right eye GC9A01", (180.34, 106.68),
                  {"1": "+3V3_H", "2": "GND_H", "3": "SCK", "4": "MOSI", "5": "DC", "6": "CS_R", "7": "RST", "8": "BL"}),
                P("U8", f"{LIB}:SH1122_OLED", "mouth OLED 2.08in SH1122", (180.34, 149.86),
                  {"1": "GND_H", "2": "+3V3_H", "3": "SCK", "4": "MOSI", "5": "RST", "6": "DC", "7": "CS_M"})]),
]


# ---- writers ---------------------------------------------------------------------------------------
def wire(a, b):
    return f"(wire (pts (xy {fmt(a[0])} {fmt(a[1])}) (xy {fmt(b[0])} {fmt(b[1])})) (stroke (width 0) (type default)) (uuid {q(uid())}))"


def label(net, at, ang):
    just = "left" if ang in (0, 90) else "right"
    if net in GLOBAL:
        return (f"(global_label {q(net)} (shape passive) (at {fmt(at[0])} {fmt(at[1])} {ang}) (fields_autoplaced yes) "
                f"(effects (font (size 1.27 1.27)) (justify {just})) (uuid {q(uid())}) "
                f"(property \"Intersheetrefs\" \"${{INTERSHEET_REFS}}\" (at {fmt(at[0])} {fmt(at[1])} 0) "
                f"(effects (font (size 1.27 1.27)) (justify {just}) (hide yes))))")
    return (f"(label {q(net)} (at {fmt(at[0])} {fmt(at[1])} {ang}) "
            f"(effects (font (size 1.27 1.27)) (justify {just} bottom)) (uuid {q(uid())}))")


def text(s, at, size=1.27):
    return (f"(text {q(s)} (exclude_from_sim no) (at {fmt(at[0])} {fmt(at[1])} 0) "
            f"(effects (font (size {size} {size})) (justify left bottom)) (uuid {q(uid())}))")


def prop_at(sym_text, prop):
    import re
    m = re.search(r'\(property "%s" "[^"]*"\s*\(at ([-\d.]+) ([-\d.]+) ([-\d.]+)\)' % prop, sym_text)
    return (float(m.group(1)), float(m.group(2)), int(float(m.group(3)))) if m else (0.0, 0.0, 0)


def place(part, defs, path):
    text_, pins = defs[part["lib_id"]]
    sx, sy = part["at"]
    out = []
    r = prop_at(text_, "Reference")
    v = prop_at(text_, "Value")
    on_board = "yes" if part["ref"] in FOOTPRINTS else "no"
    out.append(f"(symbol (lib_id {q(part['lib_id'])}) (at {fmt(sx)} {fmt(sy)} 0) (unit 1) (exclude_from_sim no) (in_bom yes) "
               f"(on_board {on_board}) (dnp no) (uuid {q(uid('sym/' + part['ref']))})")
    if part["lib_id"] in TWO_PIN:          # vertical 2-pin parts: both texts horizontal, to the right
        left = "(effects (font (size 1.27 1.27)) (justify left))"
        out.append(f"(property \"Reference\" {q(part['ref'])} (at {fmt(sx + 3.81)} {fmt(sy - 1.27)} 0) {left})")
        out.append(f"(property \"Value\" {q(part['value'])} (at {fmt(sx + 3.81)} {fmt(sy + 1.27)} 0) {left})")
    else:
        if part["lib_id"] == "Motor:Stepper_Motor_bipolar":
            v = (0.0, -12.7, 0)
        out.append(f"(property \"Reference\" {q(part['ref'])} (at {fmt(sx + r[0])} {fmt(sy - r[1])} {r[2]}) {FONT})")
        out.append(f"(property \"Value\" {q(part['value'])} (at {fmt(sx + v[0])} {fmt(sy - v[1])} {v[2]}) {FONT})")
    out.append(f"(property \"Footprint\" {q(FOOTPRINTS.get(part['ref'], ''))} (at {fmt(sx)} {fmt(sy)} 0) {FONT_HIDE})")
    for p in ("Datasheet", "Description"):
        out.append(f"(property \"{p}\" \"\" (at {fmt(sx)} {fmt(sy)} 0) {FONT_HIDE})")
    for num in pins:
        out.append(f"(pin {q(num)} (uuid {q(uid())}))")
    out.append(f"(instances (project {q(PROJECT)} (path {q(path)} (reference {q(part['ref'])}) (unit 1)))))")
    items = ["\n".join(out)]
    for num, (_, _, px, py, ang) in pins.items():
        if num not in part["nets"]:
            raise KeyError(f"{part['ref']} pin {num} not assigned")
        net = part["nets"][num]
        pt = (sx + px, sy - py)
        if net is None:
            items.append(f"(no_connect (at {fmt(pt[0])} {fmt(pt[1])}) (uuid {q(uid())}))")
            continue
        out_ang = (ang + 180) % 360
        d = (round(math.cos(math.radians(out_ang))), -round(math.sin(math.radians(out_ang))))
        end = (pt[0] + d[0] * STUB, pt[1] + d[1] * STUB)
        items.append(wire(pt, end))
        items.append(label(net, end, int(out_ang)))
    return items


def schematic(sheet_uuid, paper, title, lib_ids, body):
    defs_text = "\n".join(symbol_def(i)[0] for i in sorted(lib_ids))
    return (f"(kicad_sch (version 20250114) (generator \"piper-watch-gen\") (generator_version \"9.0\") (uuid {q(sheet_uuid)}) "
            f"(paper {q(paper)}) (title_block (title {q(title)}) (company \"Piper-Watch\") (comment 1 \"Wiring draft generated from hardware/wiring.md\"))\n"
            f"(lib_symbols\n{defs_text}\n)\n" + "\n".join(body) + "\n(embedded_fonts no))\n")


def main():
    root_uuid = uid("root")
    sheet_blocks = []
    for i, sh in enumerate(SHEETS):
        sh["uuid"] = uid("sheet/" + sh["file"])
        lib_ids = {p["lib_id"] for p in sh["parts"]}
        defs = {i_: symbol_def(i_) for i_ in lib_ids}
        path = f"/{root_uuid}/{sh['uuid']}"
        body = []
        for part in sh["parts"]:
            body += place(part, defs, path)
        y = 180.0 if sh["paper"] == "A4" else 254.0
        for k, n in enumerate(sh["notes"]):
            body.append(text(n, (20.32, y + k * 3.81)))
        open(os.path.join(OUT, sh["file"]), "w", encoding="utf-8", newline="\n").write(
            schematic(uid("file/" + sh["file"]), sh["paper"], sh["title"], lib_ids, body))
        x = 30.48 + i * 76.2
        sheet_blocks.append(
            f"(sheet (at {fmt(x)} 60.96) (size 60.96 30.48) (exclude_from_sim no) (in_bom yes) (on_board yes) (dnp no) "
            f"(stroke (width 0.1524) (type solid)) (fill (color 0 0 0 0.0000)) (uuid {q(sh['uuid'])}) "
            f"(property \"Sheetname\" {q(sh['name'])} (at {fmt(x)} 60.2 0) (effects (font (size 1.524 1.524)) (justify left bottom))) "
            f"(property \"Sheetfile\" {q(sh['file'])} (at {fmt(x)} 92.0 0) (effects (font (size 1.27 1.27)) (justify left top))) "
            f"(instances (project {q(PROJECT)} (path {q('/' + root_uuid)} (page {q(str(i + 2))})))))")
    notes = ["Piper-Watch wiring. Power: the 19 V feed, split block, panel fuse, switch and buck.",
             "Level 2 drive: the perfboard (TMC2209), base ESP32-S3, Hall sensor and motor. Head: the XIAO and the three displays.",
             "Nets that cross sheets use global labels: +19V, +19V_FUSED, +19V_SW, +5V, GND. Everything else is local to its sheet.",
             "USB (data + logic power) runs to the Jetson from: base ESP32-S3, head XIAO ESP32-S3, C920 camera board."]
    root = (f"(kicad_sch (version 20250114) (generator \"piper-watch-gen\") (generator_version \"9.0\") (uuid {q(root_uuid)}) "
            f"(paper \"A4\") (title_block (title \"Piper-Watch wiring\") (company \"Piper-Watch\") "
            f"(comment 1 \"Wiring draft generated from hardware/wiring.md\"))\n(lib_symbols)\n"
            + "\n".join(sheet_blocks) + "\n"
            + "\n".join(text(n, (30.48, 120.0 + k * 5.08), 1.524) for k, n in enumerate(notes))
            + "\n(sheet_instances (path \"/\" (page \"1\")))\n(embedded_fonts no))\n")
    open(os.path.join(OUT, f"{PROJECT}.kicad_sch"), "w", encoding="utf-8", newline="\n").write(root)

    lib = ["(kicad_symbol_lib (version 20241209) (generator \"piper-watch-gen\") (generator_version \"9.0\")"]
    for name in CUSTOM:
        lib.append(custom_symbol(name, name))
    lib.append(")")
    open(os.path.join(OUT, f"{LIB}.kicad_sym"), "w", encoding="utf-8", newline="\n").write("\n".join(lib) + "\n")
    open(os.path.join(OUT, "sym-lib-table"), "w", encoding="utf-8", newline="\n").write(
        f"(sym_lib_table (version 7)\n  (lib (name \"{LIB}\") (type \"KiCad\") (uri \"${{KIPRJMOD}}/{LIB}.kicad_sym\") (options \"\") "
        f"(descr \"Piper-Watch module symbols\"))\n)\n")
    pro = os.path.join(OUT, f"{PROJECT}.kicad_pro")
    if not os.path.exists(pro):
        open(pro, "w", encoding="utf-8", newline="\n").write(
            '{\n  "meta": {\n    "filename": "%s.kicad_pro",\n    "version": 1\n  }\n}\n' % PROJECT)
    print("written to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
