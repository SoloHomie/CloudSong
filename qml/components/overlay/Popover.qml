import QtQuick
import QtQuick.Effects
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  Popover — 轻量弹出面板 (定位由调用方负责, 通常是锚在触发钮上方)
//  关闭方式: 触发钮再点 / 选中项 / 打开另一面板; 点击外部关闭待接
//  子项建议用 PopoverOption
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    property bool open: false
    property int panelWidth: 200
    default property alias content: col.data

    visible: open
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }   // 一次性过场
    width: panelWidth
    height: col.implicitHeight + 12
    radius: 10
    color: Theme.bg_card
    border { width: 1; color: Theme.border_standard }
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: Theme.shadow_alpha
        shadowBlur: 0.5
        shadowVerticalOffset: 2
    }

    Column {
        id: col
        anchors { fill: parent; margins: 6 }
        spacing: 2
    }
}
