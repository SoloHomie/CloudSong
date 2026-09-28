import QtQuick
import "../theme"

/// 占位页 (页面系统骨架; 后续按真实页面逐个替换成具体页面)
Rectangle {
    id: root
    color: Theme.bg_canvas

    property string title: ""

    Text {
        anchors.centerIn: parent
        text: root.title
        color: Theme.text_hint
        font { family: Theme.fontFamily; pixelSize: 14 }
    }
}
