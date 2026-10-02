import QtQuick
import "../theme"
import "../mock"
import "../components/display"

// ═══════════════════════════════════════════════════════════════
//  TaskbarBar — 任务栏播控条 (2026-10-02 用户拍板 MusicBar 同款:
//  贴靠任务栏顶端的常驻小窗, 封面/歌名·歌手 + 上一首/播放/下一首)
//  窗口管理 (贴靠/置顶/显隐/双击展开主窗) 全在 C++ TaskbarBarService,
//  QML 只画 UI; 播放状态来自 MockPlayback (待换 C++ PlaybackService);
//  歌词行待 M0 歌词服务落地后补 (MusicBar 第二行是当前歌词)
// ═══════════════════════════════════════════════════════════════
Window {
    id: bar
    objectName: "taskbarBar"
    width: 484
    height: 48
    visible: false                     // C++ dock() 后再显示
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg_window
        Rectangle {                     // 顶部 1px 边线 (MusicBar PanelBorder 同款)
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            color: Theme.border_standard
        }
    }

    Row {
        anchors { fill: parent; margins: 4 }
        spacing: 6

        // 信息区 (封面+歌名·歌手): 双击=展开/收起主窗口 (MusicBar 行为, C++ toggleMain)
        Item {
            id: infoArea
            width: bar.width - 8 - 40 - 32 - 40 - 32 - 6 * 5
            height: 40
            anchors.verticalCenter: parent.verticalCenter

            CoverArt {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 40
                height: 40
                radius: 7
                seed: MockPlayback.seed
            }

            Column {
                anchors { left: parent.left; leftMargin: 48; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 3

                // 歌名 · 歌手 (MusicBar 同款单行; 宽度同 PlayerBar 手法: 固定预留防隐式宽重算)
                Row {
                    width: parent.width
                    spacing: 4
                    Text {
                        text: MockPlayback.title !== "" ? MockPlayback.title : "未在播放"
                        width: Math.min(implicitWidth, parent.width - 120)
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                        color: Theme.text_primary
                    }
                    Text {
                        text: "·"
                        visible: MockPlayback.artist !== ""
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                    }
                    Text {
                        text: MockPlayback.artist
                        visible: MockPlayback.artist !== ""
                        width: Math.min(implicitWidth, Math.max(40, parent.width - 140))
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                    }
                }

                // 平台徽标 (无平台时只有一行)
                Text {
                    visible: MockPlayback.platform !== ""
                    text: MockPlayback.platform
                    font { family: Theme.fontFamily; pixelSize: 10 }
                    color: Theme.text_hint
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onDoubleTapped: TaskbarBar.toggleMain()
            }
        }

        BarBtn {
            anchors.verticalCenter: parent.verticalCenter
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/prev.svg"
            tip: "上一首"
            onClicked: MockPlayback.prev()
        }

        // 播放/暂停 (主按钮; 与 PlayerBar 中控同款: 图标常驻主题蓝, hover/pressed 变白)
        Item {
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            IconImage {
                anchors.centerIn: parent
                size: 22
                source: MockPlayback.playing ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/pause.svg"
                                            : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                color: (playMouse.containsMouse || playMouse.pressed) ? "#ffffff" : Theme.accent
            }
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MockPlayback.playPause()
            }
            Tooltip {
                text: MockPlayback.playing ? "暂停" : "播放"
                shown: playMouse.containsMouse
                delay: 0   // hover 即展示
                radius: 8
                bgColor: Theme.bg_card
                borderColor: Theme.border_standard
                anchorItem: parent
            }
        }

        BarBtn {
            anchors.verticalCenter: parent.verticalCenter
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/next.svg"
            tip: "下一首"
            onClicked: MockPlayback.next()
        }
    }
}
