#!/usr/bin/env python3
"""Move one servo to an angle (degrees from centre) slowly and HOLD it there (torque stays on).

usage: py goto.py [--id N] [--speed S] ANGLE        e.g.  py goto.py --id 2 -53.3
       py goto.py [--id N] --release                torque off (the servo turns freely)
"""
import argparse
import time

from sts import Bus, deg_to_pos, pos_to_deg

ap = argparse.ArgumentParser()
ap.add_argument("--id", type=int, default=1, help="servo ID (1 = pan, 2 = tilt)")
ap.add_argument("--speed", type=int, default=300, help="steps/s (300 = ~26 deg/s)")
ap.add_argument("--acc", type=int, default=10)
ap.add_argument("--release", action="store_true", help="turn torque off and exit")
ap.add_argument("angle", nargs="?", type=float)
args = ap.parse_args()

bus = Bus()
try:
    if args.release:
        bus.torque(args.id, False)
        print(f"ID {args.id}: torque off")
    else:
        bus.torque(args.id, True)
        bus.goto(args.id, deg_to_pos(args.id, args.angle), args.speed, args.acc)
        t0 = time.time()
        time.sleep(0.2)
        while bus.status(args.id)["moving"] and time.time() - t0 < 20:
            time.sleep(0.05)
        s = bus.status(args.id)
        print(f"ID {args.id}: at {pos_to_deg(args.id, s['pos']):+.1f} deg (holding), load {s['load%']:+.1f} %")
finally:
    bus.close()
