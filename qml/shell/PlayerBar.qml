import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  PlayerBar — 底部播放条 (原版 MusicFree PlayerBar 三列同构)
//   左: 封面 + 爱心 + 信息两行 / 中: 仅上一曲·播放·下一曲(2026-09-28 用户拍板) / 右: 下载·音质·音量·歌词·循环·队列
//   全部状态来自注入的 playback (当前 MockPlayback, 待换 C++ PlaybackService);
//   进度 250ms 步进 (playback Timer), 无连续动画
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    height: 74
    property QtObject playback: null
    signal openQueueRequested()
    signal showListenModeRequested()

    // ── 顶部进度条 (点击跳进度, hover 变亮; 热区 12px, 视觉轨道 3px 太难点中) ──
    Item {
        id: progressHit
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 12
        Rectangle {
            id: progressTrack
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3
            color: progMouse.containsMouse ? Theme.d6 : Theme.border_default
            Behavior on color { ColorAnimation { duration: 150 } }
            Rectangle {
                id: progressFill
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: (playback.duration > 0)
                       ? progressTrack.width * Math.min(1, Math.max(0, playback.position / playback.duration))
                       : 0
                color: Theme.accent
            }
        }
        MouseArea {
            id: progMouse
            anchors.fill: parent
            hoverEnabled: true
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
            width: 52
            height: 52
            anchors.verticalCenter: parent.verticalCenter
            CoverArt { anchors.fill: parent; seed: playback.seed }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showListenModeRequested()
            }
        }

        // 爱心 (靠左: 封面旁; 未喜欢=普通图标色, 已喜欢=红心且 hover 不变白)
        BarBtn {
            icon: playback.favorite ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                                    : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
            iconColor: playback.favorite ? Theme.danger_fg : "transparent"
            fixedColor: playback.favorite
            tip: "喜欢"
            onClicked: playback.toggleFavorite()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            // 窗口窄时信息列收缩, 优先保住中控与右侧工具 (最小 800 宽; 左组仅封面+爱心+信息, 右组已含歌词+循环)
            width: Math.max(100, Math.min(210, root.width - 690))
            spacing: 4

            // 行1: 歌名
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: playback.title !== "" ? playback.title : "未在播放"
                font { family: Theme.fontFamily; pixelSize: 14 }
                color: Theme.text_primary
            }

            // 行2: 歌手 · 平台徽标 · 时间
            Row {
                height: 16
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - 140)
                    elide: Text.ElideRight
                    visible: playback.artist !== ""
                    text: playback.artist
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.text_secondary
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: playback.platform !== ""
                    height: 15
                    width: pbText.implicitWidth + 12
                    radius: 8
                    color: Theme.tag_preset_bg
                    Text {
                        id: pbText
                        anchors.centerIn: parent
                        text: playback.platform
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MockData.fmtTime(playback.position) + " / " + MockData.fmtTime(playback.duration)
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.text_secondary   // text_hint 4.12:1 不达标, 次级色 6.2:1
                }
            }
        }

    }

    // ── 中: 仅上一曲 / 播放 / 下一曲 (2026-09-28 用户拍板) ──
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        spacing: 16

        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/prev.svg"
            tip: "上一首"
            onClicked: playback.prev()
        }

        // 播放/暂停 (主按钮; 无背景, 图标常驻主题蓝, hover/pressed 变白)
        Item {
            width: 44
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            IconImage {
                anchors.centerIn: parent
                size: 26
                source: playback.playing ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/pause.svg"
                                        : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                color: (playMouse.containsMouse || playMouse.pressed) ? "#ffffff" : Theme.accent
            }
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: playback.playPause()
            }
            Tooltip {
                text: playback.playing ? "暂停" : "播放"
                shown: playMouse.containsMouse
                delay: 0   // hover 即展示
                radius: 8
                bgColor: Theme.bg_card
                borderColor: Theme.border_standard
                anchorItem: parent
            }
        }

        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/next.svg"
            tip: "下一首"
            onClicked: playback.next()
        }
    }

    // ── 右: 下载 / 音质 / 音量 / 队列 ──
    Row {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 10

        // 下载 (动作待接 C++ DownloadManager)
        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/download.svg"
            tip: "下载"
            onClicked: {}
        }

        // 音质
        Item {
            id: qualityWrap
            width: qualityBtn.width
            height: qualityBtn.height
            BarBtn {
                id: qualityBtn
                icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/quality.svg"
                tip: "音质"
                suppressTip: qualityPop.open
                onClicked: { qualityPop.open = !qualityPop.open; volumePop.open = false }
            }
            Popover {
                id: qualityPop
                panelWidth: 140
                anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                PopoverOption { text: "标准品质"; active: playback.quality === "标准品质"; onSelected: { playback.quality = "标准品质"; qualityPop.open = false } }
                PopoverOption { text: "较高品质"; active: playback.quality === "较高品质"; onSelected: { playback.quality = "较高品质"; qualityPop.open = false } }
                PopoverOption { text: "极高品质"; active: playback.quality === "极高品质"; onSelected: { playback.quality = "极高品质"; qualityPop.open = false } }
                PopoverOption { text: "无损品质"; active: playback.quality === "无损品质"; onSelected: { playback.quality = "无损品质"; qualityPop.open = false } }
                PopoverOption { text: "Hi-Res";   active: playback.quality === "Hi-Res";   onSelected: { playback.quality = "Hi-Res";   qualityPop.open = false } }
            }
        }

        // 音量 (hover 即弹竖向调节条, 不再弹 tooltip; 点击直接开关音量; 移出按钮与面板 300ms 后关闭)
        Item {
            id: volumeWrap
            width: volumeBtn.width
            height: volumeBtn.height
            BarBtn {
                id: volumeBtn
                icon: playback.volume === 0 ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/volume-mute.svg"
                                            : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/volume-notice.svg"
                onHoverEntered: { volCloseTimer.stop(); volumePop.open = true; qualityPop.open = false }
                onHoverExited: volCloseTimer.restart()
                onClicked: playback.toggleMute()   // 点击直接开关音量
            }
            Timer {
                id: volCloseTimer
                interval: 300
                onTriggered: volumePop.open = false
            }
            Popover {
                id: volumePop
                panelWidth: 40
                spacing: 8
                anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                // 悬停联动: 鼠标进面板取消关闭计时, 移出面板重启计时 (拖拽中不关)
                onHoveredChanged: { if (hovered) volCloseTimer.stop(); else volCloseTimer.restart() }

                // 竖向调节条 (顶部=100%, 底部=0; 热区 28 宽, 视觉轨道 4px 居中; 轨道上下各留 12, 把手到顶/到底不贴气泡边)
                Item {
                    id: volHit
                    width: 28
                    height: 160
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        id: volTrack
                        anchors { top: parent.top; topMargin: 12; bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
                        width: 4
                        radius: 2
                        color: Theme.border_default
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            height: volTrack.height * playback.volume
                            width: 4
                            radius: 2
                            color: Theme.accent
                        }
                        Rectangle {
                            // 圆钮挂在 volTrack 内 (轨道坐标系), volume=1 时中心在轨道顶端, 收进轨道内不溢出
                            y: Math.max(0, Math.min(volTrack.height - 14, volTrack.height * (1 - playback.volume) - 7))
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: "#ffffff"
                            border { width: 1; color: Theme.border_standard }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: volCloseTimer.stop()   // 拖拽期间不关面板
                        onReleased: { if (!volumePop.hovered) volCloseTimer.restart() }
                        onClicked: function(mouse) { playback.setVolume(Math.max(0, Math.min(1, 1 - (mouse.y - volTrack.y) / volTrack.height))) }
                        onPositionChanged: function(mouse) {
                            if (pressed) playback.setVolume(Math.max(0, Math.min(1, 1 - (mouse.y - volTrack.y) / volTrack.height)))
                        }
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

        // 桌面歌词 / 循环模式 (随右侧工具区)
        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/lyrics.svg"
            tip: "桌面歌词"
            active: playback.desktopLyric
            onClicked: playback.desktopLyric = !playback.desktopLyric
        }
        BarBtn {
            icon: playback.loopMode === 0 ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/repeat.svg"
                 : playback.loopMode === 1 ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/repeat-one.svg"
                 : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/shuffle.svg"
            tip: "循环模式"
            active: playback.loopMode !== 0
            onClicked: playback.toggleLoop()
        }

        // 队列
        BarBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/queue.svg"
            tip: "播放队列"
            onClicked: root.openQueueRequested()
        }
    }

    // (BarBtn 图标按钮已提取至同目录 BarBtn.qml, 2026-10-02)
}
