import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  Popover — 轻量弹出面板
//  定位: 调用方用 anchors 把本组件(占位点 1×1)放到触发钮上方/下方,
//  placement 决定面板从占位点向上还是向下展开
//  2026-09-28 二修: 原 in-place Rectangle + layer.effect(MultiEffect 阴影) 在用户机上
//  面板内容渲染不出(气泡看不见); 改为窗口级挂载 —— 面板本体挂 Window.contentItem
//  顶层 (同 display/Tooltip 已验证路径), 避开祖先裁剪/兄弟 z 顺序, 去掉图层效果,
//  阴影以纯边框代替; 开合过渡保持原 imperative 动画参数
//  关闭方式: 触发钮再点 / 选中项 / 打开另一面板; hover 打开模式由触发侧
//  配合 hovered + 计时器实现 (音量调节条); 点击外部关闭待接
//  子项建议用 PopoverOption
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property bool open: false
    property int panelWidth: 200
    property string placement: "above"   // "above"=面板在占位点上方(默认) / "below"=下方
    property int spacing: 2              // 内容列间距 (音量竖向面板用 8)
    property bool hovered: panelHover.hovered   // 悬停联动: 鼠标当前是否在面板上
    default property alias content: col.data

    width: 1
    height: 1

    // 面板本体 (打开时挂载到窗口顶层; 关闭后归还本组件以随树销毁)
    Rectangle {
        id: panel
        z: 2147483647
        visible: false
        opacity: 0
        scale: 0.92
        width: root.panelWidth
        height: col.implicitHeight + 12
        radius: 10
        color: Theme.bg_card
        border { width: 1; color: Theme.border_standard }

        Column {
            id: col
            anchors { fill: parent; margins: 6 }
            spacing: root.spacing
        }
        HoverHandler {
            id: panelHover
        }
    }

    // 出现/关闭过渡 (与 EnterFade/ExitFade 同参数; 窗口级挂载, 手写 imperative 动画)
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "scale"; from: 0.92; to: 1; duration: 200; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: hideAnim
        NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
        ScriptAction { script: { panel.visible = false; panel.parent = root } }
    }

    onOpenChanged: {
        if (open) {
            hideAnim.stop()
            if (!Window.window) return
            var p = root.mapToItem(Window.window.contentItem, 0, 0)
            panel.parent = Window.window.contentItem
            panel.x = p.x - panel.width / 2
            panel.y = root.placement === "below" ? p.y : p.y - panel.height
            panel.visible = true
            panel.opacity = 0
            panel.scale = 0.92
            showAnim.start()
        } else {
            showAnim.stop()
            hideAnim.start()
        }
    }

    // 面板还挂在窗口上时本组件被销毁 (页面弹出等): 一并销毁, 防孤儿面板引用已毁对象
    Component.onDestruction: {
        if (panel.parent !== root) panel.destroy()
    }
}
