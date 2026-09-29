"""Guards the two-language promise: no Turkish text hiding in the QML, and
every Str.* the UI reads is actually defined in Str.qml."""
import glob
import os
import re
import unittest

UI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui")
TR_CHARS = re.compile("[çğıöşüÇĞİÖŞÜ]")
# Words that are meant to stay as they are in every language.
ALLOWED = {"Türkçe"}


def qml_files():
    return [f for f in sorted(glob.glob(os.path.join(UI, "*.qml"))) if os.path.basename(f) != "Str.qml"]


def lines_of(path):
    with open(path, encoding="utf-8") as fh:
        return list(enumerate(fh.read().splitlines(), 1))


def strip_comments(line):
    i = line.find("//")
    return line if i < 0 else line[:i]


class Strings(unittest.TestCase):
    def test_no_turkish_literals_outside_str(self):
        found = []
        for f in qml_files():
            for n, line in lines_of(f):
                for lit in re.findall(r'"([^"\n]*)"', strip_comments(line)):
                    if TR_CHARS.search(lit) and lit not in ALLOWED:
                        found.append("%s:%d: %r" % (os.path.basename(f), n, lit))
        self.assertEqual(found, [], "Turkish text outside Str.qml:\n" + "\n".join(found))

    def test_every_str_reference_is_defined(self):
        with open(os.path.join(UI, "Str.qml"), encoding="utf-8") as fh:
            src = fh.read()
        defined = set(re.findall(r"property\s+(?:string|var|bool|int|real)\s+(\w+)", src))
        defined |= set(re.findall(r"function\s+(\w+)\s*\(", src))
        missing = []
        for f in qml_files():
            for n, line in lines_of(f):
                for name in re.findall(r"\bStr\.(\w+)", strip_comments(line)):
                    if name not in defined:
                        missing.append("%s:%d: Str.%s" % (os.path.basename(f), n, name))
        self.assertEqual(missing, [], "Str members that do not exist:\n" + "\n".join(missing))

    def test_both_languages_for_every_plain_string(self):
        with open(os.path.join(UI, "Str.qml"), encoding="utf-8") as fh:
            src = fh.read()
        bad = []
        for m in re.finditer(r"readonly property (?:string|var) (\w+): tr \? (.*)$", src, re.M):
            body = m.group(2)
            if ":" not in body:
                bad.append(m.group(1))
        self.assertEqual(bad, [], "properties with only one language: %s" % bad)


if __name__ == "__main__":
    unittest.main()
