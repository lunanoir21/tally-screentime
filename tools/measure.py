#!/usr/bin/env python3
"""Measures what Tally costs, against an empty Quickshell.

    tools/measure.py [--seconds 45] [--settle 10]

Each scenario is a fresh Quickshell process (own state folder, invented
history). CPU is the process's user+system time over the window, as a share
of one core; RSS is resident memory at the end; wakeups are the process's
voluntary context switches per second, a fair stand-in for "how often does it
wake the machine". Counting is on, so your own window changes are billed
like always; keep the machine as you normally use it.

Scenarios: an empty shell; Tally with the card closed; the card open; the
card open with a focus session running (a 1 s clock); and, for memory, the
peak reached while a board report is made.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
TARGET = "lunanoir.tally-screentime"
TICKS = os.sysconf("SC_CLK_TCK")


def stat(pid):
    with open("/proc/%d/stat" % pid) as fh:
        f = fh.read().rsplit(")", 1)[1].split()
    return (int(f[11]) + int(f[12])) / TICKS          # utime + stime, seconds


def status(pid):
    out = {}
    with open("/proc/%d/status" % pid) as fh:
        for line in fh:
            k, _, v = line.partition(":")
            out[k] = v.strip()
    return out


def kb(s):
    return int(s.split()[0])


def start(qml, env):
    e = dict(os.environ, **env)
    p = subprocess.Popen(["quickshell", "-p", qml, "-n"], env=e, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    return p


def ipc(qml, *args):
    return subprocess.run(["quickshell", "ipc", "-p", qml, "call", TARGET, *args], capture_output=True, text=True, timeout=20)


def wait_ipc(qml, tries=40):
    for _ in range(tries):
        if ipc(qml, "close").returncode == 0:
            return True
        time.sleep(0.5)
    return False


def sample(pid, seconds):
    c0, w0, t0 = stat(pid), int(status(pid)["voluntary_ctxt_switches"]), time.time()
    time.sleep(seconds)
    c1, w1, t1 = stat(pid), int(status(pid)["voluntary_ctxt_switches"]), time.time()
    s = status(pid)
    return {
        "cpu": 100.0 * (c1 - c0) / (t1 - t0),
        "rss_mb": kb(s["VmRSS"]) / 1024.0,
        "wakeups": (w1 - w0) / (t1 - t0),
        "threads": int(s["Threads"]),
    }


def run(name, qml, env, seconds, settle, setup=None):
    p = start(qml, env)
    try:
        if qml.endswith("Main.qml") and not wait_ipc(qml):
            raise RuntimeError("Tally did not come up")
        time.sleep(settle)
        if setup:
            setup()
            time.sleep(3)
        r = sample(p.pid, seconds)
        r["name"] = name
        return r
    finally:
        try:
            ipc(qml, "close")
        except Exception:
            pass
        p.terminate()
        try:
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            p.kill()


def export_peak(qml, env, out_dir, settle):
    p = start(qml, env)
    try:
        if not wait_ipc(qml):
            raise RuntimeError("Tally did not come up")
        time.sleep(settle)
        before = kb(status(p.pid)["VmHWM"])
        ipc(qml, "report", "week", "board", "png", "theme")
        time.sleep(8)
        after = kb(status(p.pid)["VmHWM"])
        rss = kb(status(p.pid)["VmRSS"])
        return {"name": "peak while a board report is made", "peak_mb": after / 1024.0, "extra_mb": (after - before) / 1024.0,
                "after_mb": rss / 1024.0, "made": any(f.endswith(".png") for f in os.listdir(out_dir))}
    finally:
        p.terminate()
        try:
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            p.kill()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seconds", type=int, default=45)
    ap.add_argument("--settle", type=int, default=10)
    ap.add_argument("--json", help="also write the numbers here")
    a = ap.parse_args()

    if not shutil.which("quickshell"):
        print("quickshell is not on PATH", file=sys.stderr)
        return 1
    work = tempfile.mkdtemp(prefix="tally-measure-")
    state, out = os.path.join(work, "state"), os.path.join(work, "out")
    os.makedirs(out)
    subprocess.run([sys.executable, os.path.join(HERE, "make_demo_history.py"), state, "--weeks", "52"], check=True, capture_output=True)
    env = {"TALLY_STATE_DIR": state, "TALLY_EXPORT_DIR": out, "TALLY_KEEP_OPEN": "1"}
    main_qml = os.path.abspath(os.path.join(ROOT, "Main.qml"))
    base_qml = os.path.abspath(os.path.join(HERE, "measure", "baseline.qml"))

    rows = []
    rows.append(run("empty Quickshell (one window)", base_qml, {}, a.seconds, a.settle))
    rows.append(run("Tally, card closed", main_qml, env, a.seconds, a.settle))
    rows.append(run("Tally, card open (Day)", main_qml, env, a.seconds, a.settle, lambda: ipc(main_qml, "page", "day")))
    rows.append(run("Tally, card open + focus session", main_qml, env, a.seconds, a.settle, lambda: ipc(main_qml, "focus")))
    peak = export_peak(main_qml, env, out, a.settle)

    base = rows[0]
    print("| scenario | CPU (% of one core) | memory (MB) | wakeups / s |")
    print("|---|---:|---:|---:|")
    for r in rows:
        print("| %s | %.2f | %.0f | %.1f |" % (r["name"], r["cpu"], r["rss_mb"], r["wakeups"]))
    print()
    print("Tally on top of an empty Quickshell, card closed: %+.2f %% CPU, %+.0f MB, %+.1f wakeups/s"
          % (rows[1]["cpu"] - base["cpu"], rows[1]["rss_mb"] - base["rss_mb"], rows[1]["wakeups"] - base["wakeups"]))
    print("Making a board report: memory peaks at %.0f MB (+%.0f MB over before); report %s"
          % (peak["peak_mb"], peak["extra_mb"], "made" if peak["made"] else "NOT made"))
    print("(%ds per scenario, %ds settle, 52 weeks of history, counting on)" % (a.seconds, a.settle))
    if a.json:
        with open(a.json, "w") as fh:
            json.dump({"rows": rows, "export": peak, "seconds": a.seconds}, fh, indent=1)
    shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
