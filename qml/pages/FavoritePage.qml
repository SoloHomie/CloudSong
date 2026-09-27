import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"

// ═══════════════════════════════════════════════════════════════
//  FavoritePage — 我喜欢的音乐
//   取消喜欢后歌曲即时移出本页 (onLikeToggled 重算过滤)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var favSongs: MockData.songs.filter(function(s) { return s.liked })

    PageHeader {
        id: header
        title: "我喜欢的音乐"
        subtitle: "共 " + root.favSongs.length + " 首 · 双击播放"
    }

    SongToolbar {
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        disabled: root.favSongs.length === 0
        onPlayAllRequested: MockPlayback.loadQueue(root.favSongs)
    }

    SongTable {
        anchors { top: header.bottom; topMargin: 40; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.favSongs
        emptyTitle: "还没有喜欢的歌曲"
        emptyMessage: "播放列表里点一下心形图标, 喜欢的歌就会出现在这里"
        emptyActionText: "去推荐页逛逛"
        onEmptyActionRequested: root.navigate("recommend")   // 根页名
        onPlayRequested: function(s, i) {
            MockPlayback.loadQueue(root.favSongs)
            MockPlayback.playIndex(i)
        }
        onLikeToggled: function(s) {
            root.favSongs = MockData.songs.filter(function(x) { return x.liked })
        }
    }
}
