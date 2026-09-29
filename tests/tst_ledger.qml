import QtQuick
import QtTest
import "../ui/js/Ledger.js" as Ledger
import "../ui/js/Model.js" as Model

TestCase {
    name: "Ledger"

    readonly property int min: 60000
    function at(day, h, m) { return new Date(2026, 8, day, h, m, 0).getTime(); }

    function test_span_inside_one_hour() {
        var r = Ledger.addSpan({}, "kitty", at(29, 10, 0), at(29, 10, 30));
        var d = r.days["2026-09-29"];
        compare(d.total, 30 * min);
        compare(d.apps.kitty, 30 * min);
        compare(d.h[10], 30 * min);
        compare(d.h.length, 24);
        compare(r.lastKey, "2026-09-29");
    }

    function test_span_across_an_hour() {
        var d = Ledger.addSpan({}, "kitty", at(29, 10, 50), at(29, 11, 10)).days["2026-09-29"];
        compare(d.h[10], 10 * min);
        compare(d.h[11], 10 * min);
        compare(d.total, 20 * min);
    }

    function test_span_across_midnight() {
        var r = Ledger.addSpan({}, "kitty", at(29, 23, 50), at(30, 0, 10));
        compare(r.days["2026-09-29"].total, 10 * min);
        compare(r.days["2026-09-29"].h[23], 10 * min);
        compare(r.days["2026-09-30"].total, 10 * min);
        compare(r.days["2026-09-30"].h[0], 10 * min);
        compare(r.lastKey, "2026-09-30");
    }

    function test_total_always_equals_apps_and_hours() {
        var days = {};
        var t = at(29, 8, 13);
        var apps = ["a", "b", "c"];
        for (var i = 0; i < 200; i++) {
            var len = (1 + (i * 7) % 55) * 1000 + 250;
            days = Ledger.addSpan(days, apps[i % 3], t, t + len).days;
            t += len + ((i * 3) % 5) * 1000;
        }
        for (var k in days) {
            var d = days[k];
            var sa = 0, sh = 0;
            for (var a in d.apps) sa += d.apps[a];
            for (var h = 0; h < d.h.length; h++) sh += d.h[h];
            compare(sa, d.total, "apps sum, " + k);
            compare(sh, d.total, "hours sum, " + k);
        }
    }

    function test_span_does_not_mutate_the_input() {
        var first = Ledger.addSpan({}, "a", at(29, 9, 0), at(29, 9, 10)).days;
        var snapshot = JSON.stringify(first);
        Ledger.addSpan(first, "a", at(29, 9, 10), at(29, 9, 20));
        compare(JSON.stringify(first), snapshot);
    }

    function test_refund_takes_back_the_idle_time() {
        var days = Ledger.addSpan({}, "kitty", at(29, 10, 0), at(29, 10, 45)).days;
        var r = Ledger.refundSpan(days, "kitty", at(29, 10, 45), 3 * min, at(29, 10, 0));
        compare(r.given, 3 * min);
        compare(r.days["2026-09-29"].total, 42 * min);
        compare(r.days["2026-09-29"].apps.kitty, 42 * min);
        compare(r.days["2026-09-29"].h[10], 42 * min);
    }

    function test_refund_never_goes_before_the_run() {
        var days = Ledger.addSpan({}, "kitty", at(29, 10, 30), at(29, 10, 45)).days;
        var r = Ledger.refundSpan(days, "kitty", at(29, 10, 45), 60 * min, at(29, 10, 30));
        compare(r.given, 15 * min);
        compare(r.days["2026-09-29"].total, 0);
    }

    function test_refund_across_an_hour() {
        var days = Ledger.addSpan({}, "kitty", at(29, 9, 50), at(29, 10, 10)).days;
        var r = Ledger.refundSpan(days, "kitty", at(29, 10, 10), 15 * min, at(29, 9, 50));
        var d = r.days["2026-09-29"];
        compare(d.h[10], 0);
        compare(d.h[9], 5 * min);
        compare(d.total, 5 * min);
    }

    function test_refund_shortens_the_longest_run() {
        var days = Ledger.addSpan({}, "kitty", at(29, 10, 0), at(29, 10, 20)).days;
        days["2026-09-29"].best = [20 * min, at(29, 10, 0)];
        var r = Ledger.refundSpan(days, "kitty", at(29, 10, 20), 3 * min, at(29, 10, 0));
        compare(r.days["2026-09-29"].best[0], 17 * min);
    }

    function test_refund_without_a_run_does_nothing() {
        var days = Ledger.addSpan({}, "kitty", at(29, 10, 0), at(29, 10, 20)).days;
        compare(Ledger.refundSpan(days, "kitty", at(29, 10, 20), 3 * min, 0).given, 0);
        compare(Ledger.refundSpan(days, "", at(29, 10, 20), 3 * min, at(29, 10, 0)).given, 0);
    }

    function test_purge() {
        var days = { "2026-09-29": { total: 1 }, "2026-01-01": { total: 2 }, "2025-01-01": { total: 3 } };
        var r = Ledger.purge(days, "2026-09-29", 90);
        compare(Object.keys(r.days).length, 1);
        compare(r.dropped, 2);
        compare(Ledger.purge(days, "2026-09-29", 0).dropped, 0);
        compare(Ledger.purge(days, "2026-09-29", 365).dropped, 1);
    }

    // ---- restoring a backup ----

    function day(total, apps) { return { total: total, apps: apps || {}, h: [], s: {}, best: [0, 0], n: {} }; }

    function test_parse_a_backup() {
        var r = Ledger.parseImport({ days: { "2026-09-28": day(3 * 3600000, { a: 2 * 3600000, b: 3600000 }) } });
        compare(Object.keys(r.days).length, 1);
        compare(r.days["2026-09-28"].h.length, 24);   // padded
        compare(r.skipped, 0);
    }

    function test_parse_a_json_report() {
        var rep = { report: { days: [{ key: "2026-09-27", total: 600000, apps: { a: 600000 }, h: [] }, { key: "2026-09-28", total: 0, apps: {}, h: [] }] } };
        var r = Ledger.parseImport(rep);
        compare(Object.keys(r.days).sort().join(","), "2026-09-27,2026-09-28");
    }

    function test_parse_refuses_what_is_not_a_history() {
        compare(Ledger.parseImport({ hello: 1 }).error, "unrecognized");
        compare(Ledger.parseImport(null).error, "unrecognized");
        compare(Ledger.parseImport({ days: [1, 2] }).error, "unrecognized");
    }

    function test_parse_skips_days_it_cannot_trust() {
        var r = Ledger.parseImport({ days: {
            "2026-09-28": day(3600000, { a: 3600000 }),
            "2026-13-40": day(1000),                          // not a date
            "yesterday": day(1000),
            "2026-09-27": day(-5),                            // negative
            "2026-09-26": day(25 * 3600000),                  // more than a day
            "2026-09-25": day(1000, { a: 3600000 }),          // apps add up to more than the day
            "2026-09-24": { total: 1000, apps: { a: "x" } }   // not a number
        } });
        compare(Object.keys(r.days).join(","), "2026-09-28");
        compare(r.skipped, 6);
    }

    function test_merge_adds_replaces_and_keeps() {
        var current = { "2026-09-28": day(100), "2026-09-27": day(500), "2026-09-26": day(0) };
        var incoming = { "2026-09-28": day(300), "2026-09-27": day(200), "2026-09-26": day(50), "2026-09-25": day(70) };
        var m = Ledger.mergeHistory(current, incoming);
        compare(m.added, 2);      // 09-26 was empty, 09-25 is new
        compare(m.replaced, 1);   // 09-28 was smaller
        compare(m.kept, 1);       // 09-27 already had more
        compare(m.days["2026-09-27"].total, 500);
        compare(m.days["2026-09-28"].total, 300);
        compare(current["2026-09-28"].total, 100);   // the input is untouched
    }

    function test_importing_twice_changes_nothing() {
        var current = { "2026-09-28": day(100) };
        var incoming = { "2026-09-28": day(300), "2026-09-25": day(70) };
        var once = Ledger.mergeHistory(current, incoming);
        var twice = Ledger.mergeHistory(once.days, incoming);
        compare(twice.added + twice.replaced, 0);
        compare(JSON.stringify(twice.days), JSON.stringify(once.days));
    }
}
