import QtQuick
import "../../theme"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  GeneralSettings — 设置子页面: 通用 (外观 / 字体 / 启动行为)
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property bool autoLaunch: false
    property bool minimizeToTray: true
    property int fontIdx: 0               // 0 MiSans 1 微软雅黑 (待接 C++ ConfigService 持久化)

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

            SettingRow {
                title: "主题"
                ctrlReserve: 290   // 同默认音质: 三段分段条占位
                SuretyTagSelector {
                    anchors.verticalCenter: parent.verticalCenter
                    displayMode: "segment"
                    selectedIndex: AppCfg.themeIndex
                    model: [ { label: "浅色" }, { label: "深色" }, { label: "跟随系统" } ]
                    onTagSelected: function(i) { AppCfg.themeIndex = i }
                }
            }
            SettingRow {
                title: "背景材质"
                subtitle: "云母 / 亚克力 · Windows 系统合成"
                ctrlReserve: 290   // 三段分段条占位, 同主题行
                SuretyTagSelector {
                    anchors.verticalCenter: parent.verticalCenter
                    displayMode: "segment"
                    selectedIndex: AppCfg.materialIndex
                    model: [ { label: "不透明" }, { label: "云母" }, { label: "亚克力" } ]
                    onTagSelected: function(i) { AppCfg.materialIndex = i }
                }
            }
            SettingRow {
                title: "界面字体"
                subtitle: "全局生效 · 需重启后完全刷新"
                SuretyComboBox {
                    anchors.verticalCenter: parent.verticalCenter
                    model: [ { text: "MiSans" }, { text: "微软雅黑" } ]
                    currentIndex: root.fontIdx
                    onItemSelected: function(i, t) {
                        root.fontIdx = i
                        // Theme 为单例可写; 全部组件 family 绑定此 token, 立即全局切换
                        Theme.fontFamily = i === 0 ? "MiSans VF" : "Microsoft YaHei UI"
                    }
                }
            }
            SettingRow {
                title: "开机自启动"
                SuretySwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.autoLaunch
                    onToggled: function(v) { root.autoLaunch = v }
                }
            }
            SettingRow {
                title: "关闭窗口时最小化到托盘"
                SuretySwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.minimizeToTray
                    onToggled: function(v) { root.minimizeToTray = v }
                }
            }
        }
    }
}
