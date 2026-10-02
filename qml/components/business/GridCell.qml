import QtQuick
import "../../theme"
import "../display"

// ═══════════════════════════════════════════════════════════════
//  GridCell — 媒体卡片网格单元 (封面/标题/副标题 + hover 播放提示)
//  2026-10-02 自 MediaGrid 内联组件提取; cellWidth/cellH 由宿主注入
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    width: cellWidth - 14
    height: cellH - 12
    required property int index
    required property var modelData
    required property real cellWidth
    required property real cellH
    property var it: modelData
    property bool hover: cellMouse.containsMouse
    signal openRequested(var item)

    CoverArt {
        id: cover
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.width
        seed: it.seed !== undefined ? it.seed : 0
    }

    // hover 播放提示
    Rectangle {
        visible: hover
        anchors { right: cover.right; bottom: cover.bottom; margins: 8 }
        width: 30
        height: 30
        radius: 15
        color: Qt.rgba(0, 0, 0, 0.55)
        IconImage {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
            color: "#ffffff"
            size: 14
        }
    }

    Text {
        anchors { top: cover.bottom; topMargin: 8; left: parent.left; right: parent.right }
        elide: Text.ElideRight
        text: it.title
        font { family: Theme.fontFamily; pixelSize: 13 }
        color: Theme.text_primary
    }
    Text {
        anchors { top: cover.bottom; topMargin: 26; left: parent.left; right: parent.right }
        elide: Text.ElideRight
        text: it.subtitle !== undefined ? it.subtitle : ""
        font { family: Theme.fontFamily; pixelSize: 11 }
        color: Theme.text_secondary
    }

    MouseArea {
        id: cellMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openRequested(it)
    }
}
