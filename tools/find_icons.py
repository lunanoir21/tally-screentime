#!/usr/bin/env python3
"""Finds app icons by name and prints them as data: URIs (JSON).

    find_icons.py firefox kitty /opt/app/icon.png ...  ->  {"firefox": "data:image/svg+xml;base64,...", ...}

A name is looked up in the icon themes on the machine (PNG near 64 px, else an
SVG); an absolute path is read as it is. Icons over 120 KB, and names with no
file, are left out. Only the standard library is used.
"""
import base64
import json
import os
import re
import sys

MAX_BYTES = 120 * 1024
HOME = os.path.expanduser("~")
DIRS = [
    HOME + "/.local/share/icons", HOME + "/.icons", "/usr/local/share/icons", "/usr/share/icons",
    HOME + "/.local/share/flatpak/exports/share/icons", "/var/lib/flatpak/exports/share/icons",
    "/usr/local/share/pixmaps", "/usr/share/pixmaps",
]
MIME = {".png": "image/png", ".svg": "image/svg+xml"}
# Extra folders to search first (colon separated); the tests use this.
DIRS = [d for d in os.environ.get("TALLY_ICON_DIRS", "").split(":") if d] + DIRS


def score(path):
    """Higher is better: a 64 px PNG beats everything, then nearby sizes, then SVG."""
    low = path.lower()
    if "symbolic" in low:
        return -1000
    ext = os.path.splitext(low)[1]
    if ext == ".svg":
        return -30
    m = re.search(r"/(\d+)x\1(?:@\d+x)?/", low) or re.search(r"/(\d+)/", low)
    size = int(m.group(1)) if m else 48
    return -abs(size - 64)


def index(wanted):
    found = {}
    for base in DIRS:
        if not os.path.isdir(base):
            continue
        for root, _dirs, files in os.walk(base):
            for f in files:
                stem, ext = os.path.splitext(f)
                if stem in wanted and ext.lower() in MIME:
                    found.setdefault(stem, []).append(os.path.join(root, f))
    return found


def uri(path):
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return ""
        with open(path, "rb") as fh:
            raw = fh.read()
    except OSError:
        return ""
    return "data:%s;base64,%s" % (MIME[os.path.splitext(path)[1].lower()], base64.b64encode(raw).decode("ascii"))


def main(names):
    out = {}
    named = [n for n in names if not n.startswith("/")]
    found = index(set(named)) if named else {}
    for n in names:
        if n.startswith("/"):
            if os.path.splitext(n)[1].lower() in MIME:
                u = uri(n)
                if u:
                    out[n] = u
            continue
        for p in sorted(found.get(n, []), key=score, reverse=True):
            u = uri(p)
            if u:
                out[n] = u
                break
    json.dump(out, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
