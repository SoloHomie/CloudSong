import QtQuick
import QtQuick.Controls
import "../theme"
import "../components/overlay"
import "../pages/settings"

// ═══════════════════════════════════════════════════════════════
//  SettingsDialog — 设置弹窗 (2026-10-12 用户定: 设置相关页面一律弹窗
//  形式展示, 不再走页栈跳转)
//  窗体 = 暗化遮罩 + 居中大面板 (随窗口缩, 上限 980×680; 内容列宽
//  680 居中见 SettingSubPage); 内容 = 旧设置页树原样入驻
//  (SettingsPage: 分类栏 + 七子页懒加载)。M3 设置内容重建时只换
//  内容组件, 弹窗壳沿用
//  ⚠ 子页 navigate 未接线: "$auth"(云漫游登录钮) / "sheets"(迁移
//    面板) 在 M1 壳暂无去路, 点击无响应属预期 — 待账户/歌单页落地
// ═══════════════════════════════════════════════════════════════
Popup {
    id: root

    width: Math.min((Overlay.overlay ? Overlay.overlay.width : 1200) - 120, 980)
    height: Math.min((Overlay.overlay ? Overlay.overlay.height : 800) - 120, 680)

    modal: true
    focus: true
    padding: 0
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: ModalOverlay {}
    enter: EnterFade {}
    exit: ExitFade {}

    background: Rectangle {
        color: Theme.bg_page
        radius: 16
        border.width: 1
        border.color: Theme.border_standard
    }

    contentItem: Item {
        SettingsPage {
            anchors.fill: parent
        }

        // 关闭钮 (浮在设置页头右上空位 — 页头右侧槽位闲置, 不撞; 样式同 DialogShell)
        Rectangle {
            width: 28; height: 28; radius: 8
            anchors { top: parent.top; right: parent.right; margins: 18 }
            color: closeMouse.containsMouse ? Theme.hover_bg : "transparent"
            z: 10
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? Theme.text_primary : Theme.text_secondary
                font.pixelSize: 12
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }
    }
}
