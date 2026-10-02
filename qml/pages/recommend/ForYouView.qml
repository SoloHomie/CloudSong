import QtQuick
import "../../theme"
import "../../mock"
import "../../components/display"
import "../../components/buttons"
import "../../components/controls"
import "../../components/business"
import "../../components/recommend"

// ═══════════════════════════════════════════════════════════════
//  ForYouView — 推荐页子页面: 为你推荐 (模块化首页)
//  模块按 recommendModules 顺序渲染: 每日推荐大卡 / 猜你喜欢 / 精选歌单 / 今日热歌
//  内容按口味画像 (我喜欢的音乐) 生成: 每日推荐每天轮换, 猜你喜欢按偏好排序
//  模块可开/关/排序 (右上角「自定义首页」进入编辑态), 偏好存 MockData.recommendModules
//  待 C++ RecommendService + ConfigService 替换 (页面消费方式不变)
//  2026-10-02 自 RecommendPage 拆分; 歌单网格/热歌两模块体已提取至
//  components/recommend/ (SheetGridModule/HotModule), 每日推荐直接用业务组件
//  DailyMixCard (已分类, 再包一层即空壳)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
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
        SheetGridModule {
            width: parent.width
            model: root.forYouSheets
            onOpenRequested: function(it) {
                root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                         count: it.count, desc: it.desc, platform: it.platform })
            }
        }
    }
    property Component featuredBody: Component {
        SheetGridModule {
            width: parent.width
            model: MockData.sheets
            onOpenRequested: function(it) {
                root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                         count: it.count, desc: it.desc, platform: it.platform })
            }
        }
    }
    property Component hotBody: Component {
        HotModule {
            width: parent.width
            songs: root.hotSongs
            onPlayAllRequested: MockPlayback.loadQueue(root.hotSongs)
            onPlayRequested: function(i) {
                MockPlayback.loadQueue(root.hotSongs)
                MockPlayback.playIndex(i)
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

    Flickable {
        id: recFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: recCol.height + 24
        clip: true
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
}
