import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQml.Models
import "../theme"
import "../mock"

/// ──────────────────────────────────────────────────────────
///  侧边导航 (自 BallsHackPro 移植: 福利块与硬编码导航已剥离,
///  model 属性注入; 支持 header 角色渲染分组标签)
/// ──────────────────────────────────────────────────────────
Rectangle {
    id: sideBar
    width: 160
    color: "transparent"   // 原: AppCfg.materialIndex===0 ? Theme.neutral0 : transparent (materialIndex 产品专属已剥离)

    property int selectedIndex: 0
    // 导航内容归本模块管理 (main.qml 只负责布局, 不注入条目); 角色: kind("header"=分组标签/headerText/headerBtn右侧小＋, "spacer"=弹性占位, "item"=导航项/icon/text/badge/badgeText/page(页面下标), "action"=底部操作按钮/icon/text)
    property var model: ListModel {
        ListElement { kind: "item"; page: 0; animated: true; text: "推荐" }   // 声纹动画(SVG无法自带动画, 只能用QML); page=View 中页面下标
        ListElement { kind: "item"; page: 1; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/mode.svg"; text: "听歌模式" }
        ListElement { kind: "header"; headerText: "我的音乐" }
        ListElement { kind: "item"; page: 2; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/fav.svg"; text: "我喜欢的音乐" }
        ListElement { kind: "item"; page: 3; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/recent.svg"; text: "历史播放" }
        ListElement { kind: "header"; headerText: "创建的歌单"; headerBtn: true }   // 小标签, 右侧小＋按钮; 歌单(默认"我的歌单"+新建)动态列在其下
        // 本地音乐/下载管理 2026-10-01 用户拍板不占侧栏; 服务项(云漫游/歌单迁移/插件)之后放到不显眼处(如设置页)
        ListElement { kind: "spacer" }   // 弹簧沉底: 选项靠上, 下方留白
    }
    signal pageSwitchRequested(int page)
    signal createRequested()
    signal sheetRequested(var sheet)   // 点击自建歌单项 → 歌单详情页参数

    // ── 自建歌单动态行 (kind:"sheetItem", 插在"我的歌单"之下; 数据源 MockData.createdSheets) ──
    function syncCreatedSheets() {
        // 行号会随插入变化, 先记下当前选中的根页面
        var selPage = -1
        if (selectedIndex >= 0 && selectedIndex < model.count && model.get(selectedIndex).kind === "item")
            selPage = model.get(selectedIndex).page
        // 清旧行
        for (var i = model.count - 1; i >= 0; i--)
            if (model.get(i).kind === "sheetItem") model.remove(i)
        // 找"创建的歌单"分组标签, 其后按序插入 (默认"我的歌单"+新建歌单同一套模板)
        var base = -1
        for (var j = 0; j < model.count; j++)
            if (model.get(j).kind === "header" && model.get(j).headerText === "创建的歌单") { base = j; break }
        for (var k = 0; k < MockData.createdSheets.length; k++) {
            var s = MockData.createdSheets[k]
            model.insert(base + 1 + k, {
                kind: "sheetItem",
                icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/playlist.svg",
                text: s.title,
                sheetId: s.id, sheetTitle: s.title, sheetSeed: s.seed,
                sheetCount: s.count, sheetPlatform: s.platform
            })
        }
        // 恢复选中行
        if (selPage >= 0)
            for (var m = 0; m < model.count; m++)
                if (model.get(m).kind === "item" && model.get(m).page === selPage) { selectedIndex = m; break }
    }

    Component.onCompleted: syncCreatedSheets()
    Connections {
        target: MockData
        function onCreatedSheetsChanged() { syncCreatedSheets() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 5

        Repeater {
            model: sideBar.model
            delegate: DelegateChooser {
                role: "kind"
                // 分组标签
                DelegateChoice {
                    roleValue: "header"
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.bottomMargin: 1
                        height: 20
                        color: "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: headerText
                            color: Theme.text_hint
                            font { family: Theme.fontFamily; pixelSize: 13; weight: Font.Bold }
                        }
                        // 标签右侧小添加按钮 (headerBtn: true 时显示, 如"创建的歌单"; 无背景, 仅图标)
                        Rectangle {
                            visible: typeof headerBtn !== "undefined" && headerBtn
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            width: 18; height: 18
                            color: "transparent"
                            Image {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/add.svg"
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                layer.enabled: true   // 默认与标题同色, hover 变白
                                layer.effect: MultiEffect {
                                    colorizationColor: headerBtnMouse.containsMouse ? "#ffffff" : Theme.text_hint
                                    colorization: 1.0
                                }
                            }
                            MouseArea {
                                id: headerBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sideBar.createRequested()
                            }
                        }
                    }
                }
                // 弹性占位 (把后续项推到侧栏底部)
                DelegateChoice {
                    roleValue: "spacer"
                    Item { Layout.fillHeight: true }
                }
                // 导航项
                DelegateChoice {
                    roleValue: "item"   // 无 roleValue 的 choice 是无序 catch-all (Qt6.11 实测), 会吞掉后面的 sheetItem/action 行 (2026-10-01)
                    SideBarDelegate {
                        Layout.fillWidth: true
                        iconImage: icon
                        sideText: qsTr(text)
                        isSelected: index === sideBar.selectedIndex
                        showBeta: typeof badge !== "undefined" && badge
                        badgeText: typeof badgeText !== "undefined" && badgeText !== "" ? badgeText : "BETA"
                        animatedBars: typeof animated !== "undefined" && animated
                        onClicked: { sideBar.selectedIndex = index; sideBar.pageSwitchRequested(page) }
                    }
                }
                // 自建歌单项 (动态插入; 点击直接进对应歌单详情页, 不改根页面选中)
                // 注意: 动态插入行的新角色名 (sheetId 等) 不进委托上下文, 须经 model.get(index) 读取
                // (2026-10-01 实机 ReferenceError: sheetId is not defined; 静态角色 icon/text 不受影响)
                DelegateChoice {
                    roleValue: "sheetItem"
                    SideBarDelegate {
                        Layout.fillWidth: true
                        iconImage: icon
                        sideText: qsTr(text)
                        isSelected: false
                        showBeta: false
                        onClicked: {
                            var row = sideBar.model.get(index)
                            sideBar.sheetRequested({
                                kind: "sheet", id: row.sheetId, title: row.sheetTitle, seed: row.sheetSeed,
                                count: row.sheetCount, platform: row.sheetPlatform, mine: true
                            })
                        }
                    }
                }
                // 底部操作按钮 (如"新建歌单")
                DelegateChoice {
                    roleValue: "action"
                    SideBarDelegate {
                        Layout.fillWidth: true
                        iconImage: icon
                        sideText: qsTr(text)
                        isSelected: false
                        showBeta: false
                        onClicked: sideBar.createRequested()
                    }
                }
            }
        }
    }
}
