import QtQuick
import "../../components/controls"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  DownloadSettings — 设置子页面: 下载 (目录 / 歌词)
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root
    property string downloadDir: "C:\\Users\\Lenovo\\Music"
    property bool downloadLyric: false

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 680)
        spacing: 18
        bottomPadding: 24

            SettingRow {
                title: "下载目录"
                subtitle: root.downloadDir
            }
            SettingRow {
                title: "同时下载歌词"
                SuretySwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.downloadLyric
                    onToggled: function(v) { root.downloadLyric = v }
                }
            }
    }
}
