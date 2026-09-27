import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  SectionHeader — 设置页分节标题
// ═══════════════════════════════════════════════════════════════════════════════
Item {
    id: root

    property string title:     ""
    property color  barColor:  Theme.accent
    property int    fontSize:  20

    width:  parent ? parent.width : 240
    implicitHeight: Math.max(21, root.fontSize + 7)

    Row {
        spacing: 6

        Rectangle {
            width: 3
            height: root.fontSize
            radius: 2
            color: root.barColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.title
            color: Theme.text_primary
            font.pixelSize: root.fontSize
            font.weight: Font.Bold
            font.family: "Microsoft YaHei UI"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
