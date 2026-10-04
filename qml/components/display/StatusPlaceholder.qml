import QtQuick
import "../../theme"
import "../buttons"

// ──────────────────────────────────────────────────────────────
//  StatusPlaceholder — 三态占位 (加载中 / 空态 / 错误)
//  空态必有出口: actionText 显示为按钮, 点击发 actionRequested
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property string status: "empty"     // empty | loading | error
    property string title: ""
    property string message: ""
    property string actionText: ""
    signal actionRequested()

    Column {
        anchors.centerIn: parent
        spacing: 10
        width: Math.min(360, parent.width - 48)

        LoadingDots {
            anchors.horizontalCenter: parent.horizontalCenter
            running: root.status === "loading"
            visible: root.status === "loading"
            dotColor: Theme.accent
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.title !== ""
            text: root.title
            font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
            color: Theme.text_primary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.message !== ""
            text: root.message
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_secondary
        }

        SuretyBtn {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionText !== ""
            height: 30
            text: root.actionText
            variant: "outline"
            font.pixelSize: 12
            onClicked: root.actionRequested()
        }
    }
}
