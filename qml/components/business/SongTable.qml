import QtQuick
import "../../theme"
import "../../mock"
import "../display"

// ═══════════════════════════════════════════════════════════════
//  SongTable — 歌曲列表 (虚拟化 + 行内 hover 操作 + 双击播放)
//  model: JS 数组 [{title,artist,album,duration,liked,platform,seed}]
//  行内喜欢原地改对象并自动刷新; 右键菜单/多选待接 C++ 服务
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var model: []
    property string emptyTitle: "暂无歌曲"
    property string emptyMessage: ""
    property string emptyActionText: ""
    property bool timeColumn: false   // true=专辑列显示播放时间(playTime, 历史播放页用)
    signal playRequested(var song, int index)
    signal likeToggled(var song)
    signal downloadRequested(var song)
    signal emptyActionRequested()
    function refreshModel() { root.model = root.model.slice() }   // JS 对象变更后强制刷新绑定

    // 列宽
    readonly property real colIdx: 44
    readonly property real colArtist: 150
    readonly property real colAlbum: 200
    readonly property real colDur: 60
    readonly property real colAct: 84
    readonly property real colTitle: root.width - colIdx - colArtist - colAlbum - colDur - colAct

    // ── 表头 ──
    Row {
        id: headerRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 34
        Text {
            width: root.colIdx
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "#"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        Text {
            width: root.colTitle
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: "标题"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        Text {
            width: root.colArtist
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: "歌手"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        Text {
            width: root.colAlbum
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: root.timeColumn ? "时间" : "专辑"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        Text {
            width: root.colDur
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: "时长"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_hint
        }
        Item { width: root.colAct; height: parent.height }
    }

    // ── 空态 ──
    StatusPlaceholder {
        anchors { top: headerRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.model.length === 0
        status: "empty"
        title: root.emptyTitle
        message: root.emptyMessage
        actionText: root.emptyActionText
        onActionRequested: root.emptyActionRequested()
    }

    // ── 列表 ──
    ListView {
        id: songList
        anchors { top: headerRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.model
        clip: true
        visible: root.model.length > 0
        boundsBehavior: Flickable.StopAtBounds
        delegate: SongRow
    }

    component SongRow: Item {
        width: songList.width
        height: 44
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
                width: Math.min(implicitWidth, parent.width - 46)
                elide: Text.ElideRight
                text: s.title
                font { family: Theme.fontFamily; pixelSize: 14 }
                color: Theme.text_primary
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
                    onClicked: { s.liked = !s.liked; root.likeToggled(s); root.refreshModel() }
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
}
