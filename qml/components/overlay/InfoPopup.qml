import QtQuick
import QtQuick.Layouts
import "../buttons"

// ═══════════════════════════════════════════════════════════════════════════════
//  InfoPopup — 居中信息弹窗 (统一窗体 DialogShell: 标题 + 自定义内容 + 底部按钮)
//  用法:
//    InfoPopup { id: myPopup; title: "帮助"; content: Component { ... } }
//    myPopup.open()
// ═══════════════════════════════════════════════════════════════════════════════

DialogShell {
    id: root
    property Component popupContent: null   // 自定义内容区
    property bool hideDefaultBtn: false     // 设为 true 隐藏默认"知道了"按钮
    property string extraText: ""           // 非空时在"知道了"左侧显示扩展按钮
    signal extraClicked()                   // 扩展按钮点击

    width: 322

    content: Component {
        Item {
            implicitHeight: body.implicitHeight + 38
            ColumnLayout {
                id: body
                anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 18; bottomMargin: 20 }
                spacing: 8

                // ── 自定义内容 ──
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: root.popupContent
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
}
