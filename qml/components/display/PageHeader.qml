import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  PageHeader — 页面标题行 (左: 标题+副标题; 右: 操作插槽)
//  width 默认撑满父宽: 裸放(不写 anchors)时右操作区锚 parent.right
//  才不会飞出页面 (2026-09-28 本地音乐"扫描本地"按钮跑出页面实锤)
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    height: 64
    width: parent.width
    property string title: ""
    property string subtitle: ""
    default property alias content: rightRow.data

    Column {
        anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            text: root.title
            font { family: Theme.fontFamily; pixelSize: 21; weight: Font.Bold }
            color: Theme.text_primary
        }
        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_secondary
        }
    }

    Row {
        id: rightRow
        anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 10
    }
}
