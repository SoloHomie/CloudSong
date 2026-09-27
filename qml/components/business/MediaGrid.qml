import QtQuick
import "../../theme"
import "../display"

// ──────────────────────────────────────────────────────────────
//  MediaGrid — 媒体卡片网格 (歌单/专辑/歌手通用)
//  model: JS 数组 [{title,subtitle,seed,platform}]
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property var model: []
    property real cellWidth: 150
    property string emptyTitle: "暂无内容"
    property string emptyMessage: ""
    property string emptyActionText: ""
    signal openRequested(var item)
    signal emptyActionRequested()

    readonly property real cellH: root.cellWidth + 44

    StatusPlaceholder {
        anchors.fill: parent
        visible: root.model.length === 0
        status: "empty"
        title: root.emptyTitle
        message: root.emptyMessage
        actionText: root.emptyActionText
        onActionRequested: root.emptyActionRequested()
    }

    GridView {
        id: grid
        anchors.fill: parent
        model: root.model
        clip: true
        visible: root.model.length > 0
        cellWidth: root.cellWidth
        cellHeight: cellH
        boundsBehavior: Flickable.StopAtBounds
        delegate: GridCell
    }

    component GridCell: Item {
        width: root.cellWidth - 14
        height: cellH - 12
        property var it: modelData
        property bool hover: cellMouse.containsMouse

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
            font { family: "Microsoft YaHei UI"; pixelSize: 13 }
            color: Theme.text_primary
        }
        Text {
            anchors { top: cover.bottom; topMargin: 26; left: parent.left; right: parent.right }
            elide: Text.ElideRight
            text: it.subtitle !== undefined ? it.subtitle : ""
            font { family: "Microsoft YaHei UI"; pixelSize: 11 }
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
}
