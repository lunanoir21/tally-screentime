import QtQuick
import "js/Model.js" as Model

// Top apps with their icon, share, time and a thin bar.
Column {
    id: c

    property var m
    property var pal
    property real tile: 34
    property real namePx: 14
    property real timePx: 13
    property real rowGap: 12
    property real barH: 4

    spacing: rowGap

    Repeater {
        model: c.m.topApps
        Item {
            id: row
            required property int index
            required property var modelData
            width: c.width
            height: c.tile

            TAppIcon {
                id: ico
                appId: row.modelData.id
                name: row.modelData.id === "" ? "" : TallyTracker.appName(row.modelData.id)
                other: row.modelData.id === ""
                size: c.tile
                letterPx: c.tile * 0.42
                color: c.pal.tile
                ink: c.pal.fg
                sync: true
            }
            Item {
                anchors.left: ico.right
                anchors.leftMargin: c.tile * 0.4
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: c.namePx * 1.3 + 8 + c.barH
                TText {
                    id: nm
                    px: c.namePx
                    font.weight: Font.Medium
                    color: c.pal.fg
                    text: row.modelData.id === "" ? Str.others(row.modelData.other) : TallyTracker.appName(row.modelData.id)
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - tm.width - sh.width - 24)
                }
                TText { id: sh; anchors.left: nm.right; anchors.leftMargin: 8; anchors.baseline: nm.baseline; px: c.namePx * 0.8; color: c.pal.muted; text: "%" + Math.round(row.modelData.share * 100) }
                TText { id: tm; anchors.right: parent.right; anchors.baseline: nm.baseline; px: c.timePx; color: c.pal.fg; text: Str.fmt(row.modelData.ms) }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: c.barH
                    radius: c.barH / 2
                    color: c.pal.track
                    Rectangle { width: Math.max(2, parent.width * row.modelData.rel); height: c.barH; radius: c.barH / 2; color: row.index === 0 ? c.pal.acc : c.pal.bar }
                }
            }
        }
    }
}
