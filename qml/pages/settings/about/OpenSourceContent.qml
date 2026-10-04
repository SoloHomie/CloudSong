import QtQuick
import "../../../theme"

// ═══════════════════════════════════════════════════════════════
//  OpenSourceContent — "Open Source Notice" 折叠卡内容物
//  开源组件致谢列表 (行可点跳转)
//  2026-10-04 自 AboutSettings 抽离
// ═══════════════════════════════════════════════════════════════
Column {
    anchors { left: parent.left; right: parent.right }
    Repeater {
        model: [
            { n: "Qt Framework", u: "https://www.qt.io" },
            { n: "MS VC++ Runtime", u: "https://visualstudio.microsoft.com" }
        ]
        delegate: Rectangle {
            width: parent.width
            height: 36
            color: "transparent"
            Row {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8 }
                Column {
                    width: parent.width
                    spacing: 1
                    Text {
                        text: modelData.n
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_primary
                    }
                    Text {
                        text: modelData.u
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        color: Theme.accent_text
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(modelData.u)
            }
        }
    }
}
