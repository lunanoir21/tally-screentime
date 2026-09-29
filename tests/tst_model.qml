import QtQuick
import QtTest
import "../ui/js/Model.js" as Model

TestCase {
    name: "Model"

    function test_dayKey_and_shift() {
        compare(Model.dayKey(new Date(2026, 8, 29, 23, 59)), "2026-09-29");
        compare(Model.shiftKey("2026-09-29", 1), "2026-09-30");
        compare(Model.shiftKey("2026-09-30", 1), "2026-10-01");
        compare(Model.shiftKey("2026-12-31", 1), "2027-01-01");
        compare(Model.shiftKey("2026-03-01", -1), "2026-02-28");
        compare(Model.shiftKey("2028-03-01", -1), "2028-02-29");
    }

    function test_weekday_is_monday_first() {
        compare(Model.weekday("2026-09-28"), 0); // Monday
        compare(Model.weekday("2026-09-29"), 1);
        compare(Model.weekday("2026-10-04"), 6); // Sunday
    }

    function test_fmt() {
        compare(Model.fmt(0, true), "0d");
        compare(Model.fmt(59 * 1000, true), "0d");
        compare(Model.fmt(12 * 60000, true), "12d");
        compare(Model.fmt((4 * 60 + 12) * 60000, true), "4s 12d");
        compare(Model.fmt((4 * 60 + 5) * 60000, true), "4s 05d");
        compare(Model.fmt((4 * 60 + 12) * 60000, false), "4h 12m");
        compare(Model.fmt(-5, true), "0d");
    }

    function test_fmtTight_and_marks() {
        compare(Model.fmtTight((6 * 60 + 12) * 60000, true), "6s12d");
        compare(Model.fmtTight(38 * 60000, false), "38m");
        compare(Model.fmtMarks(0, true), "0");
        compare(Model.fmtMarks(360, true), "6s");
        compare(Model.fmtMarks(90, true), "1s 30d");
        compare(Model.fmtMarks(90, false), "1h 30m");
        compare(Model.fmtMarks(30, true), "30d");
    }

    function test_fmtHours() {
        compare(Model.fmtHours(0, true, "kapalı"), "kapalı");
        compare(Model.fmtHours(6, true, "x"), "6s 00d");
        compare(Model.fmtHours(4.5, false, "x"), "4h 30m");
    }

    function test_clock() {
        compare(Model.clock(25 * 60000), "25:00");
        compare(Model.clock(18 * 60000 + 42000), "18:42");
        compare(Model.clock(1), "00:01"); // rounds up: a running clock never shows 00:00 early
        compare(Model.clock(-1000), "00:00");
    }

    function test_dates_in_both_languages() {
        compare(Model.shortDate("2026-09-29", true), "29 Eyl");
        compare(Model.shortDate("2026-09-29", false), "Sep 29");
        compare(Model.longDate("2026-09-29", true), "Salı 29 Eyl");
        compare(Model.longDate("2026-09-29", false), "Tuesday, Sep 29");
    }

    function test_appRows_folds_the_tail() {
        var rows = Model.appRows({ a: 600, b: 300, c: 60, d: 30, e: 10 }, 1000, 2);
        compare(rows.length, 3);
        compare(rows[0].id, "a");
        compare(rows[2].id, "");
        compare(rows[2].other, 3);
        compare(rows[2].ms, 100);
        compare(rows[0].rel, 1);
        fuzzyCompare(rows[1].share, 0.3, 1e-9);
    }

    function test_mergeApps_and_sum() {
        var list = [{ total: 10, apps: { a: 4, b: 6 } }, { total: 5, apps: { a: 5 } }, null];
        var m = Model.mergeApps(list);
        compare(m.a, 9);
        compare(m.b, 6);
        compare(Model.sumTotal(list), 15);
    }

    function test_monogram() {
        compare(Model.monogram("firefox"), "F");
        compare(Model.monogram(""), "?");
    }
}
