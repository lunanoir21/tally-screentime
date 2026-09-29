#!/usr/bin/env python3
"""Wrap one PNG into a one-page PDF.

    img2pdf.py in.png out.pdf --page a4          # A4 portrait, image fills the page
    img2pdf.py in.png out.pdf --page px          # page = image pixels at 96 dpi
    img2pdf.py in.png out.pdf --page px --scale 2  # the PNG was rendered at 2x

Uses Pillow when it is installed, ImageMagick otherwise. The image goes in as
a high-quality JPEG (q95, no chroma subsampling) so a report stays sharp and
small; exits 2 if neither tool is available.
"""
import argparse
import os
import shutil
import subprocess
import sys

A4_PT = (595.276, 841.890)


def page_points(kind, size_px, scale):
    if kind == "a4":
        return A4_PT
    # 96 css px per inch, 72 pt per inch
    return (size_px[0] / scale * 0.75, size_px[1] / scale * 0.75)


def with_pillow(src, dst, kind, scale):
    from PIL import Image

    im = Image.open(src)
    if im.mode in ("RGBA", "LA", "P"):
        flat = Image.new("RGB", im.size, (255, 255, 255))
        flat.paste(im.convert("RGBA"), mask=im.convert("RGBA").split()[3])
        im = flat
    else:
        im = im.convert("RGB")
    w_pt, _ = page_points(kind, im.size, scale)
    resolution = im.size[0] / (w_pt / 72.0)
    im.save(dst, "PDF", resolution=resolution, quality=95, subsampling=0)


def with_imagemagick(src, dst, kind, scale):
    tool = shutil.which("magick") or shutil.which("convert")
    if not tool:
        raise RuntimeError("no Pillow and no ImageMagick")
    probe = subprocess.run([tool, "identify", "-format", "%w %h", src], capture_output=True, text=True)
    if probe.returncode != 0:
        # `magick identify` differs from the legacy `identify`
        probe = subprocess.run([tool, src, "-format", "%w %h", "info:"], capture_output=True, text=True)
    w, h = (int(x) for x in probe.stdout.split())
    w_pt, _ = page_points(kind, (w, h), scale)
    density = w / (w_pt / 72.0)
    subprocess.run([tool, src, "-background", "white", "-alpha", "remove", "-quality", "95",
                    "-density", "%.3f" % density, "-units", "PixelsPerInch", dst], check=True)


def main(argv):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--page", choices=["a4", "px"], default="px")
    p.add_argument("--scale", type=float, default=2.0, help="pixel scale the PNG was rendered at")
    a = p.parse_args(argv)
    if not os.path.isfile(a.src):
        print("no such file: " + a.src, file=sys.stderr)
        return 1
    try:
        try:
            with_pillow(a.src, a.dst, a.page, a.scale)
        except ImportError:
            with_imagemagick(a.src, a.dst, a.page, a.scale)
    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        return 2
    except Exception as e:  # a real failure, not a missing tool
        print("failed: %s" % e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
