pragma Singleton
import QtQuick
import Quickshell
import "js/Model.js" as Model

// Every user-visible string, in Turkish and English: the language setting,
// or the locale when it is "auto". Parameterised strings are functions; a
// function that reads `tr` re-evaluates the bindings that call it when the
// language changes.
Item {
    id: s

    readonly property bool tr: {
        var l = TallyStore.language;
        if (l === "tr")
            return true;
        if (l === "en")
            return false;
        var loc = Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "";
        return loc.toLowerCase().indexOf("tr") === 0;
    }
    function t(trText, enText) { return tr ? trText : enText; }

    // ---- Durations and dates -----------------------------------------------------------
    readonly property string uh: tr ? "s" : "h"
    readonly property string um: tr ? "d" : "m"
    function fmt(ms) { return Model.fmt(ms, tr); }
    function fmtTight(ms) { return Model.fmtTight(ms, tr); }
    function fmtHours(h) { return Model.fmtHours(h, tr, tr ? "kapalı" : "off"); }
    function fmtMarks(min) { return Model.fmtMarks(min, tr); }
    function fmtGoal(h) { return Model.fmtMarks(h * 60, tr); }
    function month(i) { return Model.MONTHS[tr ? "tr" : "en"][i]; }
    function dayShort(i) { return Model.DAYS_SHORT[tr ? "tr" : "en"][i]; }
    function dayLong(i) { return Model.DAYS_LONG[tr ? "tr" : "en"][i]; }
    function shortDate(key) { return Model.shortDate(key, tr); }
    function longDate(key) { return Model.longDate(key, tr); }
    function sec(ms) {
        var v = Math.round(ms / 1000);
        var m = Math.floor(v / 60), r = String(v % 60).padStart(2, "0");
        return tr ? m + "d " + r + "sn" : m + "m " + r + "s";
    }
    // Monday-first single-row labels down the heatmap's left edge.
    readonly property var mapDays: tr ? ["Pt", "Ça", "Cu", "Pz"] : ["Mo", "We", "Fr", "Su"]

    // ---- Common ------------------------------------------------------------------------------
    readonly property string tabDay: tr ? "Gün" : "Day"
    readonly property string tabWeek: tr ? "Hafta" : "Week"
    readonly property string tabMap: tr ? "Harita" : "Map"
    readonly property string apps: tr ? "Uygulamalar" : "Apps"
    readonly property string today: tr ? "Bugün" : "Today"
    readonly property string yesterday: tr ? "Dün" : "Yesterday"
    readonly property string settings: tr ? "Ayarlar" : "Settings"
    readonly property string backUp: tr ? "Yedekle" : "Back up"
    readonly property string restore: tr ? "Geri yükle" : "Restore"
    readonly property string restorePath: tr ? "yedek dosyasının yolu, Enter ile içe aktar" : "path to a backup, Enter to import"
    function importDone(a, r) { return tr ? a + " gün eklendi, " + r + " gün güncellendi" : a + " days added, " + r + " updated"; }
    function importNothing(k) { return tr ? "yeni bir şey yok (" + k + " gün zaten var)" : "nothing new (" + k + " days already there)"; }
    readonly property string importFailed: tr ? "dosya okunamadı ya da bir Tally yedeği değil" : "could not read the file, or it is not a Tally backup"
    readonly property string historyBackedUp: tr ? "Yedek ~/tally-history.json dosyasına yazıldı" : "Backup written to ~/tally-history.json"
    readonly property string exportJson: tr ? "Dışa aktar · .json" : "Export · .json"
    readonly property string back: tr ? "Geri" : "Back"
    readonly property string next: tr ? "İleri" : "Next"
    readonly property string skip: tr ? "Atla" : "Skip"
    readonly property string done: tr ? "Bitti" : "Done"
    readonly property string soon: tr ? "henüz kayıt yok" : "nothing recorded yet"
    function days(n) { return tr ? n + " gün" : n + (n === 1 ? " day" : " days"); }

    // ---- Day ------------------------------------------------------------------------------------
    readonly property string focusedTime: tr ? "ODAKLANILAN SÜRE" : "FOCUSED TIME"
    readonly property string fromYesterday: tr ? "dünden" : "vs yesterday"
    readonly property string fromPrevDay: tr ? "önceki günden" : "vs the day before"
    function dailyGoal(h) { return tr ? "Günlük hedef · " + fmtGoal(h) : "Daily goal · " + fmtGoal(h); }
    function goalLeft(pct, left) { return tr ? "%" + pct + " · " + left + " kaldı" : pct + "% · " + left + " left"; }
    function goalOver(over) { return tr ? "hedef aşıldı · +" + over : "goal reached · +" + over; }
    readonly property string goalOff: tr ? "Günlük hedef kapalı · Ayarlar'dan aç" : "Daily goal is off · turn it on in Settings"
    readonly property string hourByHour: tr ? "SAAT SAAT" : "HOUR BY HOUR"
    function peak(hour, min) { return tr ? "en yoğun " + hour + " · " + min + " dk" : "peak " + hour + " · " + min + " min"; }
    readonly property string appsLabel: tr ? "UYGULAMALAR" : "APPS"
    function allApps(n) { return tr ? "tümü, " + n + " →" : "all " + n + " →"; }
    function others(n) { return tr ? "Diğer (" + n + ")" : "Others (" + n + ")"; }
    readonly property string startFocus: tr ? "Odak modunu başlat" : "Start focus mode"
    readonly property string focusSession: tr ? "Odak oturumu" : "Focus session"
    function longestRun(dur, at) { return tr ? "en uzun kesintisiz oturum " + dur + " · " + at : "longest uninterrupted run " + dur + " · " + at; }

    // ---- Week -----------------------------------------------------------------------------------------
    readonly property string last7: tr ? "Son 7 gün" : "Last 7 days"
    readonly property string sevenDays: tr ? "7 gün" : "7 days"
    readonly property string dailyAvg: tr ? "GÜNLÜK ORTALAMA" : "DAILY AVERAGE"
    readonly property string fromLastWeek: tr ? "geçen haftadan" : "vs last week"
    readonly property string dayByDay: tr ? "GÜN GÜN" : "DAY BY DAY"
    function dashedGoal(h) { return tr ? "kesikli çizgi = hedef " + fmtGoal(h) : "dashed line = goal " + fmtGoal(h); }
    readonly property string total: tr ? "toplam" : "total"
    readonly property string longestDay: tr ? "en uzun gün" : "longest day"
    readonly property string goalReached: tr ? "hedefe ulaşılan" : "goal reached"
    function ofSeven(n) { return tr ? n + " / 7 gün" : n + " / 7 days"; }
    readonly property string topThisWeek: tr ? "BU HAFTA EN ÇOK" : "MOST USED THIS WEEK"
    readonly property string exportWeek: tr ? "Haftayı dışa aktar · .json" : "Export week · .json"
    readonly property string weekExported: tr ? "Hafta dışa aktarıldı" : "Week exported"

    // ---- Map -----------------------------------------------------------------------------------------------
    readonly property string last16: tr ? "SON 16 HAFTA · TOPLAM" : "LAST 16 WEEKS · TOTAL"
    readonly property string hoursWord: tr ? "saat" : "hours"
    readonly property string less: tr ? "az" : "less"
    readonly property string more: tr ? "çok" : "more"
    readonly property string pickedDay: tr ? "seçili gün" : "selected day"
    readonly property string weekRhythm: tr ? "HAFTANIN RİTMİ · ORTALAMA" : "WEEK RHYTHM · AVERAGE"
    readonly property string dailyAvgLow: tr ? "günlük ortalama" : "daily average"
    readonly property string busiestDay: tr ? "en yoğun gün" : "busiest day"
    function streakLabel(mark) { return tr ? "en uzun seri (" + mark + "+)" : "longest streak (" + mark + "+)"; }
    function daysRecorded(n) { return tr ? n + " gün" : n + (n === 1 ? " day" : " days"); }

    // ---- Apps / app ---------------------------------------------------------------------------------------------
    function appsOfDay(date) { return tr ? "UYGULAMALAR · " + date.toUpperCase() : "APPS · " + date.toUpperCase(); }
    function appCount(n) { return tr ? n + " uygulama" : n + (n === 1 ? " app" : " apps"); }
    function appId(id) { return (tr ? "app id · " : "app id · ") + id; }
    readonly property string todayCaps: tr ? "BUGÜN" : "TODAY"
    readonly property string ofTotal: tr ? "toplamın" : "of total"
    readonly property string last14: tr ? "SON 14 GÜN" : "LAST 14 DAYS"
    function dashedLimit(h) { return tr ? "kesikli çizgi = sınır " + fmtGoal(h) : "dashed line = limit " + fmtGoal(h); }
    readonly property string sessionsToday: tr ? "bugün oturum" : "sessions today"
    readonly property string longest: tr ? "en uzun" : "longest"
    readonly property string avg14: tr ? "14 gün ort." : "14-day avg"
    readonly property string dailyLimit: tr ? "Günlük sınır" : "Daily limit"
    function used(t) { return tr ? t + " kullanıldı" : t + " used"; }
    function leftOf(t) { return tr ? t + " kaldı" : t + " left"; }
    readonly property string limitExceeded: tr ? "sınır aşıldı" : "limit exceeded"
    readonly property string atLimit: tr ? "Sınıra gelince" : "At the limit"
    readonly property string modeNotify: tr ? "Bildir" : "Notify"
    readonly property string modeWarn: tr ? "Uyar" : "Warn"
    readonly property string modeDim: tr ? "Karart" : "Dim"
    readonly property string stopTracking: tr ? "Takipten çıkar" : "Stop tracking"

    // ---- Focus -------------------------------------------------------------------------------------------------------------
    readonly property string focusCaps: tr ? "ODAK OTURUMU" : "FOCUS SESSION"
    readonly property string focusPaused: tr ? "ODAK OTURUMU · DURAKLATILDI" : "FOCUS SESSION · PAUSED"
    function startedAt(t) { return tr ? "başladı " + t : "started " + t; }
    function endsAt(t) { return tr ? "biter " + t : "ends " + t; }
    readonly property string thisSession: tr ? "BU OTURUMDA" : "THIS SESSION"
    readonly property string pause: tr ? "Duraklat" : "Pause"
    readonly property string resume: tr ? "Devam" : "Resume"
    readonly property string finish: tr ? "Bitir" : "Finish"

    // ---- Settings -------------------------------------------------------------------------------------------------------------
    readonly property string secLook: tr ? "GÖRÜNÜM" : "APPEARANCE"
    readonly property string alwaysShow: tr ? "Bar'da her zaman göster" : "Always show in the bar"
    readonly property string pillContent: tr ? "Pill içeriği" : "Pill content"
    readonly property string pillIcon: tr ? "Simge" : "Icon"
    readonly property string pillIconTime: tr ? "Simge + süre" : "Icon + time"
    readonly property string pillGoalLine: tr ? "Pill'de hedef çizgisi" : "Goal line on the pill"
    readonly property string theme: tr ? "Tema" : "Theme"
    readonly property string language: tr ? "Dil" : "Language"
    readonly property string langAuto: tr ? "Otomatik" : "Auto"
    readonly property string secGoal: tr ? "HEDEF" : "GOAL"
    readonly property string dailyGoalRow: tr ? "Günlük hedef" : "Daily goal"
    readonly property string notifyNear: tr ? "%80'e gelince bildir" : "Notify at 80%"
    readonly property string notifyOver: tr ? "Hedef aşılınca bildir" : "Notify when exceeded"
    readonly property string secTrack: tr ? "TAKİP" : "TRACKING"
    readonly property string idleAfter: tr ? "Boşta sayılma süresi" : "Idle after"
    readonly property string countVideo: tr ? "Video oynarken say" : "Count while video plays"
    readonly property string untracked: tr ? "Takip dışı uygulamalar" : "Untracked apps"
    readonly property string addChip: tr ? "+ ekle" : "+ add"
    readonly property string secData: tr ? "VERİ" : "DATA"
    readonly property string keepHistory: tr ? "Geçmişi sakla" : "Keep history"
    readonly property var retention: tr ? ["90 gün", "1 yıl", "süresiz"] : ["90 days", "1 year", "forever"]
    readonly property var idleOpts: tr ? ["1d", "3d", "5d", "10d"] : ["1m", "3m", "5m", "10m"]
    readonly property string resetToday: tr ? "Bugünü sıfırla" : "Reset today"
    readonly property string sure: tr ? "Emin misin?" : "Sure?"
    readonly property string historyExported: tr ? "Geçmiş dışa aktarıldı" : "History exported"

    // ---- Pill, dim, notifications --------------------------------------------------------------------------------------------------
    readonly property string idleSuffix: tr ? " · boşta" : " · idle"
    function tipToday(t, pct) { return tr ? "Bugün " + t + (pct >= 0 ? " · hedefin %" + pct + "'i" : "") : "Today " + t + (pct >= 0 ? " · " + pct + "% of goal" : ""); }
    readonly property string tipEmpty: tr ? "Tally · henüz kayıt yok" : "Tally · nothing recorded yet"
    function hitLimit(app) { return tr ? app + " sınırına ulaştın" : "You reached " + app + "'s limit"; }
    function limitLine(h) { return tr ? "Günlük sınır " + fmtGoal(h) : "Daily limit " + fmtGoal(h); }
    readonly property string keepGoing: tr ? "Devam et" : "Continue"
    readonly property string nGoalNear: tr ? "Günlük hedefe yaklaştın" : "Close to your daily goal"
    function nGoalNearBody(left, h) { return tr ? left + " kaldı · hedef " + fmtGoal(h) : left + " left · goal " + fmtGoal(h); }
    readonly property string nGoalOver: tr ? "Günlük hedef aşıldı" : "Daily goal reached"
    function nGoalOverBody(total, over) { return tr ? total + " · hedefin " + over + " üstünde" : total + " · " + over + " over your goal"; }
    function nAppNear(app) { return tr ? app + " sınırına yaklaştı" : app + " is close to its limit"; }
    function nAppNearBody(left, h) { return tr ? left + " kaldı · günlük sınır " + fmtGoal(h) : left + " left · daily limit " + fmtGoal(h); }
    readonly property string nFocusEnd: tr ? "Odak oturumu bitti" : "Focus session over"
    function nFocusEndBody(min, parts) { return min + (tr ? " dk" : " min") + (parts ? " · " + parts : ""); }

    // ---- Themes ---------------------------------------------------------------------------------------------------------------------------
    function themeName(t) {
        if (t.id === "system") return tr ? "Sistemi izle" : "Follow system";
        if (t.id === "ultrawhite") return tr ? "Ultra Beyaz" : "Ultra White";
        return t.name;
    }
    function themeTag(tag) {
        if (tag === "user") return tr ? "kullanıcı" : "user";
        if (tag === "auto") return tr ? "otomatik" : "auto";
        return tr ? "yerleşik" : "bundled";
    }
    readonly property string searchThemes: tr ? "Tema ara…" : "Search themes…"
    function themeCount(n) { return tr ? n + " tema" : n + (n === 1 ? " theme" : " themes"); }
    readonly property string allThemes: tr ? "TÜM TEMALAR" : "ALL THEMES"
    function defaultTheme(name) { return (tr ? "Varsayılan • " : "Default • ") + name; }
    readonly property string pickerKeys: tr ? "↑↓ gez · ↵ uygula · esc kapat" : "↑↓ move · ↵ apply · esc close"
    readonly property string preview: tr ? "ÖNİZLEME" : "PREVIEW"
    readonly property string ofGoal70: tr ? "%70 hedef" : "70% of goal"
    readonly property string applied: tr ? "Uygulandı" : "Applied"
    readonly property string apply: tr ? "Uygula" : "Apply"
    readonly property string accentFromTheme: tr ? "Vurgu rengi temadan gelir" : "The accent comes from the theme"

    // ---- First run -------------------------------------------------------------------------------------------------------------------------------
    readonly property string obLangTitle: tr ? "Dil" : "Language"
    readonly property string obLangBody: tr ? "Tally'nin hangi dilde konuşacağını seç. Sonra Ayarlar'dan değiştirebilirsin." : "Choose the language Tally speaks. You can change it later in Settings."
    readonly property string obWhatTitle: tr ? "Ekran süresi, hafifçe." : "Screen time, kept light."
    readonly property string obWhatBody: tr ? "Tally, hangi pencerenin ne kadar süre odakta kaldığını sayar ve günlük hedefine göre gösterir." : "Tally counts how long each window has focus and shows it against a daily goal."
    readonly property string obPoint1: tr ? "Yalnızca odaktaki pencereyi sayar; boştayken durur." : "It counts only the focused window, and stops when you are away."
    readonly property string obPoint2: tr ? "Hiçbir şey makineden çıkmaz; geçmiş kendi dosyanda durur." : "Nothing leaves your machine; the history is a file of your own."
    readonly property string obPoint3: tr ? "Arka plan servisi yok: boştayken işlemciyi hiç çalıştırmaz." : "There is no background service: when you are idle, it does no work at all."
    readonly property string obLookTitle: tr ? "Bir görünüm seç" : "Pick a look"
    readonly property string obLookBody: tr ? "Hepsi Ayarlar'dan yeniden seçilebilir; orada on altı tema var." : "You can change it any time in Settings, where all sixteen themes live."
    readonly property string obGoalTitle: tr ? "Hedefin ne olsun?" : "Set your goal"
    readonly property string obGoalBody: tr ? "Günlük odak hedefin, panelde çentikli cetvel olarak görünür. Pill'in ne göstereceğini de seç." : "Your daily focus goal is drawn as a ruler of tick marks in the panel. Choose what the pill shows too."
    readonly property string obGoalRow: tr ? "Günlük hedef" : "Daily goal"
    readonly property string obStart: tr ? "Başla" : "Start"
    readonly property string obKeyHint: tr ? "↵ ileri" : "↵ next"
    function obStep(i, n) { return (i + 1) + " / " + n; }
    readonly property string obHint: tr ? "Sağ tık: ayarlar · Sol tık: panel" : "Right-click: settings · Left-click: panel"

    // ---- Reports ------------------------------------------------------------------------------------------------------------------------------
    readonly property string createReport: tr ? "Rapor oluştur…" : "Create report…"
    readonly property string exportTitle: tr ? "Raporu dışa aktar" : "Export report"
    readonly property string secWhat: tr ? "NEYİ" : "WHAT"
    readonly property string scopeDay: tr ? "Bugün" : "Today"
    readonly property string scopeWeek: tr ? "Bu hafta" : "This week"
    readonly property string scopeAll: tr ? "Tüm veriler" : "All data"
    function scopeSub(scope, n) {
        if (scope === "day") return tr ? "1 gün" : "1 day";
        if (scope === "week") return tr ? "son 7 gün" : "last 7 days";
        return tr ? n + " gün" : n + (n === 1 ? " day" : " days");
    }
    readonly property string secKind: tr ? "RAPOR TÜRÜ" : "REPORT STYLE"
    readonly property string kindA: tr ? "Sayfa" : "Page"
    readonly property string kindB: tr ? "Kart" : "Card"
    readonly property string kindC: tr ? "Pano" : "Board"
    readonly property var kindNote: tr
        ? ["Cetvel sayfası · A4, yazdırmaya uygun", "Paylaşım kartı · 1080 × 1350", "Geniş pano · 1600 × 900"]
        : ["Ruler page · A4, made for print", "Share card · 1080 × 1350", "Wide board · 1600 × 900"]
    readonly property string secFormat: tr ? "BİÇİM" : "FORMAT"
    readonly property var formatNote: tr
        ? ["Görsel, şeffaf olmayan arka plan", "Tek sayfa, seçilen türün boyutunda", "Etkileşimli sayfa: karelerin üzerine gel, bir güne tıkla", "Raporun ham verisi"]
        : ["Image, opaque background", "One page, at the style's size", "Interactive page: hover the tiles, click a day", "The report's raw data"]
    readonly property string look: tr ? "Görünüm" : "Look"
    readonly property string lookTheme: tr ? "Temam" : "My theme"
    readonly property string lookPaper: tr ? "Açık kâğıt" : "Light paper"
    readonly property string openWhenSaved: tr ? "Kaydedince aç" : "Open when saved"
    readonly property string doExport: tr ? "Dışa aktar" : "Export"
    readonly property string working: tr ? "Rapor hazırlanıyor" : "Preparing the report"
    readonly property string saved: tr ? "Rapor kaydedildi" : "Report saved"
    readonly property string openFile: tr ? "Aç" : "Open"
    readonly property string showFolder: tr ? "Klasörde göster" : "Show in folder"
    readonly property string copyImage: tr ? "Kopyala" : "Copy"
    readonly property string copied: tr ? "Kopyalandı" : "Copied"
    readonly property string exportFailed: tr ? "Rapor oluşturulamadı" : "The report could not be made"

    function reportTitle(scope) {
        if (scope === "day") return tr ? "GÜN RAPORU" : "DAY REPORT";
        if (scope === "week") return tr ? "HAFTA RAPORU" : "WEEK REPORT";
        return tr ? "TÜM VERİLER" : "ALL DATA";
    }
    function heroLabel(scope) {
        if (scope === "day") return focusedTime;
        if (scope === "week") return dailyAvg;
        return tr ? "TOPLAM SÜRE" : "TOTAL TIME";
    }
    function chartTitle(kind) {
        if (kind === "hour") return hourByHour;
        if (kind === "day") return dayByDay;
        return tr ? "HAFTA HAFTA" : "WEEK BY WEEK";
    }
    function period(from, to) {
        if (from === to) return longDate(from);
        return shortDate(from) + " – " + shortDate(to) + " " + to.slice(0, 4);
    }
    function generated(date) {
        var hm = String(date.getHours()).padStart(2, "0") + ":" + String(date.getMinutes()).padStart(2, "0");
        var key = date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0") + "-" + String(date.getDate()).padStart(2, "0");
        return tr ? shortDate(key) + " " + date.getFullYear() + " · " + hm + " tarihinde oluşturuldu" : "Generated " + shortDate(key) + ", " + date.getFullYear() + " · " + hm;
    }
    readonly property string privacy: tr ? "Veriler bu cihazdan çıkmadı" : "Your data never left this device"
    function hoursPartial(pct) { return tr ? "saatlik dağılım kayıtların %" + pct + "'ini kapsıyor" : "the hourly split covers " + pct + "% of the records"; }
    function dashedWeekGoal(h) { return tr ? "kesikli çizgi = haftalık hedef " + fmtGoal(h * 7) : "dashed line = weekly goal " + fmtGoal(h * 7); }
    readonly property string statPeak: tr ? "en yoğun saat" : "busiest hour"
    readonly property string statApps: tr ? "uygulama" : "apps"
    readonly property string statGoalPct: tr ? "hedefin" : "of goal"
    readonly property string statRecorded: tr ? "kayıtlı gün" : "days recorded"
    readonly property string topApps: tr ? "EN ÇOK KULLANILAN" : "MOST USED"
    function ofAvgGoal(pct) { return tr ? "ortalama hedefin %" + pct + "'si" : "average is " + pct + "% of goal"; }
    readonly property string hourlyTotal: tr ? "SAAT SAAT · TOPLAM" : "HOUR BY HOUR · TOTAL"
    function peakAt(h) { return tr ? "en yoğun saat " + h : "busiest hour " + h; }

    // ---- The interactive page's text ----------------------------------------------------------------------------------------------------------
    // Phrases with {tokens} are filled in by the page itself.
    function htmlI18n(data) {
        var l = tr ? "tr" : "en";
        var scope = data.scope;
        var note = data.seriesGoal <= 0 ? "" : data.seriesKind === "week" ? dashedWeekGoal(data.goalMs / 3600000) : dashedGoal(data.goalMs / 3600000);
        return {
            tr: tr,
            units: { h: uh, m: um },
            dayShort: Model.DAYS_SHORT[l],
            dayLong: Model.DAYS_LONG[l],
            months: Model.MONTHS[l],
            t: {
                title: reportTitle(scope),
                period: period(data.from, data.to),
                heroLabel: heroLabel(scope),
                deltaDay: fromYesterday,
                deltaWeek: fromLastWeek,
                goalCap: data.goalMs > 0 ? dailyGoal(data.goalMs / 3600000) : "",
                goalOver: goalOver("{t}"),
                goalLeft: goalLeft("{p}", "{t}"),
                ofAvgGoal: ofAvgGoal("{p}"),
                goalOff: goalOff,
                chartTitle: chartTitle(data.seriesKind),
                chartNote: note,
                peakHour: t("en aktif saat {h} · {t}", "busiest hour {h} · {t}"),
                peakBadge: t("en aktif saat", "busiest hour"),
                longestBadge: t("en uzun gün", "longest day"),
                busiestWeek: t("en yoğun hafta", "busiest week"),
                heatTitle: t("GÜN KAROLARI", "DAY TILES"),
                heatNote: t("bir güne tıkla", "click a day"),
                less: less,
                more: more,
                reset: t("tüm döneme dön", "back to the whole period"),
                hoursTitle: hourByHour,
                hoursPartial: hoursPartial("{p}"),
                appsTitle: topApps,
                none: t("kayıt yok", "no activity"),
                shareDay: t("günün %{p}'si", "{p}% of the day"),
                sharePeriod: t("dönemin %{p}'i", "{p}% of the period"),
                ofGoal: t("hedefin %{p}'i", "{p}% of goal"),
                top: t("en çok: {a} {t}", "top app: {a} {t}"),
                avgDay: t("günlük ort. {t}", "{t} per day"),
                weekOf: t("{d} haftası", "Week of {d}"),
                usedDays: t("{n} gün kullanıldı", "used on {n} days"),
                statPeak: statPeak,
                statRun: t("en uzun kesintisiz oturum", "longest uninterrupted run"),
                statGoal: goalReached,
                statGoalPct: statGoalPct,
                statApps: statApps,
                longestDay: longestDay,
                total: total,
                statRecorded: statRecorded,
                days: t("gün", "days"),
                hintPeak: t("bu saatte toplam {t} odaklandın", "{t} focused at this hour in total"),
                hintRun: t("boşta kalmadan geçen en uzun aralıksız süre", "the longest stretch without going idle"),
                hintGoalDay: t("günün toplamının hedefe oranı", "the day's total against the goal"),
                hintApps: t("en az bir dakika kullanılan uygulamalar", "apps used for at least a minute"),
                hintLongest: "{d}: {t}",
                hintGoalDays: t("hedefe ulaşılan gün sayısı", "days that reached the goal"),
                hintTotal: t("dönemin toplamı", "total for the period"),
                hintRecorded: t("kaydı olan gün sayısı", "days with any activity"),
                lookLabel: t("Temam / açık kâğıt", "My theme / light paper"),
                privacy: privacy
            }
        };
    }
}
