import base64
import json
import os
import subprocess
import sys
import tempfile
import unittest

TOOL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools", "find_icons.py")


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(data)


class FindIcons(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        t = os.path.join(self.root, "hicolor")
        write(t + "/48x48/apps/foo.png", b"PNG48")
        write(t + "/64x64/apps/foo.png", b"PNG64")
        write(t + "/256x256/apps/foo.png", b"PNG256")
        write(t + "/scalable/apps/foo.svg", b"<svg/>")
        write(t + "/scalable/apps/only-svg.svg", b"<svg id='x'/>")
        write(t + "/symbolic/apps/sym-symbolic.svg", b"<svg/>")
        write(t + "/64x64/apps/huge.png", b"x" * (130 * 1024))
        write(self.root + "/loose.png", b"LOOSE")

    def run_tool(self, *names):
        env = dict(os.environ, TALLY_ICON_DIRS=self.root)
        r = subprocess.run([sys.executable, TOOL, *names], capture_output=True, text=True, env=env)
        self.assertEqual(r.returncode, 0, r.stderr)
        return json.loads(r.stdout)

    def decode(self, uri):
        head, b64 = uri.split(",", 1)
        return head, base64.b64decode(b64)

    def test_prefers_the_png_nearest_64(self):
        head, raw = self.decode(self.run_tool("foo")["foo"])
        self.assertEqual(head, "data:image/png;base64")
        self.assertEqual(raw, b"PNG64")

    def test_falls_back_to_svg(self):
        head, raw = self.decode(self.run_tool("only-svg")["only-svg"])
        self.assertEqual(head, "data:image/svg+xml;base64")
        self.assertEqual(raw, b"<svg id='x'/>")

    def test_symbolic_icons_are_last_resort_only(self):
        out = self.run_tool("sym-symbolic")
        # still returned (it is the only file), but never chosen over a real icon
        self.assertIn("sym-symbolic", out)

    def test_missing_and_oversized_are_left_out(self):
        out = self.run_tool("nope", "huge")
        self.assertEqual(out, {})

    def test_absolute_paths_are_read_as_they_are(self):
        p = os.path.join(self.root, "loose.png")
        out = self.run_tool(p)
        self.assertEqual(self.decode(out[p])[1], b"LOOSE")

    def test_several_names_at_once(self):
        out = self.run_tool("foo", "only-svg", "nope")
        self.assertEqual(sorted(out), ["foo", "only-svg"])


if __name__ == "__main__":
    unittest.main()
