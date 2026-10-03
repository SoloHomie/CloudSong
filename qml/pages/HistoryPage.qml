pragma ComponentBehavior: Bound
import QtQuick
import "../mock"
import "../components/buttons"
import "../templates"

// ═══════════════════════════════════════════════════════════════
//  HistoryPage — 历史播放 (SongListPage 模板; 时间列; 一键清空)
//  真实数据待接 C++ HistoryService (含去重)
// ═══════════════════════════════════════════════════════════════
SongListPage {
    id: root
    title: "历史播放"
    subtitle: historySongs.length > 0 ? "共 " + historySongs.length + " 首" : ""
    songs: historySongs
    timeColumn: true
    emptyTitle: "暂无播放记录"
    emptyMessage: "听过的歌会按时间顺序出现在这里"
    emptyActionText: "去听点什么"

    property var historySongs: MockData.songs.slice(0, 8).map(function(s, i) {
        return Object.assign({}, s, { playTime: ["今天 14:32", "今天 11:07", "昨天 23:40", "昨天 19:56",
                                                 "昨天 08:15", "10-25", "10-24", "10-23"][i] })
    })

    headerExtra: Component {
        SuretyBtn {
            height: 28
            text: "清空"
            variant: "ghost"
            font.pixelSize: 12
            visible: root.historySongs.length > 0
            onClicked: root.historySongs = []
        }
    }
}
