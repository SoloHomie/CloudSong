import QtQuick
import QtQuick.Layouts
import "../theme"
import "../mock"
import "../components/buttons"
import "../components/controls"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  CreateSheetDialog — 新建/重命名歌单弹窗 (侧栏"创建的歌单"＋ / 我的歌单页"新建歌单" /
//  歌单详情页"重命名"共用; sheetId 非空 = 重命名模式)
//  数据写 MockData.createdSheets, 侧栏与我的歌单页经变更信号联动
//  (待 C++ SheetService 替换 MockData)
// ═══════════════════════════════════════════════════════════════
DialogShell {
    id: root
    title: sheetId !== "" ? "重命名歌单" : "新建歌单"
    width: 360

    property string sheetId: ""        // 非空 = 重命名模式
    property string initialName: ""    // 重命名模式打开时预填

    content: Component {
        Item {
            implicitHeight: body.implicitHeight + 38

            ColumnLayout {
                id: body
                anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 18; bottomMargin: 20 }
                spacing: 14
                SuretyTextField {
                    id: nameInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    placeholder: "歌单名称"
                    font.pixelSize: 13
                    customBg: Theme.bg_input
                    onAccepted: submit()
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10
                    SuretyBtn {
                        Layout.preferredHeight: 28
                        text: "取消"
                        variant: "ghost"
                        font.pixelSize: 12
                        onClicked: { nameInput.text = ""; root.close() }
                    }
                    SuretyBtn {
                        Layout.preferredHeight: 28
                        text: root.sheetId !== "" ? "保存" : "创建"
                        variant: "primary"
                        font.pixelSize: 12
                        onClicked: submit()
                    }
                }
            }

            function submit() {
                var n = nameInput.text.trim()
                if (n !== "")
                    root.sheetId !== "" ? MockData.renameCreatedSheet(root.sheetId, n)
                                        : MockData.addCreatedSheet(n)
                nameInput.text = ""
                root.close()
            }

            // 每次打开按模式初始化输入 (创建清空, 重命名预填现名)
            Connections {
                target: root
                function onOpened() { nameInput.text = root.sheetId !== "" ? root.initialName : "" }
            }
        }
    }
}
