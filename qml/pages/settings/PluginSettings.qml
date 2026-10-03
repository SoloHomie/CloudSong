import QtQuick
import "../../mock"
import "../../components/layout"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  PluginSettings — 设置子页面: 插件管理
//  2026-09-29 用户拍板: 折叠卡内嵌, 不再跳页
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 680)
        spacing: 18
        bottomPadding: 24

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
