import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../buttons"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 140
    radius: 8

    property var plan: ({})

    color: Theme.bg_card
    border { width: 1; color: Theme.border_default }

    signal subscribeClicked()

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: plan.name || ""
            color: Theme.text_secondary
            font { pixelSize: 12; weight: Font.Bold; family: Theme.fontFamily }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "¥" + ((plan.amount || 0) / 100).toFixed(0)
            color: Theme.text_primary
            font { pixelSize: 24; weight: Font.Bold; family: Theme.fontFamily }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (plan.days || 0) + " 天"
            color: Theme.text_hint
            font { pixelSize: 11; family: Theme.fontFamily }
        }

        SuretyBtn {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.topMargin: 8
            text: "订阅"
            variant: "primary"
            font.pixelSize: 12; font.weight: Font.Bold
            onClicked: root.subscribeClicked()
        }
    }
}
