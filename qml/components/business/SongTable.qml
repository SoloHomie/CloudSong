import QtQuick
import "../../theme"
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
        // 2026-10-02 实锤: Qt 6.11 命名内联组件裸名当 delegate 静默产出空列表
        // (count=0 零报错), 必须包匿名 Component (GridCell/QueueRow 同款修复);
        // 行组件已提取至同目录 SongRow.qml, 列宽与动作由宿主注入
        delegate: Component {
            SongRow {
                colIdx: root.colIdx
                colTitle: root.colTitle
                colArtist: root.colArtist
                colAlbum: root.colAlbum
                colDur: root.colDur
                timeColumn: root.timeColumn
                onPlayRequested: function(s, i) { root.playRequested(s, i) }
                onLikeToggled: function(s) { root.likeToggled(s); root.refreshModel() }
                onDownloadRequested: function(s) { root.downloadRequested(s) }
            }
        }
    }
}
