import QtQuick
import QtQuick.Dialogs
import "../theme"
import "../components/overlay"
import "../components/display"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  AddPluginDialog — 添加插件弹窗 (2026-10-01 用户拍板: 按钮改"添加插件",
//  弹窗内可拖入 .js 文件 / 点选本地文件)
//  安装结果: 成功即关 (面板顶部 opMsg 统一提示"已安装 xxx"),
//  失败留窗内显示原因 (不合法/被占用/复制失败)
// ═══════════════════════════════════════════════════════════════
DialogShell {
    id: root
    title: "添加插件"
    subtitle: "拖入或选择 .js 插件文件 (MusicFree 协议)"
    width: 420

    property string errText: ""
    function tryInstall(path) { root.errText = ""; Plugins.installPluginFromFile(path) }

    Connections {
        target: Plugins
        function onPluginOpFinished(ok, msg) {
            if (!root.visible) return   // 面板侧的自有处理不受影响
            if (ok) root.close()
            else root.errText = msg
        }
    }

    content: Component {
        Item {
            implicitHeight: body.height + 40
            clip: true

            Column {
                id: body
                anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20; top: parent.top; topMargin: 18 }
                spacing: 12

                // ── 拖放区 (拖入高亮) ──
                Rectangle {
                    width: parent.width
                    height: 104
                    radius: 8
                    color: dropArea.containsDrag
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                        : Theme.bg_input
                    border {
                        width: 1
                        color: dropArea.containsDrag ? Theme.accent : Theme.border_default
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        onEntered: function(drag) { if (!drag.hasUrls) drag.accepted = false }
                        onDropped: function(drop) {
                            if (drop.urls.length > 0) root.tryInstall(String(drop.urls[0]))
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 22
                            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
                            color: dropArea.containsDrag ? Theme.accent : Theme.text_hint
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dropArea.containsDrag ? "松开以安装" : "拖入 .js 文件到此处"
                            font { family: Theme.fontFamily; pixelSize: 12 }
                            color: dropArea.containsDrag ? Theme.accent : Theme.text_secondary
                        }
                    }
                }

                // ── 失败原因 ──
                Text {
                    width: parent.width
                    visible: root.errText !== ""
                    text: root.errText
                    elide: Text.ElideRight
                    font { family: Theme.fontFamily; pixelSize: 11 }
                    color: Theme.danger
                }

                // ── 选择文件 ──
                SuretyBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 30
                    text: "选择文件"
                    variant: "ghost"
                    font.pixelSize: 12
                    onClicked: fileDialog.open()
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "选择插件文件"
        nameFilters: ["JavaScript 插件 (*.js)"]
        onAccepted: root.tryInstall(String(selectedFile))
    }
}
