import QtQuick
import "../../components/layout"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  ServiceSettings — 设置子页面: 服务 (云漫游 / 歌单迁移)
//  2026-09-29 用户拍板: 原跳独立页改为折叠卡内嵌, 内容即面板组件
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root
    signal navigate(string name, var params)

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 680)
        spacing: 18
        bottomPadding: 24

            SuretyCollapse {
                width: parent.width
                title: "云漫游"
                subtitle: "歌单与播放进度多设备同步 · ¥3/月"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    RoamPanel {
                        onNavigate: function(name, params) { root.navigate(name, params) }
                    }
                }
            }
            SuretyCollapse {
                width: parent.width
                title: "歌单迁移"
                subtitle: "截图 / 链接 / 文本 / 备份 → CloudSong 歌单 · 一次性买断"
                open: false
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    MigratePanel {
                        onNavigate: function(name, params) { root.navigate(name, params) }
                    }
                }
            }
    }
}
