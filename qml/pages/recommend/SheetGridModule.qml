import QtQuick
import "../../components/business"

// ═══════════════════════════════════════════════════════════════
//  SheetGridModule — 推荐页模块组件: 歌单网格 (猜你喜欢 / 精选歌单共用)
//  2026-10-02 自 RecommendPage 内联 forYouBody/featuredBody 提取;
//  两者同为 MediaGrid 配置仅 model 不同, 合并为一组件免重复代码。
//  根直接是 MediaGrid: model/openRequested 由调用方注入直通,
//  Loader 定高与原内联版行为一致 (根不可包空 Item, implicitHeight 为 0)
// ═══════════════════════════════════════════════════════════════
MediaGrid {
    cellWidth: 160
    height: 2 * (cellWidth + 44) - 12
}
