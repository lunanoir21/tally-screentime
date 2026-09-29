// Tally report: one self-contained page. The data is in #payload; nothing
// here talks to the network. Hover or focus a tile for its details, click a
// day to look at that day alone.
(function () {
  'use strict';

  var P = JSON.parse(document.getElementById('payload').textContent);
  var R = P.report, I = P.i18n, T = I.t, N = P.names || {}, ICONS = P.icons || {};
  var U = I.units;
  var goal = R.goalMs;
  var st = { sel: -1, look: P.look };

  // ---- helpers ------------------------------------------------------------------------------
  function el(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function tpl(s, o) {
    return String(s).replace(/\{(\w+)\}/g, function (_, k) { return o[k] != null ? o[k] : ''; });
  }
  function fmt(ms) {
    var t = Math.floor(Math.max(0, ms) / 60000), h = Math.floor(t / 60), m = t % 60;
    return h > 0 ? h + U.h + ' ' + pad(m) + U.m : m + U.m;
  }
  function tight(ms) {
    var t = Math.floor(Math.max(0, ms) / 60000), h = Math.floor(t / 60), m = t % 60;
    return h > 0 ? h + U.h + pad(m) + U.m : m + U.m;
  }
  function name(id) { return N[id] || id; }
  function keyDate(k) { var p = k.split('-'); return new Date(+p[0], +p[1] - 1, +p[2], 12); }
  function dayKey(d) { return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()); }
  function shift(k, n) { var d = keyDate(k); d.setDate(d.getDate() + n); return dayKey(d); }
  function wd(k) { return (keyDate(k).getDay() + 6) % 7; }
  function shortDate(k) {
    var d = keyDate(k), m = I.months[d.getMonth()];
    return I.tr ? d.getDate() + ' ' + m : m + ' ' + d.getDate();
  }
  function longDate(k) {
    var n = I.dayLong[wd(k)];
    return I.tr ? n + ' ' + shortDate(k) : n + ', ' + shortDate(k);
  }
  function pct(x) { return Math.round(x * 100); }
  function sum(a) { var s = 0; for (var i = 0; i < a.length; i++) s += a[i]; return s; }
  function peakOf(h) {
    var p = -1;
    for (var i = 0; i < h.length; i++) if (h[i] > 0 && (p < 0 || h[i] > h[p])) p = i;
    return p;
  }
  function hourRange(i) { return pad(i) + ':00 – ' + pad((i + 1) % 24) + ':00'; }

  // ---- what is selected ------------------------------------------------------------------------
  function selDays() { return st.sel >= 0 ? [R.days[st.sel]] : R.days; }
  function selHours() {
    var h = [], i;
    for (i = 0; i < 24; i++) h.push(0);
    selDays().forEach(function (d) { (d.h || []).forEach(function (v, j) { if (j < 24) h[j] += v; }); });
    return h;
  }
  function selApps() {
    var m = {}, tot = 0;
    selDays().forEach(function (d) {
      tot += d.total;
      for (var k in d.apps) m[k] = (m[k] || 0) + d.apps[k];
    });
    var a = [];
    for (var id in m) if (m[id] >= 60000) a.push({ id: id, ms: m[id], share: tot > 0 ? m[id] / tot : 0 });
    a.sort(function (x, y) { return y.ms - x.ms; });
    return a;
  }
  function selTotal() { return sum(selDays().map(function (d) { return d.total; })); }
  function topApp(d) {
    var best = null;
    for (var k in d.apps) if (!best || d.apps[k] > d.apps[best]) best = k;
    return best;
  }
  function daysUsed(id) {
    var n = 0;
    R.days.forEach(function (d) { if ((d.apps[id] || 0) >= 60000) n++; });
    return n;
  }

  // ---- weeks (for the "all" chart) -------------------------------------------------------------------
  var weeks = [];
  if (R.seriesKind === 'week') {
    R.series.forEach(function (s) {
      weeks.push(R.days.filter(function (d) { return shift(d.key, -d.weekday) === s.key; }));
    });
  }

  // ---- tooltips ------------------------------------------------------------------------------------------
  // Each returns { t: title, l: [lines], b: badge }.
  function tipHours(i, h, ctxDay) {
    var tot = sum(h), ms = h[i] || 0;
    var lines = [fmt(ms) + (tot > 0 ? ' · ' + tpl(ctxDay ? T.shareDay : T.sharePeriod, { p: pct(ms / tot) }) : '')];
    return { t: hourRange(i), l: ms > 0 ? lines : [T.none], b: i === peakOf(h) && ms > 0 ? T.peakBadge : '' };
  }
  function tipDay(i) {
    var d = R.days[i], lines = [];
    if (d.total <= 0) return { t: longDate(d.key), l: [T.none], b: '' };
    lines.push(fmt(d.total) + (goal > 0 ? ' · ' + tpl(T.ofGoal, { p: pct(d.total / goal) }) : ''));
    var top = topApp(d);
    if (top) lines.push(tpl(T.top, { a: esc(name(top)), t: fmt(d.apps[top]) }));
    var ph = peakOf(d.h || []);
    if (ph >= 0) lines.push(tpl(T.peakHour, { h: pad(ph) + ':00', t: fmt(d.h[ph]) }));
    return { t: longDate(d.key), l: lines, b: d.key === R.longestDay.key && R.dayCount > 1 ? T.longestBadge : '' };
  }
  function tipWeek(i) {
    var ds = weeks[i], tot = sum(ds.map(function (d) { return d.total; }));
    var first = ds.length ? ds[0].key : R.series[i].key;
    var lines = [fmt(tot)];
    if (goal > 0) lines[0] += ' · ' + tpl(T.ofGoal, { p: pct(tot / (goal * 7)) });
    lines.push(tpl(T.avgDay, { t: fmt(tot / 7) }));
    return { t: tpl(T.weekOf, { d: shortDate(first) }), l: tot > 0 ? lines : [T.none], b: '' };
  }
  function tipFor(kind, i) {
    if (kind === 'h') return tipHours(i, selHours(), st.sel >= 0 || R.scope === 'day');
    if (kind === 'b') {
      if (R.seriesKind === 'hour') return tipHours(i, R.hours, true);
      if (R.seriesKind === 'day') return tipDay(i);
      return tipWeek(i);
    }
    if (kind === 'd') return tipDay(i);
    if (kind === 'a') {
      var a = selApps()[i];
      return { t: esc(name(a.id)), l: [fmt(a.ms) + ' · ' + tpl(st.sel >= 0 ? T.shareDay : T.sharePeriod, { p: pct(a.share) }), tpl(T.usedDays, { n: daysUsed(a.id) })], b: '' };
    }
    if (kind === 't') {
      var frac = (i + 1) / 40;
      return { t: tpl(T.ofGoal, { p: pct(frac) }), l: [fmt(goal * frac)], b: '' };
    }
    if (kind === 's') {
      var s = statList()[i];
      return { t: s.label, l: [s.hint], b: '' };
    }
    return null;
  }

  var tip = document.getElementById('tip');
  function showTip(target) {
    var raw = target.getAttribute('data-tip');
    if (!raw) return hideTip();
    var p = raw.split(':'), c = tipFor(p[0], +p[1]);
    if (!c) return hideTip();
    tip.innerHTML = '<b>' + c.t + '</b>' + c.l.map(function (x) { return '<span>' + x + '</span>'; }).join('') + (c.b ? '<em>' + esc(c.b) + '</em>' : '');
    tip.hidden = false;
    var r = target.getBoundingClientRect(), w = tip.offsetWidth, h = tip.offsetHeight;
    var x = Math.max(8, Math.min(window.innerWidth - w - 8, r.left + r.width / 2 - w / 2));
    var y = r.top - h - 12;
    if (y < 8) y = r.bottom + 12;
    tip.style.left = x + 'px';
    tip.style.top = y + 'px';
    tip.classList.add('on');
  }
  function hideTip() { tip.classList.remove('on'); }

  // ---- tiles -----------------------------------------------------------------------------------------------------
  function heroTile() {
    var t = el('section', 'tile hero s5');
    var ms = R.scope === 'week' ? R.avgPerDay : R.total;
    var mins = Math.floor(ms / 60000), h = Math.floor(mins / 60), m = mins % 60;
    t.appendChild(el('div', 'lab', esc(T.heroLabel)));
    t.appendChild(el('div', 'num', (h > 0 ? '<span>' + h + '</span><i>' + U.h + '</i>' : '') + '<span>' + m + '</span><i>' + U.m + '</i>'));
    if (R.prevTotal != null && R.prevTotal > 0) {
      var up = R.total >= R.prevTotal;
      var txt = R.scope === 'day' ? fmt(Math.abs(R.total - R.prevTotal)) : (I.tr ? '%' : '') + pct(Math.abs(R.total - R.prevTotal) / R.prevTotal) + (I.tr ? '' : '%');
      t.appendChild(el('div', 'delta', '<b><em>' + (up ? '▲' : '▼') + '</em> ' + esc(txt) + '</b>' + esc(R.scope === 'day' ? T.deltaDay : T.deltaWeek)));
    }
    if (goal > 0) {
      var basis = R.scope === 'day' ? R.total : R.avgPerDay, ratio = basis / goal;
      var filled = Math.floor(Math.min(1, ratio) * 40);
      var right = R.scope === 'day'
        ? (R.total >= goal ? tpl(T.goalOver, { t: fmt(R.total - goal) }) : tpl(T.goalLeft, { p: pct(ratio), t: fmt(goal - R.total) }))
        : tpl(T.ofAvgGoal, { p: pct(ratio) });
      t.appendChild(el('div', 'goalrow', '<span>' + esc(T.goalCap) + '</span><b>' + esc(right) + '</b>'));
      var ruler = el('div', 'ruler');
      for (var i = 0; i < 40; i++) {
        var b = el('button', (i < filled ? 'on ' : '') + (i === filled - 1 ? 'acc ' : '') + (i % 10 === 0 ? 'tall' : ''));
        b.setAttribute('data-tip', 't:' + i);
        b.setAttribute('aria-label', fmt(goal * (i + 1) / 40));
        ruler.appendChild(b);
      }
      t.appendChild(ruler);
      var marks = el('div', 'marks');
      [0, 1, 2, 3, 4].forEach(function (k) {
        var mm = goal / 60000 * k / 4, hh = Math.floor(mm / 60), r = Math.round(mm % 60);
        marks.appendChild(el('span', '', k === 0 ? '0' : (hh > 0 ? hh + U.h : '') + (r ? (hh > 0 ? ' ' : '') + r + U.m : '')));
      });
      t.appendChild(marks);
    } else {
      t.appendChild(el('div', 'goalrow', '<span>' + esc(T.goalOff) + '</span>'));
    }
    return t;
  }

  function chartTile() {
    var t = el('section', 'tile s7');
    t.appendChild(el('div', 'row', '<span class="lab">' + esc(T.chartTitle) + '</span><span class="note">' + esc(T.chartNote) + '</span>'));
    var series = R.series, n = series.length;
    var mx = 60000;
    series.forEach(function (s) { if (s.ms > mx) mx = s.ms; });
    if (R.seriesGoal * 1.11 > mx) mx = R.seriesGoal * 1.11; else mx = mx * 1.12;
    var peak = -1;
    series.forEach(function (s, i) { if (s.ms > 0 && (peak < 0 || s.ms > series[peak].ms)) peak = i; });
    var chart = el('div', 'chart');
    chart.style.setProperty('--gap', (n > 16 ? 4 : n > 8 ? 6 : 12) + 'px');
    if (n <= 3) chart.className += ' few';
    if (R.seriesGoal > 0) {
      var g = el('div', 'goal');
      g.style.bottom = Math.min(100, R.seriesGoal / mx * 100) + '%';
      chart.appendChild(g);
    }
    var bars = el('div', 'bars');
    series.forEach(function (s, i) {
      var b = el('button', 'bar' + (s.isToday ? ' now' : '') + (R.seriesGoal > 0 && s.ms >= R.seriesGoal ? ' hit' : '') + (R.seriesKind === 'day' && st.sel === i ? ' sel' : '') + (R.seriesKind === 'day' && st.sel >= 0 && st.sel !== i ? ' dim' : ''));
      b.setAttribute('data-tip', 'b:' + i);
      if (R.seriesKind === 'day') b.setAttribute('data-day', i);
      var f = el('div', 'fill');
      f.style.height = (s.ms / mx * 100) + '%';
      b.appendChild(f);
      if (i === peak) {
        var txt = R.seriesKind === 'hour' ? tpl(T.peakHour, { h: pad(i) + ':00', t: fmt(s.ms) }) : R.seriesKind === 'day' ? T.longestBadge : T.busiestWeek;
        b.appendChild(el('span', 'flag', esc(txt)));
      }
      bars.appendChild(b);
    });
    chart.appendChild(bars);
    t.appendChild(chart);
    var xl = el('div', 'xl');
    xl.style.setProperty('--gap', chart.style.getPropertyValue('--gap'));
    if (n <= 3) xl.className += ' few';
    series.forEach(function (s, i) {
      var lab = '', sub = '';
      if (R.seriesKind === 'hour') lab = i % 6 === 0 ? pad(i) : '';
      else if (R.seriesKind === 'day') { lab = I.dayShort[wd(s.key)]; sub = tight(s.ms); }
      else lab = i % 3 === 0 ? shortDate(s.key) : '';
      xl.appendChild(el('span', '', esc(lab) + (sub ? '<small>' + esc(sub) + '</small>' : '')));
    });
    t.appendChild(xl);
    return t;
  }

  function heatTile() {
    var t = el('section', 'tile s7');
    t.appendChild(el('div', 'row', '<span class="lab">' + esc(T.heatTitle) + '</span><span class="note">' + esc(T.heatNote) + '</span>'));
    var last = shift(R.to, -wd(R.to));
    var start = shift(last, -15 * 7);
    var first = shift(R.from, -wd(R.from));
    if (first > start) start = first;
    var byKey = {};
    R.days.forEach(function (d, i) { byKey[d.key] = i; });
    var maxT = 1;
    R.days.forEach(function (d) { if (d.total > maxT) maxT = d.total; });
    var heat = el('div', 'heat');
    var cols = Math.round((keyDate(last) - keyDate(start)) / 604800000) + 1;
    heat.style.gridTemplateColumns = 'repeat(' + cols + ', minmax(0, 1fr))';
    heat.style.maxWidth = (cols * 46 + (cols - 1) * 5) + 'px';
    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < 7; r++) {
        var k = shift(start, c * 7 + r), i = byKey[k];
        var b = el('button');
        if (i == null || k > R.to) { b.className = 'void'; b.disabled = true; heat.appendChild(b); continue; }
        var d = R.days[i], ratio = goal > 0 ? d.total / goal : d.total / maxT;
        var lv = d.total < 60000 ? 0 : ratio < 0.25 ? 1 : ratio < 0.5 ? 2 : ratio < 0.75 ? 3 : 4;
        b.className = 'l' + lv + (d.isToday ? ' now' : '') + (st.sel === i ? ' sel' : '');
        b.setAttribute('data-tip', 'd:' + i);
        b.setAttribute('data-day', i);
        b.setAttribute('aria-label', longDate(d.key) + ' ' + fmt(d.total));
        heat.appendChild(b);
      }
    }
    t.appendChild(heat);
    var lg = el('div', 'legend', esc(T.less));
    for (var l = 0; l < 5; l++) lg.appendChild(el('i', 'l' + l));
    lg.appendChild(document.createTextNode(T.more));
    t.appendChild(lg);
    return t;
  }

  function chipHtml() {
    if (st.sel < 0) return '';
    return '<span class="chip">' + esc(shortDate(R.days[st.sel].key)) + '<button data-reset aria-label="' + esc(T.reset) + '">✕</button></span>';
  }

  function hoursTile(span) {
    var h = selHours(), mx = 1, i;
    h.forEach(function (v) { if (v > mx) mx = v; });
    var peak = peakOf(h);
    var t = el('section', 'tile ' + span);
    t.appendChild(el('div', 'row', '<span class="lab">' + esc(T.hoursTitle) + '</span>' + chipHtml()));
    var strip = el('div', 'hours');
    for (i = 0; i < 24; i++) {
      var b = el('button', (h[i] === 0 ? 'zero ' : '') + (i === peak ? 'peak' : ''));
      b.setAttribute('data-tip', 'h:' + i);
      b.setAttribute('aria-label', hourRange(i) + ' ' + fmt(h[i]));
      var f = el('i');
      f.style.height = (h[i] / mx * 100) + '%';
      b.appendChild(f);
      strip.appendChild(b);
    }
    t.appendChild(strip);
    var hx = el('div', 'hx');
    ['00', '06', '12', '18', '24'].forEach(function (x) { hx.appendChild(el('span', '', x)); });
    t.appendChild(hx);
    if (peak >= 0) t.appendChild(el('div', 'peakline', esc(T.peakBadge) + ' <b>' + pad(peak) + ':00</b> · ' + esc(fmt(h[peak]))));
    var tot = selTotal(), covered = sum(h);
    if (tot > 0 && covered / tot < 0.98) t.appendChild(el('div', 'cover', esc(tpl(T.hoursPartial, { p: Math.round(covered / tot * 100) }))));
    return t;
  }

  function appsTile(span) {
    var a = selApps().slice(0, 8);
    var t = el('section', 'tile ' + span);
    t.appendChild(el('div', 'row', '<span class="lab">' + esc(T.appsTitle) + '</span>' + chipHtml()));
    if (!a.length) { t.appendChild(el('div', 'empty', esc(T.none))); return t; }
    var box = el('div', 'apps'), top = a[0].ms;
    a.forEach(function (x, i) {
      var b = el('button', 'app' + (i === 0 ? ' first' : ''));
      b.setAttribute('data-tip', 'a:' + i);
      var nm = name(x.id);
      var glyph = ICONS[x.id] ? '<img alt="" src="' + esc(ICONS[x.id]) + '">' : esc(nm.charAt(0).toUpperCase());
      b.innerHTML = '<span class="mono">' + glyph + '</span><span><span class="l1r"><span class="nm">' + esc(nm) + '<small>' + (I.tr ? '%' : '') + pct(x.share) + (I.tr ? '' : '%') + '</small></span><span class="tm">' + esc(fmt(x.ms)) + '</span></span><div class="trk"><i style="width:' + Math.max(2, x.ms / top * 100) + '%"></i></div></span>';
      box.appendChild(b);
    });
    t.appendChild(box);
    return t;
  }

  function statList() {
    var ph = peakOf(R.hours);
    var s = [];
    s.push({ label: T.statPeak, value: ph >= 0 ? pad(ph) + ':00' : '—', sub: ph >= 0 ? fmt(R.hours[ph]) : '', hint: ph >= 0 ? tpl(T.hintPeak, { t: fmt(R.hours[ph]) }) : T.none });
    if (R.scope === 'day') {
      s.push({ label: T.statRun, value: R.bestRun.ms >= 60000 ? fmt(R.bestRun.ms) : '—', sub: '', hint: T.hintRun });
      s.push({ label: T.statGoalPct, value: goal > 0 ? (I.tr ? '%' : '') + pct(R.total / goal) + (I.tr ? '' : '%') : '—', sub: '', hint: T.hintGoalDay });
      s.push({ label: T.statApps, value: String(R.apps.filter(function (x) { return x.ms >= 60000; }).length), sub: '', hint: T.hintApps });
    } else {
      s.push({ label: T.longestDay, value: R.longestDay.ms > 0 ? shortDate(R.longestDay.key) : '—', sub: R.longestDay.ms > 0 ? fmt(R.longestDay.ms) : '', hint: R.longestDay.ms > 0 ? tpl(T.hintLongest, { d: longDate(R.longestDay.key), t: fmt(R.longestDay.ms) }) : T.none });
      s.push({ label: T.statGoal, value: R.goalHits + ' / ' + R.dayCount, sub: '', hint: T.hintGoalDays });
      s.push({ label: R.scope === 'week' ? T.total : T.statRecorded, value: R.scope === 'week' ? fmt(R.total) : String(R.recordedDays), sub: R.scope === 'week' ? '' : T.days, hint: R.scope === 'week' ? T.hintTotal : T.hintRecorded });
    }
    return s;
  }
  function statTiles(span) {
    return statList().map(function (s, i) {
      var t = el('section', 'tile st ' + span);
      var b = el('button', 'stat');
      b.setAttribute('data-tip', 's:' + i);
      b.innerHTML = '<span class="lab">' + esc(s.label) + '</span><span class="v">' + esc(s.value) + (s.sub ? '<small>' + esc(s.sub) + '</small>' : '') + '</span>';
      t.appendChild(b);
      return t;
    });
  }

  // ---- page ----------------------------------------------------------------------------------------------------------
  var MARK = '<svg width="34" height="34" viewBox="0 0 64 64" fill="none" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 38H17L23 16L32 50L39 26L43 34H50" stroke="var(--fg)" stroke-width="5"/><path d="M58 20V46" stroke="var(--acc)" stroke-width="5"/></svg>';

  function applyPalette() {
    var p = P.pal[st.look], s = document.documentElement.style;
    s.setProperty('--card', p.card); s.setProperty('--fg', p.fg); s.setProperty('--acc', p.acc);
    document.documentElement.setAttribute('data-look', st.look);
  }

  function render() {
    applyPalette();
    var app = document.getElementById('app');
    app.innerHTML = '';
    var wrap = el('div', 'wrap');
    var top = el('header', 'top');
    top.innerHTML = '<div class="brand">' + MARK + '<b>tally</b></div><div class="meta"><div><div class="t">' + esc(T.title) + '</div><div class="p">' + esc(T.period) + '</div></div><button class="look" data-lookbtn aria-label="' + esc(T.lookLabel) + '" title="' + esc(T.lookLabel) + '"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16z" fill="currentColor"/></svg></button></div>';
    wrap.appendChild(top);
    var grid = el('div', 'grid');
    grid.appendChild(heroTile());
    grid.appendChild(chartTile());
    if (R.scope === 'day') {
      grid.appendChild(appsTile('s7'));
      var box = el('div', 's5'); box.style.display = 'grid'; box.style.gridTemplateColumns = '1fr 1fr'; box.style.gap = '16px';
      statTiles('s12').forEach(function (x) { x.style.gridColumn = 'auto'; box.appendChild(x); });
      grid.appendChild(box);
    } else if (R.scope === 'week') {
      grid.appendChild(hoursTile('s7'));
      grid.appendChild(appsTile('s5'));
      statTiles('s4').forEach(function (x, i) { x.className = 'tile st s3x'; x.style.gridColumn = 'span 3'; grid.appendChild(x); });
    } else {
      grid.appendChild(heatTile());
      grid.appendChild(hoursTile('s5'));
      grid.appendChild(appsTile('s7'));
      var box2 = el('div', 's5'); box2.style.display = 'grid'; box2.style.gridTemplateColumns = '1fr 1fr'; box2.style.gap = '16px';
      statTiles('s12').forEach(function (x) { x.style.gridColumn = 'auto'; box2.appendChild(x); });
      grid.appendChild(box2);
    }
    wrap.appendChild(grid);
    wrap.appendChild(el('div', 'foot', '<span>' + esc(P.generated) + '</span><span>' + esc(T.privacy) + '</span>'));
    app.appendChild(wrap);
  }

  // The website can hand the page its theme (three #rrggbb colours, nothing else).
  window.addEventListener('message', function (e) {
    var d = e.data;
    if (!d || d.type !== 'tally-theme' || !d.pal) return;
    var ok = /^#[0-9a-fA-F]{6}$/;
    if (!ok.test(d.pal.card) || !ok.test(d.pal.fg) || !ok.test(d.pal.acc)) return;
    P.pal.theme = { card: d.pal.card, fg: d.pal.fg, acc: d.pal.acc };
    st.look = 'theme';
    render();
  });

  document.addEventListener('click', function (e) {
    var d = e.target.closest('[data-day]');
    if (d) { var i = +d.getAttribute('data-day'); st.sel = st.sel === i ? -1 : i; render(); hideTip(); return; }
    if (e.target.closest('[data-reset]')) { st.sel = -1; render(); hideTip(); return; }
    if (e.target.closest('[data-lookbtn]')) { st.look = st.look === 'paper' ? 'theme' : 'paper'; render(); return; }
    var t = e.target.closest('[data-tip]');
    if (t) showTip(t);
  });
  document.addEventListener('pointerover', function (e) {
    if (e.pointerType === 'touch') return;
    var t = e.target.closest('[data-tip]');
    if (t) showTip(t); else hideTip();
  });
  document.addEventListener('focusin', function (e) { var t = e.target.closest('[data-tip]'); if (t) showTip(t); });
  document.addEventListener('focusout', hideTip);
  window.addEventListener('scroll', hideTip, { passive: true });

  render();

  // #sel=3&pin=b:5 — used to take pictures of a hovered state.
  var m = /sel=(\d+)/.exec(location.hash);
  if (m) { st.sel = +m[1]; render(); }
  m = /pin=(\w:\d+)/.exec(location.hash);
  if (m) { var pinned = document.querySelector('[data-tip="' + m[1] + '"]'); if (pinned) showTip(pinned); }
  m = /look=(theme|paper)/.exec(location.hash);
  if (m) { st.look = m[1]; render(); }
})();
