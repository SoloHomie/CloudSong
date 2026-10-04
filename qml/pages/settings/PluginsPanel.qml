import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../dialogs"
import "../../components/display"
import "../../components/buttons"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  PluginsPanel — 插件管理面板 (设置页"插件"分类折叠卡内容)
//  2026-09-29 由 PluginManagerPage 迁入: 原 ListView 改为 Column+Repeater
//  (设置页已有外层 Flickable, 不可嵌套滚动容器)
//  2026-10-01 实装: 列表/开关全接 Plugins service
//  (plugins 属性 + setPluginEnabled); 停用名单落 QSettings, reload 即生效。
//  添加插件 = AddPluginDialog (拖入 .js / 选择本地文件, 成功即关)。
//  同日晚 动画: 数据经 ListModel 按 platform 就地更新 (代理不重建),
//  停用变暗/开关滑动动画得以完整播放 (直接绑 Plugins.plugins 会
//  因 reload 重建代理, 动画被截断)。
//  2026-10-04 去卡直排: 折叠卡壳删除, 本面板成为页面本体
//  (去 14px 卡片内边距, 改 Layout.fillWidth 与页面列同宽)
// ═══════════════════════════════════════════════════════════════
Column {
    id: root
    Layout.fillWidth: true
    bottomPadding: 12
    spacing: 8   // 添加行与插件卡之间 / 插件卡之间 的纵向间隔

    property string opMsg: ""
    function showOpMsg(ok, msg) { root.opMsg = msg; opMsgTimer.restart() }

    // 与 Plugins.plugins 保持同步的本地模型: 按 platform 就地更新/追加/移除
    ListModel { id: pluginModel }
    function syncModel() {
        const list = Plugins.plugins || []
        const seen = {}
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            seen[p.platform] = true
            let idx = -1
            for (let j = 0; j < pluginModel.count; j++) {
                if (pluginModel.get(j).platform === p.platform) { idx = j; break }
            }
            if (idx >= 0) {
                for (const k in p) pluginModel.setProperty(idx, k, p[k])
            } else {
                pluginModel.append(p)
            }
        }
        for (let j = pluginModel.count - 1; j >= 0; j--) {
            if (!seen[pluginModel.get(j).platform]) pluginModel.remove(j)
        }
    }

    Connections {
        target: Plugins
        function onPluginsLoaded() { root.syncModel() }
        function onPluginOpFinished(ok, msg) { root.showOpMsg(ok, msg) }
    }
    Component.onCompleted: root.syncModel()

    Timer { id: opMsgTimer; interval: 4000; onTriggered: root.opMsg = "" }

    // 安装入口行 (左侧操作反馈文案, 右侧"添加插件"; 弹性占位项把按钮恒推右端,
    // 文案空时兜底 — 2026-10-04 由 Row+magic 120 改 RowLayout)
    RowLayout {
        width: parent.width
        height: 40
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: Math.max(80, parent.width - addBtn.implicitWidth - 24)
            Layout.alignment: Qt.AlignVCenter
            visible: root.opMsg !== ""
            text: root.opMsg
            elide: Text.ElideRight
            font { family: Theme.fontFamily; pixelSize: 11 }
            color: Theme.text_secondary
        }
        Item { Layout.fillWidth: true }   // 弹性占位: 把按钮推到行右端
        SuretyBtn {
            id: addBtn
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 30
            text: "添加插件"
            variant: "primary"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
            onClicked: addDialog.open()
        }
    }

    // 添加插件弹窗 (拖入 .js / 选择本地文件, 成功即关)
    AddPluginDialog { id: addDialog }

    // ── 插件卡列表 ──
    Repeater {
        model: pluginModel
        delegate: 
        Rectangle {
            width: parent.width
            height: 64
            radius: 10

            color: Theme.bg_card
            border { width: 1; color: Theme.border_default }
            opacity: model.enabled ? 1.0 : 0.55
            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // 卡片行: 左图标(48 原色品牌图) | 名称+描述 | 右开关
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 16
                spacing: 12
                IconImage {
                    Layout.alignment: Qt.AlignVCenter
                    size: 32
                    // 未知平台回退 music.svg 是白色源图, 关着色会隐形 → 仍着色
                    tint: model.platform !== "网易云" && model.platform !== "酷狗"
                    source: model.platform === "网易云" ? "qrc:/qt/qml/cloudsong/qml/assets/icons/netease.svg"
                          : model.platform === "酷狗" ? "qrc:/qt/qml/cloudsong/qml/assets/icons/kugou.svg"
                          : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
                }
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: (model.name || model.platform) + "  v" + model.version
                        font { family: Theme.fontFamily; pixelSize: 13 }
                        color: Theme.text_primary
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: model.enabled ? (model.description || "暂无描述") : "已停用"
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        color: Theme.text_secondary
                    }
                }
                SuretySwitch {
                    Layout.alignment: Qt.AlignVCenter
                    checked: model.enabled
                    onToggled: function(v) { Plugins.setPluginEnabled(model.platform, v) }
                }
            }
        }
    }
}
