import QtQuick
import "../../theme"
import QtQuick.Controls

// ═══════════════════════════════════════════════════════════════════════════════
//  SuretyTextArea — GitHub Primer Dark 规范多行输入框
//
//  用法:
//    SuretyTextArea {
//        label:       "描述"
//        placeholder: "请输入内容..."
//        maxLength:   500
//        showCounter: true
//        minHeight:   140
//    }
// ═══════════════════════════════════════════════════════════════════════════════
Rectangle {
    id: root

    // ── 公开 API ──
    property alias  text:           textArea.text
    property alias  readOnly:       textArea.readOnly
    property alias  font:           textArea.font
    property alias  hovered:        hoverArea.containsMouse
    property alias  cursorPosition: textArea.cursorPosition

    property string label:        ""
    property string placeholder:  ""
    property string helperText:   ""
    property int    maxLength:    0           // 0 = 不限制
    property int    minHeight:    120
    property int    maxHeight:    0           // 0 = 自动撑开，不限制
    property bool   isError:      false
    property bool   showCounter:  false

    // ── 隐式尺寸（供 Layout 使用）──
    implicitWidth: 168
    implicitHeight: (labelText.visible ? labelText.height + 5 : 0)
                     + inputBox.height
                     + (footerRow.visible ? footerRow.implicitHeight + 4 : 0)

    color: "transparent"

    // ═══════════════════════════════════════════════════════════════════════
    //  设计 Token（GitHub Primer Dark）
    // ═══════════════════════════════════════════════════════════════════════
    readonly property color _bg:            Theme.bg_page
    readonly property color _bgReadOnly:    Theme.input_readonly_bg
    readonly property color _border:        Theme.border_default
    readonly property color _borderHover:   Theme.border_standard
    readonly property color _borderFocus:   Theme.accent
    readonly property color _borderError:   Theme.danger_fg
    readonly property color _text:          Theme.text_primary
    readonly property color _textReadOnly:  Theme.text_hint
    readonly property color _placeholder:   Theme.text_disabled
    readonly property color _helper:        Theme.text_secondary
    readonly property color _error:         Theme.danger_fg
    readonly property color _counter:       Theme.text_hint
    readonly property color _counterWarn:   Theme.warning_fg
    readonly property color _selection:     Theme.accent
    readonly property color _selectionFg:   Theme.text_bright

    // ═══════════════════════════════════════════════════════════════════════
    //  Label（可选）
    // ═══════════════════════════════════════════════════════════════════════
    Text {
        id: labelText
        anchors.left: parent.left
        anchors.top: parent.top
        visible: root.label !== ""
        text: root.label
        color: _helper
        font.pixelSize: 13
        font.weight: Font.Bold
        font.family: "JetBrains Mono"
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  输入区域容器
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        id: inputBox
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: labelText.visible ? labelText.bottom : parent.top
        anchors.topMargin: labelText.visible ? 6 : 0

        // 自动撑开高度，有上限时启用内部滚动
        readonly property real contentH: Math.max(textArea.implicitHeight, root.minHeight - 28)
        readonly property real idealH: contentH + 28
        height: root.maxHeight > 0 ? Math.min(idealH, root.maxHeight) : idealH

        radius: 4
        color: textArea.readOnly ? _bgReadOnly : _bg
        border.width: 1
        border.color: {
            if (root.isError)             return _borderError
            if (textArea.activeFocus)     return _borderFocus
            if (hoverArea.containsMouse)  return _borderHover
            return _border
        }
        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ── 聚焦 / 错误光环 ──
        Rectangle {
            id: glowRing
            anchors.fill: parent; anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: root.isError ? _borderError : _borderFocus
            opacity: (textArea.activeFocus || root.isError) ? 0.22 : 0.0
            visible: opacity > 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        // ── Hover 状态追踪（不拦截事件）──
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        // ── Placeholder ──
        Text {
            id: placeholderText
            anchors.left: parent.left;   anchors.right: parent.right
            anchors.top: parent.top;     anchors.bottom: parent.bottom
            anchors.leftMargin: 7;      anchors.rightMargin: 7
            anchors.topMargin: 7;       anchors.bottomMargin: 7
            text: root.placeholder
            color: _placeholder
            font: textArea.font
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            visible: textArea.text === "" && !textArea.activeFocus && !textArea.readOnly
        }

        // ── Flickable + TextArea（内部滚动）──
        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 0        // scrollbar 侧不留 margin
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            contentWidth:  textArea.contentWidth
            contentHeight: textArea.contentHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            TextArea.flickable: TextArea {
                id: textArea
                // 宽度跟随 Flickable，使自动换行生效
                width: flickable.width - 6  // 给 scrollbar 留空隙

                // 文字颜色
                color: readOnly ? _textReadOnly : _text
                font.pixelSize: 13
                font.family: Theme.fontFamily

                // 换行
                wrapMode: Text.WordWrap

                // 选中
                selectByMouse: true
                selectByKeyboard: true
                persistentSelection: true
                activeFocusOnPress: !readOnly
                selectionColor: _selection
                selectedTextColor: _selectionFg

                // 光标
                cursorVisible: activeFocus

                // 内边距归零（由 Flickable 的 margin 控制）
                padding: 0
                topPadding: 0;    bottomPadding: 0
                leftPadding: 0;   rightPadding: 0

                // 透明背景
                background: Rectangle { color: "transparent" }

                // ── 光标样式 ──
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: textArea.readOnly ? Qt.ArrowCursor : Qt.IBeamCursor
                }

                // ── 最大长度限制 ──
                onTextChanged: {
                    if (root.maxLength > 0 && text.length > root.maxLength) {
                        var p = cursorPosition
                        text = text.substring(0, root.maxLength)
                        cursorPosition = Math.min(p, root.maxLength)
                    }
                }

                // ── 键盘导航 ──
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) {
                        // 允许 Tab 键将焦点移出，但先尝试移动焦点到下一个控件
                        event.accepted = false
                    }
                }
            }

            // ── 竖向滚动条（自定义样式）──
            ScrollBar.vertical: ScrollBar {
                id: vScrollBar
                policy: ScrollBar.AsNeeded
                hoverEnabled: true

                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: Theme.text_hint
                    opacity: {
                        if (!vScrollBar.active && !vScrollBar.hovered) return 0.3
                        if (vScrollBar.hovered) return 0.7
                        return 0.5
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                background: Rectangle {
                    implicitWidth: 3
                    color: "transparent"
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  底部信息栏：helper text + 字数统计
    // ═══════════════════════════════════════════════════════════════════════
    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: inputBox.bottom
        anchors.topMargin: 3
        visible: root.isError || root.helperText !== ""
                 || (root.showCounter && root.maxLength > 0)

        // ── 左侧：help / error 文本 ──
        Text {
            id: helperLabel
            text: {
                if (root.isError) {
                    return root.helperText !== "" ? root.helperText : "输入内容有误，请检查"
                }
                return root.helperText
            }
            color: root.isError ? _error : _helper
            font.pixelSize: 11
            font.family: "JetBrains Mono"
            elide: Text.ElideRight
            width: parent.width - (counterLabel.visible ? counterLabel.implicitWidth + 8 : 0)
        }

        // 间距
        Item { width: 4; height: 1 }

        // ── 右侧：字数统计 ──
        Text {
            id: counterLabel
            visible: root.showCounter && root.maxLength > 0
            text: textArea.text.length + "/" + root.maxLength
            color: {
                var pct = textArea.text.length / root.maxLength
                if (pct >= 1.0)  return _error
                if (pct >= 0.9)  return _counterWarn
                return _counter
            }
            font.pixelSize: 11
            font.family: "JetBrains Mono"
            horizontalAlignment: Text.AlignRight
        }
    }
}
