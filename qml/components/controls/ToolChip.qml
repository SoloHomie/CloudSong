import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  ToolChip — 听歌模式工具小圆片按钮 (A-/A+/翻译/桌面歌词)
//  2026-10-02 自 ListenModePage 内联组件提取
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: root
    height: 28
    width: chipText.implicitWidth + 24
    radius: 14
    property string text: ""
    property bool active: false
    signal clicked()
    color: active ? Theme.accent : (chipMouse.containsMouse ? Theme.hover_bg : Theme.bg_input)
    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.text
        font { family: Theme.fontFamily; pixelSize: 12 }
        color: root.active ? "#ffffff" : Theme.text_primary
    }
    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
