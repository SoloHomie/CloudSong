import QtQuick
import "../../../theme"

// ═══════════════════════════════════════════════════════════════
//  PrivacyContent — "隐私政策" 折叠卡内容物
//  2026-10-04 自 AboutSettings 抽离
// ═══════════════════════════════════════════════════════════════
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
