import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  SettingsPage — 设置页 (分组: 服务/通用/播放/下载/数据/关于)
//  持久化待接 C++ ConfigService; 当前仅内存态
// ═══════════════════════════════════════════════════════════════
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
    property var qualityNames: ["标准品质", "较高品质", "无损品质"]

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: setCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: setCol
            x: 24
            width: parent.width - 48
            spacing: 18

            PageHeader {
                width: parent.width
                title: "设置"
                subtitle: "所有设置仅保存在本地"
            }

            // ── 服务 ──
            GroupBox {
                title: "订阅与数据服务"
                RowSetting {
                    title: "云漫游"
                    subtitle: "歌单与播放进度多设备同步 · ¥3/月"
                    onClicked: root.navigate("roam")
                    Badge { text: "P1" }
                }
                RowSetting {
                    title: "歌单迁移"
                    subtitle: "从 MusicFree 备份导入歌单 · 一次性买断"
                    onClicked: root.navigate("migrate")
                    Badge { text: "P1" }
                }
            }

            // ── 通用 ──
            GroupBox {
                title: "通用"
                RowSetting {
                    title: "主题"
                    subtitle: ["浅色", "深色", "跟随系统"][AppCfg.themeIndex]
                    onClicked: root.navigate("theme")
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
                        color: Theme.text_hint
                        size: 14
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

            // ── 播放 ──
            GroupBox {
                title: "播放"
                RowSetting {
                    title: "默认音质"
                    subtitle: root.qualityNames[root.qualityIdx]
                    onClicked: root.qualityIdx = (root.qualityIdx + 1) % 3
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

            // ── 下载 ──
            GroupBox {
                title: "下载"
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
            GroupBox {
                title: "数据管理"
                RowSetting {
                    title: "清理缓存"
                    subtitle: "当前占用 23.4 MB"
                    onClicked: {}
                    SuretyBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "清理"
                        variant: "outline"
                        font.pixelSize: 11
                    }
                }
                RowSetting {
                    title: "清空搜索历史"
                    onClicked: MockData.clearSearchHistory()
                    SuretyBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "清空"
                        variant: "outline"
                        font.pixelSize: 11
                    }
                }
            }

            // ── 插件 ──
            GroupBox {
                title: "插件"
                RowSetting {
                    title: "插件管理"
                    subtitle: "已启用 " + MockData.plugins.filter(function(p) { return p.enabled }).length + " 个插件"
                    onClicked: root.navigate("plugins")
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
                        color: Theme.text_hint
                        size: 14
                    }
                }
            }

            // ── 关于 ──
            GroupBox {
                title: "关于"
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
            }
        }
    }

    // ── 分组容器 (组件根给 id, 避免 parent 链静态解析) ──
    component GroupBox: Item {
        id: gb
        width: parent.width
        property string title: ""
        default property alias rows: rowsCol.data
        height: rowsCol.height + 30

        Text {
            anchors { top: gb.top; left: gb.left; leftMargin: 2 }
            text: gb.title
            font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: Font.Bold }
            color: Theme.text_hint
        }
        Column {
            id: rowsCol
            anchors { top: gb.top; topMargin: 26; left: gb.left; right: gb.right }
        }
    }

    // ── 设置行 (整行可点; 右侧控件声明在行 MouseArea 之上, 可独立点击) ──
    component RowSetting: Item {
        id: rs
        width: parent.width
        height: 52
        property string title: ""
        property string subtitle: ""
        signal clicked()
        default property alias ctrl: ctrlRow.data
        property bool hover: rowMouse.containsMouse

        Rectangle {
            anchors.fill: rs
            radius: 8
            color: rowMouse.containsMouse ? Theme.hover_bg : "transparent"
        }
        MouseArea {
            id: rowMouse
            anchors.fill: rs
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rs.clicked()
        }
        Column {
            anchors { left: rs.left; leftMargin: 14; right: rs.right; rightMargin: 170; verticalCenter: rs.verticalCenter }
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
            anchors { right: rs.right; rightMargin: 14; verticalCenter: rs.verticalCenter }
            spacing: 8
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
