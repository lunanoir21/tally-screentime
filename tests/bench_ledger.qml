import QtQuick
import QtTest
import "../ui/js/Ledger.js" as Ledger
import "../ui/js/Report.js" as Report
import "../ui/js/Model.js" as Model

// Not part of the suite (no tst_ prefix). Run it on its own:
//   qmltestrunner -input tests/bench_ledger.qml
// The engine is the one Quickshell uses, so these are the real costs.
TestCase {
    name: "Bench"

    // A year of history, 8 apps, hourly buckets.
    function year() {
        var days = {};
        var t = new Date(2026, 0, 1, 9, 0).getTime();
        for (var d = 0; d < 365; d++) {
            for (var i = 0; i < 40; i++) {
                var from = t + d * 86400000 + i * 600000;
                days = Ledger.addSpan(days, "app" + (i % 8), from, from + 300000).days;
            }
        }
        return days;
    }
    property var big: null
    function initTestCase() { big = year(); }

    // what every 15 s tick costs while something is being counted
    function benchmark_commit_into_a_year_of_history() {
        var now = new Date(2026, 11, 31, 14, 0).getTime();
        Ledger.addSpan(big, "app1", now - 15000, now);
    }
    function benchmark_take_back_three_minutes() {
        var now = new Date(2026, 11, 31, 14, 0).getTime();
        Ledger.refundSpan(big, "app1", now, 180000, now - 600000);
    }
    // what opening the card, or a report, costs
    function benchmark_report_for_the_whole_year() {
        Report.build(big, { scope: "all", todayKey: "2026-12-31", goalHours: 6 });
    }
    function benchmark_report_for_a_week() {
        Report.build(big, { scope: "week", todayKey: "2026-12-31", goalHours: 6 });
    }
    function benchmark_serialise_the_history() {
        JSON.stringify({ days: big });
    }
}
