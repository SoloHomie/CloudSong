import QtQuick
import QtQuick.Effects
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  Popover — 轻量弹出面板 (定位由调用方负责, 通常是锚在触发钮上方)
//  关闭方式: 触发钮再点 / 选中项 / 打开另一面板; 点击外部关闭待接
//  2026-09-28: 加出现/关闭过渡 (原 visible 绑定致关闭瞬间消失, 改 imperative 动画)
//  子项建议用 PopoverOption
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    property bool open: false
    property int panelWidth: 200
    default property alias content: col.data

    visible: false
    opacity: 0
    scale: 0.92
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

    onOpenChanged: {
        if (open) {
            hideAnim.stop()
            visible = true
            opacity = 0
            scale = 0.92
            showAnim.start()
        } else {
            showAnim.stop()
            hideAnim.start()
        }
    }

    // 出现/关闭过渡 (与 EnterFade/ExitFade 同参数; 手写浮层无 Popup 的 enter/exit, 用 imperative)
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; from: 0.92; to: 1; duration: 200; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; from: 1; to: 0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "scale"; from: 1; to: 0.96; duration: 130; easing.type: Easing.InCubic }
        }
        ScriptAction { script: root.visible = false }
    }

    Column {
        id: col
        anchors { fill: parent; margins: 6 }
        spacing: 2
    }
}
