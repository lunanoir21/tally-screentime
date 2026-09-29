"""The website's promises: its theme list is the app's, and its demo page is
the current report script."""
import os
import re
import unittest

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def read(*p):
    with open(os.path.join(ROOT, *p), encoding="utf-8") as fh:
        return fh.read()


def themes_from(text, pattern):
    return [m for m in re.findall(pattern, text)]


class Site(unittest.TestCase):
    def test_same_themes_as_the_app(self):
        app = re.findall(r'id: "(\w+)", name: "([^"]+)", tag: "\w+", sw: \[[^\]]*\], card: "(#\w+)", fg: "(#\w+)", acc: "(#\w+)"',
                         read("ui", "js", "Themes.js"))
        site = re.findall(r'id: "(\w+)", name: "([^"]+)", (?:en: "[^"]+", )?sw: \[[^\]]*\], card: "(#\w+)", fg: "(#\w+)", acc: "(#\w+)"',
                          read("docs", "index.html"))
        self.assertEqual(len(app), 16)
        self.assertEqual(site, app)

    def test_english_names_for_the_two_translated_themes(self):
        html = read("docs", "index.html")
        self.assertIn('id: "ultrawhite", name: "Ultra Beyaz", en: "Ultra White"', html)
        self.assertIn('id: "system", name: "Sistemi izle", en: "Follow system"', html)

    def test_demo_carries_the_current_report_script(self):
        self.assertIn(read("ui", "html", "report.js"), read("docs", "demo.html"),
                      "docs/demo.html is out of date: rebuild it after changing ui/html/report.js")

    def test_report_only_accepts_plain_colours_from_outside(self):
        js = read("ui", "html", "report.js")
        self.assertIn("'tally-theme'", js)
        self.assertIn("/^#[0-9a-fA-F]{6}$/", js)

    def test_demo_has_no_personal_paths(self):
        demo = read("docs", "demo.html")
        for bad in ("/home/", "@gmail", "@protonmail"):
            self.assertNotIn(bad, demo)

    def test_site_files_it_links_to_exist(self):
        html = read("docs", "index.html")
        for ref in set(re.findall(r'(?:src|href)="((?:assets|screenshots|reports)/[^"#?]+|demo\.html)"', html)):
            self.assertTrue(os.path.exists(os.path.join(ROOT, "docs", ref)), ref)


if __name__ == "__main__":
    unittest.main()
