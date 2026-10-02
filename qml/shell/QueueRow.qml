import QtQuick
import "../theme"
import "../components/display"

// ═══════════════════════════════════════════════════════════════
//  QueueRow — 播放队列行 (当前曲声纹 / 双击跳曲 / 行内移除)
//  2026-10-02 自 QueueDrawer 内联组件提取; playback 由宿主注入
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    width: parent.width
    height: 48
    required property int index
    required property var modelData
    property QtObject playback: null
    property bool hover: rowMouse.containsMouse
    property bool current: playback !== null && index === playback.currentIndex

    Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }

    // 指示区: 当前曲=声纹, 其他=序号
    Item {
        x: 16
        width: 28
        height: parent.height
        Text {
            visible: !current
            anchors.centerIn: parent
            text: index + 1
            font { family: Theme.fontFamily; pixelSize: 12 }
            color: Theme.text_hint
        }
        SoundBars {
            visible: current
            anchors.centerIn: parent
            running: playback !== null && playback.playing
        }
    }

    // 信息
    Column {
        x: 52
        width: parent.width - 52 - 44
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: modelData.title !== undefined ? modelData.title : ""
            font { family: Theme.fontFamily; pixelSize: 13; weight: current ? Font.Bold : Font.Normal }
            color: current ? Theme.accent_text : Theme.text_primary
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: (modelData.artist !== undefined ? modelData.artist : "") +
                  (modelData.platform !== undefined && modelData.platform !== "" ? " · " + modelData.platform : "")
            font { family: Theme.fontFamily; pixelSize: 11 }
            color: Theme.text_secondary
        }
    }

    // 移除
    IconImage {
        visible: hover
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/x.svg"
        color: Theme.text_hint
        size: 12
        MouseArea {
            z: 1   // 行级 rowMouse 声明在后会压住本图标, 抬升 z 才能收到点击
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (playback !== null) playback.removeFromQueue(index)
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onDoubleClicked: if (playback !== null) playback.playIndex(index)
    }
}
