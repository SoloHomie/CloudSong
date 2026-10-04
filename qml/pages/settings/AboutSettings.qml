import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components/buttons"
import "../../components/layout"
import "../../templates"
import "about"

// ═══════════════════════════════════════════════════════════════
//  AboutSettings — 设置子页面: 关于 (版本/更新 / 开源致谢 / 协议与隐私)
//  BallsHackPro 同款布局: 品牌头部区 + 折叠卡
//  折叠卡内容物已抽离到 about/ (OpenSourceContent 等)
//  2026-10-02 自 SettingsPage 拆分; 2026-10-04 底部弹簧+内容物抽离
// ═══════════════════════════════════════════════════════════════
SettingSubPage {
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

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: Math.min(parent.width - 48, 680)
        height: Math.max(implicitHeight, root.height)   // root=视口高(勿用 parent.height, 与 contentHeight 成环)
        spacing: 3

        // 头部: 应用名 + 版本(可点跳仓库) + 检查更新按钮
        Column {
            Layout.fillWidth: true
            spacing: 5
            Text {
                text: "CloudSong"
                font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
                color: Theme.text_primary
            }
            Row {
                spacing: 5
                Text {
                    text: "Version 1.0.0"
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
        Item { Layout.preferredHeight: 4 }
        // ═══ Open Source Notice ═══
        SuretyCollapse {
            Layout.fillWidth: true
            title: "Open Source Notice"
            subtitle: "本软件使用了以下开源组件，谨此致谢"
            titlePadding: 10
            titleFontSize: 14
            subtitleFontSize: 11
            content: Component { OpenSourceContent {} }
        }
        Item { Layout.preferredHeight: 6 }   // 折叠卡之间额外留白
        SuretyCollapse {
            Layout.fillWidth: true
            title: "用户协议"
            subtitle: "最后更新日期: 2026 年 9 月 28 日"
            titlePadding: 10
            titleFontSize: 14
            subtitleFontSize: 11
            content: Component { UserAgreementContent {} }
        }
        Item { Layout.preferredHeight: 6 }   // 折叠卡之间额外留白
        SuretyCollapse {
            Layout.fillWidth: true
            title: "隐私政策"
            subtitle: "最后更新日期: 2026 年 9 月 28 日"
            titlePadding: 10
            titleFontSize: 14
            subtitleFontSize: 11
            content: Component { PrivacyContent {} }
        }
        Item { Layout.preferredHeight: 6 }   // 折叠卡之间额外留白
        SuretyCollapse {
            Layout.fillWidth: true
            title: "软件许可"
            subtitle: "GPL-3.0 — Copyright © 2026 Homie"
            titlePadding: 10
            titleFontSize: 14
            subtitleFontSize: 11
            content: Component { LicenseContent {} }
        }
        // 底部弹簧: 吸收剩余空间; 内容超高滚动时保底 24 底部留白
        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 24
        }
    }
}
