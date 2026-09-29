import QtQuick
import "js/Model.js" as Model

// Everything a report view prints, derived from the data object built by
// js/Report.js. The three views differ only in how they lay this out.
QtObject {
    id: m

    property var data: ({})

    readonly property string scope: data.scope || "day"
    readonly property bool hasGoal: data.goalMs > 0
    readonly property bool isAvg: scope !== "day"

    readonly property string title: Str.reportTitle(scope)
    readonly property string period: Str.period(data.from || "", data.to || "")
    readonly property string heroLabel: Str.heroLabel(scope)
    // day: the total; week: the daily average; all: the total.
    readonly property double heroMs: scope === "week" ? data.avgPerDay : data.total
    // What the goal ruler measures: a day's total, or the daily average.
    readonly property double rulerMs: scope === "day" ? data.total : data.avgPerDay
    readonly property real ratio: hasGoal ? rulerMs / data.goalMs : 0
    readonly property int filled: Math.floor(Math.min(1, ratio) * 40)

    readonly property string rulerRight: {
        if (!hasGoal)
            return "";
        if (scope === "day")
            return data.total >= data.goalMs ? Str.goalOver(Str.fmt(data.total - data.goalMs))
                : Str.goalLeft(Math.round(ratio * 100), Str.fmt(data.goalMs - data.total));
        return Str.ofAvgGoal(Math.round(ratio * 100));
    }
    readonly property var rulerMarks: [0, 1, 2, 3, 4].map(i => Str.fmtMarks(data.goalMs / 60000 * i / 4))

    // Change against the stretch just before; none for "all data".
    readonly property bool hasDelta: data.prevTotal !== null && data.prevTotal !== undefined && data.prevTotal > 0
    readonly property bool deltaUp: data.total >= data.prevTotal
    readonly property string deltaText: scope === "day"
        ? Str.fmt(Math.abs(data.total - data.prevTotal))
        : "%" + Math.round(Math.abs(data.total - data.prevTotal) / Math.max(1, data.prevTotal) * 100)
    readonly property string deltaSuffix: scope === "day" ? Str.fromYesterday : Str.fromLastWeek

    // Chart: scale, goal line and one entry per bar.
    readonly property double scaleMs: {
        var mx = 0;
        for (var i = 0; i < data.series.length; i++)
            mx = Math.max(mx, data.series[i].ms);
        var base = Math.max(mx, data.seriesGoal * 1.11);
        return Math.max(base, 60000);
    }
    readonly property real goalFrac: data.seriesGoal > 0 ? Math.min(1, data.seriesGoal / scaleMs) : 0
    readonly property string chartTitle: Str.chartTitle(data.seriesKind)
    readonly property string chartNote: data.seriesGoal <= 0 ? ""
        : data.seriesKind === "week" ? Str.dashedWeekGoal(data.goalMs / 3600000) : Str.dashedGoal(data.goalMs / 3600000)
    readonly property var bars: (data.series || []).map(function (s, i) {
        var label = "", sub = "";
        if (data.seriesKind === "day") {
            label = Str.dayShort(Model.weekday(s.key));
            sub = Str.fmtTight(s.ms);
        } else if (data.seriesKind === "week") {
            label = (i % 3 === 0) ? Str.shortDate(s.key) : "";
        } else {
            label = (i % 6 === 0) ? String(s.key).padStart(2, "0") : "";
        }
        return {
            key: s.key, ms: s.ms, frac: s.ms / scaleMs, label: label, sub: sub,
            today: s.isToday === true,
            hit: data.seriesGoal > 0 && s.ms >= data.seriesGoal
        };
    })

    readonly property var trio: {
        if (scope === "day")
            return [
                { label: Str.statPeak, value: data.peakHour >= 0 ? String(data.peakHour).padStart(2, "0") + ":00" : "—" },
                { label: Str.statApps, value: String(data.apps.length) },
                { label: Str.statGoalPct, value: hasGoal ? "%" + Math.round(ratio * 100) : "—" }
            ];
        if (scope === "week")
            return [
                { label: Str.total, value: Str.fmt(data.total) },
                { label: Str.longestDay, value: Str.dayShort(Model.weekday(data.longestDay.key)) + " · " + Str.fmt(data.longestDay.ms) },
                { label: Str.goalReached, value: Str.ofSeven(data.goalHits) }
            ];
        return [
            { label: Str.statRecorded, value: Str.days(data.recordedDays) },
            { label: Str.longestDay, value: Str.shortDate(data.longestDay.key) + " · " + Str.fmt(data.longestDay.ms) },
            { label: Str.goalReached, value: Str.days(data.goalHits) }
        ];
    }

    readonly property var topApps: Model.appRows(appMap(), data.total, 5)
    function appMap() {
        // Under a minute would print as "0d"; those apps stay out of the list.
        var o = {};
        for (var i = 0; i < (data.apps || []).length; i++)
            if (data.apps[i].ms >= 60000)
                o[data.apps[i].id] = data.apps[i].ms;
        return o;
    }

    readonly property double hourMax: Math.max.apply(null, (data.hours || [0]).concat([1]))
    readonly property bool showHours: scope !== "day" && data.peakHour >= 0
    readonly property string hoursNote: data.hourCover > 0 && data.hourCover < 0.98
        ? Str.hoursPartial(Math.round(data.hourCover * 100)) : ""
    readonly property string peakText: data.peakHour >= 0 ? Str.peakAt(String(data.peakHour).padStart(2, "0") + ":00") : ""
    readonly property string generated: Str.generated(new Date())
    readonly property string totalText: Str.fmt(data.total)
}
