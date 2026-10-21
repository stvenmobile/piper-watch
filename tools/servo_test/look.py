#!/usr/bin/env python3
"""Pan + tilt together: move both servos at once through a list of "looks", report each, hold at the end.

usage: py look.py [--speed S] [--acc A]
Angles are servo degrees (robot convention: pan + = left, tilt + = up); tilt is clamped to LIMITS in sts.py.
"""
import argparse
import time

from sts import Bus, deg_to_pos, pos_to_deg

PAN, TILT = 1, 2
T_LEVEL = -33.0       # tilt servo angle with the head about level (by eye)
T_UP = 6.3            # max up
T_DOWN = -70.0        # max down

LOOKS = [             # (name, pan, tilt)
    ("forward", 0, T_LEVEL),
    ("left", 60, T_LEVEL),
    ("right", -60, T_LEVEL),
    ("forward", 0, T_LEVEL),
    ("up", 0, T_UP),
    ("down", 0, T_DOWN),
    ("up-left", 45, T_UP),
    ("down-right", -45, T_DOWN),
    ("up-right", -45, T_UP),
    ("down-left", 45, T_DOWN),
    ("far left", 90, T_LEVEL),
    ("far right", -90, T_LEVEL),
    ("forward", 0, T_LEVEL),
]

ap = argparse.ArgumentParser()
ap.add_argument("--speed", type=int, default=400, help="steps/s (400 = ~35 deg/s)")
ap.add_argument("--acc", type=int, default=15)
ap.add_argument("--hold", type=float, default=1.0, help="seconds at each look")
args = ap.parse_args()

bus = Bus()
try:
    for sid in (PAN, TILT):
        if bus.ping(sid) is None:
            raise SystemExit(f"ID {sid} doesn't answer - is it on the bus?")
        bus.torque(sid, True)
    for name, p, t in LOOKS:
        bus.goto(PAN, deg_to_pos(PAN, p), args.speed, args.acc)
        bus.goto(TILT, deg_to_pos(TILT, t), args.speed, args.acc)
        t0 = time.time()
        time.sleep(0.2)
        while (bus.status(PAN)["moving"] or bus.status(TILT)["moving"]) and time.time() - t0 < 20:
            time.sleep(0.05)
        sp, st = bus.status(PAN), bus.status(TILT)
        print(f"{name:10s} pan {pos_to_deg(PAN, sp['pos']):+6.1f} (load {sp['load%']:+5.1f} %)   "
              f"tilt {pos_to_deg(TILT, st['pos']):+6.1f} (load {st['load%']:+5.1f} %)   "
              f"{time.time() - t0:4.1f} s, {sp['volts']:.1f} V")
        time.sleep(args.hold)
    print("holding forward")
except KeyboardInterrupt:
    print("stopped - torque off")
    for sid in (PAN, TILT):
        bus.torque(sid, False)
finally:
    bus.close()
