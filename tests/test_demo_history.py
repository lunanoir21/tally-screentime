import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
import unittest

TOOL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools", "make_demo_history.py")


class DemoHistory(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        subprocess.run([sys.executable, TOOL, self.dir, "--today", "2026-09-29", "--weeks", "6"], check=True, capture_output=True)
        with open(os.path.join(self.dir, "history.json")) as fh:
            self.days = json.load(fh)["days"]

    def test_totals_add_up(self):
        for key, d in self.days.items():
            self.assertEqual(sum(d["apps"].values()), d["total"], key)
            self.assertEqual(sum(d["h"]), d["total"], key)
            self.assertEqual(len(d["h"]), 24, key)
            self.assertGreaterEqual(min(d["h"]), 0, key)

    def test_range_and_today(self):
        self.assertEqual(len(self.days), 42)
        self.assertIn("2026-09-29", self.days)
        self.assertNotIn("2026-09-30", self.days)
        self.assertEqual(self.days["2026-09-29"]["total"] // 60000, 252)
        self.assertEqual(sum(self.days["2026-09-29"]["h"][17:]), 0)  # today is still going

    def test_no_day_is_longer_than_a_day(self):
        for key, d in self.days.items():
            self.assertLess(d["total"], 24 * 3600000, key)

    def test_same_seed_same_history(self):
        other = tempfile.mkdtemp()
        subprocess.run([sys.executable, TOOL, other, "--today", "2026-09-29", "--weeks", "6"], check=True, capture_output=True)
        with open(os.path.join(other, "history.json")) as a, open(os.path.join(self.dir, "history.json")) as b:
            self.assertEqual(a.read(), b.read())


if __name__ == "__main__":
    unittest.main()
