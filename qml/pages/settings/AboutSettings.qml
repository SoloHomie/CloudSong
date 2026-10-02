import QtQuick
import "../../theme"
import "../../components/buttons"
import "../../components/layout"

// ═══════════════════════════════════════════════════════════════
//  AboutSettings — 设置子页面: 关于 (版本/更新 / 开源致谢 / 协议与隐私)
//  BallsHackPro 同款布局: 品牌头部区 + 折叠卡
//  2026-10-02 自 SettingsPage 拆分
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property string latestVersion: ""     // 更新检测结果 (待接 C++ UpdaterService)
    property bool checkingUpdate: false

    // 检查更新模拟 (待接 C++ UpdaterService 后移除)
    Timer {
        id: checkTimer
        interval: 1200
        repeat: false
        onTriggered: root.checkingUpdate = false
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 680)
            spacing: 18

            // 头部: 应用名 + 版本(可点跳仓库) + 检查更新按钮
            Column {
                width: parent.width
                spacing: 5
                Text {
                    text: "CloudSong"
                    font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
                    color: Theme.text_primary
                }
                Row {
                    spacing: 5
                    Text {
                        text: "Version 0.1.0"
                        font { family: "JetBrains Mono"; pixelSize: 12 }
                        color: Theme.text_hint
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://github.com/SoloHomie/CloudSong")
                        }
                    }
                    SuretyBtn {
                        visible: root.latestVersion !== ""
                        text: "v" + root.latestVersion + " 可用"
                        variant: "default"
                        font.pixelSize: 11
                        onClicked: Qt.openUrlExternally("https://github.com/SoloHomie/CloudSong/releases")
                    }
                }
                Row {
                    spacing: 8
                    SuretyBtn {
                        width: 110
                        height: 30
                        text: root.checkingUpdate ? "检查中..." : "检查更新"
                        variant: "outline"
                        enabled: !root.checkingUpdate
                        font.pixelSize: 12
                        onClicked: {
                            root.checkingUpdate = true
                            checkTimer.start()
                        }
                    }
                }
            }
            Item { width: 1; height: 6 }
            // ═══ Open Source Notice ═══
            SuretyCollapse {
                width: parent.width
                title: "Open Source Notice"
                subtitle: "本软件使用了以下开源组件，谨此致谢"
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Column {
                        anchors { left: parent.left; right: parent.right }
                        Repeater {
                            model: [
                                { n: "Qt Framework", u: "https://www.qt.io" },
                                { n: "MS VC++ Runtime", u: "https://visualstudio.microsoft.com" }
                            ]
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                color: "transparent"
                                Row {
                                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8 }
                                    Column {
                                        width: parent.width
                                        spacing: 1
                                        Text {
                                            text: modelData.n
                                            font { family: Theme.fontFamily; pixelSize: 12 }
                                            color: Theme.text_primary
                                        }
                                        Text {
                                            text: modelData.u
                                            font { family: Theme.fontFamily; pixelSize: 11 }
                                            color: Theme.accent_text
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally(modelData.u)
                                }
                            }
                        }
                    }
                }
            }
            Item { width: 1; height: 8 }   // 折叠卡之间额外留白
            SuretyCollapse {
                width: parent.width
                title: "用户协议"
                subtitle: "最后更新日期: 2026 年 9 月 28 日"
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Text {
                        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                        topPadding: 4
                        bottomPadding: 14
                        text: `最后更新日期：2026 年 9 月 28 日

一、定义
1.1 "本软件"指 CloudSong 桌面音乐播放器及其全部组件。
1.2 "插件"指通过 MusicFree 插件协议接入的第三方音源扩展，由各自作者开发维护。
1.3 "增值服务"指云漫游等按订阅或买断方式提供的功能。

二、许可范围
2.1 本软件以 GPL-3.0 开源协议授权，任何人可自由使用、修改与分发，衍生作品须以相同协议开放源代码。
2.2 增值服务适用单独的服务条款，不影响开源部分的授权。

三、插件与音源
3.1 本软件自身不存储、不提供任何受版权保护的音乐内容，播放能力完全由插件实现。
3.2 用户应自行遵守所使用音源平台的服务条款与所在地法律，因使用第三方插件产生的一切后果由用户自行承担。

四、增值服务
4.1 云漫游仅同步用户自行创建的歌单与播放进度数据。
4.2 订阅期内可随时退订；退订后已购买的周期内功能仍可使用。

五、知识产权
5.1 本软件界面设计、图标与文档归开发者所有；源代码按 GPL-3.0 向公众开放。
5.2 本软件中出现的第三方商标与内容归各自权利人所有。

六、隐私保护
6.1 本软件仅在您主动开启云漫游时同步歌单结构与播放进度，不收集本地播放记录与播放内容。
6.2 详见「隐私政策」。

七、免责声明
7.1 本软件按"现状"提供，开发者不对插件可用性、音源稳定性及任何第三方服务作出保证。
7.2 因不可抗力、网络故障或第三方原因造成的服务中断，开发者不承担责任。

八、责任限制
8.1 在任何情况下，开发者均不对因使用或无法使用本软件而产生的任何间接、偶然或结果性损害承担责任。

九、协议终止
9.1 本协议在用户卸载本软件前持续有效；如用户违反本协议，开发者有权终止授权。

十、法律适用
10.1 本协议的订立、执行与解释均适用中华人民共和国法律。

如对本协议有任何疑问，请联系开发者。`
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                        wrapMode: Text.WordWrap
                        lineHeight: 1.6
                    }
                }
            }
            Item { width: 1; height: 8 }   // 折叠卡之间额外留白
            SuretyCollapse {
                width: parent.width
                title: "隐私政策"
                subtitle: "最后更新日期: 2026 年 9 月 28 日"
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Text {
                        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                        topPadding: 4
                        bottomPadding: 14
                        text: `最后更新日期：2026 年 9 月 28 日

一、我们收集的信息
1.1 账户信息：注册使用的邮箱地址，仅用于登录验证与订阅管理。
1.2 漫游数据：仅当您主动开启云漫游时，歌单结构与播放进度会同步至服务器。
1.3 我们不收集：本地播放记录、本地文件路径以及任何播放内容本身。

二、信息的使用
账户信息用于身份验证与订阅服务；漫游数据仅用于多设备同步。

三、存储与安全
数据加密传输并存储于受控服务器。我们不出售、不与第三方共享您的任何数据。

四、您的权利
您可随时关闭云漫游并清除服务器端数据；注销账户后，所有关联数据将被永久删除。`
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                        wrapMode: Text.WordWrap
                        lineHeight: 1.6
                    }
                }
            }
            Item { width: 1; height: 8 }   // 折叠卡之间额外留白
            SuretyCollapse {
                width: parent.width
                title: "软件许可"
                subtitle: "GPL-3.0 — Copyright © 2026 Homie"
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Text {
                        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                        topPadding: 4
                        bottomPadding: 14
                        text: `GNU GENERAL PUBLIC LICENSE Version 3 — 中文摘要（以官方英文原文为准，https://www.gnu.org/licenses/gpl-3.0.html）

1. 自由使用：任何人可自由运行、复制、分发、研究、修改本软件。
2. 源码开放：分发本软件或衍生作品时，必须同时提供完整源代码，并以相同 GPL-3.0 协议授权。
3. 专利保护：贡献者授予用户与本软件相关的专利许可。
4. 免责声明：本软件按"现状"提供，不作任何形式的明示或默示保证。

本软件使用了以下开源组件（完整列表见 Open Source Notice）：
· Qt Framework — LGPL-3.0 / GPL-3.0 / Commercial
· MS VC++ Runtime — Microsoft Software License Terms

插件生态兼容 MusicFree 插件协议（GPL-3.0）。`
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                        wrapMode: Text.WordWrap
                        lineHeight: 1.6
                    }
                }
            }
        }
    }
}
