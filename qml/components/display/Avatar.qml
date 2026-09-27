import QtQuick
import "../../theme"

Rectangle {
    id: root
    width: 24; height: 24
    radius: 6

    property string name: ""
    property color accentColor: Theme.accent_text
    property real bgOpacity: 0.12
    property int fontSize: 15
    property string fontFamily: "Arial"

    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, root.bgOpacity)

    Text {
        anchors.centerIn: parent
        text: root.name.charAt(0)
        color: root.accentColor
        font.pixelSize: root.fontSize
        font.weight: Font.Bold
        font.family: root.fontFamily
    }
}
