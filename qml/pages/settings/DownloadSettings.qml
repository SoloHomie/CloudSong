import QtQuick
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  DownloadSettings — 设置子页面: 下载 (目录 / 歌词)
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property string downloadDir: "C:\\Users\\Lenovo\\Music"
    property bool downloadLyric: false

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
}
