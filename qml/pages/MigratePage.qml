import QtQuick
import "../theme"
import "../components/display"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  MigratePage — 歌单迁移 (P1 买断, UI 框架)
//  三步向导: 选来源(截图/链接/文本/本地文件) → 识别预览(未命中标黄+手动修正) → 完成
//  免费=1 个歌单试迁移; 买断 ¥9.9-19.9 不限量
//  来源与识别结果为页面内 mock, 待接 C++ MigrateService
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int step: 0                 // 0选择来源 1识别预览 2完成迁移
    property int sourceIdx: 0            // 0截图 1链接 2文本 3本地文件
    property var sources: [
        { name: "歌单截图", desc: "上传其他 App 的歌单截图, 自动识别", icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg" },
        { name: "分享链接", desc: "粘贴歌单分享链接, 自动解析", icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/list.svg" },
        { name: "文本粘贴", desc: "粘贴歌单文字列表, 按行解析", icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/lyrics.svg" },
        { name: "本地备份文件", desc: "musicfree-backup.json 等备份文件", icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/folder.svg" }
    ]
    // 识别结果 mock (待接 C++ MigrateService)
    property var recog: ({
        platform: "网易云音乐",
        songs: [
            { title: "晴天", artist: "周杰伦", hit: true },
            { title: "七里香", artist: "周杰伦", hit: true },
            { title: "普通朋友", artist: "陶喆", hit: true },
            { title: "孤独患者", artist: "陈奕迅", hit: true },
            { title: "断了的弦", artist: "周杰伦", hit: false },
            { title: "爱在西元前", artist: "周杰伦", hit: true },
            { title: "夜的第七章", artist: "周杰伦", hit: false }
        ]
    })
    readonly property int hitCount: recog.songs.filter(function(s) { return s.hit }).length
    readonly property int missCount: recog.songs.length - hitCount

    PageHeader {
        id: header
        title: "歌单迁移"
        subtitle: "截图 / 链接 / 文本 / 备份文件 → CloudSong 歌单"
    }

    // ── 步骤指示器 ──
    Row {
        anchors { top: header.bottom; topMargin: 6; horizontalCenter: parent.horizontalCenter }
        spacing: 28
        Repeater {
            model: ["选择来源", "识别预览", "完成迁移"]
            delegate: Row {
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: index <= root.step ? Theme.accent : Theme.bg_input
                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        font { family: Theme.fontFamily; pixelSize: 11; weight: Font.Bold }
                        color: index <= root.step ? "#ffffff" : Theme.text_hint
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    font { family: Theme.fontFamily; pixelSize: 12; weight: index === root.step ? Font.Bold : Font.Normal }
                    color: index <= root.step ? Theme.text_primary : Theme.text_hint
                }
            }
        }
    }

    Flickable {
        anchors { top: header.bottom; topMargin: 54; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: stepCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: stepCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 680)
            spacing: 16

            // ══ Step 0: 选择来源 ══
            Column {
                visible: root.step === 0
                width: parent.width
                spacing: 16

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "把其他音乐 App 的歌单迁移到 CloudSong: 支持截图识别、分享链接、纯文本与 MusicFree 备份文件四种方式。"
                    font { family: Theme.fontFamily; pixelSize: 13 }
                    color: Theme.text_secondary
                }

                Repeater {
                    model: root.sources
                    delegate: Rectangle {
                        width: parent.width
                        height: 56
                        radius: 10
                        color: srcMouse.containsMouse ? Theme.hover_bg : Theme.bg_card
                        border { width: 1; color: index === root.sourceIdx ? Theme.accent : Theme.border_standard }

                        Row {
                            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: 12
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                source: modelData.icon
                                color: index === root.sourceIdx ? Theme.accent : Theme.text_hint
                                size: 18
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Text {
                                    text: modelData.name
                                    font { family: Theme.fontFamily; pixelSize: 13; weight: Font.Bold }
                                    color: Theme.text_primary
                                }
                                Text {
                                    text: modelData.desc
                                    font { family: Theme.fontFamily; pixelSize: 11 }
                                    color: Theme.text_hint
                                }
                            }
                        }
                        MouseArea {
                            id: srcMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sourceIdx = index
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "免费可试迁移 1 个歌单; 买断 ¥9.9-19.9 不限量"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.warning_fg
                }

                SuretyBtn {
                    height: 34
                    variant: "primary"
                    font.pixelSize: 13
                    text: "下一步"
                    onClicked: root.step = 1
                }
            }

            // ══ Step 1: 识别预览 ══
            Column {
                visible: root.step === 1
                width: parent.width
                spacing: 16

                // 平台识别结果
                Row {
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "识别到"
                        font { family: Theme.fontFamily; pixelSize: 13 }
                        color: Theme.text_secondary
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        width: platText.implicitWidth + 14
                        radius: 10
                        color: Theme.tag_preset_bg
                        Text {
                            id: platText
                            anchors.centerIn: parent
                            text: root.recog.platform
                            font { family: Theme.fontFamily; pixelSize: 11 }
                            color: Theme.tag_preset_fg
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "共 " + root.recog.songs.length + " 首"
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_hint
                    }
                }

                // 歌曲列表卡
                Rectangle {
                    width: parent.width
                    radius: 10
                    color: Theme.bg_card
                    border { width: 1; color: Theme.border_standard }

                    Column {
                        width: parent.width
                        topPadding: 4
                        bottomPadding: 4
                        // 表头
                        Row {
                            x: 20
                            width: parent.width - 40
                            height: 30
                            Text {
                                width: parent.width * 0.45
                                anchors.verticalCenter: parent.verticalCenter
                                text: "歌曲"
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_hint
                            }
                            Text {
                                width: parent.width * 0.30
                                anchors.verticalCenter: parent.verticalCenter
                                text: "歌手"
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_hint
                            }
                            Text {
                                width: parent.width * 0.25
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: "状态"
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_hint
                            }
                        }
                        Repeater {
                            model: root.recog.songs
                            delegate: Item {
                                width: parent.width
                                height: 40
                                Row {
                                    anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                                    Text {
                                        width: parent.width * 0.45
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: modelData.title
                                        font { family: Theme.fontFamily; pixelSize: 12 }
                                        color: modelData.hit ? Theme.text_primary : Theme.warning_fg
                                    }
                                    Text {
                                        width: parent.width * 0.30
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: modelData.artist
                                        font { family: Theme.fontFamily; pixelSize: 12 }
                                        color: Theme.text_secondary
                                    }
                                    Item {
                                        width: parent.width * 0.25
                                        height: 40
                                        Text {
                                            visible: modelData.hit
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                            text: "已命中"
                                            font { family: Theme.fontFamily; pixelSize: 11 }
                                            color: Theme.success_fg
                                        }
                                        Row {
                                            visible: !modelData.hit
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                            spacing: 8
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                height: 16
                                                width: missText.implicitWidth + 12
                                                radius: 8
                                                color: Theme.warning
                                                Text {
                                                    id: missText
                                                    anchors.centerIn: parent
                                                    text: "未命中"
                                                    font { family: Theme.fontFamily; pixelSize: 10 }
                                                    color: "#ffffff"
                                                }
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "修正"
                                                font { family: Theme.fontFamily; pixelSize: 11 }
                                                color: Theme.accent_text
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {}   // 待接 C++ MigrateService.fixSong
                                                }
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    visible: index < root.recog.songs.length - 1
                                    anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20; bottom: parent.bottom }
                                    height: 1
                                    color: Theme.border_default
                                }
                            }
                        }
                    }
                }

                // 统计行 (未命中仅提示, 不阻断)
                Text {
                    visible: root.missCount > 0
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.missCount + " 首未命中, 可手动修正后导入; 未修正的将跳过"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.warning_fg
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "本次为免费试迁移 (1 个歌单); 更多歌单买断 ¥9.9-19.9 不限量"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.text_hint
                }

                Row {
                    spacing: 10
                    SuretyBtn {
                        height: 32
                        variant: "outline"
                        font.pixelSize: 12
                        text: "返回"
                        onClicked: root.step = 0
                    }
                    SuretyBtn {
                        height: 32
                        variant: "primary"
                        font.pixelSize: 12
                        text: "确认导入"
                        onClicked: root.step = 2
                    }
                }
            }

            // ══ Step 2: 完成 ══
            Column {
                visible: root.step === 2
                width: parent.width
                spacing: 16

                Item { width: 1; height: 20 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: Theme.success
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font { family: Theme.fontFamily; pixelSize: 24; weight: Font.Bold }
                        color: "#ffffff"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "迁移完成"
                    font { family: Theme.fontFamily; pixelSize: 16; weight: Font.Bold }
                    color: Theme.text_primary
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "导入文件已生成: cloudsong-import-20260928.json (" + root.recog.songs.length + " 首)"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.text_secondary
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "重装或换机后, 打开「设置 → 歌单迁移」选择「本地备份文件」即可一键恢复全部歌单"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.text_hint
                }

                SuretyBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 34
                    variant: "primary"
                    font.pixelSize: 13
                    text: "去我的歌单"
                    onClicked: root.navigate("sheets")
                }
            }
        }
    }
}
