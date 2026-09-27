import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../buttons"

// ═══════════════════════════════════════════════════════════════════════════════
//  InfoPopup — 居中信息弹窗（ModalOverlay 遮罩）
//  标题 + 自定义内容区 + 关闭按钮
//  用法:
//    InfoPopup { id: myPopup; title: "帮助"; content: Component { ... } }
//    myPopup.open()
// ═══════════════════════════════════════════════════════════════════════════════

Popup {
    id: root
    property string title: ""
    property alias popupContent: contentLoader.sourceComponent
    property bool hideDefaultBtn: false  // 设为 true 隐藏默认"知道了"按钮
    property string extraText: ""        // 非空时在"知道了"左侧显示扩展按钮
    signal extraClicked()                // 扩展按钮点击

    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0
    background: null
    parent: Overlay.overlay
    width: 322
    height: Math.min(bodyLogic.implicitHeight + 48, parent ? parent.height - 80 : 520)
    x: Math.round((parent ? parent.width - width : 0) / 2)
    y: Math.round((parent ? parent.height - height : 0) / 2)

    Overlay.modal: ModalOverlay {}

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: Theme.bg_page
        border.width: 1
        border.color: Theme.border_default

        ColumnLayout {
            id: bodyLogic
            anchors { fill: parent; margins: 24 }
            spacing: 8

            // ── 标题 ──
            Text {
                text: root.title
                color: Theme.text_primary
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "Microsoft YaHei UI"
                Layout.fillWidth: true
            }

            // ── 分隔线 ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border_default
            }

            // ── 自定义内容 ──
            Loader {
                id: contentLoader
                Layout.fillWidth: true
            }

            // ── 底部按钮排: 扩展按钮靠左 + 关闭按钮靠右, 中间留空 ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                SuretyBtn {
                    visible: root.extraText !== ""
                    text: root.extraText
                    font.pixelSize: 12; font.weight: Font.Bold
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 88
                    cornerRadius: 6
                    onClicked: root.extraClicked()
                }
                Item { Layout.fillWidth: true }   // 中间间隔, 撑开两端
                SuretyBtn {
                    visible: !root.hideDefaultBtn
                    text: "知道了"
                    font.pixelSize: 12; font.weight: Font.Bold
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 72
                    cornerRadius: 6
                    onClicked: root.close()
                }
            }
        }
    }
}
