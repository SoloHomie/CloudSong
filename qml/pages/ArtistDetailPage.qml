import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  ArtistDetailPage — 歌手详情 (歌曲/专辑 两 tab)
//   搜索进入 (params 含 id/platform) = 真实数据: getArtistWorks 分
//   "music"/"album" 两请求并行拉取, 各自独立加载/失败态;
//   无 id = Mock 兜底 (M0 假源入口)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property string name: params.name !== undefined ? params.name : "歌手"
    property string desc: params.desc !== undefined ? params.desc : ""
    property int seed: params.seed !== undefined ? params.seed : 0
    property string platform: params.platform !== undefined ? params.platform : ""
    property bool followed: false
    property int activeTab: 0

    // ── 真实数据拉取 (有插件 id 即远程) ──
    // 挂在 onParamsChanged: 页面创建时 params 还是 {}, View 就绪后才注 params
    property string artistId: params.id !== undefined ? params.id : ""
    property bool remote: root.artistId !== "" && root.platform !== ""
    property int pendingSongId: -1
    property int pendingAlbumId: -1
    property bool loadingSongs: false
    property bool loadingAlbums: false
    property string songError: ""
    property string albumError: ""
    property var fetchedSongs: []
    property var fetchedAlbums: []
    property var songs: root.remote ? root.fetchedSongs : MockData.songsForSheet(root.seed, 10)
    property var albums: root.remote ? root.fetchedAlbums : MockData.albums.filter(function(a) { return a.artist === root.name })

    onParamsChanged: fetchRemote()
    function fetchRemote() {
        if (!root.remote) return
        if (root.pendingSongId === -1) {
            root.loadingSongs = true
            root.pendingSongId = Plugins.getArtistWorks(root.params, 1, "music", root.platform)
        }
        if (root.pendingAlbumId === -1) {
            root.loadingAlbums = true
            root.pendingAlbumId = Plugins.getArtistWorks(root.params, 1, "album", root.platform)
        }
    }
    Connections {
        target: Plugins
        function onArtistWorksFinished(id, isEnd, data) {
            if (id === root.pendingSongId) {
                root.pendingSongId = -1
                root.loadingSongs = false
                root.fetchedSongs = MockData.normSongs(data, root.platform)
            } else if (id === root.pendingAlbumId) {
                root.pendingAlbumId = -1
                root.loadingAlbums = false
                root.fetchedAlbums = data
            }
        }
        function onArtistWorksFailed(id, code, message) {
            if (id === root.pendingSongId) {
                root.pendingSongId = -1
                root.loadingSongs = false
                root.songError = code + ": " + message
            } else if (id === root.pendingAlbumId) {
                root.pendingAlbumId = -1
                root.loadingAlbums = false
                root.albumError = code + ": " + message
            }
        }
    }

    // ── 头部 ──
    Row {
        id: headRow
        anchors { top: parent.top; topMargin: 20; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        height: 160
        spacing: 20

        CoverArt {
            width: 160
            height: 160
            radius: 80
            seed: root.seed
        }

        Column {
            width: parent.width - 180
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.name
                font { family: Theme.fontFamily; pixelSize: 22; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: root.desc !== ""
                text: root.desc + (root.platform !== "" ? " · " + root.platform : "")
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_secondary
            }

            Row {
                spacing: 10
                SuretyBtn {
                    height: 32
                    variant: "primary"
                    font.pixelSize: 12
                    iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                    text: "播放热门"
                    onClicked: MockPlayback.loadQueue(root.songs)
                }
                SuretyBtn {
                    height: 32
                    variant: root.followed ? "default" : "outline"
                    font.pixelSize: 12
                    iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
                    text: root.followed ? "已关注" : "关注"
                    onClicked: root.followed = !root.followed
                }
            }
        }
    }

    // ── tab ──
    TabBar {
        id: tabs
        anchors { top: headRow.bottom; topMargin: 4; left: parent.left; leftMargin: 24 }
        items: [{ text: "歌曲" }, { text: "专辑" }]
        onActivated: function(i) { root.activeTab = i }
    }

    // 歌曲
    Column {
        anchors { top: tabs.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.activeTab === 0
        SongToolbar {
            width: parent.width
            onPlayAllRequested: MockPlayback.loadQueue(root.songs)
        }
        SongTable {
            width: parent.width
            height: parent.height - 40
            model: root.songs
            emptyTitle: root.loadingSongs ? "正在加载…" : (root.songError !== "" ? "加载失败" : "暂无热门歌曲")
            emptyMessage: root.songError
            onPlayRequested: function(s, i) {
                MockPlayback.loadQueue(root.songs)
                MockPlayback.playIndex(i)
            }
        }
    }

    // 专辑
    MediaGrid {
        anchors { top: tabs.bottom; topMargin: 12; left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
        visible: root.activeTab === 1
        cellWidth: 160
        model: root.albums.map(function(a) {
            // 远程专辑条目无 seed/platform: 统一补齐 (进详情页依赖这两项判 remote)
            return Object.assign({}, a, {
                subtitle: a.date !== undefined ? a.date : "",
                seed: a.seed !== undefined ? a.seed : MockData.seedOf(a.id),
                platform: (a.platform !== undefined && a.platform !== "") ? a.platform : root.platform
            })
        })
        emptyTitle: root.loadingAlbums ? "正在加载…" : (root.albumError !== "" ? "加载失败" : "暂无专辑")
        emptyMessage: root.albumError
        onOpenRequested: function(it) {
            root.navigate("album", { id: it.id, title: it.title, artist: it.artist,
                                     date: it.date, count: it.count, seed: it.seed, platform: it.platform })
        }
    }
}
