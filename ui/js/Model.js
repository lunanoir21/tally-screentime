.pragma library

// Pure helpers, no QML types. Durations are milliseconds everywhere.

var MONTHS = {
    tr: ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"],
    en: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
};
var DAYS_SHORT = {
    tr: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cts", "Paz"],
    en: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
};
var DAYS_LONG = {
    tr: ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"],
    en: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
};
// Hours and minutes: "4s 12d" in Turkish, "4h 12m" in English.
function unitH(tr) { return tr ? "s" : "h"; }
function unitM(tr) { return tr ? "d" : "m"; }

function dayKey(date) {
    var y = date.getFullYear();
    var m = String(date.getMonth() + 1).padStart(2, "0");
    var d = String(date.getDate()).padStart(2, "0");
    return y + "-" + m + "-" + d;
}

function keyToDate(key) {
    var p = key.split("-");
    return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]), 12, 0, 0);
}

function shiftKey(key, days) {
    var d = keyToDate(key);
    d.setDate(d.getDate() + days);
    return dayKey(d);
}

// Monday = 0
function weekday(key) {
    return (keyToDate(key).getDay() + 6) % 7;
}

function dayNum(key) {
    return keyToDate(key).getDate();
}

// "29 Eyl" / "Sep 29"
function shortDate(key, tr) {
    var d = keyToDate(key);
    var m = MONTHS[tr ? "tr" : "en"][d.getMonth()];
    return tr ? d.getDate() + " " + m : m + " " + d.getDate();
}

// "Salı 29 Eyl" / "Tuesday, Sep 29"
function longDate(key, tr) {
    var day = DAYS_LONG[tr ? "tr" : "en"][weekday(key)];
    return tr ? day + " " + shortDate(key, tr) : day + ", " + shortDate(key, tr);
}

function newDay() {
    return { total: 0, apps: {}, h: [], s: {}, best: [0, 0], n: {} };
}

function minutes(ms) {
    return Math.floor(Math.max(0, ms) / 60000);
}

// "4s 12d" / "4h 12m"
function fmt(ms, tr) {
    var t = minutes(ms);
    var h = Math.floor(t / 60);
    var m = t % 60;
    return h > 0 ? h + unitH(tr) + " " + String(m).padStart(2, "0") + unitM(tr) : m + unitM(tr);
}

// "4s12d" (week chart labels)
function fmtTight(ms, tr) {
    var t = minutes(ms);
    var h = Math.floor(t / 60);
    var m = t % 60;
    return h > 0 ? h + unitH(tr) + String(m).padStart(2, "0") + unitM(tr) : m + unitM(tr);
}

// "6s 00d" (goal / limit steppers), hours as a fraction; `off` when zero
function fmtHours(hours, tr, off) {
    if (hours <= 0)
        return off;
    var h = Math.floor(hours);
    var m = Math.round((hours - h) * 60);
    return h + unitH(tr) + " " + String(m).padStart(2, "0") + unitM(tr);
}

// "6s" / "1s 30d" — goal marks, no leading zero
function fmtMarks(min, tr) {
    var h = Math.floor(min / 60);
    var m = Math.round(min % 60);
    if (h === 0 && m === 0)
        return "0";
    return m === 0 ? h + unitH(tr) : h > 0 ? h + unitH(tr) + " " + m + unitM(tr) : m + unitM(tr);
}

// "18:42"
function clock(ms) {
    var s = Math.max(0, Math.ceil(ms / 1000));
    return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
}

function hhmm(epoch) {
    var d = new Date(epoch);
    return String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
}

function monogram(name) {
    var s = String(name || "?").replace(/[^A-Za-z0-9À-ɏ]/g, "");
    return s.length ? s.charAt(0).toUpperCase() : "?";
}

// Sorted app rows for a set of app->ms maps, with the tail folded into
// one "Diğer (n)" row. `rel` is relative to the leading app.
function appRows(apps, total, limit, skip) {
    var out = [];
    for (var k in apps)
        if (!skip || skip.indexOf(k) === -1)
            out.push({ id: k, ms: apps[k] });
    out.sort(function (a, b) { return b.ms - a.ms; });
    var head = limit > 0 ? out.slice(0, limit) : out;
    var tail = limit > 0 ? out.slice(limit) : [];
    if (tail.length) {
        var sum = 0;
        for (var i = 0; i < tail.length; i++)
            sum += tail[i].ms;
        head.push({ id: "", other: tail.length, ms: sum });
    }
    var top = head.length ? head[0].ms : 1;
    var all = total > 0 ? total : 1;
    for (var j = 0; j < head.length; j++) {
        head[j].rel = top > 0 ? head[j].ms / top : 0;
        head[j].share = head[j].ms / all;
    }
    return head;
}

function mergeApps(list) {
    var out = {};
    for (var i = 0; i < list.length; i++) {
        var a = list[i] ? list[i].apps : null;
        if (!a)
            continue;
        for (var k in a)
            out[k] = (out[k] || 0) + a[k];
    }
    return out;
}

function sumTotal(list) {
    var t = 0;
    for (var i = 0; i < list.length; i++)
        t += list[i] ? list[i].total : 0;
    return t;
}
