import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  TabBar — 下划线标签页 (文本 tab, 选中态 accent 下划线)
//  用法: TabBar { items: [{text:"排行榜"},{text:"推荐歌单"}]; onActivated: {...} }
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    height: 36
    property var items: []          // [{text}] JS 数组
    property int activeIndex: 0
    signal activated(int index)

    Row {
        anchors.fill: parent
        spacing: 26

        Repeater {
            model: root.items
            delegate: Item {
                width: tabText.implicitWidth + 8
                height: parent.height
                property bool active: index === root.activeIndex

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData.text
                    font { family: Theme.fontFamily; pixelSize: 14; weight: active ? Font.Bold : Font.Normal }
                    color: active ? Theme.text_primary : Theme.text_secondary
                }
                Rectangle {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width: tabText.implicitWidth
                    height: 2.5
                    radius: 1.25
                    color: Theme.accent
                    visible: active
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (index === root.activeIndex) return
                        root.activeIndex = index
                        root.activated(index)
                    }
                }
            }
        }
    }
}
