.pragma library
.import "Model.js" as Model

// Turns the history into the numbers a report prints. Pure: history in,
// plain data out — the same object feeds the picture, the PDF and the JSON
// export, so all three always agree, and a test can check it against a
// hand-made history.
//
//   days   { "YYYY-MM-DD": { total, apps:{id:ms}, h:[24 x ms], best:[ms,start], ... } }
//   opts   { scope: "day"|"week"|"all", todayKey, viewKey, weekEnd, goalHours }

function daysBetween(a, b) {
    return Math.round((Model.keyToDate(b) - Model.keyToDate(a)) / 86400000);
}

function firstRecorded(days, todayKey) {
    var first = "";
    for (var k in days)
        if (days[k].total > 0 && k <= todayKey && (first === "" || k < first))
            first = k;
    return first || todayKey;
}

function rangeOf(days, opts) {
    var today = opts.todayKey;
    if (opts.scope === "day") {
        var d = opts.viewKey || today;
        return { from: d, to: d };
    }
    if (opts.scope === "week") {
        var end = opts.weekEnd || today;
        return { from: Model.shiftKey(end, -6), to: end };
    }
    return { from: firstRecorded(days, today), to: today };
}

function sumRange(days, from, to) {
    var t = 0;
    for (var k = from; k <= to; k = Model.shiftKey(k, 1))
        t += days[k] ? days[k].total : 0;
    return t;
}

function build(days, opts) {
    var goalMs = (opts.goalHours || 0) * 3600000;
    var r = rangeOf(days, opts);
    var n = daysBetween(r.from, r.to) + 1;

    var list = [];
    var total = 0, recorded = 0, hits = 0;
    var hours = [];
    for (var i = 0; i < 24; i++)
        hours.push(0);
    var appMs = {};
    var longest = { key: r.from, ms: 0 };
    var best = { ms: 0, start: 0 };

    for (var j = 0; j < n; j++) {
        var key = Model.shiftKey(r.from, j);
        var d = days[key];
        var t = d ? d.total : 0;
        list.push({
            key: key, total: t, weekday: Model.weekday(key), isToday: key === opts.todayKey, hit: goalMs > 0 && t >= goalMs,
            // for the interactive page: what that day was made of
            apps: d ? Object.assign({}, d.apps) : {},
            h: d && d.h ? d.h.slice(0, 24) : []
        });
        total += t;
        if (t > 0)
            recorded++;
        if (goalMs > 0 && t >= goalMs)
            hits++;
        if (t > longest.ms)
            longest = { key: key, ms: t };
        if (!d)
            continue;
        for (var a in d.apps)
            appMs[a] = (appMs[a] || 0) + d.apps[a];
        var h = d.h || [];
        for (var q = 0; q < h.length && q < 24; q++)
            hours[q] += h[q];
        if (d.best && d.best[0] > best.ms)
            best = { ms: d.best[0], start: d.best[1] };
    }

    var apps = [];
    for (var id in appMs)
        apps.push({ id: id, ms: appMs[id], share: total > 0 ? appMs[id] / total : 0 });
    apps.sort(function (x, y) { return y.ms - x.ms; });

    var hourSum = hours.reduce(function (x, y) { return x + y; }, 0);
    var peak = -1;
    for (var p = 0; p < 24; p++)
        if (hours[p] > 0 && (peak < 0 || hours[p] > hours[peak]))
            peak = p;

    // What to compare against: the equally long stretch just before.
    var prevTotal = null;
    if (opts.scope !== "all")
        prevTotal = sumRange(days, Model.shiftKey(r.from, -n), Model.shiftKey(r.from, -1));

    // The chart: hours for a day, days for a week, weeks for everything.
    var series = [], seriesKind = "day", seriesGoal = goalMs;
    if (opts.scope === "day") {
        seriesKind = "hour";
        seriesGoal = 0;
        for (var hh = 0; hh < 24; hh++)
            series.push({ key: String(hh), ms: hours[hh] });
    } else if (opts.scope === "week") {
        for (var w = 0; w < list.length; w++)
            series.push({ key: list[w].key, ms: list[w].total, isToday: list[w].isToday });
    } else {
        seriesKind = "week";
        seriesGoal = goalMs * 7;
        var weeks = {};
        var order = [];
        for (var x = 0; x < list.length; x++) {
            var mon = Model.shiftKey(list[x].key, -list[x].weekday);
            if (weeks[mon] === undefined) {
                weeks[mon] = 0;
                order.push(mon);
            }
            weeks[mon] += list[x].total;
        }
        order = order.slice(-16);
        for (var o = 0; o < order.length; o++)
            series.push({ key: order[o], ms: weeks[order[o]], isToday: order[o] === Model.shiftKey(opts.todayKey, -Model.weekday(opts.todayKey)) });
    }

    return {
        scope: opts.scope,
        from: r.from,
        to: r.to,
        dayCount: n,
        recordedDays: recorded,
        total: total,
        avgPerDay: n > 0 ? total / n : 0,
        goalMs: goalMs,
        goalHits: hits,
        prevTotal: prevTotal,
        days: list,
        apps: apps,
        hours: hours,
        // How much of the total the hourly buckets account for; older
        // history was recorded before hourly buckets existed.
        hourCover: total > 0 ? Math.min(1, hourSum / total) : 0,
        peakHour: peak,
        longestDay: longest,
        bestRun: best,
        series: series,
        seriesKind: seriesKind,
        seriesGoal: seriesGoal
    };
}
