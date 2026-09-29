"""The cost numbers in the READMEs and on the website are the ones in
docs/data/measure.json, not remembered ones."""
import json
import os
import re
import unittest

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def read(*p):
    with open(os.path.join(ROOT, *p), encoding="utf-8") as fh:
        return fh.read()


class Numbers(unittest.TestCase):
    def setUp(self):
        self.m = json.loads(read("docs", "data", "measure.json"))
        self.rows = self.m["rows"]

    def test_the_readme_table_matches(self):
        text = read("README.md").replace("**", "")
        for r in self.rows:
            line = "%.2f | %.0f MB | %.1f" % (r["cpu"], r["rss_mb"], r["wakeups"])
            self.assertIn(line, text, r["name"])

    def test_the_site_table_matches(self):
        html = read("docs", "index.html")
        for r in self.rows:
            self.assertIn("<td>%.2f %%</td><td>%.0f MB</td><td>%.1f</td>" % (r["cpu"], r["rss_mb"], r["wakeups"]), html, r["name"])

    def test_the_headline_sentence_matches(self):
        base, closed = self.rows[0], self.rows[1]
        text = read("README.md")
        self.assertIn("**%.1f %% of a core, %.0f MB and half a wakeup per second**" % (closed["cpu"] - base["cpu"], closed["rss_mb"] - base["rss_mb"]), text)

    def test_the_peak_matches(self):
        text = read("README.md")
        self.assertIn("peaks at %.0f MB" % self.m["export"]["peak_mb"], text)
        self.assertIn("about %.0f MB over" % self.m["export"]["extra_mb"], text)


if __name__ == "__main__":
    unittest.main()
