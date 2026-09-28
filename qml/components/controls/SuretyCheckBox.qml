import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  CheckBox — 发光勾选框 (CSS 灵感)
//  用法:
//    CheckBox { label: "全局"; checked: true; onToggled: console.log(checked) }
//    CheckBox { accentColor: "#00ff88" }  // 自定义强调色
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // ── 公开属性 ──
    property bool   checked:     false
    property string label:       ""
    property bool   enabled:     true
    property int    fontSize:    16
    property int    fontWeight:  Font.Normal
    property color  labelColor:  Theme.text_primary
    property int    boxSize:     16
    property color  accentColor: Theme.accent

    signal toggled(bool checked)

    readonly property int paddingH: 6
    readonly property int paddingV: 4

    implicitWidth:  paddingH * 2 + (labelText.visible ? boxSize + 9 + labelText.implicitWidth : boxSize)
    implicitHeight: paddingV * 2 + Math.max(boxSize, labelText.implicitHeight)

    readonly property color _glow:  Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)
    readonly property color _border: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, enabled ? 0.7 : 0.3)

    // ═══════════════════════════════════════
    //  发光层 (外发光模拟 box-shadow)
    // ═══════════════════════════════════════
    Rectangle {
        id: glow1
        width: box.width + 8; height: box.height + 8
        anchors.centerIn: box
        radius: 5
        color: "transparent"
        border.width: 2
        border.color: root._glow
        opacity: root.checked ? 0.5 : (hoverMA.containsMouse ? 0.3 : 0)
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Rectangle {
        id: glow2
        width: box.width + 16; height: box.height + 16
        anchors.centerIn: box
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: root._glow
        opacity: hoverMA.containsMouse ? 0.25 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ═══════════════════════════════════════
    //  勾选框
    // ═══════════════════════════════════════
    Rectangle {
        id: box
        width: root.boxSize; height: root.boxSize
        radius: 4
        anchors.left: parent.left
        anchors.leftMargin: root.paddingH
        anchors.verticalCenter: parent.verticalCenter

        // 背景
        color: {
            if (!root.enabled) return Theme.bg_input
            if (root.checked)  return root.accentColor
            return Theme.bg_card
        }
        border.width: root.checked ? 0 : 2
        border.color: root._border

        scale: root.checked ? 1 : (hoverMA.containsMouse ? 1.1 : 1)
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.3 } }

        // ── 填充动画层 ──
        Rectangle {
            anchors.centerIn: parent
            width:  parent.width  * (root.checked ? 1 : 0)
            height: parent.height * (root.checked ? 1 : 0)
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.accentColor }
                GradientStop { position: 1.0; color: Qt.lighter(root.accentColor, 1.3) }
            }
            opacity: root.checked ? 1 : 0
            scale: root.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }
        }

        // ── 勾号 (矢量 Canvas) ──
        Canvas {
            anchors.centerIn: parent
            width:  parent.width  * 0.65
            height: parent.height * 0.45
            opacity: root.checked ? 1 : 0
            scale:   root.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var pad = 2
                var w = width - pad * 2
                var h = height - pad * 2
                ctx.strokeStyle = Theme.isDark ? "#1a1a1a" : "#ffffff"
                ctx.lineWidth = 2.5
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(pad, pad + h * 0.5)
                ctx.lineTo(pad + w * 0.4, pad + h)
                ctx.lineTo(pad + w, pad)
                ctx.stroke()
            }
        }

    }

    // ═══════════════════════════════════════
    //  标签文字
    // ═══════════════════════════════════════
    Text {
        id: labelText
        visible: root.label !== ""
        // 2026-09-28 修复: 原 anchors.left + x 冲突(锚点覆盖 x), hover 位移从未生效;
        // 去掉 left 锚点, 位置全由 x 绑定决定 (verticalCenter 锚点与 x 不冲突, 保留)
        x: root.paddingH + box.width + 6 + (hoverMA.containsMouse ? 5 : 0)
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.labelColor
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
        font.family: Theme.fontFamily
        opacity: root.enabled ? (hoverMA.containsMouse ? 1 : 0.85) : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on x       { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // ═══════════════════════════════════════
    //  交互
    // ═══════════════════════════════════════
    MouseArea {
        id: hoverMA
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!root.enabled) return
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
