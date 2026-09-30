import QtQuick
import QtQuick.Dialogs
import "../../theme"
import "../display"
import "../buttons"
import "../controls"

// ═══════════════════════════════════════════════════════════════
//  PluginsPanel — 插件管理面板 (设置页"插件"分类折叠卡内容)
//  2026-09-29 由 PluginManagerPage 迁入: 原 ListView 改为 Column+Repeater
//  (设置页已有外层 Flickable, 不可嵌套滚动容器)
//  2026-10-01 实装: 列表/开关/本地安装全接 Plugins service
//  (plugins 属性 + setPluginEnabled + installPluginFromFile);
//  停用名单落 QSettings, runtime reload 即生效。
//  同日晚 动画: 数据经 ListModel 按 platform 就地更新 (代理不重建),
//  停用变暗/开关滑动动画得以完整播放 (直接绑 Plugins.plugins 会
//  因 reload 重建代理, 动画被截断)。
// ═══════════════════════════════════════════════════════════════
Column {
    id: root
    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14 }
    bottomPadding: 12
    spacing: 12

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

    // 安装入口行 (左侧为操作反馈文案)
    Row {
        width: parent.width
        height: 30
        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: parent.width - 120
            visible: root.opMsg !== ""
            text: root.opMsg
            elide: Text.ElideRight
            font { family: Theme.fontFamily; pixelSize: 11 }
            color: Theme.text_secondary
        }
        SuretyBtn {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: 30
            text: "从本地安装"
            variant: "primary"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
            onClicked: fileDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        title: "选择插件文件"
        nameFilters: ["JavaScript 插件 (*.js)"]
        onAccepted: Plugins.installPluginFromFile(String(selectedFile))
    }

    // ── 插件卡列表 ──
    Repeater {
        model: pluginModel
        delegate: Rectangle {
            width: parent.width
            height: 64
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_default }
            opacity: model.enabled ? 1.0 : 0.55
            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            IconImage {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                size: 20
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
                color: model.enabled ? Theme.accent : Theme.text_hint
                Behavior on color {
                    ColorAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
            Column {
                anchors { left: parent.left; leftMargin: 52; right: parent.right; rightMargin: 90; verticalCenter: parent.verticalCenter }
                spacing: 3
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
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                checked: model.enabled
                onToggled: function(v) { Plugins.setPluginEnabled(model.platform, v) }
            }
        }
    }
}
