"""The interactive report's assets: the script parses, the template has every
marker once, and every phrase the script asks for exists in Str.qml."""
import os
import re
import shutil
import subprocess
import unittest

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui")
HTML = os.path.join(ROOT, "html")


def read(*p):
    with open(os.path.join(*p), encoding="utf-8") as fh:
        return fh.read()


class HtmlAssets(unittest.TestCase):
    def test_template_has_each_marker_once(self):
        t = read(HTML, "template.html")
        for m in ("LANG", "LOOK", "TITLE", "FONTS", "CSS", "PAYLOAD", "JS"):
            self.assertEqual(t.count("/*@%s@*/" % m), 1, m)

    def test_script_has_no_closing_script_tag(self):
        self.assertNotIn("</script", read(HTML, "report.js").lower())

    @unittest.skipUnless(shutil.which("node"), "node is not installed")
    def test_script_parses(self):
        r = subprocess.run(["node", "--check", os.path.join(HTML, "report.js")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_css_braces_balance(self):
        css = read(HTML, "report.css")
        self.assertEqual(css.count("{"), css.count("}"))

    def test_fonts_are_inlined(self):
        f = read(HTML, "fonts.css")
        self.assertGreaterEqual(f.count("@font-face"), 4)
        self.assertNotIn("http", f)

    def test_every_phrase_the_script_uses_is_defined(self):
        js = read(HTML, "report.js")
        used = set(re.findall(r"\bT\.(\w+)", js))
        str_qml = read(ROOT, "Str.qml")
        block = str_qml[str_qml.index("function htmlI18n"):]
        defined = set(re.findall(r"^\s+(\w+):", block, re.M))
        missing = sorted(used - defined)
        self.assertEqual(missing, [], "T.* used by report.js but not given by Str.htmlI18n: %s" % missing)

    def test_only_the_button_toggles_the_look(self):
        # <html data-look="..."> carries the current look, so a click handler that
        # matched on [data-look] matched every click anywhere on the page.
        js = read(HTML, "report.js")
        self.assertNotIn("closest('[data-look]')", js)
        self.assertIn("closest('[data-lookbtn]')", js)
        self.assertEqual(js.count("data-lookbtn"), 2)  # the button and its handler

    def test_no_network_calls(self):
        js = read(HTML, "report.js")
        for bad in ("fetch(", "XMLHttpRequest", "http://", "https://", "WebSocket", "sendBeacon", "import("):
            self.assertNotIn(bad, js)
        self.assertNotIn("url(http", read(HTML, "report.css"))


if __name__ == "__main__":
    unittest.main()
