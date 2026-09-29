#!/usr/bin/env python3
"""Writes a believable, invented history for screenshots and demos.

    make_demo_history.py OUT_DIR [--today YYYY-MM-DD] [--weeks 20] [--seed 7]

OUT_DIR gets history.json and settings.json. Point Tally at it with
TALLY_STATE_DIR=OUT_DIR (and TALLY_DEMO=1 to stop it counting anything).
Nothing here comes from a real machine.
"""
import argparse
import datetime as dt
import json
import os
import random

MIN = 60000
# app id -> weight
APPS = {
    "firefox": 38, "kitty": 24, "chromium": 16, "Spotify": 8,
    "obsidian": 6, "org.telegram.desktop": 5, "mpv": 3,
}
# how a working day is spread over the hours (weights per hour, 0-23)
HOUR_SHAPE = [0, 0, 0, 0, 0, 0, 0, 1, 5, 9, 11, 10, 6, 8, 10, 11, 9, 6, 4, 4, 3, 2, 1, 0]


def split(total, weights, rng):
    """Splits `total` ms over `weights` (integers, sums exactly)."""
    if total <= 0:
        return [0] * len(weights)
    noisy = [w * rng.uniform(0.6, 1.4) for w in weights]
    s = sum(noisy) or 1
    parts = [int(total * x / s) for x in noisy]
    parts[max(range(len(parts)), key=lambda i: weights[i])] += total - sum(parts)
    return parts


def make_day(date, today, rng):
    weekday = date.weekday()
    base = rng.uniform(4.2, 7.0) if weekday < 5 else rng.uniform(1.0, 4.0)
    if rng.random() < 0.07:
        base *= 0.3  # a day off
    total = int(base * 60) * MIN + rng.randrange(0, MIN)
    shape = list(HOUR_SHAPE)
    if date == today:
        total = 252 * MIN + 13000  # 4h 12m so far
        shape = [w if h <= 16 else 0 for h, w in enumerate(HOUR_SHAPE)]
    if weekday >= 5:
        shape = [w if 10 <= h <= 22 else 0 for h, w in enumerate(shape)]
        shape = [w or (2 if 10 <= h <= 22 else 0) for h, w in enumerate(shape)]
    h = split(total, shape, rng)
    ids = list(APPS)
    weights = [APPS[a] * (1.6 if weekday >= 5 and a in ("mpv", "Spotify") else 1) for a in ids]
    apps = dict(zip(ids, split(total, weights, rng)))
    apps = {a: ms for a, ms in apps.items() if ms > 0}
    sessions = {a: [max(1, ms // (18 * MIN)), min(ms, int(rng.uniform(12, 70) * MIN))] for a, ms in apps.items()}
    best_ms = min(total, int(rng.uniform(35, 110) * MIN))
    start_h = next((i for i, x in enumerate(h) if x), 9)
    best_start = int(dt.datetime(date.year, date.month, date.day, start_h, 5).timestamp() * 1000)
    return {"total": total, "apps": apps, "h": h, "s": sessions, "best": [best_ms, best_start], "n": {}}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("out")
    p.add_argument("--today", default=dt.date.today().isoformat())
    p.add_argument("--weeks", type=int, default=20)
    p.add_argument("--seed", type=int, default=7)
    a = p.parse_args()
    rng = random.Random(a.seed)
    today = dt.date.fromisoformat(a.today)
    days = {}
    for i in range(a.weeks * 7):
        d = today - dt.timedelta(days=i)
        days[d.isoformat()] = make_day(d, today, rng)
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "history.json"), "w") as fh:
        json.dump({"days": days}, fh, indent=1, sort_keys=True)
    with open(os.path.join(a.out, "settings.json"), "w") as fh:
        json.dump({
            "language": "en", "onboarded": True, "themeId": "noir", "goalHours": 6,
            "pillVisible": True, "pillTime": True, "pillGoalLine": True,
            "notifyNear": True, "notifyOver": False, "idleMinutes": 3, "countVideo": True,
            "excluded": ["quickshell", "xdg-desktop-portal"], "retentionDays": 365, "limits": {},
        }, fh, indent=1)
    print("wrote %d days to %s" % (len(days), a.out))


if __name__ == "__main__":
    main()
