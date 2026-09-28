import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  PluginManagerPage — 插件管理 (启用/停用 + 本地安装入口)
//  插件自由获取、自由分享, 与 MusicFree 插件协议兼容;
//  真实安装/校验待接 C++ PluginManager (9 白名单模块)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var plugins: MockData.plugins

    function refresh() { root.plugins = root.plugins.slice() }   // 开关回写后刷新

    PageHeader {
        id: header
        title: "插件管理"
        subtitle: "插件协议兼容 MusicFree, 自由获取、自由分享"
        SuretyBtn {
            height: 30
            text: "从本地安装"
            variant: "primary"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
        }
    }

    // ── 插件卡列表 ──
    ListView {
        anchors { top: header.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.plugins
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            width: ListView.view.width - 48
            height: 64
            x: 24
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
        spacing: 8
        topMargin: 8
    }
}
