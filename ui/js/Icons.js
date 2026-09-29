.pragma library

// 24 x 24 viewBox, one path string per icon (stroked unless FILLED).
var PATHS = {
    pulse: "M2 12h4l2.5-7 4 14 3-9 1.5 2H22",
    sliders: "M3 6h9M16 6h5M3 12h3M10 12h11M3 18h11M18 18h3M12 6a2 2 0 1 0 4 0a2 2 0 1 0 -4 0M6 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0M14 18a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
    close: "M6 6l12 12M18 6L6 18",
    left: "M14 6l-6 6 6 6",
    right: "M10 6l6 6-6 6",
    up: "M12 19V5M6 11l6-6 6 6",
    down: "M12 5v14M6 13l6 6 6-6",
    search: "M4.5 11a6.5 6.5 0 1 0 13 0a6.5 6.5 0 1 0 -13 0M16 16l4.5 4.5",
    check: "M5 12.5l4.5 4.5L19 7.5",
    download: "M12 4v11M7 10l5 5 5-5M5 20h14",
    share: "M12 15V4M7 9l5-5 5 5M5 14v5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-5",
    play: "M8 5l11 7-11 7z",
    pause: "M7 5h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1zM15 5h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"
};

var FILLED = { play: true, pause: true };
