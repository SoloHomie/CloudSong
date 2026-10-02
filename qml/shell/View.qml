import QtQuick
import "../theme"
import "../pages"
import "../pages/recommend"
import "../pages/settings"
import "../pages/listenmode"
import "../components/transition"

// ═══════════════════════════════════════════════════════════════
//  View — 内容显示区: 页面栈 (四大板块之一)
//
//  侧栏 5+2 主页面 = 根页面 (switchRoot); 详情/搜索/设置等 = push 入栈;
//  TitleBar 后退/前进 绑定 canGoBack/canGoForward。
//
//  页面契约: 每页有 params 属性与 navigate(name, params) 信号;
//  特殊名: "$back"=返回上一页, "$auth"=请求打开登录弹窗(转发 authRequested)。
//  过渡动画 = PageSwitch 统一转场 (前进右滑入/后退左滑入/根切换淡入, 2026-10-01);
//  栈持久化待接。
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: view
    color: "transparent"   // 画布底色归 main.qml 窗口背景层 (云母/亚克力材质需透出)

    property var stack: []
    property int cursor: -1
    property var rootNames: ["recommend", "listen", "favorite", "history", "sheets", "local", "downloads"]
    // 转场方向 (PageSwitch 消费): 0=根切换淡入 1=前进右滑入 -1=后退左滑入
    property int transitionDirection: 0

    readonly property bool canGoBack: cursor > 0
    readonly property bool canGoForward: cursor < stack.length - 1
    readonly property string currentName: cursor >= 0 && cursor < stack.length ? stack[cursor].name : ""
    signal authRequested()

    // ── 导航 ──
    function switchRoot(idx) {
        transitionDirection = 0
        stack = [{ name: rootNames[idx], params: {} }]
        cursor = 0
    }
    function push(name, params) {
        if (name === "$back") { back(); return }
        if (name === "$auth") { authRequested(); return }
        transitionDirection = 1
        var arr = stack.slice(0, cursor + 1)
        arr.push({ name: name, params: params !== undefined ? params : {} })
        stack = arr
        cursor = arr.length - 1
    }
    function back() { if (cursor > 0) { transitionDirection = -1; cursor-- } }
    function forward() { if (cursor < stack.length - 1) { transitionDirection = 1; cursor++ } }

    function componentFor(name) {
        switch (name) {
        case "recommend":  return recommendComp
        case "listen":     return listenComp
        case "favorite":   return favoriteComp
        case "history":    return historyComp
        case "sheets":     return sheetsComp
        case "local":      return localComp
        case "downloads":  return downloadsComp
        case "search":     return searchComp
        case "sheet":      return sheetComp
        case "album":      return albumComp
        case "artist":     return artistComp
        case "settings":   return settingsComp
        }
        return recommendComp
    }

    PageSwitch {
        id: pageLoader
        anchors.fill: parent
        sourceComponent: view.cursor >= 0 ? view.componentFor(view.stack[view.cursor].name) : null
        direction: view.transitionDirection
        // 新页实例就绪 (动画开始前): 接 navigate + 注入 params
        onPageLoaded: function(item) {
            item.navigate.connect(view.push)
            view.applyCurrent()
        }
    }

    onCursorChanged: Qt.callLater(applyCurrent)   // 同组件连续 push (sheet→sheet) 无转场, 靠此更新 params
    function applyCurrent() {
        if (!pageLoader.item || view.cursor < 0) return
        pageLoader.item.params = view.stack[view.cursor].params
    }

    Component.onCompleted: switchRoot(0)

    // ── 页面组件注册 ──
    Component { id: recommendComp;  RecommendPage {} }
    Component { id: listenComp;     ListenModePage {} }
    Component { id: favoriteComp;   FavoritePage {} }
    Component { id: historyComp;    HistoryPage {} }
    Component { id: sheetsComp;     MySheetsPage {} }
    Component { id: localComp;      LocalMusicPage {} }
    Component { id: downloadsComp;  DownloadPage {} }
    Component { id: searchComp;     SearchPage {} }
    Component { id: sheetComp;      SheetDetailPage {} }
    Component { id: albumComp;      AlbumDetailPage {} }
    Component { id: artistComp;     ArtistDetailPage {} }
    Component { id: settingsComp;   SettingsPage {} }
}
