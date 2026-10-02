import QtQuick
import "../../theme"
import "../../mock"
import "../display"

// ═══════════════════════════════════════════════════════════════
//  SongRow — 歌曲列表行 (序号/标题+徽标/歌手/专辑/时长/行内操作)
//  2026-10-02 自 SongTable 内联组件提取; 列宽与动作由宿主注入
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    width: parent.width
    height: 44
    // Qt 6.8+ delegate 的 modelData/index 须显式 required 注入
    required property int index
    required property var modelData
    // 宿主注入: 列宽与行为
    required property real colIdx
    required property real colTitle
    required property real colArtist
    required property real colAlbum
    required property real colDur
    required property bool timeColumn
    signal playRequested(var song, int index)
    signal likeToggled(var song)
    signal downloadRequested(var song)

    property var s: modelData
    property bool hover: rowMouse.containsMouse

    Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }

    // 序号 / hover 播放提示
    Item {
        width: root.colIdx
        height: parent.height
        Text {
            visible: !hover
            anchors.centerIn: parent
            text: index + 1
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        IconImage {
            visible: hover
            anchors.centerIn: parent
            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
            color: Theme.text_primary
            size: 12
        }
    }

    // 标题 + 平台徽标
    Row {
        x: root.colIdx
        width: root.colTitle - 8
        height: parent.height
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width - 46 - (s.vip === true ? 44 : 0))
            elide: Text.ElideRight
            text: s.title
            font { family: Theme.fontFamily; pixelSize: 14 }
            color: Theme.text_primary
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: s.vip === true
            height: 16
            width: vipText.implicitWidth + 12
            radius: 8
            color: Theme.warning
            Text {
                id: vipText
                anchors.centerIn: parent
                text: "VIP"
                font { family: Theme.fontFamily; pixelSize: 10 }
                color: Theme.warning_fg
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: s.platform !== undefined && s.platform !== ""
            height: 16
            width: platformText.implicitWidth + 12
            radius: 8
            color: Theme.tag_preset_bg
            Text {
                id: platformText
                anchors.centerIn: parent
                text: s.platform
                font { family: Theme.fontFamily; pixelSize: 10 }
                color: Theme.tag_preset_fg
            }
        }
    }

    // 歌手 / 专辑
    Text {
        x: root.colIdx + root.colTitle
        width: root.colArtist - 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: s.artist !== undefined ? s.artist : ""
        font { family: Theme.fontFamily; pixelSize: 14 }
        color: Theme.text_secondary
    }
    Text {
        x: root.colIdx + root.colTitle + root.colArtist
        width: root.colAlbum - 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.timeColumn ? (s.playTime !== undefined ? s.playTime : "")
                               : (s.album !== undefined ? s.album : "")
        font { family: Theme.fontFamily; pixelSize: 14 }
        color: Theme.text_secondary
    }

    // 时长
    Text {
        x: root.colIdx + root.colTitle + root.colArtist + root.colAlbum
        width: root.colDur - 4
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: MockData.fmtTime(s.duration)
        font { family: Theme.fontFamily; pixelSize: 13 }
        color: Theme.text_hint
    }

    // 行内操作 (hover 出现; 喜欢后常驻)
    Row {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 14
        IconImage {
            id: likeIcon
            visible: hover || s.liked
            source: s.liked ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                            : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
            color: s.liked ? Theme.accent : Theme.text_hint
            size: 16
            MouseArea {
                z: 1   // 行级 rowMouse 声明在后会压住本图标, 抬升 z 才能收到点击
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { s.liked = !s.liked; root.likeToggled(s) }
            }
        }
        IconImage {
            visible: hover
            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/download.svg"
            color: Theme.text_hint
            size: 16
            MouseArea {
                z: 1   // 同喜欢图标: 须抬到行级 rowMouse 之上
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.downloadRequested(s)
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onDoubleClicked: root.playRequested(s, index)
    }
}
