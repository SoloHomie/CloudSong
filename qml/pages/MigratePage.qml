import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  MigratePage — 歌单迁移 (P1 占位页: 三步向导)
//  来源 = MusicFree 备份文件 (JSON); 买断 ¥9.9-19.9 一次性
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int step: 0                  // 0 选择来源 1 解析结果 2 完成
    property var source: "musicfree"      // musicfree | file
    property var parsed: ({ sheets: 3, songs: 127, failed: 2 })

    PageHeader {
        id: header
        title: "歌单迁移"
        subtitle: "P1 里程碑 · 原型占位"
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            width: p1Text.implicitWidth + 12
            radius: 9
            color: Theme.tag_preset_bg
            Text {
                id: p1Text
                anchors.centerIn: parent
                text: "P1"
                font { family: "Microsoft YaHei UI"; pixelSize: 10 }
                color: Theme.tag_preset_fg
            }
        }
    }

    // ── 步骤指示 ──
    Row {
        anchors { top: header.bottom; topMargin: 8; left: parent.left; leftMargin: 24 }
        spacing: 10
        Repeater {
            model: ["选择来源", "解析确认", "完成导入"]
            delegate: Row {
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: index <= root.step ? Theme.accent : Theme.bg_input
                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        font { family: "Microsoft YaHei UI"; pixelSize: 11; weight: Font.Bold }
                        color: index <= root.step ? "#ffffff" : Theme.text_hint
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    font { family: "Microsoft YaHei UI"; pixelSize: 12; weight: index === root.step ? Font.Bold : Font.Normal }
                    color: index <= root.step ? Theme.text_primary : Theme.text_hint
                }
            }
        }
    }

    // ── 步骤内容 ──
    Column {
        anchors { top: header.bottom; topMargin: 56; left: parent.left; leftMargin: 24 }
        width: 480
        spacing: 16
        visible: root.step === 0

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "把 MusicFree 的备份文件导入 CloudSong, 歌单、收藏一次到位。导入仅在本地解析, 不上传任何数据。"
            font { family: "Microsoft YaHei UI"; pixelSize: 13 }
            color: Theme.text_secondary
        }

        Rectangle {
            width: parent.width
            height: 56
            radius: 10
            color: selMouse.containsMouse ? Theme.hover_bg : Theme.bg_card
            border { width: 1; color: root.source === "musicfree" ? Theme.accent : Theme.border_default }
            Row {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MusicFree 备份文件"
                    font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: Font.Bold }
                    color: Theme.text_primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "musicfree-backup.json"
                    font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                    color: Theme.text_hint
                }
            }
            MouseArea {
                id: selMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.source = "musicfree"
            }
        }

        SuretyBtn {
            height: 34
            variant: "primary"
            font.pixelSize: 13
            text: "下一步"
            onClicked: root.step = 1
        }
    }

    Column {
        anchors { top: header.bottom; topMargin: 56; left: parent.left; leftMargin: 24 }
        width: 480
        spacing: 16
        visible: root.step === 1

        Text {
            text: "解析完成"
            font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
            color: Theme.text_primary
        }
        Column {
            spacing: 8
            Repeater {
                model: [
                    { k: "识别歌单", v: root.parsed.sheets + " 个" },
                    { k: "识别歌曲", v: root.parsed.songs + " 首" },
                    { k: "未能匹配", v: root.parsed.failed + " 首 (导入后标灰, 可手动换源)" }
                ]
                delegate: Row {
                    width: parent.width
                    spacing: 12
                    Text {
                        width: 100
                        text: modelData.k
                        font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                        color: Theme.text_secondary
                    }
                    Text {
                        text: modelData.v
                        font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                        color: Theme.text_primary
                    }
                }
            }
        }
        Text {
            text: "买断价 ¥9.9 - ¥19.9 (按识别规模), 一次付费永久使用"
            font { family: "Microsoft YaHei UI"; pixelSize: 12 }
            color: Theme.text_hint
        }
        Row {
            spacing: 10
            SuretyBtn {
                height: 34
                variant: "outline"
                font.pixelSize: 13
                text: "返回"
                onClicked: root.step = 0
            }
            SuretyBtn {
                height: 34
                variant: "primary"
                font.pixelSize: 13
                text: "确认导入"
                onClicked: root.step = 2
            }
        }
    }

    Column {
        anchors { top: header.bottom; topMargin: 56; left: parent.left; leftMargin: 24 }
        width: 480
        spacing: 16
        visible: root.step === 2

        Rectangle {
            width: 56
            height: 56
            radius: 28
            color: Theme.success
            Text {
                anchors.centerIn: parent
                text: "✓"
                font { family: "Microsoft YaHei UI"; pixelSize: 26; weight: Font.Bold }
                color: "#ffffff"
            }
        }
        Text {
            text: "导入完成"
            font { family: "Microsoft YaHei UI"; pixelSize: 16; weight: Font.Bold }
            color: Theme.text_primary
        }
        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "3 个歌单已出现在「我的歌单」。去看看吧。"
            font { family: "Microsoft YaHei UI"; pixelSize: 13 }
            color: Theme.text_secondary
        }
        SuretyBtn {
            height: 34
            variant: "primary"
            font.pixelSize: 13
            text: "去我的歌单"
            onClicked: root.navigate("sheets")
        }
    }
}
