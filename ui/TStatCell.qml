import QtQuick

Rectangle {
    id: root
    property string label: ""
    property string value: ""
    property real padX: 12

    implicitHeight: 58
    radius: 12
    color: TallyTheme.cell

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: root.padX
        spacing: 5
        TText { px: 10; text: root.label; color: TallyTheme.muted }
        TText { px: 14; text: root.value; font.weight: Font.Medium }
    }
}
