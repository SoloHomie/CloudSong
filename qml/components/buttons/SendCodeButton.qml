import QtQuick
import "../../theme"

Rectangle {
    id: root
    implicitWidth: 91; implicitHeight: 32
    radius: 6

    property int  countdown: 0
    property bool sending:   false
    signal clicked()

    readonly property bool _disabled: countdown > 0 || sending

    color: {
        if (_disabled) return Theme.border_default
        if (btnHover.containsMouse) return Theme.accent_hover
        return Theme.accent
    }
    border.width: 1
    border.color: _disabled ? Theme.border_standard : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: sending ? "发送中..." : (countdown > 0 ? countdown + "s 后重发" : "发送验证码")
        color: _disabled ? Theme.text_disabled : Theme.text_bright
        font.pixelSize: 12; font.weight: Font.Bold
        font.family: "Microsoft YaHei UI"
    }

    MouseArea {
        id: btnHover
        anchors.fill: parent; hoverEnabled: true
        cursorShape: _disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        enabled: !_disabled
        onClicked: root.clicked()
    }
}
