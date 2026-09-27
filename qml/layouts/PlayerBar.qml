import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  PlayerBar — 底部播放条 (原版 MusicFree PlayerBar 三列同构)
//   左: 封面 + 信息两行 / 中: 桌面歌词开关 + 播放控制 / 右: 音质·倍速·音量 + 队列
//   全部状态来自注入的 playback (当前 MockPlayback, 待换 C++ PlaybackService);
//   进度 250ms 步进 (playback Timer), 无连续动画
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    height: 72
    property QtObject playback: null
    signal openQueueRequested()
    signal showListenModeRequested()

    // ── 顶部进度条 (点击跳进度) ──
    Rectangle {
        id: progressTrack
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 3
        color: Theme.border_default
        Rectangle {
            id: progressFill
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: (playback.duration > 0)
                   ? progressTrack.width * Math.min(1, Math.max(0, playback.position / playback.duration))
                   : 0
            color: Theme.accent
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                if (playback.duration > 0)
                    playback.seek(playback.duration * mouse.x / progressTrack.width)
            }
        }
    }

    // ── 左: 封面 + 信息 ──
    Row {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 10

        // 封面 (点击进入听歌模式)
        Item {
            width: 48
            height: 48
            anchors.verticalCenter: parent.verticalCenter
            CoverArt { anchors.fill: parent; seed: playback.seed }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showListenModeRequested()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 210
            spacing: 5

            // 行1: 歌名 · 歌手 · 平台
            Row {
                width: parent.width
                height: 16
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - 52)
                    elide: Text.ElideRight
                    text: (playback.title !== "" ? playback.title + " · " + playback.artist : "未在播放")
                    font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                    color: Theme.text_primary
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: playback.platform !== ""
                    height: 16
                    width: pbText.implicitWidth + 12
                    radius: 8
                    color: Theme.tag_preset_bg
                    Text {
                        id: pbText
                        anchors.centerIn: parent
                        text: playback.platform
                        font { family: "Microsoft YaHei UI"; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
            }

            // 行2: 喜欢 / 下载 / 时间
            Row {
                height: 14
                spacing: 14
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 14
                    source: playback.favorite ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                                             : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
                    color: playback.favorite ? Theme.accent : Theme.text_hint
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playback.toggleFavorite()
                    }
                }
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 14
                    source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/download.svg"
                    color: Theme.text_hint
                    // 下载动作待接 C++ DownloadManager
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MockData.fmtTime(playback.position) + " / " + MockData.fmtTime(playback.duration)
                    font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                    color: Theme.text_hint
                }
            }
        }
    }

    // ── 中: 桌面歌词开关 + 播放控制 + 循环 ──
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        spacing: 14

        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/lyrics.svg"
            active: playback.desktopLyric
            onClicked: playback.desktopLyric = !playback.desktopLyric
        }
        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/prev.svg"
            onClicked: playback.prev()
        }

        // 播放/暂停 (主按钮)
        Rectangle {
            width: 38
            height: 38
            radius: 19
            anchors.verticalCenter: parent.verticalCenter
            color: playMouse.containsMouse ? Theme.accent_hover : Theme.accent
            IconImage {
                anchors.centerIn: parent
                size: 16
                source: playback.playing ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/pause.svg"
                                        : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                color: "#ffffff"
            }
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: playback.playPause()
            }
        }

        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/next.svg"
            onClicked: playback.next()
        }
        BarBtn {
            icon: playback.loopMode === 0 ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/repeat.svg"
                 : playback.loopMode === 1 ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/repeat-one.svg"
                 : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/shuffle.svg"
            active: playback.loopMode !== 0
            onClicked: playback.toggleLoop()
        }
    }

    // ── 右: 音质 / 倍速 / 音量 / 队列 ──
    Row {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 12

        // 音质
        Item {
            id: qualityWrap
            width: qualityBtn.width
            height: qualityBtn.height
            BarBtn {
                id: qualityBtn
                icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/quality.svg"
                onClicked: { qualityPop.open = !qualityPop.open; speedPop.open = false; volumePop.open = false }
            }
            Popover {
                id: qualityPop
                panelWidth: 140
                anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                PopoverOption { text: "标准品质"; active: playback.quality === "标准品质"; onSelected: { playback.quality = "标准品质"; qualityPop.open = false } }
                PopoverOption { text: "较高品质"; active: playback.quality === "较高品质"; onSelected: { playback.quality = "较高品质"; qualityPop.open = false } }
                PopoverOption { text: "无损品质"; active: playback.quality === "无损品质"; onSelected: { playback.quality = "无损品质"; qualityPop.open = false } }
            }
        }

        // 倍速
        Item {
            id: speedWrap
            width: speedBtn.width
            height: speedBtn.height
            BarBtn {
                id: speedBtn
                text: playback.rate.toString() + "x"
                active: playback.rate !== 1.0
                onClicked: { speedPop.open = !speedPop.open; qualityPop.open = false; volumePop.open = false }
            }
            Popover {
                id: speedPop
                panelWidth: 120
                anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                PopoverOption { text: "0.5x";  active: playback.rate === 0.5;  onSelected: { playback.setRate(0.5);  speedPop.open = false } }
                PopoverOption { text: "0.75x"; active: playback.rate === 0.75; onSelected: { playback.setRate(0.75); speedPop.open = false } }
                PopoverOption { text: "1.0x";  active: playback.rate === 1.0;  onSelected: { playback.setRate(1.0);  speedPop.open = false } }
                PopoverOption { text: "1.25x"; active: playback.rate === 1.25; onSelected: { playback.setRate(1.25); speedPop.open = false } }
                PopoverOption { text: "1.5x";  active: playback.rate === 1.5;  onSelected: { playback.setRate(1.5);  speedPop.open = false } }
                PopoverOption { text: "2.0x";  active: playback.rate === 2.0;  onSelected: { playback.setRate(2.0);  speedPop.open = false } }
            }
        }

        // 音量
        Item {
            id: volumeWrap
            width: volumeBtn.width
            height: volumeBtn.height
            BarBtn {
                id: volumeBtn
                icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/volume.svg"
                onClicked: { volumePop.open = !volumePop.open; qualityPop.open = false; speedPop.open = false }
            }
            Popover {
                id: volumePop
                panelWidth: 210
                anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                Row {
                    height: 28
                    spacing: 10
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 14
                        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/volume.svg"
                        color: Theme.text_secondary
                    }
                    Rectangle {
                        id: volTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        height: 4
                        radius: 2
                        color: Theme.border_default
                        Rectangle {
                            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                            width: volTrack.width * playback.volume
                            radius: 2
                            color: Theme.accent
                        }
                        Rectangle {
                            x: volTrack.width * playback.volume - 5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: 5
                            color: "#ffffff"
                            border { width: 1; color: Theme.border_standard }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) { playback.setVolume(mouse.x / volTrack.width) }
                            onPositionChanged: function(mouse) {
                                if (pressed) playback.setVolume(mouse.x / volTrack.width)
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(playback.volume * 100) + "%"
                        font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                        color: Theme.text_secondary
                    }
                }
            }
        }

        // 分隔
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 16
            color: Theme.border_standard
        }

        // 队列
        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/queue.svg"
            onClicked: root.openQueueRequested()
        }
    }

    // ── 圆形图标按钮 (28×28, hover 高亮) ──
    component BarBtn: Item {
        width: 28
        height: 28
        property string icon: ""
        property string text: ""
        property bool active: false
        property bool enabled: true
        signal clicked()

        Rectangle {
            visible: btnMouse.containsMouse
            anchors.fill: parent
            radius: 14
            color: Theme.hover_bg
        }
        IconImage {
            visible: parent.icon !== ""
            anchors.centerIn: parent
            source: parent.icon
            size: 16
            color: parent.active ? Theme.accent : (parent.enabled ? Theme.text_primary : Theme.text_disabled)
        }
        Text {
            visible: parent.text !== ""
            anchors.centerIn: parent
            text: parent.text
            font { family: "Microsoft YaHei UI"; pixelSize: 12; weight: parent.active ? Font.Bold : Font.Normal }
            color: parent.active ? Theme.accent_text : Theme.text_primary
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (parent.enabled) parent.clicked()
        }
    }
}
