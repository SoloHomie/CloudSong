import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  HistoryPage — 历史播放 (时间列; 一键清空)
//  真实数据待接 C++ HistoryService (含去重)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var historySongs: MockData.songs.slice(0, 8).map(function(s, i) {
        return Object.assign({}, s, { playTime: ["今天 14:32", "今天 11:07", "昨天 23:40", "昨天 19:56",
                                                 "昨天 08:15", "10-25", "10-24", "10-23"][i] })
    })

    PageHeader {
        id: header
        title: "历史播放"
        subtitle: root.historySongs.length > 0 ? "共 " + root.historySongs.length + " 首" : ""
        SuretyBtn {
            height: 28
            text: "清空"
            variant: "ghost"
            font.pixelSize: 12
            visible: root.historySongs.length > 0
            onClicked: root.historySongs = []
        }
    }

    SongToolbar {
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        disabled: root.historySongs.length === 0
        onPlayAllRequested: MockPlayback.loadQueue(root.historySongs)
    }

    SongTable {
        anchors { top: header.bottom; topMargin: 40; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.historySongs
        timeColumn: true
        emptyTitle: "暂无播放记录"
        emptyMessage: "听过的歌会按时间顺序出现在这里"
        emptyActionText: "去听点什么"
        onEmptyActionRequested: root.navigate("recommend")
        onPlayRequested: function(s, i) {
            MockPlayback.loadQueue(root.historySongs)
            MockPlayback.playIndex(i)
        }
    }
}
