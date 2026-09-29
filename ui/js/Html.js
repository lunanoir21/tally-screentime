.pragma library

// Puts the interactive report together: one HTML file holding its styles,
// script, fonts and data. Pure text in, text out.

function escapeHtml(s) {
    return String(s).split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;").split('"').join("&quot;");
}

// JSON that is safe inside a <script> block.
function jsonForScript(obj) {
    return JSON.stringify(obj)
        .split("<").join("\\u003c")
        .split("\u2028").join("\\u2028")
        .split("\u2029").join("\\u2029");
}

function fill(text, marker, value) {
    return text.split(marker).join(value);
}

// parts: { template, css, js, fonts }   payload: { look, title, i18n, ... }
function assemble(parts, payload) {
    var html = parts.template;
    html = fill(html, "/*@LANG@*/", payload.i18n.tr ? "tr" : "en");
    html = fill(html, "/*@LOOK@*/", payload.look);
    html = fill(html, "/*@TITLE@*/", escapeHtml(payload.i18n.t.title));
    html = fill(html, "/*@FONTS@*/", parts.fonts);
    html = fill(html, "/*@CSS@*/", parts.css);
    html = fill(html, "/*@PAYLOAD@*/", jsonForScript(payload));
    html = fill(html, "/*@JS@*/", parts.js);
    return html;
}
