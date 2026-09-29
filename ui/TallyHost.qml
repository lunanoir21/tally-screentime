import QtQuick
import Quickshell
import Quickshell.Io

// Integration point: one `TallyHost {}` in the shell root, one `TallyPill {}`
// in the bar. Each surface is created on open and unloaded after its own
// closing animation, so nothing sits mapped (and invisible) while closed.
Scope {
    id: host

    // Start tracking as soon as the shell loads, not on first open.
    readonly property bool trackerReady: TallyTracker.ready

    function targetScreen() {
        var screens = Quickshell.screens;
        for (var i = 0; i < screens.length; i++)
            if (screens[i].name === TallyStore.anchorScreen)
                return screens[i];
        return screens.length ? screens[0] : null;
    }

    Loader {
        id: panelLoader
        active: false
        sourceComponent: TallyPanel {
            screen: host.targetScreen()
            onDismissed: panelLoader.active = false
        }
    }

    Loader {
        id: pickerLoader
        active: false
        sourceComponent: TallyThemePicker {
            screen: host.targetScreen()
            onDismissed: pickerLoader.active = false
        }
    }

    Loader {
        active: TallyStore.onboardingOpen
        sourceComponent: TallyOnboarding { screen: host.targetScreen() }
    }

    // The hidden window that draws a report; it exists only during an export.
    Loader {
        active: TallyExport.job !== null
        sourceComponent: TallyReportJob { screen: host.targetScreen(); job: TallyExport.job }
    }

    Loader {
        active: TallyStore.dimApp !== ""
        sourceComponent: Variants {
            model: Quickshell.screens
            TallyDim { required property var modelData; screen: modelData }
        }
    }

    Connections {
        target: TallyStore
        function onPanelOpenChanged() {
            if (TallyStore.panelOpen) {
                // Reopening mid-close: drop the closing instance first.
                panelLoader.active = false;
                panelLoader.active = true;
            } else {
                TallyStore.closePicker();
                if (panelLoader.item)
                    panelLoader.item.requestClose();
            }
        }
        function onPickerOpenChanged() {
            if (TallyStore.pickerOpen) {
                pickerLoader.active = false;
                pickerLoader.active = true;
            } else if (pickerLoader.item) {
                pickerLoader.item.requestClose();
            }
        }
    }

    IpcHandler {
        target: "lunanoir.tally-screentime"
        function open(): void { TallyStore.openPanel("day"); }
        function close(): void {
            TallyStore.closePicker();
            TallyStore.closePanel();
        }
        function toggle(): void { TallyStore.togglePanel(); }
        function settings(): void { TallyStore.openPanel("settings"); }
        // day | week | map | apps | settings | focus
        function page(name: string): void { TallyStore.openPanel(name); }
        // switch page of an already open card
        function goto(name: string): void { TallyStore.goto(name); }
        function app(id: string): void {
            TallyStore.openPanel("day");
            TallyStore.openApp(id);
        }
        // step 0..3 of the first-run tour
        function onboarding(step: int): void {
            TallyStore.tourStart = step;
            TallyStore.onboardingOpen = false;
            TallyStore.onboardingOpen = true;
        }
        // auto | tr | en
        function language(code: string): void { TallyStore.set("language", code); }
        // scope: day|week|all  kind: page|card|board  format: png|pdf|json  look: theme|paper
        function report(scope: string, kind: string, format: string, look: string): void {
            TallyExport.scope = scope;
            TallyExport.kind = kind;
            TallyExport.format = format;
            TallyExport.look = look;
            TallyExport.run();
        }
        // write ~/tally-history.json
        function backup(): void { TallyTracker.exportAll(); }
        // merge the days of a backup (or a JSON report) into the history
        function restore(path: string): string {
            var r = TallyTracker.importFrom(path);
            return r.error ? "error: " + r.error : r.added + " added, " + r.replaced + " replaced, " + r.kept + " kept, " + r.skipped + " skipped";
        }
        function themes(): void { TallyStore.openPicker(); }
        function focus(): void {
            if (!TallyStore.focusActive)
                TallyStore.startFocus();
            TallyStore.openPanel("focus");
        }
    }
}
