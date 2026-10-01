import QtQuick
import QtQuick.Layouts
import "../theme"
import "../mock"
import "../components/buttons"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  DeleteSheetDialog — 删除自建歌单确认弹窗 (歌单详情页"更多"菜单)
//  确认即 MockData.removeCreatedSheet, 侧栏与我的歌单页经变更信号联动
// ═══════════════════════════════════════════════════════════════
DialogShell {
    id: root
    title: "删除歌单"
    width: 340

    property string sheetId: ""
    property string sheetTitle: ""

    content: Component {
        Item {
            implicitHeight: body.implicitHeight + 38

            ColumnLayout {
                id: body
                anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 18; bottomMargin: 20 }
                spacing: 14
                Text {
                    Layout.fillWidth: true
                    text: "确定删除歌单「" + root.sheetTitle + "」吗？此操作不可恢复。"
                    wrapMode: Text.Wrap
                    font { family: Theme.fontFamily; pixelSize: 13 }
                    color: Theme.text_primary
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10
                    SuretyBtn {
                        Layout.preferredHeight: 28
                        text: "取消"
                        variant: "ghost"
                        font.pixelSize: 12
                        onClicked: root.close()
                    }
                    SuretyBtn {
                        Layout.preferredHeight: 28
                        text: "删除"
                        variant: "danger"
                        font.pixelSize: 12
                        onClicked: { MockData.removeCreatedSheet(root.sheetId); root.close() }
                    }
                }
            }
        }
    }
}
