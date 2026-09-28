import QtQuick
import "../../theme"
import "../display"

// ──────────────────────────────────────────────────────────────
//  PopoverOption — Popover 内单行选项 (hover 高亮, active 强调)
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    // 宽必填: Rectangle 默认宽 0, Popover 的 Column 不拉伸子项 → 0×30 隐形条 (2026-09-29 音质菜单"只有气泡没选项"根因)
    width: parent.width
    height: 30
    radius: 6
    color: mouse.containsMouse ? Theme.hover_bg : "transparent"
    property string text: ""
    property bool active: false
    signal selected()

    Text {
        anchors { fill: parent; leftMargin: 10; rightMargin: root.active ? 30 : 10 }
        verticalAlignment: Text.AlignVCenter
        text: root.text
        font { family: Theme.fontFamily; pixelSize: 13; weight: active ? Font.Bold : Font.Normal }
        color: active ? Theme.accent_text : Theme.text_primary
    }
    // 选中项右侧勾选 (不只靠颜色/字重传达状态)
    IconImage {
        visible: root.active
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        size: 14
        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/check.svg"
        color: Theme.accent_text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected()
    }
}
