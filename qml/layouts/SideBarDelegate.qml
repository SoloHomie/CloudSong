import QtQuick
import QtQuick.Effects
import "../theme"
import "../components/display"

Rectangle {
    id: root
    width: parent ? parent.width : 80
    height: 30
    radius: 5

    property string iconImage: ""
    property string sideText:  ""
    property bool   isSelected: false
    property bool   showBeta: false
    property string badgeText: "BETA"
    property bool   animatedBars: false   // 图标位显示声纹动画 (推荐) 替代静态 Image

    signal clicked()

    color: {
        if (isSelected)              return Qt.rgba(0.12, 0.44, 0.92, 0.15)
        if (mouseArea.containsMouse) return Qt.rgba(0.12, 0.44, 0.92, 0.08)
        return "transparent"
    }

    border.width: isSelected ? 1 : 0
    border.color: isSelected ? Qt.rgba(0.12, 0.44, 0.92, 0.50) : "transparent"
    Behavior on color       { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3; height: 12; radius: 2
        color: Theme.accent
        visible: isSelected
    }

    Row {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 6

        SoundBars {
            visible: animatedBars
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
        }
        Image {
            id: sideIcon
            visible: !animatedBars
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            source: iconImage
            sourceSize: Qt.size(32, 32)
            fillMode: Image.PreserveAspectFit
            smooth: true
            layer.enabled: !Theme.isDark
            layer.effect: MultiEffect {
                colorizationColor: Theme.isDark ? "transparent" : Theme.text_secondary
                colorization: Theme.isDark ? 0.0 : 1.0
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: sideText
            font.pixelSize: 13; font.weight: Font.Bold
            font.family: "Microsoft YaHei UI"
            color: isSelected ? Theme.accent_text
                 : mouseArea.containsMouse ? Theme.text_primary
                 : Theme.text_secondary
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            visible: root.showBeta
            anchors.verticalCenter: parent.verticalCenter
            width: betaText.implicitWidth + 8; height: 13; radius: 3
            color: Qt.rgba(Theme.purple_fg.r, Theme.purple_fg.g, Theme.purple_fg.b, 0.15)
            border { width: 1; color: Theme.purple }
            Text {
                id: betaText
                anchors.centerIn: parent
                text: root.badgeText
                color: Theme.purple_fg
                font.pixelSize: 8; font.weight: Font.Bold
                font.family: "JetBrains Mono"
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
