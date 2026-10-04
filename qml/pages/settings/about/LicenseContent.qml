import QtQuick
import "../../../theme"

// ═══════════════════════════════════════════════════════════════
//  LicenseContent — "软件许可" 折叠卡内容物
//  GPL-3.0 中文摘要
//  2026-10-04 自 AboutSettings 抽离
// ═══════════════════════════════════════════════════════════════
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
