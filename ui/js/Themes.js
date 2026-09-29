.pragma library

// sw: the five swatches shown in the picker (first one is the surface);
// card / fg / acc: the three colours the widget is drawn from.
// Everything else (muted, faint, hairlines, fills) is mixed from these.
var LIST = [
    { id: "system", name: "Sistemi izle", tag: "auto", sw: ["#0f0f10", "#ececec", "#a8a8ad", "#5d5d63", "#e0a458"], card: "#0f0f10", fg: "#ececec", acc: "#e0a458" },
    { id: "catppuccin", name: "Catppuccin", tag: "bundled", sw: ["#1e1e2e", "#89b4fa", "#f38ba8", "#a6e3a1", "#f9e2af"], card: "#1e1e2e", fg: "#cdd6f4", acc: "#89b4fa" },
    { id: "latte", name: "Catppuccin Latte", tag: "bundled", sw: ["#eff1f5", "#1e66f5", "#d20f39", "#40a02b", "#fe640b"], card: "#eff1f5", fg: "#4c4f69", acc: "#1e66f5" },
    { id: "ethereal", name: "Ethereal", tag: "bundled", sw: ["#0d0f1c", "#7d8fe0", "#e58fb0", "#98b98c", "#e4b872"], card: "#0d0f1c", fg: "#d8dcf0", acc: "#8fa0ff" },
    { id: "everforest", name: "Everforest", tag: "bundled", sw: ["#2d353b", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3"], card: "#2d353b", fg: "#d3c6aa", acc: "#a7c080" },
    { id: "flexoki", name: "Flexoki Light", tag: "bundled", sw: ["#fffcf0", "#205ea6", "#af3029", "#66800b", "#ad8301"], card: "#fffcf0", fg: "#403e3c", acc: "#205ea6" },
    { id: "gruvbox", name: "Gruvbox", tag: "bundled", sw: ["#282828", "#fb4934", "#b8bb26", "#fabd2f", "#83a598"], card: "#282828", fg: "#ebdbb2", acc: "#fabd2f" },
    { id: "hackerman", name: "Hackerman", tag: "bundled", sw: ["#0b0c16", "#82fb9c", "#4fe88f", "#50f7d4", "#829dd4"], card: "#0b0c16", fg: "#ddf7ff", acc: "#82fb9c" },
    { id: "kanagawa", name: "Kanagawa", tag: "bundled", sw: ["#1f1f28", "#c34043", "#76946a", "#7e9cd8", "#e6c384"], card: "#1f1f28", fg: "#dcd7ba", acc: "#7e9cd8" },
    { id: "lasthorizon", name: "Last Horizon", tag: "bundled", sw: ["#14100f", "#d99a82", "#9fb3ba", "#c9a86a", "#7c6f6a"], card: "#14100f", fg: "#e3d5cf", acc: "#d99a82" },
    { id: "lumon", name: "Lumon", tag: "bundled", sw: ["#0f1c26", "#4a83b0", "#5b9bc4", "#79bfe6", "#a8e0f5"], card: "#0f1c26", fg: "#cfe6f4", acc: "#79bfe6" },
    { id: "noir", name: "Noir", tag: "bundled", sw: ["#0f0f10", "#ececec", "#a8a8ad", "#5d5d63", "#e0a458"], card: "#0f0f10", fg: "#ececec", acc: "#e0a458" },
    { id: "nord", name: "Nord", tag: "bundled", sw: ["#2e3440", "#88c0d0", "#bf616a", "#a3be8c", "#ebcb8b"], card: "#2e3440", fg: "#eceff4", acc: "#88c0d0" },
    { id: "tokyonight", name: "Tokyo Night", tag: "bundled", sw: ["#1a1b26", "#7aa2f7", "#f7768e", "#9ece6a", "#e0af68"], card: "#1a1b26", fg: "#c0caf5", acc: "#7aa2f7" },
    { id: "ultrawhite", name: "Ultra Beyaz", tag: "bundled", sw: ["#ffffff", "#000000", "#4d4d4d", "#9a9a9a", "#dcdcdc"], card: "#ffffff", fg: "#262626", acc: "#000000" },
    { id: "vantablack", name: "Vantablack", tag: "bundled", sw: ["#000000", "#ffffff", "#bdbdbd", "#6b6b6b", "#2a2a2a"], card: "#000000", fg: "#d9d9d9", acc: "#ffffff" }
];

var DEFAULT_ID = "noir";

function indexOf(id) {
    for (var i = 0; i < LIST.length; i++)
        if (LIST[i].id === id)
            return i;
    return -1;
}

function byId(id) {
    var i = indexOf(id);
    return LIST[i >= 0 ? i : indexOf(DEFAULT_ID)];
}
