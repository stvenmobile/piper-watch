#!/usr/bin/env python3
"""Make the servo's CURRENT position read as 2048 (centre); stored in the servo. Does not move it.

usage: py centre_here.py [id]
"""
import sys
import time

from sts import ADDR_POS, ADDR_TORQUE, Bus

sid = int(sys.argv[1]) if len(sys.argv) > 1 else 1
bus = Bus()
try:
    print("before:", bus.r2(sid, ADDR_POS))
    try:
        bus.w1(sid, ADDR_TORQUE, 128)      # STS: 128 -> current position becomes 2048 (offset saved in EEPROM)
    except IOError:
        pass                               # it sometimes doesn't answer while saving - the read below confirms
    time.sleep(0.3)
    bus.w1(sid, ADDR_TORQUE, 0)
    print("after: ", bus.r2(sid, ADDR_POS))
finally:
    bus.close()
