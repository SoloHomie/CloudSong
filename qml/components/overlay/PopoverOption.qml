import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  PopoverOption — Popover 内单行选项 (hover 高亮, active 强调)
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    height: 30
    radius: 6
    color: mouse.containsMouse ? Theme.hover_bg : "transparent"
    property string text: ""
    property bool active: false
    signal selected()

    Text {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        verticalAlignment: Text.AlignVCenter
        text: root.text
        font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: active ? Font.Bold : Font.Normal }
        color: active ? Theme.accent_text : Theme.text_primary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected()
    }
}
