import QtQuick
import "../../theme"
import "../display"
import "../buttons"

// ═══════════════════════════════════════════════════════════════
//  DailyMixCard — 每日推荐大卡 (推荐页首位模块, 2026-10-01)
//  左: 2×2 封面拼贴 (点击进歌单)  中: DAILY MIX 眉标/标题/口味说明/
//  偏好标签/操作按钮  右: 品牌色幽灵音符
//  全部数据由页面注入 (C++ 服务化后换数据源即可, 本组件零改动)
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: root
    height: 208
    radius: 14
    color: Theme.bg_card
    border { width: 1; color: Theme.border_default }
    clip: true

    property var songs: []
    property string artistLine: ""   // "常听 周杰伦 · 赵雷 · Beyond" 式拼接
    property var tagList: []
    property string dateText: ""    // "10月1日" 式
    signal openRequested()
    signal playRequested()

    // 右上品牌色柔光 (低透明大圆, 氛围层)
    Rectangle {
        width: 260; height: 260; radius: 130
        anchors { right: parent.right; top: parent.top; rightMargin: -90; topMargin: -110 }
        color: Theme.accent
        opacity: 0.07
    }

    Row {
        anchors { fill: parent; margins: 16 }
        spacing: 20

        // 2×2 封面拼贴 (取自每日推荐前 4 首; 点击层在 Grid 外,
        // 锚点放 Grid 内会与布局定位冲突 → qmllint 实锤)
        Item {
            width: 176; height: 176
            anchors.verticalCenter: parent.verticalCenter
            Grid {
                anchors.fill: parent
                columns: 2
                spacing: 8
                Repeater {
                    model: 4
                    CoverArt {
                        width: 84; height: 84
                        radius: 10
                        seed: root.songs.length > index ? root.songs[index].seed : index
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openRequested()
            }
        }

        Column {
            width: parent.width - 176 - 64 - 40   // 减去拼贴 + 右侧幽灵音符位 + 间距
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // 眉标: DAILY MIX + 更新日期胶囊
            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DAILY MIX"
                    font { family: Theme.fontFamily; pixelSize: 11; weight: Font.Bold; letterSpacing: 1.5 }
                    color: Theme.accent_text
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16; radius: 8
                    width: dateTxt.implicitWidth + 12
                    color: Theme.tag_preset_bg
                    Text {
                        id: dateTxt
                        anchors.centerIn: parent
                        text: root.dateText + "更新"
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: "每日推荐"
                font { family: Theme.fontFamily; pixelSize: 24; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: "根据你的口味生成 · 常听 " + root.artistLine
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_secondary
            }

            // 偏好标签 (画像可见化: 让人看见"为什么推荐")
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.tagList
                    delegate: Rectangle {
                        height: 18; radius: 9
                        width: tagTxt.implicitWidth + 12
                        color: Theme.tag_custom_bg
                        Text {
                            id: tagTxt
                            anchors.centerIn: parent
                            text: modelData
                            font { family: Theme.fontFamily; pixelSize: 10 }
                            color: Theme.tag_custom_fg
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "今天为你挑了 " + root.songs.length + " 首"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_hint
            }

            Row {
                spacing: 10
                SuretyBtn {
                    height: 32
                    variant: "primary"
                    font.pixelSize: 12
                    iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                    text: "播放全部"
                    onClicked: root.playRequested()
                }
                SuretyBtn {
                    height: 32
                    variant: "outline"
                    font.pixelSize: 12
                    text: "查看歌单"
                    onClicked: root.openRequested()
                }
            }
        }

        // 幽灵音符 (视觉平衡占位)
        Item {
            width: 64; height: 64
            anchors.verticalCenter: parent.verticalCenter
            IconImage {
                anchors.fill: parent
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
                color: Theme.accent
                opacity: 0.16
            }
        }
    }
}
