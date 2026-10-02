import QtQuick
import "../../components/display"
import "../../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  RecommendPage — 推荐页外壳 (TabBar + 子页面容器)
//  2026-10-01 个性化重做: Tab1 为你推荐模块化首页 / Tab2 排行榜
//  2026-10-02 拆分: 两 tab 内容拆为 qml/pages/recommend/ 子页面
//  (ForYouView 为你推荐 / RankingView 排行榜), 模块体组件与排序小按钮
//  MoveBtn 均归入本目录; 本页只剩 TabBar+「自定义首页」按钮+子页容器, 视觉交互零变化
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    TabBar {
        id: tabs
        anchors { top: parent.top; topMargin: 20; left: parent.left; leftMargin: 24 }
        items: [{ text: "为你推荐" }, { text: "排行榜" }]
    }

    // 自定义首页 (仅推荐 tab; 编辑态变「完成」)
    SuretyBtn {
        anchors { top: parent.top; topMargin: 20; right: parent.right; rightMargin: 24 }
        visible: tabs.activeIndex === 0
        height: 30
        variant: forYou.editing ? "primary" : "outline"
        font.pixelSize: 12
        text: forYou.editing ? "完成" : "自定义首页"
        onClicked: forYou.editing = !forYou.editing
    }

    // ══ Tab 0: 为你推荐 (模块化) ══
    ForYouView {
        id: forYou
        anchors { top: tabs.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: tabs.activeIndex === 0
        onNavigate: function(name, params) { root.navigate(name, params) }
    }

    // ══ Tab 1: 排行榜 ══
    RankingView {
        id: ranking
        anchors { top: tabs.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: tabs.activeIndex === 1
        onNavigate: function(name, params) { root.navigate(name, params) }
    }
}
