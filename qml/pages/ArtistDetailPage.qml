import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  ArtistDetailPage — 歌手详情 (歌曲/专辑 两 tab)
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
    property var songs: MockData.songsForSheet(root.seed, 10)
    property var albums: MockData.albums.filter(function(a) { return a.artist === root.name })

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
                font { family: "Microsoft YaHei UI"; pixelSize: 22; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: root.desc !== ""
                text: root.desc + (root.platform !== "" ? " · " + root.platform : "")
                font { family: "Microsoft YaHei UI"; pixelSize: 12 }
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
            emptyTitle: "暂无热门歌曲"
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
            return Object.assign({}, a, { subtitle: a.date })
        })
        emptyTitle: "暂无专辑"
        onOpenRequested: function(it) {
            root.navigate("album", { id: it.id, title: it.title, artist: it.artist,
                                     date: it.date, count: it.count, seed: it.seed, platform: it.platform })
        }
    }
}
