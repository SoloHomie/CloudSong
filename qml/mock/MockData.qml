import QtQuick
pragma Singleton

// ═══════════════════════════════════════════════════════════════
//  MockData — 模拟数据层 (全部为纯展示假数据)
//
//  C++ 数据服务落地后逐项替换, 各页代码零改动:
//    songs / sheets / toplists / albums / artists → 插件协议数据 (C++ 服务)
//    searchHistory                                → C++ SearchHistoryService
//    plugins                                      → C++ PluginManager
//    downloads / folders                          → C++ DownloadManager / 本地库
// ═══════════════════════════════════════════════════════════════
QtObject {
    id: root

    // 封面占位配色 (seed 索引)
    readonly property var palette: ["#8957e5", "#1f6feb", "#238636", "#b35900", "#d1242f", "#8250df", "#0a7e8c", "#6e40c9"]

    function fmtTime(ms) {
        if (!ms || ms < 0) return "--:--"
        var t = Math.floor(ms / 1000)
        var m = Math.floor(t / 60)
        var s = t % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // ── 歌曲 ──
    property var songs: [
        {id: "s01", title: "晴天",        artist: "周杰伦",   album: "叶惠美",       duration: 269000, platform: "网易云", liked: true,  seed: 1},
        {id: "s02", title: "平凡之路",    artist: "朴树",     album: "猎户星座",     duration: 302000, platform: "网易云", liked: false, seed: 2},
        {id: "s03", title: "山丘",        artist: "李宗盛",   album: "山丘",         duration: 412000, platform: "QQ音乐", liked: true,  seed: 3},
        {id: "s04", title: "夜空中最亮的星", artist: "逃跑计划", album: "世界",       duration: 252000, platform: "网易云", liked: false, seed: 4},
        {id: "s05", title: "成都",        artist: "赵雷",     album: "无法长大",     duration: 323000, platform: "网易云", liked: true,  seed: 5},
        {id: "s06", title: "理想",        artist: "赵雷",     album: "无法长大",     duration: 289000, platform: "网易云", liked: false, seed: 5},
        {id: "s07", title: "南方姑娘",    artist: "赵雷",     album: "赵小雷",       duration: 296000, platform: "网易云", liked: false, seed: 5},
        {id: "s08", title: "浮夸",        artist: "陈奕迅",   album: "U87",          duration: 279000, platform: "QQ音乐", liked: true,  seed: 6},
        {id: "s09", title: "十年",        artist: "陈奕迅",   album: "黑白灰",       duration: 226000, platform: "QQ音乐", liked: false, seed: 6},
        {id: "s10", title: "好久不见",    artist: "陈奕迅",   album: "认了吧",       duration: 246000, platform: "QQ音乐", liked: false, seed: 6},
        {id: "s11", title: "稻香",        artist: "周杰伦",   album: "魔杰座",       duration: 223000, platform: "网易云", liked: true,  seed: 1},
        {id: "s12", title: "七里香",      artist: "周杰伦",   album: "七里香",       duration: 298000, platform: "网易云", liked: false, seed: 1},
        {id: "s13", title: "海阔天空",    artist: "Beyond",   album: "乐与怒",       duration: 325000, platform: "QQ音乐", liked: true,  seed: 7},
        {id: "s14", title: "光辉岁月",    artist: "Beyond",   album: "命运派对",     duration: 301000, platform: "QQ音乐", liked: false, seed: 7},
        {id: "s15", title: "斑马斑马",    artist: "宋冬野",   album: "安和桥北",     duration: 274000, platform: "网易云", liked: false, seed: 0},
        {id: "s16", title: "董小姐",      artist: "宋冬野",   album: "安和桥北",     duration: 264000, platform: "网易云", liked: false, seed: 0},
        {id: "s17", title: "起风了",      artist: "买辣椒也用券", album: "起风了",    duration: 287000, platform: "网易云", liked: true,  seed: 8},
        {id: "s18", title: "海底",        artist: "一支榴莲", album: "海底",         duration: 268000, platform: "网易云", liked: false, seed: 2}
    ]

    // ── 歌单 ──
    property var sheets: [
        {id: "p01", title: "华语经典 2000s",  subtitle: "云谣编辑部",   count: 120, seed: 1, platform: "网易云", desc: "千禧年华语乐坛的黄金年代, 每一首都是青春。"},
        {id: "p02", title: "深夜民谣电台",    subtitle: "云谣编辑部",   count: 86,  seed: 2, platform: "网易云", desc: "适合一个人听的民谣, 城市与远方的歌。"},
        {id: "p03", title: "粤语老歌珍藏",    subtitle: "老歌迷",       count: 64,  seed: 6, platform: "QQ音乐", desc: "Beyond、陈奕迅与那个时代的港乐。"},
        {id: "p04", title: "雨天咖啡馆",      subtitle: "云谣编辑部",   count: 45,  seed: 0, platform: "网易云", desc: "轻爵士与温暖人声, 雨天的标配。"},
        {id: "p05", title: "通勤路上听的歌",  subtitle: "通勤族",       count: 98,  seed: 3, platform: "QQ音乐", desc: "把拥挤的地铁变成自己的演唱会。"},
        {id: "p06", title: "我的歌单",        subtitle: "我",           count: 23,  seed: 5, platform: "本地",   desc: "自己收藏的零零碎碎, 都是心情。"}
    ]

    // ── 收藏的歌单 ──
    property var starredSheets: [
        {id: "sp01", title: "学习专注 白噪音", subtitle: "StudyHub", count: 52, seed: 7, platform: "网易云", desc: "提升专注力的白噪音合集。"},
        {id: "sp02", title: "周杰伦全部专辑",  subtitle: "JayFan",   count: 187, seed: 1, platform: "网易云", desc: "从 Jay 到最伟大的作品。"}
    ]

    // ── 自建歌单 (新建歌单弹窗写入; 侧栏"创建的歌单"分组与我的歌单页消费; 待 C++ SheetService 替换) ──
    // 注意: createdSheetsChanged 为属性自动变更信号, 勿重复声明 (2026-10-01 qmllint 实锤)
    property var createdSheets: []
    function addCreatedSheet(title) {
        createdSheets = createdSheets.concat([{ id: "m" + Date.now(), title: title, subtitle: "我",
                                                count: 0, seed: 2, platform: "本地" }])
        createdSheetsChanged()
    }

    // ── 榜单 ──
    property var toplists: [
        {id: "t01", title: "飙升榜",   platform: "网易云", seed: 1, top3: ["起风了", "晴天", "海底"]},
        {id: "t02", title: "热歌榜",   platform: "网易云", seed: 3, top3: ["晴天", "平凡之路", "成都"]},
        {id: "t03", title: "新歌榜",   platform: "QQ音乐", seed: 6, top3: ["十年", "浮夸", "海阔天空"]},
        {id: "t04", title: "流行指数榜", platform: "网易云", seed: 0, top3: ["夜空中最亮的星", "董小姐", "斑马斑马"]},
        {id: "t05", title: "民谣热歌榜", platform: "网易云", seed: 2, top3: ["成都", "南方姑娘", "理想"]}
    ]

    // ── 专辑 ──
    property var albums: [
        {id: "a01", title: "叶惠美",    artist: "周杰伦",   date: "2003", count: 11, seed: 1, platform: "网易云"},
        {id: "a02", title: "无法长大",  artist: "赵雷",     date: "2016", count: 10, seed: 5, platform: "网易云"},
        {id: "a03", title: "U87",       artist: "陈奕迅",   date: "2005", count: 10, seed: 6, platform: "QQ音乐"},
        {id: "a04", title: "安和桥北",  artist: "宋冬野",   date: "2013", count: 9,  seed: 0, platform: "网易云"},
        {id: "a05", title: "乐与怒",    artist: "Beyond",   date: "1993", count: 12, seed: 7, platform: "QQ音乐"},
        {id: "a06", title: "七里香",    artist: "周杰伦",   date: "2004", count: 10, seed: 1, platform: "网易云"}
    ]

    // ── 歌手 ──
    property var artists: [
        {id: "ar01", name: "周杰伦",   desc: "华语流行天王",   seed: 1, platform: "网易云"},
        {id: "ar02", name: "陈奕迅",   desc: "港乐代表歌手",   seed: 6, platform: "QQ音乐"},
        {id: "ar03", name: "赵雷",     desc: "民谣唱作人",     seed: 5, platform: "网易云"},
        {id: "ar04", name: "Beyond",   desc: "摇滚乐队",       seed: 7, platform: "QQ音乐"},
        {id: "ar05", name: "宋冬野",   desc: "民谣歌手",       seed: 0, platform: "网易云"},
        {id: "ar06", name: "朴树",     desc: "唱作人",         seed: 2, platform: "网易云"}
    ]

    // ── 推荐歌单标签 ──
    property var tags: ["全部", "流行", "民谣", "摇滚", "电子", "国风", "轻音乐"]

    // ── 插件 ──
    property var plugins: [
        {id: "pl01", name: "网易云音乐", version: "0.5.0", enabled: true,  desc: "搜索/歌单/榜单/歌词"},
        {id: "pl02", name: "QQ音乐",     version: "0.3.2", enabled: true,  desc: "搜索/歌单/歌词"},
        {id: "pl03", name: "本地音乐",   version: "1.0.0", enabled: true,  desc: "内置本地库插件"},
        {id: "pl04", name: "咪咕音乐",   version: "0.2.1", enabled: false, desc: "搜索/榜单"}
    ]

    // ── 下载任务 ──
    property var downloads: [
        {id: "d01", name: "晴天 - 周杰伦.mp3",        size: "8.2 MB", progress: 72,  status: "downloading"},
        {id: "d02", name: "平凡之路 - 朴树.mp3",      size: "11.1 MB", progress: 35, status: "downloading"},
        {id: "d03", name: "山丘 - 李宗盛.mp3",        size: "14.3 MB", progress: 0,  status: "paused"},
        {id: "d04", name: "起风了 - 买辣椒也用券.mp3", size: "9.6 MB", progress: 0,  status: "error"},
        {id: "d05", name: "成都 - 赵雷.mp3",          size: "12.0 MB", progress: 100, status: "done"}
    ]

    // ── 本地文件夹树 ──
    property var folders: [
        {name: "D:\\Music", children: [
            {name: "周杰伦", children: [{name: "叶惠美"}, {name: "七里香"}]},
            {name: "陈奕迅", children: [{name: "U87"}, {name: "黑白灰"}]},
            {name: "单曲", children: []}
        ]},
        {name: "E:\\下载", children: []}
    ]

    // ── 歌词 (听歌模式演示) ──
    property var lyrics: [
        {t: "故事的小黄花",   tt: "The little yellow flowers of the story"},
        {t: "从出生那年就飘着", tt: "Have been drifting since the year I was born"},
        {t: "童年的荡秋千",   tt: "The swing of childhood"},
        {t: "随记忆一直晃到现在", tt: "Keeps swaying in memory until now"},
        {t: "Re So So Si Do Si La", tt: ""},
        {t: "So La Si Si Si Si La Si La So", tt: ""},
        {t: "吹着前奏望着天空", tt: "Blowing the prelude, gazing at the sky"},
        {t: "我想起花瓣试着掉落", tt: "I think of petals trying to fall"},
        {t: "为你翘课的那一天", tt: "The day I skipped class for you"},
        {t: "花落的那一天",   tt: "The day the flowers fell"},
        {t: "教室的那一间",   tt: "That classroom"},
        {t: "我怎么看不见",   tt: "Why can't I see it"},
        {t: "消失的下雨天",   tt: "The vanished rainy day"},
        {t: "我好想再淋一遍",  tt: "I want to get drenched again"}
    ]

    // ── 搜索历史 ──
    // 示例种子 (2026-09-29 用户要看效果; 覆盖歌手/歌名/歌单词/英文词,
    // 超 8 条可验证面板滚动 + "周"前缀双命中验证建议面板, 接 C++ 服务后清空)
    property var searchHistory: ["周杰伦", "晴天", "民谣", "陈奕迅", "lofi 学习",
                                  "七里香", "网易云热歌", "周深", "钢琴曲", "beyond",
                                  "海阔天空", "City Pop"]

    function addSearchHistory(q) {
        var arr = searchHistory.slice()
        var i = arr.indexOf(q)
        if (i >= 0) arr.splice(i, 1)
        arr.unshift(q)
        if (arr.length > 20) arr = arr.slice(0, 20)   // 上限 20 (规格 D4)
        searchHistory = arr
    }
    function clearSearchHistory() { searchHistory = [] }
    function removeSearchHistory(q) {   // 单条删除 (标题栏历史面板 hover ×)
        var arr = searchHistory.slice()
        var i = arr.indexOf(q)
        if (i >= 0) arr.splice(i, 1)
        searchHistory = arr
    }
    function suggestHistory(q) {   // 建议面板: 历史前缀匹配, 忽略大小写, 最多 8 条
        var s = String(q || "").toLowerCase()
        if (s === "") return []
        var r = []
        for (var i = 0; i < searchHistory.length && r.length < 8; i++)
            if (String(searchHistory[i]).toLowerCase().indexOf(s) === 0) r.push(searchHistory[i])
        return r
    }

    // ── 查询 ──
    function searchAll(query) {
        var q = String(query || "").toLowerCase()
        if (q === "") return { songs: [], albums: [], artists: [], sheets: [] }
        function hit() {
            var r = []
            for (var i = 0; i < arguments.length; i++) r.push(String(arguments[i] || "").toLowerCase().indexOf(q) >= 0)
            return r.indexOf(true) >= 0
        }
        var s = [], al = [], ar = [], sh = []
        for (var i = 0; i < songs.length; i++)
            if (hit(songs[i].title, songs[i].artist, songs[i].album)) s.push(songs[i])
        for (i = 0; i < albums.length; i++)
            if (hit(albums[i].title, albums[i].artist)) al.push(albums[i])
        for (i = 0; i < artists.length; i++)
            if (hit(artists[i].name)) ar.push(artists[i])
        for (i = 0; i < sheets.length; i++)
            if (hit(sheets[i].title)) sh.push(sheets[i])
        return { songs: s, albums: al, artists: ar, sheets: sh }
    }

    // 歌单/榜单/专辑 的歌曲列表: 从歌曲池切一段 (模拟)
    function songsForSheet(seed, count) {
        var r = []
        var start = (seed * 3) % songs.length
        var n = Math.min(count || 8, songs.length)
        for (var i = 0; i < n; i++) r.push(songs[(start + i) % songs.length])
        return r
    }
}
