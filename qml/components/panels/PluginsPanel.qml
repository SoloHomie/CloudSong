import QtQuick
import "../../theme"
import "../../mock"
import "../display"
import "../buttons"
import "../controls"

// ═══════════════════════════════════════════════════════════════
//  PluginsPanel — 插件管理面板 (设置页"插件"分类折叠卡内容)
//  2026-09-29 由 PluginManagerPage 迁入: 原 ListView 改为 Column+Repeater
//  (设置页已有外层 Flickable, 不可嵌套滚动容器)
//  插件自由获取、自由分享, 与 MusicFree 插件协议兼容;
//  真实安装/校验待接 C++ PluginManager (9 白名单模块)
// ═══════════════════════════════════════════════════════════════
Column {
    id: root
    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14 }
    bottomPadding: 12
    spacing: 12

    property var plugins: MockData.plugins

    function refresh() { root.plugins = root.plugins.slice() }   // 开关回写后刷新

    // 安装入口行
    Row {
        width: parent.width
        height: 30
        SuretyBtn {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: 30
            text: "从本地安装"
            variant: "primary"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
        }
    }

    // ── 插件卡列表 ──
    Repeater {
        model: root.plugins
        delegate: Rectangle {
            width: parent.width
            height: 64
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_default }
            property var p: modelData

            IconImage {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                size: 20
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
                color: p.enabled ? Theme.accent : Theme.text_hint
            }
            Column {
                anchors { left: parent.left; leftMargin: 52; right: parent.right; rightMargin: 90; verticalCenter: parent.verticalCenter }
                spacing: 3
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: p.name + "  v" + p.version
                    font { family: Theme.fontFamily; pixelSize: 13 }
                    color: Theme.text_primary
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: p.desc
                    font { family: Theme.fontFamily; pixelSize: 11 }
                    color: Theme.text_secondary
                }
            }
            SuretySwitch {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                checked: p.enabled
                onToggled: function(v) { p.enabled = v; root.refresh() }
            }
        }
    }
}
