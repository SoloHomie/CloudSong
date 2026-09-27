import QtQuick
import "../../theme"

Rectangle {
    id: root

    property alias  text:               inputField.text
    property alias  readOnly:           inputField.readOnly
    property alias  font:               inputField.font
    property alias  echoMode:           inputField.echoMode
    property alias  validator:          inputField.validator
    property alias  inputMask:          inputField.inputMask
    property alias  horizontalAlignment: inputField.horizontalAlignment
    property int    placeholderHAlign: Text.AlignLeft
    property alias  acceptableInput:    inputField.acceptableInput
    property string label:              ""
    property string placeholder:        ""
    property bool   isError:            false
    property alias  hovered:            hoverArea.containsMouse
    property color  customBg:           "transparent"
    property color  customBorder:       "transparent"

    signal accepted()
    signal editingFinished()

    property int minContentWidth: 52
    // 输入内容左右留白 (2026-09-28 用户: 原 7 太小); PasswordField 会加大右侧给眼睛图标让位
    property int contentLeftPadding: 12
    property int contentRightPadding: 12
    implicitWidth: Math.max(minContentWidth, inputField.contentWidth + 20)
    implicitHeight: labelText.visible ? labelText.implicitHeight + 4 + 36 : 36
    color: "transparent"

    // ---- 标签 ----
    Text {
        id: labelText
        anchors.left: parent.left
        anchors.top: parent.top
        visible: root.label !== ""
        text: root.label
        color: Theme.text_secondary
        font.pixelSize: 13
        font.weight: Font.Bold
        font.family: "JetBrains Mono"
    }

    // ---- 输入框容器 ----
    Rectangle {
        id: inputBox
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: labelText.visible ? labelText.bottom : parent.top
        anchors.topMargin: labelText.visible ? 6 : (parent.height - 32) / 2
        height: 32
        radius: 8
        color: root.customBg !== "transparent" ? root.customBg
               : (inputField.readOnly ? Theme.input_readonly_bg : Theme.bg_page)
        border.width: 1
        border.color: {
            if (root.customBorder !== "transparent") return root.customBorder
            if (root.isError)                        return Theme.danger_fg
            if (inputField.activeFocus)              return Theme.accent
            return Theme.border_default
        }
        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // focus / error glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: root.isError ? Theme.danger_fg : Theme.accent
            opacity: (inputField.activeFocus || root.isError) ? 0.22 : 0.0
            visible: opacity > 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        // hover 层 — 声明在 TextInput 之前, 事件后到达, 只负责 hover
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        // placeholder
        Text {
            anchors.fill: parent
            anchors.leftMargin: root.contentLeftPadding
            anchors.rightMargin: root.contentRightPadding
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: root.placeholderHAlign
            text: root.placeholder
            color: Theme.text_disabled
            font: inputField.font
            elide: Text.ElideRight
            visible: inputField.text === "" && !inputField.activeFocus
        }

        // 原生 TextInput — 声明在后, 事件先到达 (原生行为完整保留)
        TextInput {
            id: inputField
            anchors.fill: parent
            anchors.leftMargin: root.contentLeftPadding
            anchors.rightMargin: root.contentRightPadding
            color: readOnly ? Theme.text_hint : Theme.text_primary
            font.pixelSize: 14
            font.weight: Font.Bold
            font.family: "Microsoft YaHei UI"
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            activeFocusOnPress: !readOnly
            selectionColor: Theme.accent
            selectedTextColor: Theme.text_bright
            cursorVisible: activeFocus

            onAccepted: {
                root.accepted()
                inputField.focus = false
            }
            onEditingFinished: root.editingFinished()

            // cursor shape only — 不拦截事件
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: inputField.readOnly ? Qt.ArrowCursor : Qt.IBeamCursor
            }
        }
    }

    // ---- error ----
    Text {
        anchors.left: parent.left
        anchors.top: inputBox.bottom
        anchors.topMargin: 3
        visible: root.isError
        text: "Invalid input"
        color: Theme.danger_fg
        font.pixelSize: 11
        font.family: "JetBrains Mono"
    }
}
