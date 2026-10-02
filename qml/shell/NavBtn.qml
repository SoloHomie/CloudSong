import QtQuick
import "../theme"
import "../components/display"

// ═══════════════════════════════════════════════════════════════
//  NavBtn — 圆形图标按钮 (标题栏后退/前进, 28×28)
//  2026-10-02 自 TitleBar 内联组件提取
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    width: 28
    height: 28
    property string icon: ""
    property bool enabled: true
    signal clicked()

    Rectangle {
        visible: navMouse.containsMouse && root.enabled
        anchors.fill: parent
        radius: 14
        color: Theme.hover_bg
    }
    IconImage {
        anchors.centerIn: parent
        source: root.icon
        size: 16
        color: root.enabled ? Theme.text_primary : Theme.text_disabled
    }
    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
