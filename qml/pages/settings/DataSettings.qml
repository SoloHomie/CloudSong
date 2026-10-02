import QtQuick
import "../../mock"
import "../../components/buttons"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  DataSettings — 设置子页面: 数据管理 (缓存 / 搜索历史)
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
}
