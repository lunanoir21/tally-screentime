import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "..", "tools", "img2pdf.py")

try:
    from PIL import Image
except ImportError:  # the tool itself falls back to ImageMagick
    Image = None

CAN_MAKE_PNG = Image is not None or shutil.which("magick") or shutil.which("convert")


def make_png(path, w, h):
    if Image is not None:
        im = Image.new("RGBA", (w, h), (15, 15, 16, 255))
        for x in range(0, w, 7):
            im.putpixel((x, h // 2), (236, 236, 236, 255))
        im.save(path)
    else:
        tool = shutil.which("magick") or shutil.which("convert")
        subprocess.run([tool, "-size", "%dx%d" % (w, h), "xc:#0f0f10", path], check=True)


def media_box(pdf):
    with open(pdf, "rb") as fh:
        raw = fh.read()
    m = re.search(rb"/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]", raw)
    return (float(m.group(1)), float(m.group(2))) if m else None


@unittest.skipUnless(CAN_MAKE_PNG, "needs Pillow or ImageMagick to make a test image")
class Img2Pdf(unittest.TestCase):
    def run_tool(self, w, h, *args):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, True)
        png, pdf = os.path.join(d, "in.png"), os.path.join(d, "out.pdf")
        make_png(png, w, h)
        r = subprocess.run([sys.executable, TOOL, png, pdf, *args], capture_output=True, text=True)
        return r, pdf

    def test_a4_page(self):
        r, pdf = self.run_tool(1588, 2246, "--page", "a4")
        self.assertEqual(r.returncode, 0, r.stderr)
        with open(pdf, "rb") as fh:
            raw = fh.read()
        self.assertTrue(raw.startswith(b"%PDF-"))
        w, h = media_box(pdf)
        self.assertAlmostEqual(w, 595.276, delta=1.0)
        self.assertAlmostEqual(h, 841.89, delta=1.5)

    def test_pixel_page_follows_the_render_scale(self):
        # 1600 x 900 css px rendered at 2x -> 3200 x 1800 px -> 1200 x 675 pt
        r, pdf = self.run_tool(3200, 1800, "--page", "px", "--scale", "2")
        self.assertEqual(r.returncode, 0, r.stderr)
        w, h = media_box(pdf)
        self.assertAlmostEqual(w, 1200, delta=1.0)
        self.assertAlmostEqual(h, 675, delta=1.0)

    def test_one_page_only(self):
        r, pdf = self.run_tool(400, 300, "--page", "px", "--scale", "1")
        self.assertEqual(r.returncode, 0, r.stderr)
        if shutil.which("pdfinfo"):
            info = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
            self.assertRegex(info, r"Pages:\s+1\b")

    def test_missing_input_fails_cleanly(self):
        r = subprocess.run([sys.executable, TOOL, "/nonexistent.png", "/tmp/never.pdf"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)
        self.assertIn("no such file", r.stderr)


if __name__ == "__main__":
    unittest.main()
