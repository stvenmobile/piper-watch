# Piper-Watch wiring schematics (KiCad)

Open `piper-watch.kicad_pro` in KiCad 10 (or 9). Schematic only - everything is hand-wired, so
there's no PCB. `piper-watch.pdf` is a plot of all the sheets.

| Sheet | What's on it |
|---|---|
| Power | 19 V panel jack, split block (common ground), panel fuse, head switch, Jetson feed, 5 V buck |
| Level 2 drive | the perfboard (TMC2209, C1/C2, R1/R2, J1 J3 J4 J5 J6), base ESP32-S3-DevKitC-1 (N16R8), A3144 Hall, NEMA17 |
| Head | XIAO ESP32-S3, two GC9A01 eyes, SH1122 mouth OLED |

- Connections are made with net labels on short wire stubs, so parts can be moved around freely.
  Nets that cross sheets (`+19V`, `+19V_FUSED`, `+19V_SW`, `+5V`, `GND`) are global labels;
  the rest are local to their sheet.
- The modules (TMC2209, LM2596, ESP32-S3 DevKitC, XIAO, GC9A01, SH1122, A3144, barrier strip) are
  in the project library `piper-watch.kicad_sym`; everything else is from KiCad's standard libraries.
- `tools/gen_schematics.py` generated the first draft from `../wiring.md`. Once the schematics
  have been edited in KiCad, the KiCad files are the source of truth - don't re-run the generator
  over hand edits.

Checks: `kicad-cli sch erc piper-watch.kicad_sch` (0 violations on the draft), and
`kicad-cli sch export pdf piper-watch.kicad_sch` to refresh the PDF.

## Perfboard (Level 2)

`perfboard_wiring.png` is the 70 x 50 perfboard as built: top view, back of the case at the top,
parts on the 2.54 mm hole grid, every pad labelled. Wires are soldered on the underside but drawn
as seen from the top: copper = bare solid wire (thick = 19 V, GND, motor), red = insulated wire
where a run has to cross another.

It's drawn from `piper-watch.kicad_pcb`, which KiCad checks against the schematic (DRC: no
unconnected items, no schematic mismatches). Rebuild:

    "C:\Program Files\KiCad\10.0\bin\python.exe" tools/gen_perfboard.py   # placement + wire routing
    py -3 tools/plot_perfboard.py                                         # the picture (needs matplotlib)

Placement is the `PLACE` table in `gen_perfboard.py`; the wires are laid by a small grid router.
