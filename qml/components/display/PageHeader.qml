import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  PageHeader — 页面标题行 (左: 标题+副标题; 右: 操作插槽)
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    height: 64
    property string title: ""
    property string subtitle: ""
    default property alias content: rightRow.data

    Column {
        anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            text: root.title
            font { family: "Microsoft YaHei UI"; pixelSize: 20; weight: Font.Bold }
            color: Theme.text_primary
        }
        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            font { family: "Microsoft YaHei UI"; pixelSize: 12 }
            color: Theme.text_secondary
        }
    }

    Row {
        id: rightRow
        anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 10
    }
}
