# Changelog

## 0.1.0 — 2026-09-29

First version.

- Focused-window time per app and per day, with hourly buckets, session counts and the longest uninterrupted run; time spent idle is taken back.
- The bar pill (icon, icon + time, focus ring, idle, goal reached) and the card: Day, Week and Map pages, app detail with daily limits, settings.
- Focus sessions (25 minutes) and notifications for the goal, per-app limits and the end of a session.
- Sixteen themes and a launcher-style picker with a live preview.
- Turkish and English, and a first-run tour.
- Reports as PNG, one-page PDF, interactive HTML or JSON — three picture styles, drawn in the current theme or on light paper.
- Reports can be opened as soon as they are saved (*Open when saved*); the HTML report carries the apps' icons.
- Back up (`~/tally-history.json`) and restore: a backup or a JSON report is merged into the history, filling in missing days and replacing a day only with a fuller one; damaged days are skipped.
- The cost is measured, not promised: `tools/measure.py`, the numbers in the README and on the website, and `tests/bench_ledger.qml`.
- Tests: `tests/run.sh`, run by GitHub Actions on every push.
