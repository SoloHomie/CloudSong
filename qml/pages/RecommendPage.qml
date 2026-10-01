import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  RecommendPage — 推荐页 (2026-10-01 个性化重做)
//   Tab1 为你推荐: 模块化首页 — 每日推荐大卡 / 猜你喜欢 / 精选歌单 / 今日热歌
//     内容按口味画像 (我喜欢的音乐) 生成: 每日推荐每天轮换, 猜你喜欢按偏好排序
//     模块可开/关/排序 (右上角「自定义首页」进入编辑态), 偏好存 MockData.recommendModules
//     待 C++ RecommendService + ConfigService 替换 (页面消费方式不变)
//   Tab2 排行榜: 官方榜 + 更多榜单 (全局内容, 不参与个性化)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property bool editing: false   // 编辑态: 模块全显 + 头部出开关/排序控件

    // ── 个性化数据 (进页时计算; 待 C++ 服务异步化后改回调填入) ──
    property var dailySongs: MockData.dailyMix()
    property var forYouSheets: MockData.sheetsForYou()
    property var hotSongs: MockData.songs.slice(0, 10)
    property string artistLine: MockData.topArtists(3).join(" · ")
    property var tagList: MockData.topTags(5)
    property string dailyDate: (new Date().getMonth() + 1) + "月" + new Date().getDate() + "日"
    property int enabledCount: MockData.recommendModules.filter(function(m) { return m.enabled }).length

    // 榜单条目补 subtitle (top3 串联展示; 排行榜 tab 用)
    property var topListItems: MockData.toplists.map(function(t) {
        return Object.assign({}, t, { subtitle: t.top3.join(" / ") })
    })

    // ── 模块体组件 (按 key 映射; Loader 按需实例化, 隐藏模块不创建) ──
    property Component dailyBody: Component {
        DailyMixCard {
            width: parent.width
            songs: root.dailySongs
            artistLine: root.artistLine
            tagList: root.tagList
            dateText: root.dailyDate
            onPlayRequested: MockPlayback.loadQueue(root.dailySongs)
            onOpenRequested: root.navigate("sheet", { kind: "daily", title: "每日推荐",
                                                       seed: 0, desc: "根据你的口味生成 · 每天更新" })
        }
    }
    property Component forYouBody: Component {
        MediaGrid {
            width: parent.width
            cellWidth: 160
            height: 2 * (cellWidth + 44) - 12
            model: root.forYouSheets
            onOpenRequested: function(it) {
                root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                         count: it.count, desc: it.desc, platform: it.platform })
            }
        }
    }
    property Component featuredBody: Component {
        MediaGrid {
            width: parent.width
            cellWidth: 160
            height: 2 * (cellWidth + 44) - 12
            model: MockData.sheets
            onOpenRequested: function(it) {
                root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                         count: it.count, desc: it.desc, platform: it.platform })
            }
        }
    }
    property Component hotBody: Component {
        Column {
            width: parent.width
            SongToolbar {
                width: parent.width
                onPlayAllRequested: MockPlayback.loadQueue(root.hotSongs)
            }
            SongTable {
                width: parent.width
                height: 32 + root.hotSongs.length * 40
                model: root.hotSongs
                onPlayRequested: function(s, i) {
                    MockPlayback.loadQueue(root.hotSongs)
                    MockPlayback.playIndex(i)
                }
            }
        }
    }
    function bodyFor(key) {
        switch (key) {
            case "daily":    return root.dailyBody
            case "forYou":   return root.forYouBody
            case "featured": return root.featuredBody
            case "hot":      return root.hotBody
        }
        return null
    }

    // 编辑态上移/下移小按钮
    component MoveBtn: Rectangle {
        property string glyph: ""
        property bool usable: true
        signal clicked
        width: 24; height: 24; radius: 6
        color: mouse.containsMouse && usable ? Theme.hover_bg : "transparent"
        border { width: 1; color: Theme.border_default }
        opacity: usable ? 1 : 0.35
        Text {
            anchors.centerIn: parent
            text: glyph
            font { family: Theme.fontFamily; pixelSize: 11; weight: Font.Bold }
            color: usable ? Theme.text_primary : Theme.text_disabled
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: usable
            hoverEnabled: true
            cursorShape: usable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    TabBar {
        id: tabs
        anchors { top: parent.top; topMargin: 20; left: parent.left; leftMargin: 24 }
        items: [{ text: "为你推荐" }, { text: "排行榜" }]
    }

    // 自定义首页 (仅推荐 tab; 编辑态变「完成」)
    SuretyBtn {
        anchors { top: parent.top; topMargin: 20; right: parent.right; rightMargin: 24 }
        visible: tabs.activeIndex === 0
        height: 30
        variant: root.editing ? "primary" : "outline"
        font.pixelSize: 12
        text: root.editing ? "完成" : "自定义首页"
        onClicked: root.editing = !root.editing
    }

    // ══ Tab 0: 为你推荐 (模块化) ══
    Flickable {
        id: recFlick
        anchors { top: tabs.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: recCol.height + 24
        clip: true
        visible: tabs.activeIndex === 0
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: recCol
            width: parent.width
            spacing: 18

            // ── 模块 (按 recommendModules 顺序渲染; 编辑态全部可见, 关闭项置灰禁交互) ──
            Repeater {
                model: MockData.recommendModules
                delegate: Item {
                    width: recCol.width
                    height: modCol.height
                    visible: root.editing || modelData.enabled
                    opacity: modelData.enabled ? 1 : 0.5

                    Column {
                        id: modCol
                        width: parent.width
                        spacing: 10

                        // 模块头: 品牌色竖条 + 标题 + 副题 (编辑态换开关/排序控件)
                        Row {
                            x: 24
                            width: parent.width - 48
                            height: 24
                            spacing: 8
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3; height: 15; radius: 1.5
                                color: Theme.accent
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                                color: Theme.text_primary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !root.editing
                                text: modelData.sub
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_hint
                            }
                            Row {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: root.editing
                                spacing: 6
                                SuretySwitch {
                                    anchors.verticalCenter: parent.verticalCenter
                                    trackWidth: 36
                                    checked: modelData.enabled
                                    onToggled: function(v) { MockData.toggleRecommendModule(modelData.key) }
                                }
                                MoveBtn {
                                    glyph: "↑"
                                    usable: index > 0
                                    onClicked: MockData.moveRecommendModule(modelData.key, -1)
                                }
                                MoveBtn {
                                    glyph: "↓"
                                    usable: index < MockData.recommendModules.length - 1
                                    onClicked: MockData.moveRecommendModule(modelData.key, 1)
                                }
                            }
                        }

                        // 模块体 (关闭项在编辑态可见但禁交互)
                        Item {
                            x: 24
                            width: parent.width - 48
                            height: bodyLoader.height
                            Loader {
                                id: bodyLoader
                                width: parent.width
                                sourceComponent: root.bodyFor(modelData.key)
                            }
                            MouseArea {
                                anchors.fill: parent
                                visible: root.editing && !modelData.enabled
                            }
                        }
                    }
                }
            }

            // 空态: 模块全关
            StatusPlaceholder {
                x: 24
                width: parent.width - 48
                height: 240
                visible: !root.editing && root.enabledCount === 0
                title: "首页空空如也"
                message: "去「自定义首页」挑几个想看的模块"
                actionText: "自定义首页"
                onActionRequested: root.editing = true
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
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
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
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
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
                            font { family: Theme.fontFamily; pixelSize: 13; weight: Font.Bold }
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
                                font { family: Theme.fontFamily; pixelSize: 13 }
                                color: Theme.text_primary
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: t.top3.join(" / ")
                                font { family: Theme.fontFamily; pixelSize: 11 }
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
                                z: 1   // 行级 rowMouse 声明在后会压住本图标, 抬升 z 才能收到点击
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
