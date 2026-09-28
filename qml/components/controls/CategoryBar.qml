import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  CategoryBar — 设置页分类导航 (tab 下划线风格)
//  与 SuretyTagSelector 分段模式(值选择)语义区分: 本组件=视图切换导航,
//  选中项主题色文字+下划线指示器, 下划线宽度随文字, 切换收缩动画
// ═══════════════════════════════════════════════════════════════════════════════
Item {
    id: root
    property var model: []
    property int selectedIndex: 0
    signal tagSelected(int index)

    implicitWidth: row.width
    implicitHeight: 36

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            model: root.model
            delegate: Item {
                id: tab
                width: label.implicitWidth + 28
                height: root.implicitHeight
                property bool sel: index === root.selectedIndex

                Text {
                    id: label
                    anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
                    text: modelData.label
                    font { family: Theme.fontFamily; pixelSize: 14; weight: sel ? Font.Bold : Font.Normal }
                    color: sel ? Theme.accent_text
                         : (tabMouse.containsMouse ? Theme.text_primary : Theme.text_secondary)
                }
                // 下划线指示器 (宽度随文字, 切走收缩动画)
                Rectangle {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width: sel ? label.implicitWidth : 0
                    height: 2
                    radius: 1
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tagSelected(index)
                }
            }
        }
    }
}
