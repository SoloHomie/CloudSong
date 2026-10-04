import QtQuick
import "../../theme"

Item {
    id: root
    implicitWidth: field.implicitWidth
    implicitHeight: field.implicitHeight

    property alias text: field.text
    property alias placeholder: field.placeholder
    property alias readOnly: field.readOnly
    property alias label: field.label
    property alias font: field.font
    property bool showPassword: false

    SuretyTextField {
        id: field
        anchors.fill: parent
        customBg: Theme.bg_input
        customBorder: Theme.border_standard
        echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
        contentRightPadding: 30   // 给眼睛图标让位 (16 宽 + 8 右距 + 6 间隙), 防密码文字压到图标下
    }

    // 眼睛按钮 (2026-09-28 用户: 原 10px 太小不清晰 → 16px + 大 sourceSize 高清重采样)
    Image {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 16; height: 16
        source: root.showPassword ? "qrc:/qt/qml/cloudsong/qml/assets/form/eye-open.svg" : "qrc:/qt/qml/cloudsong/qml/assets/form/eye-closed.svg"
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectFit
        smooth: true; antialiasing: true
        z: 1

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showPassword = !root.showPassword
        }
    }
}
