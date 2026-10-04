import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../theme"
import "../controls"

// ═══════════════════════════════════════════════════════════════════════════════
//  SuretyCollapse — 可折叠面板
//  高度自适应内容，标题/副标题由外部定义
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // ── 公共属性 ──
    property string title: ""
    property string subtitle: ""
    property int titleFontSize: 16
    property bool titleBold: true
    property int titleSpacing: 4
    property int titlePadding: 8
    property int subtitleFontSize: 13
    property int step: -1
    property int stepFontSize: 12
    property bool open: false
    property int headerHeight: 36
    property int animationDuration: 240
    property bool switchVisible: false
    property alias switchChecked: headerSwitch.checked
    property bool shortcutVisible: false
    property alias shortcutKey: shortcutChip.boundKey
    property alias headerSlot: headerExtra.data
    property alias content: bodyLoader.sourceComponent

    signal toggled(bool open)
    signal switchToggled(bool checked)
    signal shortcutKeyBound(string key)

    implicitWidth: parent ? parent.width - 8 : 300
    implicitHeight: card.height

    // ── 动画 ──
    property real _bodyHeight: 0
    Behavior on _bodyHeight { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

    function _syncHeight() {
        _bodyHeight = (root.open && bodyLoader.item) ? bodyLoader.item.implicitHeight : 0
    }

    onOpenChanged: _syncHeight()
    Component.onCompleted: _syncHeight()
    Connections {
        target: bodyLoader.item
        function onImplicitHeightChanged() { root._syncHeight() }
    }

    // ═══ 卡片 ═══
    Rectangle {
        id: card
        width: parent.width
        height: childrenRect.height
        color: Theme.bg_page
        border.color: Theme.border_standard
        radius: 5

        ColumnLayout {
            width: parent.width
            spacing: 0

            // ── 头部 ──
            Rectangle {
                id: headerBg
                Layout.fillWidth: true
                Layout.preferredHeight: headerContent.implicitHeight + card.radius
                color: "transparent"
                radius: card.radius

                // hover 层 — 用 opacity 动画避免灰色闪烁
                Rectangle {
                    id: hoverOverlay
                    anchors.fill: parent
                    radius: card.radius
                    color: headerMouse.pressed ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                         : Theme.hover_bg
                    opacity: headerMouse.containsMouse || headerMouse.pressed ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                // 左侧 hover 指示条
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: root.open ? parent.bottom : parent.bottom
                    anchors.topMargin: 4
                    anchors.bottomMargin: root.open ? 0 : 4
                    width: 3
                    radius: 1.5
                    color: Theme.accent
                    opacity: headerMouse.containsMouse ? 0.6 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                // 展开时抹平底部圆角
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: card.radius
                    color: headerMouse.containsMouse || headerMouse.pressed ? hoverOverlay.color : "transparent"
                    visible: root.open
                }

                RowLayout {
                    id: headerContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 7

                    // 启停开关
                    SuretySwitch {
                        id: headerSwitch
                        visible: root.switchVisible
                        checked: false
                        Layout.preferredHeight: 20
                        trackWidth: 38
                        Layout.alignment: Qt.AlignVCenter
                        onToggled: root.switchToggled(checked)
                    }

                    // 快捷键
                    KeyBindChip {
                        id: shortcutChip
                        visible: root.shortcutVisible
                        Layout.alignment: Qt.AlignVCenter
                        onKeyBound: root.shortcutKeyBound(key)
                    }

                    // 序号
                    Rectangle {
                        Layout.preferredWidth: 16; Layout.preferredHeight: 16; radius: 8
                        color: root.step === 1 ? Theme.accent : "transparent"
                        border.width: root.step === 1 ? 0 : 1
                        border.color: Theme.border_standard
                        visible: root.step >= 1
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent; text: root.step
                            color: root.step === 1 ? Theme.text_bright : Theme.text_secondary 
                            font.pixelSize: root.stepFontSize; font.weight: Font.Bold
                            font.family: Theme.fontFamily
                        }
                    }

                    // 标题区 + 点击折叠
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: root.titlePadding
                        spacing: root.titleSpacing
                        Text {
                            Layout.fillWidth: true; text: root.title
                            color: Theme.text_primary
                            font.pixelSize: root.titleFontSize
                            font.weight: root.titleBold ? Font.Bold : Font.Normal
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.subtitle; color: Theme.text_hint
                            font.pixelSize: root.subtitleFontSize
                            font.family: Theme.fontFamily
                            wrapMode: Text.WordWrap
                            visible: root.subtitle !== ""
                        }
                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: { root.open = !root.open; root.toggled(root.open) }
                        }
                    }

                    // 头部右侧插槽
                    Row { id: headerExtra; spacing: 4; Layout.alignment: Qt.AlignVCenter }

                    // 展开箭头 + 点击折叠
                    Item {
                        id: arrowBox
                        Layout.preferredWidth: 20; Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignVCenter
                        scale: arrowMouse.pressed ? 0.85 : (arrowMouse.containsMouse ? 1.15 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        Image {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/arrow-up.svg"
                            fillMode: Image.PreserveAspectFit
                            rotation: root.open ? 180 : 90
                            Behavior on rotation { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }
                            layer.enabled: !Theme.isDark
                            layer.effect: MultiEffect {
                                colorizationColor: arrowMouse.containsMouse ? Theme.accent : Theme.text_secondary
                                colorization: 1.0
                            }
                        }
                        MouseArea {
                            id: arrowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.open = !root.open; root.toggled(root.open) }
                        }
                    }
                }

                // hover 背景 (放在最后，不拦截事件)
                MouseArea {
                    id: headerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.ArrowCursor
                }
            }

            // ── 内容区 ──
            Loader {
                id: bodyLoader
                Layout.fillWidth: true
                Layout.preferredHeight: root._bodyHeight
                clip: true
                onItemChanged: if (item) root._syncHeight()
            }
        }
    }
}
