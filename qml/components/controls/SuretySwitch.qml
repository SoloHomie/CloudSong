import QtQuick
import "../../theme"

//=============================================================================
// MySwitch — GitHub Primer Dark 风格可缩放开关
// 用法: MySwitch { width: 24; height: 14; checked: true; onToggled: {...} }
//=============================================================================
Item {
    id: root

    // ---- 公共属性 ----
    property bool   checked: false
    property bool   enabled: true
    property string label: ""
    property int    labelFontSize: 0
    property int    labelWidth: 0
    property int    trackWidth: 44

    signal toggled(bool checked)

    implicitWidth:  labelText.visible ? labelText.width + 9 + trackWidth : trackWidth
    implicitHeight: Math.max(labelText.implicitHeight, trackHeight)
    readonly property real trackHeight: Math.max(22, root.height)
    readonly property real knobSize:    trackHeight - 6
    readonly property real knobRadius:  knobSize / 2
    readonly property real trackRadius: trackHeight / 2
    readonly property real padding:     3

    // ---- 状态 ----
    readonly property bool _on:       checked && enabled
    readonly property bool _off:      !checked && enabled
    readonly property bool _disabled: !enabled

    // ---- 颜色 (GitHub Primer Dark 硬编码) ----
    readonly property color clr_track_off:      Theme.bg_input   // canvas.inset
    readonly property color clr_track_on:       Theme.accent   // accent.emphasis
    readonly property color clr_track_disabled: Theme.border_default   // control.disabled

    readonly property color clr_border_off:        Theme.border_standard   // border.default
    readonly property color clr_border_off_hover:  Theme.text_disabled   // border.emphasis
    readonly property color clr_border_on:         Theme.accent   // accent.emphasis
    readonly property color clr_border_on_hover:   Theme.accent_hover   // blue.4
    readonly property color clr_border_disabled:   Theme.border_default   // border.muted

    readonly property color clr_knob_off:      Theme.text_secondary   // fg.muted
    readonly property color clr_knob_on:       Theme.text_bright   // fg.onEmphasis
    readonly property color clr_knob_disabled: Theme.text_disabled   // disabled text

    readonly property color clr_label:        Theme.text_primary   // fg.default
    readonly property color clr_label_disabled: Theme.text_disabled

    // ---- 交互 ----
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    TapHandler {
        enabled: root.enabled
        onTapped: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }

    // ---- 可选标签 ----
    Text {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.enabled ? clr_label : clr_label_disabled
        font.family: Theme.fontFamily
        font.pixelSize: root.labelFontSize > 0 ? root.labelFontSize : Math.max(10, root.height * 0.58)
        visible: root.label !== ""
        width: root.labelWidth > 0 ? root.labelWidth : implicitWidth
        elide: Text.ElideRight
    }

    // ---- 滑动轨道 ----
    Rectangle {
        id: track
        anchors.left: labelText.visible ? labelText.right : parent.left
        anchors.leftMargin: labelText.visible ? 12 : 0
        anchors.verticalCenter: parent.verticalCenter

        width:  trackWidth
        height: trackHeight
        radius: trackRadius

        color: {
            if (_disabled) return clr_track_disabled
            if (_on)       return clr_track_on
            return clr_track_off
        }

        border.width: 1
        border.color: {
            if (_disabled)                return clr_border_disabled
            if (hover.containsMouse && _on)     return clr_border_on_hover
            if (_on)                      return clr_border_on
            if (hover.containsMouse && _off)    return clr_border_off_hover
            return clr_border_off
        }

        Behavior on color        { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }

        // ---- 滑动圆钮 ----
        Rectangle {
            id: knob
            width:  knobSize
            height: knobSize
            radius: knobRadius
            anchors.verticalCenter: parent.verticalCenter

            x: _on ? track.width - knob.width - padding : padding

            color: {
                if (_disabled) return clr_knob_disabled
                if (_on)       return clr_knob_on
                return clr_knob_off
            }

            Behavior on x {
                NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.3 }
            }
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    // ---- 键盘 (禁用: SendInput 的 Space 会误触发) ----
    focusPolicy: Qt.NoFocus
}
