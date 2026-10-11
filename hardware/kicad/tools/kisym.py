"""Tiny helpers for reading KiCad symbol libraries (S-expressions) - used by gen_schematics.py."""
import os
import re

KICAD_SYMS = r"C:\Program Files\KiCad\10.0\share\kicad\symbols"


def block(text, start):
    """Return the balanced (...) block starting at text[start] == '('."""
    depth, i, instr = 0, start, False
    while i < len(text):
        c = text[i]
        if instr:
            if c == "\\":
                i += 1
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
        i += 1
    raise ValueError("unbalanced")


def lib_symbol(lib, name):
    """The top-level (symbol "name" ...) block from a KiCad library file."""
    text = open(os.path.join(KICAD_SYMS, lib + ".kicad_sym"), encoding="utf-8").read()
    m = re.search(r'\n\t\(symbol "%s"\n' % re.escape(name), text)
    if not m:
        raise KeyError(f"{lib}:{name}")
    return block(text, m.start() + 2)


PIN_RE = re.compile(r'\(pin \w+ \w+\s*\(at ([-\d.]+) ([-\d.]+) ([-\d.]+)\).*?\(name "([^"]*)".*?\(number "([^"]*)"', re.S)


def pins(sym_text):
    """[(number, name, x, y, angle)] in symbol coordinates (Y up)."""
    return [(m.group(5), m.group(4), float(m.group(1)), float(m.group(2)), float(m.group(3)))
            for m in PIN_RE.finditer(sym_text)]
