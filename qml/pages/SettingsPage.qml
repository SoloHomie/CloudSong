import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"
import "../components/controls"
import "../components/layout"
import "../components/panels"
import "../components/skeleton"

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
    property int fontIdx: 0               // 0 MiSans 1 微软雅黑 (待接 C++ ConfigService 持久化)
    property string downloadDir: "C:\\Users\\Lenovo\\Music"
    property int catIdx: 0                // 0服务 1通用 2播放 3下载 4数据 5插件 6关于
    property string latestVersion: ""     // 更新检测结果 (待接 C++ UpdaterService)
    property bool checkingUpdate: false

    onCatIdxChanged: flick.contentY = 0   // 切分类回到顶部

    // ── 骨架屏 (页面按需加载: 进页创建时后台加载数据, 就绪后填入真实内容) ──
    // loading 置 false 的时机 = 未来 C++ 数据服务完成回调; 当前由 mockLoadDelay 模拟耗时
    property bool loading: true
    Timer {
        id: loadTimer
        interval: MockData.mockLoadDelay
        repeat: false
        onTriggered: root.loading = false
    }
    Component.onCompleted: loadTimer.start()

    // 检查更新模拟 (待接 C++ UpdaterService 后移除)
    Timer {
        id: checkTimer
        interval: 1200
        repeat: false
        onTriggered: root.checkingUpdate = false
    }

    // ── 页头 ──
    PageHeader {
        id: pageHead
        anchors { top: parent.top; left: parent.left; right: parent.right }
        title: "设置"
        subtitle: "所有设置仅保存在本地"
    }

    // ── 顶部分类栏 (2026-09-28 换 CategoryBar tab 下划线导航; 分段控件语义=值选择,
    //    分类栏语义=视图切换, 不再复用 SuretyTagSelector) ──
    CategoryBar {
        id: catBar
        anchors { top: pageHead.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
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

            // ── 服务 (2026-09-29 用户拍板: 原跳独立页改为折叠卡内嵌, 内容即面板组件) ──
            SuretyCollapse {
                visible: root.catIdx === 0
                width: parent.width
                title: "云漫游"
                subtitle: "歌单与播放进度多设备同步 · ¥3/月"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    RoamPanel {
                        onNavigate: function(name, params) { root.navigate(name, params) }
                    }
                }
            }
            SuretyCollapse {
                visible: root.catIdx === 0
                width: parent.width
                title: "歌单迁移"
                subtitle: "截图 / 链接 / 文本 / 备份 → CloudSong 歌单 · 一次性买断"
                open: false
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component {
                    MigratePanel {
                        onNavigate: function(name, params) { root.navigate(name, params) }
                    }
                }
            }

            // ── 通用 ──
            Column {
                visible: root.catIdx === 1
                width: parent.width
                RowSetting {
                    title: "主题"
                    ctrlReserve: 290   // 同默认音质: 三段分段条占位
                    SuretyTagSelector {
                        anchors.verticalCenter: parent.verticalCenter
                        displayMode: "segment"
                        selectedIndex: AppCfg.themeIndex
                        model: [ { label: "浅色" }, { label: "深色" }, { label: "跟随系统" } ]
                        onTagSelected: function(i) { AppCfg.themeIndex = i }
                    }
                }
                RowSetting {
                    title: "背景材质"
                    subtitle: "云母 / 亚克力 · Windows 系统合成"
                    ctrlReserve: 290   // 三段分段条占位, 同主题行
                    SuretyTagSelector {
                        anchors.verticalCenter: parent.verticalCenter
                        displayMode: "segment"
                        selectedIndex: AppCfg.materialIndex
                        model: [ { label: "不透明" }, { label: "云母" }, { label: "亚克力" } ]
                        onTagSelected: function(i) { AppCfg.materialIndex = i }
                    }
                }
                RowSetting {
                    title: "界面字体"
                    subtitle: "全局生效 · 需重启后完全刷新"
                    SuretyComboBox {
                        anchors.verticalCenter: parent.verticalCenter
                        model: [ { text: "MiSans" }, { text: "微软雅黑" } ]
                        currentIndex: root.fontIdx
                        onItemSelected: function(i, t) {
                            root.fontIdx = i
                            // Theme 为单例可写; 全部组件 family 绑定此 token, 立即全局切换
                            Theme.fontFamily = i === 0 ? "MiSans VF" : "Microsoft YaHei UI"
                        }
                    }
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

            // ── 插件 (2026-09-29 用户拍板: 同折叠卡内嵌, 不再跳页) ──
            SuretyCollapse {
                visible: root.catIdx === 5
                width: parent.width
                title: "插件管理"
                subtitle: "已启用 " + MockData.plugins.filter(function(p) { return p.enabled }).length + " 个插件 · 兼容 MusicFree 插件协议"
                open: true
                titlePadding: 12
                titleFontSize: 14
                subtitleFontSize: 11
                content: Component { PluginsPanel {} }
            }

            // ── 关于 (BallsHackPro 同款布局: 品牌头部区 + 折叠卡) ──
            Column {
                visible: root.catIdx === 6
                width: parent.width
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

    // ── 设置行 (2026-09-28 用户拍板: 行本体不接任何鼠标事件, 只有行内组件可交互。
    //    2026-09-29 增补: clickable 导航行(云漫游/迁移/主题/插件等)行体全行可点+悬停反馈,
    //    点击层声明在最底层, 不抢行内组件; 含交互控件(开关/下拉)的行 clickable=false,
    //    点击层不激活, 铁律照旧) ──
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

        // 全行点击层 (最底层; 仅 clickable 行激活, 含交互控件的行不可见不拦截)
        Rectangle {
            visible: rs.clickable
            anchors.fill: parent
            radius: 8
            color: rowMouse.containsMouse ? Theme.hover_bg : "transparent"
        }
        MouseArea {
            id: rowMouse
            visible: rs.clickable
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rs.clicked()
        }

        Column {
            anchors { left: rs.left; leftMargin: 14; right: rs.right; rightMargin: rs.ctrlReserve; verticalCenter: rs.verticalCenter }
            spacing: 2
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: rs.title
                font { family: Theme.fontFamily; pixelSize: 14 }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: rs.subtitle !== ""
                text: rs.subtitle
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_secondary
            }
        }
        Row {
            id: ctrlRow
            // clickable 时给箭头让出右侧位置
            anchors { right: rs.right; rightMargin: rs.clickable ? 38 : 14; verticalCenter: rs.verticalCenter }
            spacing: 8
        }
        // 进入箭头 (视觉提示; 行体同样可点, 两者都发 clicked)
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

    // ── 骨架屏覆盖层 (loading 期间盖住真实内容; 不透明底 + 拦截点击, 就绪即消失) ──
    Rectangle {
        id: skeleton
        visible: root.loading
        anchors.fill: parent
        color: Theme.bg_page
        z: 10

        MouseArea { anchors.fill: parent }   // 骨架期间吞掉点击

        // 页头: 标题 + 副标题
        SkeletonBlock { x: 24; y: 22; width: 64; height: 20 }
        SkeletonBlock { x: 24; y: 50; width: 150; height: 12; radius: 6 }

        // 分类栏: 7 段胶囊
        Row {
            anchors { top: parent.top; topMargin: 84; horizontalCenter: parent.horizontalCenter }
            spacing: 8
            Repeater {
                model: 7
                delegate: SkeletonBlock { width: 44; height: 26; radius: 13 }
            }
        }

        // 内容区: 设置行 (标题行 + 副标题行 + 右侧控件占位) + 折叠卡块
        Item {
            id: skelCol
            anchors { top: parent.top; topMargin: 132; horizontalCenter: parent.horizontalCenter }
            width: Math.min(parent.width - 48, 680)
            height: 500
            Column {
                anchors { left: parent.left; right: parent.right }
                spacing: 18
                Repeater {
                    model: 5
                    delegate: Item {
                        width: skelCol.width
                        height: 52
                        SkeletonBlock { anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                        width: 170; height: 14 }
                        SkeletonBlock { anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 8 }
                                        width: 220; height: 12; radius: 6 }
                        SkeletonBlock {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            width: [36, 110, 36, 120, 60][index]
                            height: [20, 26, 20, 24, 24][index]
                            radius: 6
                        }
                    }
                }
                SkeletonBlock { width: parent.width; height: 44; radius: 8 }   // 折叠卡头
                Repeater {
                    model: 2
                    delegate: Item {
                        width: skelCol.width
                        height: 52
                        SkeletonBlock { anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                        width: 150; height: 14 }
                        SkeletonBlock { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                        width: 60; height: 24; radius: 5 }
                    }
                }
            }
        }
    }
}
