import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: root

    property int contentMaxWidth: 560
    property int contentAlignment: Qt.AlignLeft
    property color color: "transparent"
    property int contentMargin: 32

    default property alias contentData: column.data

    Rectangle {
        anchors.fill: parent
        color: root.color
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight + 60
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: SuretyScrollBar { }

        // 失焦背景：放 ColumnLayout 下面，填满整个 content 区域
        MouseArea {
            anchors.fill: parent
            onClicked: root.forceActiveFocus()
        }

        ColumnLayout {
            id: column
            width: parent.width - root.contentMargin * 2

            anchors.left: root.contentAlignment === Qt.AlignLeft ? parent.left : undefined
            anchors.leftMargin: root.contentAlignment === Qt.AlignLeft ? root.contentMargin : 0
            anchors.horizontalCenter: root.contentAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
            anchors.top: parent.top
            anchors.topMargin: root.contentMargin
            spacing: 0
        }
    }

}
