.pragma library
.import "Model.js" as Model

// The bookkeeping behind the tracker, free of any QML so it can be tested
// on its own. `days` is always treated as immutable: every function returns
// a new map and copies only the day records it touches.

function clone(d) {
    return {
        total: d.total,
        apps: Object.assign({}, d.apps),
        h: (d.h || []).slice(),
        s: Object.assign({}, d.s || {}),
        best: d.best ? d.best.slice() : [0, 0],
        n: Object.assign({}, d.n || {})
    };
}

// Bills [from, to) to `app`, splitting at every hour boundary so the
// hourly buckets and the day (local midnight) both come out right.
// Returns { days, lastKey } — lastKey is the day the span ended in.
function addSpan(days, app, from, to) {
    var nd = Object.assign({}, days);
    var t = from;
    var lastKey = "";
    while (t < to) {
        var dt = new Date(t);
        var next = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate(), dt.getHours() + 1).getTime();
        var end = Math.min(to, next);
        var chunk = end - t;
        var key = Model.dayKey(dt);
        var d = clone(nd[key] || Model.newDay());
        d.total += chunk;
        d.apps[app] = (d.apps[app] || 0) + chunk;
        while (d.h.length < 24)
            d.h.push(0);
        d.h[dt.getHours()] += chunk;
        nd[key] = d;
        lastKey = key;
        t = end;
    }
    return { days: nd, lastKey: lastKey };
}

// Takes back up to `ms` of time billed to `app` just before `now`, hour by
// hour, but never further than the start of the current run. Also shortens
// the day's "longest run" if it was the run being cut. Returns { days, given }.
function refundSpan(days, app, now, ms, runStart) {
    var left = Math.min(ms, runStart ? now - runStart : 0);
    if (!app || left <= 0)
        return { days: days, given: 0 };
    var given = left;
    var nd = Object.assign({}, days);
    var t = now;
    while (left > 0) {
        var dt = new Date(t - 1);
        var hourStart = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate(), dt.getHours()).getTime();
        var chunk = Math.min(left, t - hourStart);
        var key = Model.dayKey(dt);
        if (!nd[key])
            break;
        var d = clone(nd[key]);
        var hr = dt.getHours();
        var take = Math.min(chunk, d.total, d.apps[app] || 0);
        d.total -= take;
        d.apps[app] = Math.max(0, (d.apps[app] || 0) - take);
        if (d.h.length > hr)
            d.h[hr] = Math.max(0, d.h[hr] - chunk);
        nd[key] = d;
        t -= chunk;
        left -= chunk;
    }
    var today = Model.dayKey(new Date(now));
    if (nd[today] && nd[today].best && nd[today].best[1] === runStart) {
        nd[today] = clone(nd[today]);
        nd[today].best[0] = Math.max(0, nd[today].best[0] - given);
    }
    return { days: nd, given: given };
}

// Drops days older than `keepDays` before `todayKey`. keepDays <= 0 keeps all.
function purge(days, todayKey, keepDays) {
    if (keepDays <= 0)
        return { days: days, dropped: 0 };
    var cutoff = Model.shiftKey(todayKey, -keepDays);
    var nd = {};
    var dropped = 0;
    for (var k in days) {
        if (k >= cutoff)
            nd[k] = days[k];
        else
            dropped++;
    }
    return { days: dropped ? nd : days, dropped: dropped };
}

// ---- Restoring a backup ---------------------------------------------------------------------

var DAY = 24 * 3600000;

function finiteNonNegative(x) {
    return typeof x === "number" && isFinite(x) && x >= 0;
}

function validKey(k) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(k))
        return false;
    var p = k.split("-");
    var d = new Date(+p[0], +p[1] - 1, +p[2], 12);
    return Model.dayKey(d) === k;
}

// One day as it may arrive from a file -> the shape the tracker keeps, or
// null if it cannot be trusted (a negative time, more than a day in a day).
function cleanDay(raw) {
    if (!raw || typeof raw !== "object" || !finiteNonNegative(raw.total) || raw.total > DAY)
        return null;
    var apps = {};
    var sum = 0;
    var src = raw.apps && typeof raw.apps === "object" ? raw.apps : {};
    for (var a in src) {
        if (!finiteNonNegative(src[a]))
            return null;
        apps[a] = src[a];
        sum += src[a];
    }
    if (sum > raw.total + 1000)
        return null;
    var h = [];
    var hs = Array.isArray(raw.h) ? raw.h : [];
    for (var i = 0; i < 24; i++) {
        var v = i < hs.length ? hs[i] : 0;
        if (!finiteNonNegative(v))
            return null;
        h.push(v);
    }
    var s = raw.s && typeof raw.s === "object" ? raw.s : {};
    var best = Array.isArray(raw.best) && raw.best.length === 2 && finiteNonNegative(raw.best[0]) && finiteNonNegative(raw.best[1]) ? raw.best.slice() : [0, 0];
    var n = raw.n && typeof raw.n === "object" ? raw.n : {};
    return { total: raw.total, apps: apps, h: h, s: s, best: best, n: n };
}

// What a file holds -> { days, skipped } or { error }. Understands a backup
// ({ days: {...} }) and a JSON report ({ report: { days: [...] } }).
function parseImport(obj) {
    var source = null;
    if (obj && obj.days && typeof obj.days === "object" && !Array.isArray(obj.days)) {
        source = obj.days;
    } else if (obj && obj.report && Array.isArray(obj.report.days)) {
        source = {};
        obj.report.days.forEach(function (d) { if (d && typeof d.key === "string") source[d.key] = d; });
    }
    if (!source)
        return { error: "unrecognized" };
    var days = {};
    var skipped = 0;
    for (var k in source) {
        var d = validKey(k) ? cleanDay(source[k]) : null;
        if (d)
            days[k] = d;
        else
            skipped++;
    }
    return { days: days, skipped: skipped };
}

// Puts imported days into the history. A day you already have is replaced
// only by a fuller one (more recorded time), never added to, so importing the
// same backup twice changes nothing.
function mergeHistory(current, incoming) {
    var nd = Object.assign({}, current);
    var added = 0, replaced = 0, kept = 0;
    for (var k in incoming) {
        var have = nd[k];
        if (!have || have.total <= 0) {
            nd[k] = incoming[k];
            added++;
        } else if (incoming[k].total > have.total) {
            nd[k] = incoming[k];
            replaced++;
        } else {
            kept++;
        }
    }
    return { days: nd, added: added, replaced: replaced, kept: kept };
}
