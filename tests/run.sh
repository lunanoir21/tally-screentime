#!/bin/sh
# Runs every test in this folder. Needs qmltestrunner (qt6-declarative) and python3.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
status=0

echo "== QML: model, ledger, report"
runner=$(command -v qmltestrunner6 || ls /usr/lib/qt6/bin/qmltestrunner /usr/lib64/qt6/bin/qmltestrunner 2>/dev/null | head -n1 || true)
if [ -z "$runner" ]; then echo "qmltestrunner (Qt 6) not found" >&2; status=1; else QT_QPA_PLATFORM=offscreen "$runner" -input "$here" || status=1; fi

echo "== Python: PDF writer, string check"
python3 -m unittest discover -s "$here" -p 'test_*.py' -v || status=1

exit $status
