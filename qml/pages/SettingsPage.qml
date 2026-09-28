import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"
import "../components/controls"
import "../components/layout"

// ═══════════════════════════════════════════════════════════
//  SettingsPage — 设置页 (上侧分类 + 下侧内容)
//  2026-09-28 重做: 原单列全分组改为顶部分段分类栏(服务/通用/播放/
//  下载/数据/插件/关于), 内容区最大宽度 680 居中, 独立滚动;
//  分组标题由分类栏承担, 内容不再重复显示组标题
//  持久化待接 C++ ConfigService; 当前仅内存态
// ═══════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property bool autoLaunch: false
    property bool minimizeToTray: true
    property bool desktopLyric: false
    property bool smtcEnabled: true
    property bool autoDegrade: true       // 受限音源自动降级 (P0)
    property bool downloadLyric: false
    property int qualityIdx: 0            // 0标准 1较高 2无损
    property string downloadDir: "C:\\Users\\Lenovo\\Music"
    property int catIdx: 0                // 0服务 1通用 2播放 3下载 4数据 5插件 6关于

    onCatIdxChanged: flick.contentY = 0   // 切分类回到顶部

    // ── 页头 ──
    PageHeader {
        id: pageHead
        anchors { top: parent.top; left: parent.left; right: parent.right }
        title: "设置"
        subtitle: "所有设置仅保存在本地"
    }

    // ── 顶部分类栏 (复用分段选择器, 与"默认音质"同视觉语言) ──
    SuretyTagSelector {
        id: catBar
        anchors { top: pageHead.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
        displayMode: "segment"
        selectedIndex: root.catIdx
        model: [
            { label: "服务" }, { label: "通用" }, { label: "播放" },
            { label: "下载" }, { label: "数据" }, { label: "插件" }, { label: "关于" }
        ]
        onTagSelected: function(i) { root.catIdx = i }
    }

    // ── 内容区 (最大宽度 680 居中, 独立滚动) ──
    Flickable {
        id: flick
        anchors { top: catBar.bottom; topMargin: 18; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: contentCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 680)
            spacing: 18

            // ── 服务 ──
            Column {
                visible: root.catIdx === 0
                width: parent.width
                RowSetting {
                    title: "云漫游"
                    subtitle: "歌单与播放进度多设备同步 · ¥3/月"
                    clickable: true
                    onClicked: root.navigate("roam")
                    Badge { text: "P1" }
                }
                RowSetting {
                    title: "歌单迁移"
                    subtitle: "从 MusicFree 备份导入歌单 · 一次性买断"
                    clickable: true
                    onClicked: root.navigate("migrate")
                    Badge { text: "P1" }
                }
            }

            // ── 通用 ──
            Column {
                visible: root.catIdx === 1
                width: parent.width
                RowSetting {
                    title: "主题"
                    subtitle: ["浅色", "深色", "跟随系统"][AppCfg.themeIndex]
                    clickable: true
                    onClicked: root.navigate("theme")
                }
                RowSetting {
                    title: "开机自启动"
                    SuretySwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.autoLaunch
                        onToggled: function(v) { root.autoLaunch = v }
                    }
                }
                RowSetting {
                    title: "关闭窗口时最小化到托盘"
                    SuretySwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.minimizeToTray
                        onToggled: function(v) { root.minimizeToTray = v }
                    }
                }
            }

            // ── 播放 (整组折叠, 其余分类保持平铺) ──
            SuretyCollapse {
                visible: root.catIdx === 2
                width: parent.width
                title: "播放"
                subtitle: "音质、歌词与系统集成"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    Column {
                        anchors { left: parent.left; right: parent.right }
                        bottomPadding: 6
                        RowSetting {
                            title: "默认音质"
                            ctrlReserve: 290   // 横向分段选择占位更宽, 标题区让出更多
                            SuretyTagSelector {
                                anchors.verticalCenter: parent.verticalCenter
                                displayMode: "segment"
                                selectedIndex: root.qualityIdx
                                model: [ { label: "标准品质" }, { label: "较高品质" }, { label: "无损品质" } ]
                                onTagSelected: function(i) { root.qualityIdx = i }
                            }
                        }
                        RowSetting {
                            title: "桌面歌词"
                            subtitle: "置顶歌词窗, 不挡工作区"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.desktopLyric
                                onToggled: function(v) { root.desktopLyric = v }
                            }
                        }
                        RowSetting {
                            title: "系统媒体控制 (SMTC)"
                            subtitle: "Windows 媒体面板与音量条显示歌曲信息"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.smtcEnabled
                                onToggled: function(v) { root.smtcEnabled = v }
                            }
                        }
                        RowSetting {
                            title: "受限音源自动降级"
                            subtitle: "某个插件不可用时, 自动用其他音源补齐同一首歌"
                            SuretySwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: root.autoDegrade
                                onToggled: function(v) { root.autoDegrade = v }
                            }
                        }
                    }
                }
            }

            // ── 下载 ──
            Column {
                visible: root.catIdx === 3
                width: parent.width
                RowSetting {
                    title: "下载目录"
                    subtitle: root.downloadDir
                }
                RowSetting {
                    title: "同时下载歌词"
                    SuretySwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.downloadLyric
                        onToggled: function(v) { root.downloadLyric = v }
                    }
                }
            }

            // ── 数据管理 ──
            Column {
                visible: root.catIdx === 4
                width: parent.width
                RowSetting {
                    title: "清理缓存"
                    subtitle: "当前占用 23.4 MB"
                    SuretyBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "清理"
                        variant: "outline"
                        font.pixelSize: 11
                        onClicked: {}   // 待接 CacheService
                    }
                }
                RowSetting {
                    title: "清空搜索历史"
                    SuretyBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "清空"
                        variant: "outline"
                        font.pixelSize: 11
                        onClicked: MockData.clearSearchHistory()
                    }
                }
            }

            // ── 插件 ──
            Column {
                visible: root.catIdx === 5
                width: parent.width
                RowSetting {
                    title: "插件管理"
                    subtitle: "已启用 " + MockData.plugins.filter(function(p) { return p.enabled }).length + " 个插件"
                    clickable: true
                    onClicked: root.navigate("plugins")
                }
            }

            // ── 关于 (版本/检查 + 协议折叠卡, BallsHackPro 同款结构) ──
            Column {
                visible: root.catIdx === 6
                width: parent.width
                RowSetting {
                    title: "版本"
                    subtitle: "CloudSong 0.1.0 (原型)"
                }
                RowSetting {
                    title: "检查更新"
                    subtitle: "当前为最新版本"
                    SuretyBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "检查"
                        variant: "outline"
                        font.pixelSize: 11
                    }
                }
                RowSetting {
                    title: "开源协议"
                    subtitle: "GPL-3.0 · 插件协议兼容 MusicFree"
                }
                Item { width: 1; height: 8 }   // 行与折叠卡之间额外留白
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

五、免责声明
5.1 本软件按"现状"提供，开发者不对插件可用性、音源稳定性及任何第三方服务作出保证。
5.2 因不可抗力、网络故障或第三方原因造成的服务中断，开发者不承担责任。

六、法律适用
本协议的解释与执行适用中华人民共和国法律。如对协议内容有疑问，请联系开发者。`
                            font { family: "Microsoft YaHei UI"; pixelSize: 12 }
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
                            font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                            color: Theme.text_secondary
                            wrapMode: Text.WordWrap
                            lineHeight: 1.6
                        }
                    }
                }
                Item { width: 1; height: 8 }   // 折叠卡之间额外留白
                SuretyCollapse {
                    width: parent.width
                    title: "开源许可"
                    subtitle: "基于以下开源项目构建"
                    titlePadding: 12
                    titleFontSize: 14
                    subtitleFontSize: 11
                    content: Component {
                        Text {
                            anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                            topPadding: 4
                            bottomPadding: 14
                            text: `本软件基于以下开源项目与协议构建，谨此致谢：

· Qt Framework 6.11 — LGPL-3.0 / GPL-3.0 / 商业许可 (https://www.qt.io)
· MusicFree 插件协议 — GPL-3.0 (https://github.com/maotoumao/MusicFree)

本软件本体以 GPL-3.0 发布，插件生态与 MusicFree 协议兼容。`
                            font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                            color: Theme.text_secondary
                            wrapMode: Text.WordWrap
                            lineHeight: 1.6
                        }
                    }
                }
            }
        }
    }

    // ── 设置行 (2026-09-28 用户拍板: 行本体不接任何鼠标事件, 只有行内组件可交互;
    //    clickable=true 时右侧自动渲染可点箭头组件, 由箭头承载点击) ──
    component RowSetting: Item {
        id: rs
        width: parent.width
        height: 52
        property string title: ""
        property string subtitle: ""
        property int ctrlReserve: 170   // 右侧控件保留宽度 (音质等横向分段选择需更大)
        property bool clickable: false
        signal clicked()
        default property alias ctrl: ctrlRow.data

        Column {
            anchors { left: rs.left; leftMargin: 14; right: rs.right; rightMargin: rs.ctrlReserve; verticalCenter: rs.verticalCenter }
            spacing: 2
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: rs.title
                font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: rs.subtitle !== ""
                text: rs.subtitle
                font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                color: Theme.text_secondary
            }
        }
        Row {
            id: ctrlRow
            // clickable 时给箭头让出右侧位置
            anchors { right: rs.right; rightMargin: rs.clickable ? 38 : 14; verticalCenter: rs.verticalCenter }
            spacing: 8
        }
        // 进入箭头 (唯一可点区域; 行本体无鼠标事件)
        IconImage {
            visible: rs.clickable
            anchors { right: rs.right; rightMargin: 14; verticalCenter: rs.verticalCenter }
            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
            color: Theme.text_hint
            size: 14
            MouseArea {
                z: 1
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: rs.clicked()
            }
        }
    }

    // ── P1 小徽标 ──
    component Badge: Rectangle {
        height: 16
        width: badgeText.implicitWidth + 10
        radius: 8
        property string text: ""
        color: Theme.tag_preset_bg
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: parent.text
            font { family: "Microsoft YaHei UI"; pixelSize: 10 }
            color: Theme.tag_preset_fg
        }
    }
}
