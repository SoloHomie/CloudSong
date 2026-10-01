import QtQuick
import QtQuick.Layouts
import "../theme"
import "../mock"
import "../components/buttons"
import "../components/controls"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  CreateSheetDialog — 新建歌单弹窗 (侧栏"创建的歌单"＋ / 我的歌单页"新建歌单"共用)
//  创建即写 MockData.createdSheets, 侧栏与我的歌单页经信号联动
//  (待 C++ SheetService 替换 MockData)
// ═══════════════════════════════════════════════════════════════
DialogShell {
    id: root
    title: "新建歌单"
    width: 360

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
                        text: "创建"
                        variant: "primary"
                        font.pixelSize: 12
                        onClicked: submit()
                    }
                }
            }

            function submit() {
                var n = nameInput.text.trim()
                if (n !== "") MockData.addCreatedSheet(n)
                nameInput.text = ""
                root.close()
            }
        }
    }
}
