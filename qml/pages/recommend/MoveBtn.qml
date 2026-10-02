import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  MoveBtn — 小号图标按钮 (↑/↓ 等文字符号)
//  2026-10-02 自 RecommendPage 内联组件提取; 编辑态排序控件用
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: root
    property string glyph: ""
    property bool usable: true
    signal clicked
    width: 24; height: 24; radius: 6
    color: mouse.containsMouse && usable ? Theme.hover_bg : "transparent"
    border { width: 1; color: Theme.border_default }
    opacity: usable ? 1 : 0.35
    Text {
        anchors.centerIn: parent
        text: glyph
        font { family: Theme.fontFamily; pixelSize: 11; weight: Font.Bold }
        color: usable ? Theme.text_primary : Theme.text_disabled
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: usable
        hoverEnabled: true
        cursorShape: usable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
