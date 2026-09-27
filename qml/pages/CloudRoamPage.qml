import QtQuick
import "../theme"
import "../components/display"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  CloudRoamPage — 云漫游 (P1 占位页, 待接订阅与云服务)
//  单档订阅 ¥3/月; 未登录点击开通跳登录弹窗 ($auth)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    PageHeader {
        id: header
        title: "云漫游"
        subtitle: "P1 里程碑 · 原型占位, 服务待上线"
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

    Column {
        anchors { top: header.bottom; topMargin: 24; left: parent.left; leftMargin: 24 }
        spacing: 16
        width: 460

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "歌单、播放状态在多设备间同步。所有数据加密存储, 音乐内容本身仍来自各插件音源, 云漫游不提供也不缓存任何音乐文件。"
            font { family: "Microsoft YaHei UI"; pixelSize: 13 }
            color: Theme.text_secondary
        }

        // 功能清单
        Column {
            spacing: 8
            Repeater {
                model: ["歌单与收藏自动同步到云端", "播放进度漫游, 换设备接着听", "两台设备内随时开通与取消"]
                delegate: Row {
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                        font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: Font.Bold }
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                        color: Theme.text_primary
                    }
                }
            }
        }

        // 订阅卡 (单档)
        Rectangle {
            width: parent.width
            height: 96
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_standard }

            Column {
                anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                spacing: 4
                Text {
                    text: "云漫游"
                    font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                    color: Theme.text_primary
                }
                Text {
                    text: "单档订阅 · 随时取消"
                    font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                    color: Theme.text_secondary
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                text: "¥3 / 月"
                font { family: "Microsoft YaHei UI"; pixelSize: 18; weight: Font.Bold }
                color: Theme.accent_text
            }
        }

        SuretyBtn {
            height: 34
            variant: "primary"
            font.pixelSize: 13
            text: "登录并开通"
            onClicked: root.navigate("$auth")
        }

        Text {
            text: "App 本体永远开源免费; 云漫游仅覆盖服务器与同步成本"
            font { family: "Microsoft YaHei UI"; pixelSize: 11 }
            color: Theme.text_hint
        }
    }
}
