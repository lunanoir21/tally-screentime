#!/usr/bin/env python3
"""Checks an exported report (JSON) against the history it was made from,
using a second, independent implementation of the arithmetic.

    verify_report.py [report.json] [history.json]

Defaults: the newest ~/Pictures/tally/*.json and ~/.local/state/tally-screentime/history.json.
Run it right after exporting; exits 1 on any mismatch.
"""
import datetime as dt
import glob
import json
import os
import sys

HOME = os.path.expanduser("~")


def newest_report():
    files = glob.glob(os.path.join(HOME, "Pictures", "tally", "*.json"))
    return max(files, key=os.path.getmtime) if files else None


def daterange(a, b):
    d = dt.date.fromisoformat(a)
    end = dt.date.fromisoformat(b)
    while d <= end:
        yield d.isoformat()
        d += dt.timedelta(days=1)


def main(argv):
    report_path = argv[0] if argv else newest_report()
    history_path = argv[1] if len(argv) > 1 else os.path.join(HOME, ".local/state/tally-screentime/history.json")
    if not report_path:
        print("no report found", file=sys.stderr)
        return 1
    rep = json.load(open(report_path))["report"]
    days = json.load(open(history_path))["days"]
    problems = []

    def check(name, got, want):
        if got != want:
            problems.append("%s: report says %r, history says %r" % (name, got, want))

    keys = list(daterange(rep["from"], rep["to"]))
    check("dayCount", rep["dayCount"], len(keys))
    total = sum(days.get(k, {}).get("total", 0) for k in keys)
    check("total", rep["total"], total)
    check("days[].total", [d["total"] for d in rep["days"]], [days.get(k, {}).get("total", 0) for k in keys])
    check("days[].key", [d["key"] for d in rep["days"]], keys)

    apps = {}
    for k in keys:
        for a, ms in days.get(k, {}).get("apps", {}).items():
            apps[a] = apps.get(a, 0) + ms
    check("apps (sum)", {a["id"]: a["ms"] for a in rep["apps"]}, apps)
    check("apps sum == total", sum(a["ms"] for a in rep["apps"]), sum(apps.values()))

    hours = [0] * 24
    for k in keys:
        for i, ms in enumerate(days.get(k, {}).get("h", [])[:24]):
            hours[i] += ms
    check("hours", rep["hours"], hours)

    goal = rep["goalMs"]
    check("goalHits", rep["goalHits"], sum(1 for k in keys if goal > 0 and days.get(k, {}).get("total", 0) >= goal))
    check("recordedDays", rep["recordedDays"], sum(1 for k in keys if days.get(k, {}).get("total", 0) > 0))
    check("avgPerDay", round(rep["avgPerDay"]), round(total / len(keys)))

    if rep["scope"] == "week":
        check("week length", len(keys), 7)
    if rep["scope"] == "all":
        first = min((k for k, v in days.items() if v.get("total", 0) > 0), default=rep["to"])
        check("all starts at first recorded day", rep["from"], first)
    if rep["prevTotal"] is not None:
        n = len(keys)
        start = dt.date.fromisoformat(rep["from"]) - dt.timedelta(days=n)
        prev = sum(days.get((start + dt.timedelta(days=i)).isoformat(), {}).get("total", 0) for i in range(n))
        check("prevTotal", rep["prevTotal"], prev)

    if problems:
        print("MISMATCH in %s" % os.path.basename(report_path))
        for p in problems:
            print("  - " + p)
        return 1
    print("ok · %s · %d days · total %d ms · %d apps" % (os.path.basename(report_path), len(keys), total, len(apps)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
