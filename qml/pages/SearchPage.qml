import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  SearchPage — 搜索页 (M0.5 真实插件版, 定案 §5)
//   歌曲/专辑/歌手/歌单 四类型 tab; 插件来源单选 chips (全部=拼接);
//   Plugins.search(requestId 异步) → 按 (type|platform) 缓存,
//   分tab不去重 (MusicFree 单源语义, 非 Mineradio 全并), 首屏只取第 1 页;
//   热词/历史/播放仍走 Mock (M0 假源, 待用户播放内核接入)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property string query: params.query !== undefined ? params.query : ""
    property int activeTab: 0
    property string selectedPlatform: ""   // "" = 全部 (各平台结果拼接不去重)
    property var typeKeys: ["music", "album", "artist", "sheet"]

    // ── 插件搜索状态 ──
    property var cache: ({})        // key "type|platform" → items
    property var errors: ({})       // key → "code: message"
    property var pendingIds: ({})   // requestId → {type,platform,key,gen}
    property int gen: 0             // query 换代计数, 过期结果直接丢弃

    // ── 工具 ──
    function seedOf(s) {
        if (s === undefined || s === null) return 0
        var str = String(s), h = 0
        for (var i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) | 0
        return ((h % 8) + 8) % 8
    }
    function typeKeyOf() { return root.typeKeys[root.activeTab] }
    function targets() {
        var list = Plugins.searchablePlatforms(root.typeKeyOf())
        if (root.selectedPlatform === "") return list
        return list.indexOf(root.selectedPlatform) >= 0 ? [root.selectedPlatform] : []
    }
    // 全部 = 各平台缓存拼接 (分tab不去重); 单选 = 只取该平台
    function merged() {
        var out = [], key = root.typeKeyOf()
        var list = root.targets()
        for (var i = 0; i < list.length; i++) {
            var c = root.cache[key + "|" + list[i]]
            if (c !== undefined) out = out.concat(c)
        }
        return out
    }
    function pendingCount() {
        var n = 0, t = root.typeKeyOf()
        for (var k in root.pendingIds)
            if (root.pendingIds[k].type === t) n++
        return n
    }

    // ── 发起/聚合 ──
    // var 对象成员变异不触发绑定重算 (2026-10-02 实锤: cache[key]=data 定向失效,
    // SongTable model/空态文案停在前值) → 每次变异后重建对象强制通知
    // (同 SongTable.refreshModel 的 slice() 惯例)
    function bump() {
        root.pendingIds = Object.assign({}, root.pendingIds)
        root.cache = Object.assign({}, root.cache)
        root.errors = Object.assign({}, root.errors)
    }
    function startSearch(type, platform) {
        var key = type + "|" + platform
        if (root.cache[key] !== undefined) return
        for (var k in root.pendingIds)
            if (root.pendingIds[k].key === key) return   // 已在途
        var id = Plugins.search(root.query.trim(), 1, type, platform)
        root.pendingIds[id] = { type: type, platform: platform, key: key, gen: root.gen }
        root.bump()
    }
    function doSearch() {   // 关键词换代: 清缓存重搜
        root.cache = {}; root.errors = {}; root.gen++
        var keep = {}
        for (var k in root.pendingIds)
            if (root.pendingIds[k].gen === root.gen) keep[k] = root.pendingIds[k]
        root.pendingIds = keep
        var list = root.targets()
        for (var i = 0; i < list.length; i++) root.startSearch(root.typeKeyOf(), list[i])
    }
    function ensureSearch() {   // 换 tab/平台: 只补缺
        var list = root.targets()
        for (var i = 0; i < list.length; i++) root.startSearch(root.typeKeyOf(), list[i])
    }

    // ── 结果映射 (MediaGrid/SongTable 字段契约; 插件字段兜底) ──
    function songItems() { return root.merged() }
    function albumItems() {
        return root.merged().map(function(it) {
            return Object.assign({}, it, {
                title: it.title !== undefined ? it.title : "",
                subtitle: it.artist !== undefined ? it.artist : "",
                seed: it.seed !== undefined ? it.seed : root.seedOf(it.id),
                count: it.count !== undefined ? it.count : 0
            })
        })
    }
    function artistItems() {
        return root.merged().map(function(a) {
            return Object.assign({}, a, {
                title: a.name !== undefined ? a.name : (a.title !== undefined ? a.title : ""),
                subtitle: a.desc !== undefined ? a.desc : "",
                seed: a.seed !== undefined ? a.seed : root.seedOf(a.id)
            })
        })
    }
    function sheetItems() {
        return root.merged().map(function(it) {
            return Object.assign({}, it, {
                title: it.title !== undefined ? it.title : "",
                subtitle: it.subtitle !== undefined ? it.subtitle
                        : (it.desc !== undefined ? it.desc : ""),
                seed: it.seed !== undefined ? it.seed : root.seedOf(it.id),
                count: it.count !== undefined ? it.count
                     : (it.worksNum !== undefined ? it.worksNum : 0)
            })
        })
    }
    function emptyMessageFor() {
        if (root.pendingCount() > 0) return "正在搜索…"
        var list = root.targets()
        if (list.length === 0)
            return Plugins.ready ? "当前类型没有可用的插件来源" : "插件加载中…"
        // 全灭才透出错误; 只要有来源成功返回(哪怕0条)就引导换词
        // (2026-10-02 实锤: 单来源失败时错误文案盖在"无结果"上, 网易云风控错误恒显)
        var err = "", anyOk = false
        for (var i = 0; i < list.length; i++) {
            var key = root.typeKeyOf() + "|" + list[i]
            if (root.errors[key] !== undefined) err = root.errors[key]
            else if (root.cache[key] !== undefined) anyOk = true
        }
        if (anyOk) return "换个关键词试试, 或调整上方来源筛选"
        return err !== "" ? "搜索失败: " + err : "换个关键词试试, 或调整上方来源筛选"
    }

    Component.onCompleted: if (root.query.trim() !== "") root.doSearch()

    // ── 插件回调 ──
    Connections {
        target: Plugins
        function onSearchFinished(id, isEnd, data) {
            var p = root.pendingIds[id]
            if (p === undefined) return
            delete root.pendingIds[id]
            if (p.gen === root.gen) root.cache[p.key] = data
            root.bump()
        }
        function onSearchFailed(id, code, message) {
            var p = root.pendingIds[id]
            if (p === undefined) return
            delete root.pendingIds[id]
            if (p.gen === root.gen) {
                root.errors[p.key] = code + ": " + message
                root.cache[p.key] = []
            }
            root.bump()
        }
        function onPluginsLoaded() {
            if (root.query.trim() !== "") root.doSearch()
        }
    }

    // 输入防抖 (VSYNC 失效环境, Timer 节流惯例)
    Timer {
        id: searchTimer
        interval: 300
        repeat: false
        onTriggered: root.doSearch()
    }

    // ── 顶部: 搜索框 + 插件来源 chips ──
    Column {
        anchors { top: parent.top; topMargin: 16; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        spacing: 10

        SuretyTextField {
            id: input
            width: 320
            height: 34
            placeholder: "搜索歌曲、歌手、专辑、歌单"
            text: root.query
            font.pixelSize: 13
            contentLeftPadding: 12
            contentRightPadding: 12
            onTextChanged: { root.query = text; searchTimer.restart() }
            onAccepted: if (text.trim() !== "") MockData.addSearchHistory(text.trim())
        }

        Row {
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "来源:"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_hint
            }
            Repeater {
                model: ["全部"].concat(Plugins.searchablePlatforms(root.typeKeyOf()))
                delegate: Rectangle {
                    height: 24
                    width: srcText.implicitWidth + 20
                    radius: 12
                    property bool isOn: (index === 0 && root.selectedPlatform === "")
                                       || root.selectedPlatform === modelData
                    color: isOn ? Theme.accent : Theme.bg_input
                    Text {
                        id: srcText
                        anchors.centerIn: parent
                        text: modelData
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        color: isOn ? "#ffffff" : Theme.text_secondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedPlatform = (index === 0) ? "" : modelData
                            if (root.query.trim() !== "") root.ensureSearch()
                        }
                    }
                }
            }
        }
    }

    // ── 无关键词: 热词兜底 ──
    Column {
        anchors { top: parent.top; topMargin: 110; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        visible: root.query.trim() === ""
        spacing: 12
        Text {
            text: "热门搜索"
            font { family: Theme.fontFamily; pixelSize: 14; weight: Font.Bold }
            color: Theme.text_primary
        }
        Row {
            spacing: 8
            Repeater {
                model: MockData.tags
                delegate: Rectangle {
                    height: 26
                    width: tagText.implicitWidth + 24
                    radius: 13
                    color: tagMouse.containsMouse ? Theme.hover_bg : Theme.bg_input
                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: modelData
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_primary
                    }
                    MouseArea {
                        id: tagMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.query = modelData; input.text = modelData }
                    }
                }
            }
        }
    }

    // ── 有结果: 类型 tab + 结果区 ──
    Column {
        anchors { top: parent.top; topMargin: 110; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.query.trim() !== ""

        TabBar {
            id: tabs
            anchors { left: parent.left; leftMargin: 24 }
            items: [{ text: "歌曲" }, { text: "专辑" }, { text: "歌手" }, { text: "歌单" }]
            onActivated: function(i) {
                root.activeTab = i
                root.selectedPlatform = ""
                if (root.query.trim() !== "") root.ensureSearch()
            }
        }

        Item {
            width: parent.width
            height: parent.height - tabs.height - 4
            anchors { left: parent.left }

            // 歌曲
            SongTable {
                anchors.fill: parent
                visible: root.activeTab === 0
                model: root.songItems()
                emptyTitle: root.pendingCount() > 0 ? "正在搜索…" : "没有找到相关歌曲"
                emptyMessage: root.emptyMessageFor()
                onPlayRequested: function(s, i) {
                    var list = root.songItems()
                    MockPlayback.loadQueue(list)
                    MockPlayback.playIndex(i)
                }
            }
            // 专辑
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 1
                cellWidth: 160
                model: root.albumItems()
                emptyTitle: root.pendingCount() > 0 ? "正在搜索…" : "没有找到相关专辑"
                emptyMessage: root.emptyMessageFor()
                onOpenRequested: function(it) {
                    root.navigate("album", it)   // 整项透传 (含 id/platform), 详情页据此拉真实专辑
                }
            }
            // 歌手
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 2
                cellWidth: 160
                model: root.artistItems()
                emptyTitle: root.pendingCount() > 0 ? "正在搜索…" : "没有找到相关歌手"
                emptyMessage: root.emptyMessageFor()
                onOpenRequested: function(it) {
                    root.navigate("artist", it)   // 整项透传 (含 id/platform), 详情页据此拉真实作品
                }
            }
            // 歌单
            MediaGrid {
                anchors { left: parent.left; leftMargin: 24; right: parent.right; bottom: parent.bottom }
                height: 2 * (cellWidth + 44) - 12
                visible: root.activeTab === 3
                cellWidth: 160
                model: root.sheetItems()
                emptyTitle: root.pendingCount() > 0 ? "正在搜索…" : "没有找到相关歌单"
                emptyMessage: root.emptyMessageFor()
                onOpenRequested: function(it) {
                    root.navigate("sheet", Object.assign({}, it, { kind: "sheet", remote: true }))   // remote=真实歌单详情
                }
            }
        }
    }
}
