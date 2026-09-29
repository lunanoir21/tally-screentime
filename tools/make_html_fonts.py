#!/usr/bin/env python3
"""Builds ui/html/fonts.css: the two typefaces of the HTML report, subset to
what it prints and inlined as base64 WOFF, so a report is one file that looks
the same on any machine.

    tools/make_html_fonts.py

Needs fontTools (pip install fonttools). Re-run only if the fonts change.
"""
import base64
import io
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, "..", "ui", "fonts")
OUT = os.path.join(HERE, "..", "ui", "html", "fonts.css")

MONO_TEXT = (
    list(range(0x20, 0x7F)) + list(range(0xA0, 0x180))
    + [0x2013, 0x2014, 0x2022, 0x2026, 0x2190, 0x2191, 0x2192, 0x2193, 0x25B2, 0x25BC, 0xB7, 0x25D0]
)
DISPLAY_TEXT = [ord(c) for c in "0123456789 shdmtally%:.,-–"]


def woff(font):
    buf = io.BytesIO()
    font.flavor = "woff"
    font.save(buf)
    return base64.b64encode(buf.getvalue()).decode("ascii")


def subset_font(path, unicodes, instance=None):
    font = TTFont(path)
    if instance:
        font = instancer.instantiateVariableFont(font, instance)
    opts = subset.Options()
    opts.layout_features = ["kern", "liga", "calt", "zero"]
    opts.name_IDs = [1, 2]
    opts.notdef_outline = True
    opts.drop_tables += ["DSIG"]
    s = subset.Subsetter(opts)
    s.populate(unicodes=unicodes)
    s.subset(font)
    return font


def face(family, weight, data):
    return (
        "@font-face{font-family:'%s';font-weight:%s;font-style:normal;font-display:swap;"
        "src:url(data:font/woff;base64,%s) format('woff')}\n" % (family, weight, data)
    )


def main():
    css = []
    for name, weight in (("JetBrainsMono-Regular.ttf", 400), ("JetBrainsMono-Medium.ttf", 500)):
        css.append(face("Tally Mono", weight, woff(subset_font(os.path.join(FONTS, name), MONO_TEXT))))
    disp = subset_font(os.path.join(FONTS, "BricolageGrotesque.ttf"), DISPLAY_TEXT,
                       {"wght": 300, "opsz": 72, "wdth": 100})
    css.append(face("Tally Display", 300, woff(disp)))
    disp5 = subset_font(os.path.join(FONTS, "BricolageGrotesque.ttf"), DISPLAY_TEXT,
                        {"wght": 500, "opsz": 24, "wdth": 100})
    css.append(face("Tally Display", 500, woff(disp5)))
    with open(OUT, "w") as fh:
        fh.write("".join(css))
    print("wrote %s (%.1f KB)" % (os.path.relpath(OUT), os.path.getsize(OUT) / 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
