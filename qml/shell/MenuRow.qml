import QtQuick
import "../theme"

// ═══════════════════════════════════════════════════════════════
//  MenuRow — 账户菜单行 (label 左 / hint 右, hover 反馈)
//  2026-10-02 自 AccountChip 内联组件提取; 菜单关闭动作由宿主在
//  onActivated 中处理 (原内联版直接引用外层 Popup)
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: menuItem
    width: parent ? parent.width : 240
    height: 34
    color: itemMouse.containsMouse ? Theme.hover_bg : "transparent"

    property string label: ""
    property string hint:  ""
    signal activated()

    Text {
        anchors.left: parent.left; anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: menuItem.label
        color: Theme.text_primary
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: menuItem.hint
        color: Theme.text_secondary
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }
    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menuItem.activated()
    }
}
