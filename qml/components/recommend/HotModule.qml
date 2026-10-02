import QtQuick
import "../business"

// ═══════════════════════════════════════════════════════════════
//  HotModule — 推荐页模块组件: 今日热歌 (工具栏 + 歌曲表)
//  2026-10-02 自 RecommendPage 内联 hotBody 提取;
//  根为 Column (与原内联版同型, Loader 定高行为不变)
// ═══════════════════════════════════════════════════════════════
Column {
    id: root
    property var songs: []
    signal playAllRequested()
    signal playRequested(int index)

    SongToolbar {
        width: parent.width
        onPlayAllRequested: root.playAllRequested()
    }
    SongTable {
        width: parent.width
        height: 32 + root.songs.length * 40
        model: root.songs
        onPlayRequested: function(s, i) { root.playRequested(i) }
    }
}
