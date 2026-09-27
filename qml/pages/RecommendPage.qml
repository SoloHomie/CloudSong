import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"

// ═══════════════════════════════════════════════════════════════
//  RecommendPage — 推荐页 (原版 Toplist + RecommendSheets 合并)
//   Tab1 推荐歌单: 精选歌单网格 + 今日热歌列表
//   Tab2 排行榜: 官方榜网格 + 更多榜单行
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    // 榜单条目补 subtitle (top3 串联展示)
    property var topListItems: MockData.toplists.map(function(t) {
        return Object.assign({}, t, { subtitle: t.top3.join(" / ") })
    })
    property var hotSongs: MockData.songs.slice(0, 10)

    TabBar {
        id: tabs
        anchors { top: parent.top; topMargin: 20; left: parent.left; leftMargin: 24 }
        items: [{ text: "推荐歌单" }, { text: "排行榜" }]
    }

    // ══ Tab 0: 推荐歌单 ══
    Flickable {
        id: sheetFlick
        anchors { top: tabs.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: sheetCol.height + 20
        clip: true
        visible: tabs.activeIndex === 0
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: sheetCol
            width: parent.width
            spacing: 4

            Text {
                x: 24
                text: "精选歌单"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            MediaGrid {
                x: 24
                width: parent.width - 48
                height: 2 * (cellWidth + 44) - 12
                cellWidth: 160
                model: MockData.sheets
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                             count: it.count, desc: it.desc, platform: it.platform })
                }
            }

            Text {
                x: 24
                text: "今日热歌"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            SongToolbar {
                width: parent.width
                onPlayAllRequested: MockPlayback.loadQueue(root.hotSongs)
            }
            SongTable {
                x: 24
                width: parent.width - 48
                height: 32 + root.hotSongs.length * 40
                model: root.hotSongs
                onPlayRequested: function(s, i) {
                    MockPlayback.loadQueue(root.hotSongs)
                    MockPlayback.playIndex(i)
                }
            }
        }
    }

    // ══ Tab 1: 排行榜 ══
    Flickable {
        id: topFlick
        anchors { top: tabs.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: topCol.height + 20
        clip: true
        visible: tabs.activeIndex === 1
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: topCol
            width: parent.width
            spacing: 4

            Text {
                x: 24
                text: "官方榜"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            MediaGrid {
                x: 24
                width: parent.width - 48
                height: 2 * (cellWidth + 44) - 12
                cellWidth: 160
                model: root.topListItems
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "toplist", id: it.id, title: it.title,
                                             seed: it.seed, platform: it.platform })
                }
            }

            Text {
                x: 24
                text: "更多榜单"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            Column {
                x: 24
                width: parent.width - 48
                Repeater {
                    model: MockData.toplists
                    delegate: Item {
                        width: parent.width
                        height: 44
                        property var t: modelData
                        property bool hover: rowMouse.containsMouse

                        Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }
                        Text {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            width: 24
                            text: index + 1
                            horizontalAlignment: Text.AlignHCenter
                            font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: Font.Bold }
                            color: index < 3 ? Theme.accent : Theme.text_hint
                        }
                        Column {
                            anchors { left: parent.left; leftMargin: 48; verticalCenter: parent.verticalCenter }
                            width: parent.width - 48 - 60
                            spacing: 2
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: t.title
                                font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                                color: Theme.text_primary
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: t.top3.join(" / ")
                                font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                                color: Theme.text_secondary
                            }
                        }
                        IconImage {
                            visible: hover
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                            color: Theme.text_primary
                            size: 14
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { MockPlayback.loadQueue(MockData.songsForSheet(t.seed, 10)) }
                            }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.navigate("sheet", { kind: "toplist", id: t.id, title: t.title,
                                                                seed: t.seed, platform: t.platform })
                        }
                    }
                }
            }
        }
    }
}
