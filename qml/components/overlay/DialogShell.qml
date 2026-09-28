import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  DialogShell — 统一弹窗窗体 (2026-09-28 用户拍板: 窗体统一, 内容各异)
//   模态遮罩 + 圆角窗体 + 标题栏(标题/可选副标题/可选头部左件/可选关闭) + 内容槽 + 出现/关闭过渡
//   内容经 content 注入, 底部按钮由内容自带:
//     DialogShell { id: dlg; title: "新建歌单"; content: Component { ... } }
//  头/体布局沿用 AuthDialog 用户指定值: 上=下=左=20, 副标题不占位, 头部高度平滑收缩
//  注: 内容经 Loader 注入, 其 Layout 附加属性不生效 → 内容根部用 implicitHeight 驱动窗体高度
// ═══════════════════════════════════════════════════════════════════════════════
Popup {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showClose: true
    property Component headerLeft: null   // 注入头部左侧控件 (如 AuthDialog 重置页返回钮)
    property alias content: contentLoader.sourceComponent

    width: 380
    modal: true
    focus: true
    padding: 0
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: ModalOverlay {}

    // 统一出现/关闭过渡 (与 SuretyComboBox 下拉同款共享件)
    enter: EnterFade {}
    exit: ExitFade {}

    background: Rectangle {
        color: Theme.bg_page
        radius: 10
        border.width: 1
        border.color: Theme.border_standard
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── 头部 (标题块留白: 上=下=左=20; 副标题空串时不占位, 高度自然收缩走过渡) ──
        Item {
            Layout.fillWidth: true
            property real smoothH: titleCol.implicitHeight + 40
            Behavior on smoothH { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Layout.preferredHeight: smoothH

            Column {
                id: titleCol
                anchors.left: parent.left
                // 有头部左件时标题让位 (如重置页返回钮), 其余保持 左=20
                anchors.leftMargin: headerLeftLoader.item ? 48 : 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.title
                    color: Theme.text_primary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 16; font.weight: Font.Bold
                }
                Text {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    color: Theme.text_secondary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                }
            }

            // 头部左件 (注入方提供)
            Loader {
                id: headerLeftLoader
                sourceComponent: root.headerLeft
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            // 关闭钮 (2026-09-19 用户指定位置: 右上角)
            Rectangle {
                visible: root.showClose
                width: 26; height: 26; radius: 6
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.top: parent.top; anchors.topMargin: 14
                color: closeMouse.containsMouse ? Theme.hover_bg : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? Theme.text_primary : Theme.text_secondary
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                color: Theme.border_default
            }
        }

        // ── 内容 ──
        Loader {
            id: contentLoader
            Layout.fillWidth: true
        }
    }
}
