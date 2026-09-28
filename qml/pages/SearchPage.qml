import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  SearchPage — 搜索页 (原版 SearchPage 同构)
//   歌曲/专辑/歌手/歌单 四类型 tab; 插件来源 chips 过滤; 热词兜底
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property string query: params.query !== undefined ? params.query : ""
    property int activeTab: 0
    property var activePlatforms: ["网易云", "QQ音乐", "本地"]   // 空=全部
    property var result: MockData.searchAll(root.query)

    function filtered(list) {
        return list.filter(function(x) {
            return root.activePlatforms.length === 0 || root.activePlatforms.indexOf(x.platform) >= 0
        })
    }

    // ── 顶部: 搜索框 + 插件来源 chips ──
    Column {
        anchors { top: parent.top; topMargin: 16; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        spacing: 10

        SuretyTextField {
            id: input
            width: 320
            height: 34
            placeholder: "搜索歌曲、歌手、专辑、歌单"
            text: root.query
            font.pixelSize: 13
            contentLeftPadding: 12
            contentRightPadding: 12
            onTextChanged: root.query = text
            onAccepted: if (text.trim() !== "") MockData.addSearchHistory(text.trim())
        }

        Row {
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "来源:"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_hint
            }
            Repeater {
                model: [{ name: "网易云", key: "网易云" }, { name: "QQ音乐", key: "QQ音乐" }, { name: "本地", key: "本地" }]
                delegate: Rectangle {
                    height: 24
                    width: srcText.implicitWidth + 20
                    radius: 12
                    property bool isOn: root.activePlatforms.indexOf(modelData.key) >= 0
                    color: isOn ? Theme.accent : Theme.bg_input
                    Text {
                        id: srcText
                        anchors.centerIn: parent
                        text: modelData.name
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        color: isOn ? "#ffffff" : Theme.text_secondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var arr = root.activePlatforms.slice()
                            var i = arr.indexOf(modelData.key)
                            if (i >= 0) arr.splice(i, 1)
                            else arr.push(modelData.key)
                            root.activePlatforms = arr
                        }
                    }
                }
            }
        }
    }

    // ── 无关键词: 热词兜底 ──
    Column {
        anchors { top: parent.top; topMargin: 110; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        visible: root.query.trim() === ""
        spacing: 12
        Text {
            text: "热门搜索"
            font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
            color: Theme.text_primary
        }
        Row {
            spacing: 8
            Repeater {
                model: MockData.tags
                delegate: Rectangle {
                    height: 26
                    width: tagText.implicitWidth + 24
                    radius: 13
                    color: tagMouse.containsMouse ? Theme.hover_bg : Theme.bg_input
                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: modelData
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_primary
                    }
                    MouseArea {
                        id: tagMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.query = modelData; input.text = modelData }
                    }
                }
            }
        }
    }

    // ── 有结果: 类型 tab + 结果区 ──
    Column {
        anchors { top: parent.top; topMargin: 110; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.query.trim() !== ""

        TabBar {
            id: tabs
            anchors { left: parent.left; leftMargin: 24 }
            items: [{ text: "歌曲" }, { text: "专辑" }, { text: "歌手" }, { text: "歌单" }]
            onActivated: function(i) { root.activeTab = i }
        }

        Item {
            width: parent.width
            height: parent.height - tabs.height - 4
            anchors { left: parent.left }

            // 歌曲
            SongTable {
                anchors.fill: parent
                visible: root.activeTab === 0
                model: root.filtered(root.result.songs)
                emptyTitle: "没有找到相关歌曲"
                emptyMessage: "换个关键词试试, 或调整上方来源筛选"
                onPlayRequested: function(s, i) {
                    var list = root.filtered(root.result.songs)
                    MockPlayback.loadQueue(list)
                    MockPlayback.playIndex(i)
                }
            }
            // 专辑
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 1
                cellWidth: 160
                model: root.filtered(root.result.albums)
                emptyTitle: "没有找到相关专辑"
                onOpenRequested: function(it) {
                    root.navigate("album", { id: it.id, title: it.title, artist: it.artist,
                                             date: it.date, count: it.count, seed: it.seed, platform: it.platform })
                }
            }
            // 歌手
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 2
                cellWidth: 160
                model: root.filtered(root.result.artists).map(function(a) {
                    return Object.assign({}, a, { title: a.name, subtitle: a.desc })
                })
                emptyTitle: "没有找到相关歌手"
                onOpenRequested: function(it) {
                    root.navigate("artist", { id: it.id, name: it.name, desc: it.desc,
                                              seed: it.seed, platform: it.platform })
                }
            }
            // 歌单
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 3
                cellWidth: 160
                model: root.filtered(root.result.sheets)
                emptyTitle: "没有找到相关歌单"
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                             count: it.count, desc: it.desc, platform: it.platform })
                }
            }
        }
    }
}
