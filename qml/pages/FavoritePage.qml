import "../mock"
import "../templates"

// ═══════════════════════════════════════════════════════════════
//  FavoritePage — 我喜欢的音乐 (SongListPage 模板)
//   取消喜欢后歌曲即时移出本页 (onLikeToggled 重算过滤)
// ═══════════════════════════════════════════════════════════════
SongListPage {
    title: "我喜欢的音乐"
    subtitle: "共 " + favSongs.length + " 首 · 双击播放"
    songs: favSongs
    emptyTitle: "还没有喜欢的歌曲"
    emptyMessage: "播放列表里点一下心形图标, 喜欢的歌就会出现在这里"
    emptyActionText: "去推荐页逛逛"

    property var favSongs: MockData.songs.filter(function(s) { return s.liked })

    onLikeToggled: function(s) {
        favSongs = MockData.songs.filter(function(x) { return x.liked })
    }
}
