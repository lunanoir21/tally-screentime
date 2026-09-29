import QtQuick
import QtTest
import "../ui/js/Html.js" as Html

TestCase {
    name: "Html"

    function parts() {
        return {
            template: '<html lang="/*@LANG@*/" data-look="/*@LOOK@*/"><title>/*@TITLE@*/</title><style>/*@FONTS@*//*@CSS@*/</style><script id="payload" type="application/json">/*@PAYLOAD@*/</script><script>/*@JS@*/</script></html>',
            css: "body{margin:0}", fonts: "@font-face{}", js: "var x = 1;"
        };
    }
    function payload(extra) {
        return Object.assign({ look: "theme", i18n: { tr: true, t: { title: "GÜN RAPORU" } }, report: { total: 5 } }, extra || {});
    }

    function test_every_marker_is_filled() {
        var out = Html.assemble(parts(), payload());
        verify(out.indexOf("/*@") < 0, "a marker was left in: " + out);
        verify(out.indexOf('lang="tr"') > 0);
        verify(out.indexOf('data-look="theme"') > 0);
        verify(out.indexOf("var x = 1;") > 0);
    }

    function test_english_page() {
        var out = Html.assemble(parts(), payload({ i18n: { tr: false, t: { title: "DAY REPORT" } } }));
        verify(out.indexOf('lang="en"') > 0);
    }

    function test_payload_round_trips() {
        var out = Html.assemble(parts(), payload({ names: { "org.x": "Zed <b>" } }));
        var a = out.indexOf('type="application/json">') + 'type="application/json">'.length;
        var b = out.indexOf("</script>", a);
        var back = JSON.parse(out.substring(a, b));
        compare(back.report.total, 5);
        compare(back.names["org.x"], "Zed <b>");
    }

    function test_data_cannot_close_the_script() {
        var evil = "</script><script>alert(1)</script>";
        var out = Html.assemble(parts(), payload({ names: { a: evil } }));
        // the only closing script tags are the template's own two
        compare(out.split("</script>").length - 1, 2);
        verify(out.indexOf("<script>alert") < 0);
    }

    function test_title_is_escaped() {
        var out = Html.assemble(parts(), payload({ i18n: { tr: true, t: { title: "<img src=x>" } } }));
        verify(out.indexOf("<title>&lt;img src=x&gt;</title>") > 0);
    }

    function test_dollar_signs_survive() {
        var p = parts();
        p.css = "a::after{content:'$& $1 $$'}";
        verify(Html.assemble(p, payload()).indexOf("content:'$& $1 $$'") > 0);
    }
}
