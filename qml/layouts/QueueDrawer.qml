import QtQuick
import "../theme"
import "../mock"
import "../components/display"

// ═══════════════════════════════════════════════════════════════
//  QueueDrawer — 播放队列抽屉 (原版 MusicFree QueueDrawer 同构)
//   右侧滑入; 当前曲声纹指示; 双击跳曲; 行内移除; 清空队列
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property QtObject playback: null
    property bool open: false

    // ── 遮罩 (点击关闭) ──
    Rectangle {
        visible: root.open
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    // ── 面板 ──
    Rectangle {
        id: panel
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 320
        x: root.open ? parent.width - width : parent.width
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }   // 一次性滑入过场
        color: Theme.bg_page

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1
            color: Theme.border_default
        }

        // ── 头部 ──
        Item {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 56

            Column {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 2
                Text {
                    text: "播放队列"
                    font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                    color: Theme.text_primary
                }
                Text {
                    visible: playback.queue.count > 0
                    text: "共 " + playback.queue.count + " 首"
                    font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                    color: Theme.text_secondary
                }
            }

            Text {
                visible: playback.queue.count > 0
                anchors { right: closeBtn.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
                text: "清空"
                font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                color: Theme.accent_text
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: playback.clearQueue()
                }
            }

            IconImage {
                id: closeBtn
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/x.svg"
                color: Theme.text_secondary
                size: 14
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.open = false
                }
            }
        }

        Rectangle {
            anchors { top: parent.top; topMargin: 56; left: parent.left; right: parent.right }
            height: 1
            color: Theme.border_default
        }

        // ── 空态 ──
        StatusPlaceholder {
            anchors { top: parent.top; topMargin: 56; left: parent.left; right: parent.right; bottom: parent.bottom }
            visible: playback.queue.count === 0
            status: "empty"
            title: "队列还是空的"
            message: "双击歌曲列表或点击「播放全部」开始播放"
        }

        // ── 列表 ──
        ListView {
            id: queueList
            anchors { top: parent.top; topMargin: 57; left: parent.left; right: parent.right; bottom: parent.bottom }
            model: playback.queue
            clip: true
            visible: playback.queue.count > 0
            boundsBehavior: Flickable.StopAtBounds
            delegate: QueueRow
        }

        component QueueRow: Item {
            width: queueList.width
            height: 48
            property bool hover: rowMouse.containsMouse
            property bool current: index === playback.currentIndex

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
                    font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                    color: Theme.text_hint
                }
                SoundBars {
                    visible: current
                    anchors.centerIn: parent
                    running: playback.playing
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
                    font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: current ? Font.Bold : Font.Normal }
                    color: current ? Theme.accent_text : Theme.text_primary
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: (modelData.artist !== undefined ? modelData.artist : "") +
                          (modelData.platform !== undefined && modelData.platform !== "" ? " · " + modelData.platform : "")
                    font { family: "Microsoft YaHei UI"; pixelSize: 11 }
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
                    onClicked: playback.removeFromQueue(index)
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onDoubleClicked: playback.playIndex(index)
            }
        }
    }
}
