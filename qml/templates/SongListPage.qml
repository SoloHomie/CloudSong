import QtQuick
import "../mock"
import "../components/display"
import "../components/business"

// ──────────────────────────────────────────────────────────
//  SongListPage — 歌单列表页骨架: 页头 + 工具栏 + 歌曲表
//  数据由页面注入 songs; 空态文案/时间列/页头附加按钮可配
//  (附加按钮用 headerExtra: Component {...}, 挂页头右区)
// ──────────────────────────────────────────────────────────
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var songs: []
    property string title: ""
    property string subtitle: ""
    property bool timeColumn: false
    property string emptyTitle: "暂无歌曲"
    property string emptyMessage: ""
    property string emptyActionText: ""
    property string emptyActionRoute: "recommend"
    property string searchPlaceholder: ""
    property Component headerExtra: null

    signal likeToggled(var song)

    PageHeader {
        id: header
        title: root.title
        subtitle: root.subtitle
    }

    // 页头右区附加按钮 (与 PageHeader rightRow 同位; 空 Component 时不渲染)
    Loader {
        anchors { right: header.right; rightMargin: 24; verticalCenter: header.verticalCenter }
        sourceComponent: root.headerExtra
    }

    SongToolbar {
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        disabled: root.songs.length === 0
        searchPlaceholder: root.searchPlaceholder
        onPlayAllRequested: MockPlayback.loadQueue(root.songs)
    }

    SongTable {
        anchors { top: header.bottom; topMargin: 40; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.songs
        timeColumn: root.timeColumn
        emptyTitle: root.emptyTitle
        emptyMessage: root.emptyMessage
        emptyActionText: root.emptyActionText
        onEmptyActionRequested: root.navigate(root.emptyActionRoute)
        onPlayRequested: function(s, i) {
            MockPlayback.loadQueue(root.songs)
            MockPlayback.playIndex(i)
        }
        onLikeToggled: function(s) { root.likeToggled(s) }
    }
}
