import QtQuick
import "../../mock"
import "../../components/buttons"
import "../../components/controls"
import "../../templates"

// ═══════════════════════════════════════════════════════════════
//  DataSettings — 设置子页面: 数据管理 (缓存 / 搜索历史)
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
    id: root

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 680)
        spacing: 18
        bottomPadding: 24

            SettingRow {
                title: "清理缓存"
                subtitle: "当前占用 23.4 MB"
                SuretyBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    text: "清理"
                    variant: "outline"
                    font.pixelSize: 11
                    onClicked: {}   // 待接 CacheService
                }
            }
            SettingRow {
                title: "清空搜索历史"
                SuretyBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    text: "清空"
                    variant: "outline"
                    font.pixelSize: 11
                    onClicked: MockData.clearSearchHistory()
                }
            }
    }
}
