import QtQuick
import "../../components/business"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  ListenModePage — 听歌模式 (原版 FullscreenPlayer 页面化)
//   听歌区共用 components/business/LyricPlayer (封面+逐行歌词高亮,
//   字号/翻译属性由 LyricPlayer 持有; 本页曾缺 lyricFontSize 定义, 提取时已修)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    LyricPlayer {
        anchors.fill: parent
        subtitleHint: "从下方播放条选择歌曲"
    }

    // (工具小圆片 ToolChip 2026-10-02 移入 components/controls, 推荐页同款听歌页共用)
}
