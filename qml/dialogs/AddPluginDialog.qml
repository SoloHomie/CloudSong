import QtQuick
import QtQuick.Dialogs
import QtQuick.Shapes
import "../theme"
import "../components/overlay"
import "../components/display"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  AddPluginDialog — 添加插件弹窗 (2026-10-01 用户拍板: 按钮改"添加插件",
//  弹窗内两种安装方式, 分段条切换:
//    ① 本地文件 — 拖入 .js / 点选本地文件
//    ② URL 下载 — 输入 http/https 链接, C++ 侧下载校验后落盘
//  安装结果: 成功即关 (面板顶部 opMsg 统一提示"已安装 xxx"),
//  失败留窗内显示原因 (不合法/被占用/下载失败/写入失败)
// ═══════════════════════════════════════════════════════════════
DialogShell {
    id: root
    title: "添加插件"
    subtitle: "拖入 .js 文件或通过链接下载 (MusicFree 协议)"
    width: 420

    property int mode: 0           // 0=本地文件 1=URL 下载
    property bool busy: false      // URL 下载中 (禁按钮防重复)
    property string errText: ""

    function tryInstall(path) { root.errText = ""; Plugins.installPluginFromFile(path) }
    function tryUrl() {
        root.errText = ""
        root.busy = true
        Plugins.installPluginFromUrl(urlField.text.trim())
    }

    Connections {
        target: Plugins
        function onPluginOpFinished(ok, msg) {
            if (!root.visible) return   // 面板侧的自有处理不受影响
            root.busy = false
            if (ok) root.close()
            else root.errText = msg
        }
    }

    content: Component {
        Item {
            implicitHeight: smoothH
            property real smoothH: body.height + 40
            Behavior on smoothH { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            clip: true

            Column {
                id: body
                anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20; top: parent.top; topMargin: 18 }
                spacing: 12

                // ── 安装方式切换 ──
                SuretyTagSelector {
                    id: modeSeg
                    anchors.horizontalCenter: parent.horizontalCenter
                    displayMode: "segment"
                    model: [ { label: "本地文件" }, { label: "URL 下载" } ]
                    onTagSelected: function(index) { root.mode = index; root.errText = "" }
                }

                // ── 方式① 拖放区 (拖入高亮; 虚线框用 Shape 画, 随尺寸动态拼路径) ──
                Rectangle {
                    id: dropZone
                    visible: root.mode === 0
                    width: parent.width
                    height: 104
                    radius: 8
                    color: dropArea.containsDrag
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                        : Theme.bg_input
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Shape {
                        anchors.fill: parent
                        ShapePath {
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [4, 3]
                            strokeWidth: 1
                            strokeColor: dropArea.containsDrag ? Theme.accent : Theme.border_default
                            fillColor: "transparent"
                            Behavior on strokeColor { ColorAnimation { duration: 150 } }
                            PathSvg {
                                // 圆角 8 的圆角矩形路径, 内缩 0.5 让 1px 描边完整落在框内。
                                // 拆成 4 边 + 4 角 8 个子路径: dash 相位按子路径重置,
                                // 四角弧段渲染完全一致 (单条连续路径会因相位漂移致各角参差)
                                path: "M 8.5 0.5 H " + (dropZone.width - 8.5)
                                    + " M " + (dropZone.width - 8.5) + " 0.5 A 8 8 0 0 1 " + (dropZone.width - 0.5) + " 8.5"
                                    + " M " + (dropZone.width - 0.5) + " 8.5 V " + (dropZone.height - 8.5)
                                    + " M " + (dropZone.width - 0.5) + " " + (dropZone.height - 8.5) + " A 8 8 0 0 1 " + (dropZone.width - 8.5) + " " + (dropZone.height - 0.5)
                                    + " M " + (dropZone.width - 8.5) + " " + (dropZone.height - 0.5) + " H 8.5"
                                    + " M 8.5 " + (dropZone.height - 0.5) + " A 8 8 0 0 1 0.5 " + (dropZone.height - 8.5)
                                    + " M 0.5 " + (dropZone.height - 8.5) + " V 8.5"
                                    + " M 0.5 8.5 A 8 8 0 0 1 8.5 0.5"
                            }
                        }
                    }

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

                // ── 方式② URL 下载行 ──
                Row {
                    visible: root.mode === 1
                    width: parent.width
                    spacing: 8

                    SuretyTextField {
                        id: urlField
                        width: parent.width - 98
                        placeholder: "https://…/plugin.js"
                        customBorder: Theme.border_standard   // 默认 neutral4 在弹窗底上太淡, 提一档
                        onAccepted: root.tryUrl()
                    }
                    SuretyBtn {
                        height: 30
                        width: 90
                        text: root.busy ? "下载中…" : "下载安装"
                        variant: "primary"
                        font.pixelSize: 12
                        enabled: !root.busy && urlField.text.trim() !== ""
                        onClicked: root.tryUrl()
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

                // ── 选择文件 (仅本地方式) ──
                SuretyBtn {
                    visible: root.mode === 0
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
