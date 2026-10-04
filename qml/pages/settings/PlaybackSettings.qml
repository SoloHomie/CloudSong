import QtQuick
import "../../components/controls"
import "../../components/layout"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  PlaybackSettings — 设置子页面: 播放 (音质 / 歌词 / 系统集成, 整组折叠)
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root
    property bool desktopLyric: false
    property bool smtcEnabled: true
    property bool autoDegrade: true       // 受限音源自动降级 (P0)
    property int qualityIdx: 0            // 0标准 1较高 2无损

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 680)
        spacing: 3
        bottomPadding: 24

            SuretyCollapse {
                width: parent.width
                title: "播放"
                subtitle: "音质、歌词与系统集成"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Column {
                        anchors { left: parent.left; right: parent.right }
                        bottomPadding: 6
                        SettingRow {
                            title: "默认音质"
                            ctrlReserve: 290   // 横向分段选择占位更宽, 标题区让出更多
                            SuretyTagSelector {
                                anchors.verticalCenter: parent.verticalCenter
                                displayMode: "segment"
                                selectedIndex: root.qualityIdx
                                model: [ { label: "标准品质" }, { label: "较高品质" }, { label: "无损品质" } ]
                                onTagSelected: function(i) { root.qualityIdx = i }
                            }
                        }
                        SettingRow {
                            title: "桌面歌词"
                            subtitle: "置顶歌词窗, 不挡工作区"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.desktopLyric
                                onToggled: function(v) { root.desktopLyric = v }
                            }
                        }
                        SettingRow {
                            title: "系统媒体控制 (SMTC)"
                            subtitle: "Windows 媒体面板与音量条显示歌曲信息"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.smtcEnabled
                                onToggled: function(v) { root.smtcEnabled = v }
                            }
                        }
                        SettingRow {
                            title: "受限音源自动降级"
                            subtitle: "某个插件不可用时, 自动用其他音源补齐同一首歌"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.autoDegrade
                                onToggled: function(v) { root.autoDegrade = v }
                            }
                        }
                    }
                }
            }
    }
}
