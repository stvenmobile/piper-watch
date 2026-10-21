#!/usr/bin/env python3
"""Write a servo's angle limits (from LIMITS in sts.py) into the servo itself. Does not move it.

usage: py set_limits.py ID          (an ID with no entry in LIMITS gets the full range back)
"""
import sys
import time

from sts import ADDR_LOCK, ADDR_MAX_ANGLE, ADDR_MIN_ANGLE, LIMITS, Bus, deg_to_pos

sid = int(sys.argv[1])
if sid in LIMITS:
    a, b = sorted(deg_to_pos(sid, d) for d in LIMITS[sid])     # raw positions (direction may flip them)
else:
    a, b = 0, 4095


def eeprom(write, *args):
    """EEPROM writes: the servo can miss a command (or not answer) while it saves the last one."""
    for attempt in range(5):
        try:
            write(*args)
            break
        except (IOError, IndexError):
            pass
        time.sleep(0.2)
    time.sleep(0.2)


bus = Bus()
try:
    eeprom(bus.w1, sid, ADDR_LOCK, 0)
    eeprom(bus.w2, sid, ADDR_MIN_ANGLE, a)
    eeprom(bus.w2, sid, ADDR_MAX_ANGLE, b)
    eeprom(bus.w1, sid, ADDR_LOCK, 1)
    print(f"ID {sid}: angle limits now {bus.r2(sid, ADDR_MIN_ANGLE)}..{bus.r2(sid, ADDR_MAX_ANGLE)} (raw)")
finally:
    bus.close()
