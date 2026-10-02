import QtQuick
import QtQuick.Effects
import "../theme"

// ═══════════════════════════════════════════════════════════════
//  WinBtn — 窗口控制按钮 (最小化/最大化/关闭, 标题栏右端)
//  2026-10-02 自 TitleBar 内联组件提取
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: root
    width: 44; height: parent.height
    color: mouseArea.containsMouse ? hoverBg : "transparent"
    radius: 0
    property string icon: ""
    property color hoverBg: Qt.rgba(1, 1, 1, 0.1)
    signal clicked()
    Image {
        id: btnIcon
        anchors.centerIn: parent
        source: root.icon
        sourceSize: Qt.size(128, 128)
        fillMode: Image.PreserveAspectFit
        smooth: true; antialiasing: true
        width: 14; height: 14
        opacity: mouseArea.containsMouse ? 1.0 : 0.6
        Behavior on opacity { NumberAnimation { duration: 150 } }
        layer.enabled: !Theme.isDark
        layer.effect: MultiEffect {
            colorizationColor: Theme.text_primary
            colorization: 1.0
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
