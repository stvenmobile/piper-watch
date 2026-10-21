#!/usr/bin/env python3
"""Slow test sweep: move through a list of angles (degrees from centre), report at each stop, then release.

usage: py sweep.py [--id N] [--speed S] [--acc A] [angle ...]     e.g.  py sweep.py --id 2 0 15 -15 0
"""
import argparse
import time

from sts import STEPS_PER_DEG, Bus, deg_to_pos, pos_to_deg

HOLD_S = 1.0     # pause at each stop

ap = argparse.ArgumentParser()
ap.add_argument("--id", type=int, default=1, help="servo ID (1 = pan, 2 = tilt)")
ap.add_argument("--speed", type=int, default=300, help="steps/s (300 = ~26 deg/s; max ~3000)")
ap.add_argument("--acc", type=int, default=10, help="x100 steps/s^2 (10 = gentle)")
ap.add_argument("angles", nargs="*", type=float, help="degrees from centre")
args = ap.parse_args()
SID, SPEED, ACC = args.id, args.speed, args.acc
ANGLES = args.angles or [0, 45, -45, 90, -90, 170, -170, 0]
print(f"ID {SID}: speed {SPEED} steps/s (~{SPEED / STEPS_PER_DEG:.0f} deg/s), acc {ACC}")

bus = Bus()
try:
    bus.torque(SID, True)
    for deg in ANGLES:
        goal = deg_to_pos(SID, deg)
        bus.goto(SID, goal, SPEED, ACC)
        t0 = time.time()
        time.sleep(0.2)
        while bus.status(SID)["moving"] and time.time() - t0 < 20:
            time.sleep(0.05)
        s = bus.status(SID)
        print(f"{deg:+7.1f} deg -> {pos_to_deg(SID, s['pos']):+7.1f} (pos {s['pos']:4d}), "
              f"{time.time() - t0:4.1f} s, load {s['load%']:+5.1f} %, {s['volts']:.1f} V, {s['temp']} C")
        time.sleep(HOLD_S)
except KeyboardInterrupt:
    print("stopped")
finally:
    bus.torque(SID, False)
    bus.close()
