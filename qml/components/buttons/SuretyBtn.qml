import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

// ═══════════════════════════════════════════════════════════
//  SuretyBtn — 主题统一按钮
//  variant: primary | default | danger | outline | ghost
//  图标用 Image 展示 SVG，高度与文字对齐
// ═══════════════════════════════════════════════════════════
Rectangle {
    id: root
    radius: root.cornerRadius

    // ── 公开属性 ──
    property string text:         ""
    property string variant:      "default"
    property bool   enabled:      true
    property string iconSource:   ""
    property color  iconColor:   "transparent"  // transparent = 跟随 textColor
    property color  customBg:     "transparent"  // transparent = 用 variant 计算
    property real   cornerRadius: 8
    property real   borderWidth:  1
    property bool   pulsing:      false  // true=内容脉动(加载/后台任务指示), 默认关不影响其他按钮

    // 字体 — 默认 15px，外部可通过 font.pixelSize 覆盖
    property font   font: Qt.font({
        family:     Theme.fontFamily,
        pixelSize: 13,
        weight:     Font.Medium
    })

    // ── 信号 ──
    signal clicked()

    // ── 只读状态 ──
    readonly property bool pressed:   mouseArea.pressed
    readonly property bool hovered:   mouseArea.containsMouse
    readonly property bool _pri:      variant === "primary"
    readonly property bool _dng:      variant === "danger"
    readonly property bool _out:      variant === "outline"
    readonly property bool _ghost:    variant === "ghost"

    // ── 尺寸 (icon-only 模式下不设最小宽度) ──
    readonly property bool _iconOnly: iconSource !== "" && text === ""
    implicitWidth:  _iconOnly ? contentRow.implicitWidth : Math.max(64, contentRow.implicitWidth + 28)
    implicitHeight: _iconOnly ? contentRow.implicitHeight : Math.max(32, btnText.implicitHeight + 16)

    // ── 背景色 ──
    color: root.customBg.a > 0 ? root.customBg :
           !enabled      ? Theme.border_default :
           _pri && pressed   ? Theme.accent_press :
           _pri && hovered   ? Theme.accent_hover :
           _pri              ? Theme.accent :
           _dng && pressed   ? Theme.btn_danger_press :
           _dng && hovered   ? Theme.danger_fg :
           _dng              ? Theme.danger :
           _out && pressed   ? Theme.accent_press :
           _out && hovered   ? Theme.accent_hover :
           _out              ? Theme.bg_card :
           _ghost && pressed ? Theme.border_standard :
           _ghost && hovered ? Theme.border_default :
           _ghost            ? "transparent" :
           pressed           ? Theme.border_emphasis :
           hovered           ? Theme.bg_card :
                                Theme.bg_input

    // ── 边框 ──
    border.width: _out && !enabled ? 1 :
                  _out              ? root.borderWidth :
                  _ghost && hovered ? 1 :
                  _ghost            ? 0 :
                  !_pri && !_dng    ? 1 : 0

    border.color: !enabled        ? Theme.border_default :
                  _out             ? Theme.accent :
                  _ghost && hovered ? Theme.border_default :
                  !_pri && !_dng   ? Theme.border_default :
                                     "transparent"

    // ── 文字色 —— "transparent" 表示自动计算 ──
    property color customTextColor: "transparent"

    readonly property color textColor:
        root.customTextColor.a > 0 ? root.customTextColor :
        !enabled  ? Theme.text_disabled :
        _pri      ? Theme.text_bright :
        _dng      ? Theme.text_bright :
        _out      ? Theme.accent_text :
        _ghost    ? Theme.text_secondary :
                    Theme.text_primary

    // ── 图标色 ── transparent 时跟随 textColor
    readonly property color _iconColor:
        root.iconColor.a > 0 ? root.iconColor : root.textColor

    // ── 动画 ──
    Behavior on color          { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color   { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    scale: pressed ? 0.96 : (hovered ? 1.03 : 1.0)
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    // ── 内容 ──
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.iconSource !== "" && root.text !== "" ? 8 : 0

        // SVG 图标 — 高分辨率渲染，消除锯齿
        Image {
            id: iconImage
            visible: root.iconSource !== "" && status === Image.Ready
            source: root.iconSource
            sourceSize: Qt.size(256, 256)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: root.enabled ? (root.hovered || root.pressed ? 1.0 : 0.65) : 0.4
            Layout.preferredWidth:  Math.max(16, btnText.implicitHeight)
            Layout.preferredHeight: Math.max(16, btnText.implicitHeight)
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        Text {
            id: btnText
            visible: root.text !== ""
            text: root.text
            color: root.textColor
            font: root.font
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── 文字过渡动画 ── 文本变化时快速淡入淡出, 消除状态切换的卡顿感
    property string _textTracker: root.text
    property bool _textReady: false   // 跳过首次绑定, 避免首帧闪白
    on_TextTrackerChanged: {
        if (!_textReady) { _textReady = true; return }
        if (root.text === "") return
        textFade.start()
    }

    SequentialAnimation {
        id: textFade
        PropertyAction { target: contentRow; property: "opacity"; value: 0.35 }
        NumberAnimation { target: contentRow; property: "opacity"; to: 1.0; duration: 260; easing.type: Easing.OutCubic }
    }

    // ── 内容脉动 (2026-09-03): pulsing=true 时闪电图标做充电脉动, 仅加载/后台任务指示;
    // 图标自身 scale, 与按钮 root 的 hover/pressed scale 无关, 互不干扰 ──
    SequentialAnimation {
        id: contentPulse
        running: root.pulsing
        loops: Animation.Infinite
        NumberAnimation { target: iconImage; property: "scale"; to: 1.22; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: iconImage; property: "scale"; to: 1.0;  duration: 220; easing.type: Easing.OutCubic }
    }

    // ── 交互 ──
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
