import QtQuick
import "../../theme"
import "../buttons"
import "../controls"

// ═══════════════════════════════════════════════════════════════
//  RoamPanel — 云漫游面板 (设置页"服务"分类折叠卡内容)
//  2026-09-29 由 CloudRoamPage 迁入: 原页级 PageHeader/Flickable 已剥除,
//  本组件只承载内容, 由外层折叠卡/设置页提供滚动
//  未登录: 营销内容 + 订阅卡 + 登录入口
//  已登录: 登录态卡(邮箱/订阅状态/续费) + 漫游范围三开关 + 设备列表(踢出)
//  状态为面板内 mock, 待接 C++ RoamService (loggedIn/subscribed/开关/设备)
//  红线: 不收集音乐内容本身, 只漫游用户自己的元数据
// ═══════════════════════════════════════════════════════════════
Column {
    id: root
    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14 }
    bottomPadding: 12
    spacing: 16
    signal navigate(string name, var params)

    // ── 状态 (mock; 待 C++ RoamService 替换) ──
    property bool loggedIn: false
    property string email: "homie@example.com"
    property bool subscribed: true
    property int remainDays: 28
    property bool syncSheets: true
    property bool syncHistory: true
    property bool syncPrefs: false
    property var devices: [
        { name: "Windows 本机", os: "Windows 11", last: "刚刚", current: true },
        { name: "iPhone 15 Pro", os: "iOS 19", last: "3 小时前", current: false },
        { name: "旧笔记本", os: "Windows 10", last: "12 天前", current: false }
    ]

    // ══ 未登录视图 ══
    Column {
        visible: !root.loggedIn
        width: parent.width
        spacing: 16

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "歌单、播放状态在多设备间同步。所有数据加密存储, 音乐内容本身仍来自各插件音源, 云漫游不提供也不缓存任何音乐文件。"
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_secondary
        }

        Column {
            spacing: 8
            Repeater {
                model: ["歌单与收藏自动同步到云端", "播放进度漫游, 换设备接着听", "自动切换最高音质", "随时开通与取消"]
                delegate: Row {
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                        font { family: Theme.fontFamily; pixelSize: 13; weight: Font.Bold }
                        color: Theme.success_fg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        font { family: Theme.fontFamily; pixelSize: 13 }
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
                    font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                    color: Theme.text_primary
                }
                Text {
                    text: "单档订阅 · 随时取消"
                    font { family: Theme.fontFamily; pixelSize: 11 }
                    color: Theme.text_secondary
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                text: "¥3 / 月"
                font { family: Theme.fontFamily; pixelSize: 18; weight: Font.Bold }
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
            font { family: Theme.fontFamily; pixelSize: 11 }
            color: Theme.text_hint
        }
    }

    // ══ 已登录视图 ══
    Column {
        visible: root.loggedIn
        width: parent.width
        spacing: 18

        // 登录态卡: 邮箱 + 订阅状态 + 续费
        Rectangle {
            width: parent.width
            height: 72
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_standard }

            Row {
                anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                spacing: 14
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: root.email.charAt(0).toUpperCase()
                        font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                        color: "#ffffff"
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        text: root.email
                        font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
                        color: Theme.text_primary
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.subscribed
                            height: 16
                            width: subText.implicitWidth + 12
                            radius: 8
                            color: Theme.success
                            Text {
                                id: subText
                                anchors.centerIn: parent
                                text: "已订阅"
                                font { family: Theme.fontFamily; pixelSize: 10 }
                                color: "#ffffff"
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.subscribed
                            text: "剩余 " + root.remainDays + " 天"
                            font { family: Theme.fontFamily; pixelSize: 11 }
                            color: Theme.text_hint
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.subscribed
                            text: "未订阅 · 开通后开始同步"
                            font { family: Theme.fontFamily; pixelSize: 11 }
                            color: Theme.warning_fg
                        }
                    }
                }
            }

            SuretyBtn {
                anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                height: 28
                variant: "outline"
                font.pixelSize: 12
                text: root.subscribed ? "续费" : "开通"
                onClicked: {}   // 待接 C++ PaymentService
            }
        }

        // 漫游范围卡: 三项独立开关
        Rectangle {
            width: parent.width
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_standard }

            Column {
                width: parent.width
                topPadding: 4
                bottomPadding: 4
                RoamSwitchRow {
                    title: "歌单同步"
                    desc: "歌单结构与收藏状态"
                    checked: root.syncSheets
                    onToggled: function(v) { root.syncSheets = v }
                }
                Rectangle {
                    x: 20
                    width: parent.width - 40
                    height: 1
                    color: Theme.border_default
                }
                RoamSwitchRow {
                    title: "播放记录"
                    desc: "最近播放与播放进度"
                    checked: root.syncHistory
                    onToggled: function(v) { root.syncHistory = v }
                }
                Rectangle {
                    x: 20
                    width: parent.width - 40
                    height: 1
                    color: Theme.border_default
                }
                RoamSwitchRow {
                    title: "偏好设置"
                    desc: "主题与播放偏好"
                    checked: root.syncPrefs
                    onToggled: function(v) { root.syncPrefs = v }
                }
            }
        }

        // 设备列表卡: 已登录设备 + 踢出
        Rectangle {
            width: parent.width
            radius: 10
            color: Theme.bg_card
            border { width: 1; color: Theme.border_standard }

            Column {
                width: parent.width
                bottomPadding: 6
                Text {
                    x: 20
                    topPadding: 14
                    bottomPadding: 4
                    text: "已登录设备"
                    font { family: Theme.fontFamily; pixelSize: 12; weight: Font.Bold }
                    color: Theme.text_hint
                }
                Repeater {
                    model: root.devices
                    delegate: Item {
                        width: parent.width
                        height: 52
                        Column {
                            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                            spacing: 3
                            Text {
                                text: modelData.name
                                font { family: Theme.fontFamily; pixelSize: 13 }
                                color: Theme.text_primary
                            }
                            Text {
                                text: modelData.os + " · " + modelData.last
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_hint
                            }
                        }
                        Rectangle {
                            visible: modelData.current
                            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                            height: 16
                            width: curText.implicitWidth + 12
                            radius: 8
                            color: Theme.tag_preset_bg
                            Text {
                                id: curText
                                anchors.centerIn: parent
                                text: "当前设备"
                                font { family: Theme.fontFamily; pixelSize: 10 }
                                color: Theme.tag_preset_fg
                            }
                        }
                        SuretyBtn {
                            visible: !modelData.current
                            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                            height: 24
                            variant: "outline"
                            font.pixelSize: 11
                            text: "踢出"
                            onClicked: {}   // 待接 C++ RoamService.kickDevice
                        }
                        Rectangle {
                            visible: index < root.devices.length - 1
                            anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20; bottom: parent.bottom }
                            height: 1
                            color: Theme.border_default
                        }
                    }
                }
            }
        }
    }

    // ── 漫游开关行 (标题+副标题 + 右侧开关) ──
    component RoamSwitchRow: Item {
        id: rsr
        width: parent.width
        height: 48
        property string title: ""
        property string desc: ""
        property bool checked: false
        signal toggled(bool v)

        Column {
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            spacing: 3
            Text {
                text: rsr.title
                font { family: Theme.fontFamily; pixelSize: 13 }
                color: Theme.text_primary
            }
            Text {
                text: rsr.desc
                font { family: Theme.fontFamily; pixelSize: 11 }
                color: Theme.text_hint
            }
        }
        SuretySwitch {
            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
            checked: rsr.checked
            onToggled: function(v) { rsr.checked = v; rsr.toggled(v) }
        }
    }
}
