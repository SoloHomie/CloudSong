import QtQuick
import "../theme"
import "../components/display"

// ═══════════════════════════════════════════════════════════════
//  BarBtn — 播放条图标按钮 (32×32; 无背景, hover/pressed 图标变白;
//  播放条内一律上下居中)
//  2026-10-02 自 PlayerBar 内联组件提取
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    width: 32
    height: 32
    anchors.verticalCenter: parent.verticalCenter
    property string icon: ""
    property string text: ""
    property string tip: ""
    property bool suppressTip: false   // 弹出面板打开时抑制悬停提示 (防盖住 Popover)
    property bool active: false
    property bool enabled: true
    property color activeColor: Theme.accent      // active 时图标色
    property bool fixedColor: false               // true 时 iconColor 恒生效, hover 不变白 (已喜欢红心)
    property color iconColor: "transparent"       // 非透明=固定色, 覆盖 active/常规逻辑
    signal clicked()
    signal hoverEntered()   // hover 打开模式 (音量调节条) 用
    signal hoverExited()

    IconImage {
        visible: root.icon !== ""
        anchors.centerIn: parent
        source: root.icon
        size: 21
        color: (root.fixedColor && root.iconColor.a > 0) ? root.iconColor
             : (btnMouse.containsMouse || btnMouse.pressed) ? "#ffffff"
             : (root.iconColor.a > 0) ? root.iconColor
             : root.active ? root.activeColor
             : (root.enabled ? Theme.text_primary : Theme.text_disabled)
    }
    Text {
        visible: root.text !== ""
        anchors.centerIn: parent
        text: root.text
        font { family: Theme.fontFamily; pixelSize: 12; weight: root.active ? Font.Bold : Font.Normal }
        color: (btnMouse.containsMouse || btnMouse.pressed) ? "#ffffff"
             : root.active ? Theme.accent_text
             : Theme.text_primary
    }
    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.hoverEntered()
        onExited: root.hoverExited()
        onClicked: if (root.enabled) root.clicked()
    }
    Tooltip {
        text: root.tip
        shown: btnMouse.containsMouse && root.tip !== "" && !root.suppressTip
        delay: 0   // hover 即展示
        radius: 8
        bgColor: Theme.bg_card
        borderColor: Theme.border_standard
        anchorItem: root
    }
}
