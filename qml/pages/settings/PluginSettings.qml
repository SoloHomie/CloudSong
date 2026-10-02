import QtQuick
import "../../mock"
import "../../components/layout"
import "../../components/panels"

// ═══════════════════════════════════════════════════════════════
//  PluginSettings — 设置子页面: 插件管理
//  2026-09-29 用户拍板: 折叠卡内嵌, 不再跳页
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
Item {
    id: root

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 680)
            spacing: 18

            SuretyCollapse {
                width: parent.width
                title: "插件管理"
                subtitle: "已启用 " + MockData.plugins.filter(function(p) { return p.enabled }).length + " 个插件 · 兼容 MusicFree 插件协议"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component { PluginsPanel {} }
            }
        }
    }
}
