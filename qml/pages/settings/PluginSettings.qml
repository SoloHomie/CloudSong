import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  PluginSettings — 设置子页面: 插件管理
//  2026-09-29 用户拍板: 折叠卡内嵌, 不再跳页
//  2026-10-02 自 SettingsPage 拆分
//  2026-10-04 去卡直排: 单卡页面里折叠卡壳是拆分残留
//  (收起=空页, 标题与侧边栏重复), 插件列表即页面本体;
//  ServiceSettings 双卡有收起用途, 保持不动
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: Math.min(parent.width - 48, 680)
        height: Math.max(implicitHeight, root.height)   // root=视口高(勿用 parent.height, 与 contentHeight 成环)
        spacing: 3

        // 页首: 标题 + 说明 (原折叠卡头部信息移入)
        Column {
            Layout.fillWidth: true
            spacing: 5
            Text {
                text: "插件管理"
                font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                text: "获取更多音源 · 兼容 MusicFree 插件协议"
                font { family: Theme.fontFamily; pixelSize: 11 }
                color: Theme.text_hint
            }
        }
        Item { Layout.preferredHeight: 4 }
        // 面板: 添加按钮行 + 插件卡列表 (原折叠卡内容物)
        PluginsPanel {
            Layout.fillWidth: true
        }
        // 底部弹簧: 吸收剩余空间; 内容超高滚动时保底 24 底部留白
        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 24
        }
    }
}
