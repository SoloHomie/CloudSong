import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  AlbumDetailPage — 专辑详情
//   头部: 封面 + 专辑信息 + 播放全部/收藏; 主体: 歌曲表
//   搜索进入 (params 含 id/platform) = 真实数据: getAlbumInfo 拉取,
//   加载中/失败有占位; 无 id = Mock 兜底 (M0 假源入口)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property string title: params.title !== undefined ? params.title : "专辑"
    property string artist: params.artist !== undefined ? params.artist : ""
    property string date: params.date !== undefined ? params.date : ""
    property int count: params.count !== undefined ? params.count : 8
    property int seed: params.seed !== undefined ? params.seed : 0
    property string platform: params.platform !== undefined ? params.platform : ""
    property bool starred: false

    // ── 真实数据拉取 (有插件 id 即远程) ──
    // 注意: 拉取挂在 onParamsChanged 而非 onCompleted — 页面创建时 params 还是 {},
    // View 在页面就绪后才注 params (PageSwitch 见 onPageLoaded), onCompleted 时 remote 恒 false
    property string albumId: params.id !== undefined ? params.id : ""
    property bool remote: root.albumId !== "" && root.platform !== ""
    property int pendingId: -1
    property bool loading: false
    property string loadError: ""
    property var fetchedSongs: []
    property var songs: root.remote ? root.fetchedSongs : MockData.songsForSheet(root.seed, root.count)

    onParamsChanged: fetchRemote()
    function fetchRemote() {
        if (!root.remote || root.pendingId !== -1) return
        root.loading = true
        root.pendingId = Plugins.getAlbumInfo(root.params, 1, root.platform)
    }
    Connections {
        target: Plugins
        function onAlbumInfoFinished(id, isEnd, albumItem, musicList) {
            if (id !== root.pendingId) return
            root.pendingId = -1
            root.loading = false
            if (albumItem !== undefined && albumItem !== null) {
                // 真实详情覆盖搜索页透传字段 (透传只是兜底)
                if (albumItem.title !== undefined && albumItem.title !== "") root.title = albumItem.title
                if (albumItem.artist !== undefined && albumItem.artist !== "") root.artist = albumItem.artist
                if (albumItem.date !== undefined && albumItem.date !== "") root.date = albumItem.date
            }
            root.fetchedSongs = MockData.normSongs(musicList, root.platform)
        }
        function onAlbumInfoFailed(id, code, message) {
            if (id !== root.pendingId) return
            root.pendingId = -1
            root.loading = false
            root.loadError = code + ": " + message
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
            seed: root.seed
        }

        Column {
            width: parent.width - 180
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Row {
                spacing: 8
                // 与 SheetDetailPage 的类型标签同构: pill 底 + 小字
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: typeText.implicitWidth + 12
                    radius: 9
                    color: Theme.tag_preset_bg
                    Text {
                        id: typeText
                        anchors.centerIn: parent
                        text: "专辑"
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.platform !== ""
                    height: 18
                    width: pfText.implicitWidth + 12
                    radius: 9
                    color: Theme.tag_preset_bg
                    Text {
                        id: pfText
                        anchors.centerIn: parent
                        text: root.platform
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.title
                font { family: Theme.fontFamily; pixelSize: 22; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.artist + (root.date !== "" ? " · " + root.date : "") + " · 共 " + root.songs.length + " 首"
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
                    text: "播放全部"
                    onClicked: MockPlayback.loadQueue(root.songs)
                }
                SuretyBtn {
                    height: 32
                    variant: root.starred ? "default" : "outline"
                    font.pixelSize: 12
                    iconSource: root.starred ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                                             : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
                    text: root.starred ? "已收藏" : "收藏"
                    onClicked: root.starred = !root.starred
                }
                SuretyBtn {
                    height: 32
                    variant: "outline"
                    font.pixelSize: 12
                    text: "查看歌手"
                    onClicked: root.navigate("artist", { id: "", name: root.artist, seed: root.seed, platform: root.platform })
                }
            }
        }
    }

    // ── 歌曲表 ──
    SongToolbar {
        anchors { top: headRow.bottom; topMargin: 8; left: parent.left; right: parent.right }
        onPlayAllRequested: MockPlayback.loadQueue(root.songs)
    }
    SongTable {
        anchors { top: headRow.bottom; topMargin: 48; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.songs
        emptyTitle: root.loading ? "正在加载…" : (root.loadError !== "" ? "加载失败" : "专辑暂无歌曲")
        emptyMessage: root.loadError
        onPlayRequested: function(s, i) {
            MockPlayback.loadQueue(root.songs)
            MockPlayback.playIndex(i)
        }
    }
}
