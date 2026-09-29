import QtQuick
import QtTest
import "../ui/js/Report.js" as Report
import "../ui/js/Model.js" as Model

TestCase {
    name: "Report"

    readonly property int min: 60000

    function hist() {
        // three days, by hand
        return {
            "2026-09-27": { total: 100 * min, apps: { a: 60 * min, b: 40 * min }, h: hours({ 9: 100 }), best: [50 * min, 111] },
            "2026-09-28": { total: 200 * min, apps: { a: 50 * min, b: 100 * min, c: 50 * min }, h: hours({ 9: 60, 14: 140 }), best: [80 * min, 222] },
            "2026-09-29": { total: 300 * min, apps: { a: 300 * min }, h: hours({ 15: 300 }), best: [120 * min, 333] }
        };
    }
    function hours(o) {
        var h = [];
        for (var i = 0; i < 24; i++) h.push((o[i] || 0) * min);
        return h;
    }
    function opts(scope, extra) {
        return Object.assign({ scope: scope, todayKey: "2026-09-29", goalHours: 4 }, extra || {});
    }

    function test_day() {
        var r = Report.build(hist(), opts("day"));
        compare(r.from, "2026-09-29");
        compare(r.to, "2026-09-29");
        compare(r.dayCount, 1);
        compare(r.total, 300 * min);
        compare(r.apps.length, 1);
        compare(r.apps[0].id, "a");
        compare(r.apps[0].share, 1);
        compare(r.peakHour, 15);
        compare(r.hours[15], 300 * min);
        compare(r.hourCover, 1);
        compare(r.goalHits, 1); // 300 min >= 4 h
        compare(r.prevTotal, 200 * min);
        compare(r.seriesKind, "hour");
        compare(r.series.length, 24);
        compare(r.bestRun.ms, 120 * min);
    }

    function test_day_picked_from_the_past() {
        var r = Report.build(hist(), opts("day", { viewKey: "2026-09-27" }));
        compare(r.total, 100 * min);
        compare(r.prevTotal, 0);
        compare(r.goalHits, 0);
        compare(r.apps[0].id, "a");
        compare(r.apps[1].id, "b");
    }

    function test_week_is_seven_days_ending_today() {
        var r = Report.build(hist(), opts("week"));
        compare(r.from, "2026-09-23");
        compare(r.to, "2026-09-29");
        compare(r.dayCount, 7);
        compare(r.days.length, 7);
        compare(r.total, 600 * min);
        fuzzyCompare(r.avgPerDay, 600 * min / 7, 1e-6);
        compare(r.goalHits, 1);
        compare(r.longestDay.key, "2026-09-29");
        compare(r.longestDay.ms, 300 * min);
        compare(r.recordedDays, 3);
        compare(r.prevTotal, 0);
        compare(r.days[6].isToday, true);
        compare(r.seriesKind, "day");
        compare(r.series.length, 7);
    }

    function test_apps_are_summed_and_sorted() {
        var r = Report.build(hist(), opts("week"));
        compare(r.apps[0].id, "a");
        compare(r.apps[0].ms, 410 * min);
        compare(r.apps[1].id, "b");
        compare(r.apps[1].ms, 140 * min);
        compare(r.apps[2].id, "c");
        var sum = 0;
        for (var i = 0; i < r.apps.length; i++) sum += r.apps[i].ms;
        compare(sum, r.total);
        var shares = 0;
        for (var j = 0; j < r.apps.length; j++) shares += r.apps[j].share;
        fuzzyCompare(shares, 1, 1e-9);
    }

    function test_hours_are_aggregated() {
        var r = Report.build(hist(), opts("week"));
        compare(r.hours[9], 160 * min);
        compare(r.hours[14], 140 * min);
        compare(r.hours[15], 300 * min);
        compare(r.peakHour, 15);
    }

    function test_week_ending_earlier() {
        var r = Report.build(hist(), opts("week", { weekEnd: "2026-09-28" }));
        compare(r.to, "2026-09-28");
        compare(r.total, 300 * min);
        compare(r.days[6].isToday, false);
    }

    function test_all_starts_at_the_first_recorded_day() {
        var r = Report.build(hist(), opts("all"));
        compare(r.from, "2026-09-27");
        compare(r.dayCount, 3);
        compare(r.total, 600 * min);
        compare(r.prevTotal, null);
        compare(r.seriesKind, "week");
        var s = 0;
        for (var i = 0; i < r.series.length; i++) s += r.series[i].ms;
        compare(s, r.total);
    }

    function test_all_groups_by_week_and_keeps_sixteen() {
        var days = {};
        var key = "2026-01-05"; // a Monday
        var total = 0;
        for (var i = 0; i < 200; i++) {
            days[key] = { total: 10 * min, apps: { a: 10 * min }, h: hours({ 10: 10 }), best: [0, 0] };
            key = Model.shiftKey(key, 1);
        }
        var r = Report.build(days, { scope: "all", todayKey: "2026-07-23", goalHours: 0 });
        compare(r.series.length, 16);
        compare(r.series[0].ms, 70 * min); // a whole week, Monday to Sunday
        compare(r.seriesGoal, 0);
        compare(r.goalHits, 0);
    }

    function test_history_without_hours_reports_partial_cover() {
        var days = { "2026-09-29": { total: 100 * min, apps: { a: 100 * min } } };
        var r = Report.build(days, opts("day"));
        compare(r.hourCover, 0);
        compare(r.peakHour, -1);
        compare(r.total, 100 * min);
        days["2026-09-29"].h = hours({ 10: 25 });
        compare(Report.build(days, opts("day")).hourCover, 0.25);
    }

    function test_empty_history() {
        var r = Report.build({}, opts("all"));
        compare(r.total, 0);
        compare(r.dayCount, 1);
        compare(r.apps.length, 0);
        compare(r.hourCover, 0);
        compare(r.avgPerDay, 0);
    }

    function test_goal_off() {
        var r = Report.build(hist(), Object.assign(opts("week"), { goalHours: 0 }));
        compare(r.goalHits, 0);
        compare(r.goalMs, 0);
    }
}
