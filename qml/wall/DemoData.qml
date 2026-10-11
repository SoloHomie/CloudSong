import QtQuick
pragma Singleton

// M1 首页墙 demo 数据与几何 (纯 Mock; 服务实装后按《服务接口定案》替换)
// 内容名字全部自写 (通用语汇), 结构自定 — 净室, 不取自参照项目
QtObject {
    // ---- 页签 (首页窄缝里的竖排按钮) ----
    readonly property var tabs: [
        { key: "playlist", label: "歌单" },
        { key: "album", label: "专辑" },
        { key: "artist", label: "歌手" },
        { key: "local", label: "本地" }
    ]

    function tabKey(i) { return tabs[i].key }
    function tabLabel(i) { return tabs[i].label }

    // ---- 世界几何 ----
    // 格 128 + 缝 8 = 步距 136; 块 = 12×8 格 (96 格), 块推进 = 12*136 × 8*136
    readonly property real cell: 128
    readonly property real gap: 8
    readonly property real pitch: cell + gap
    readonly property int blockCols: 12
    readonly property int blockRows: 8

    // 12×8 格的四种铺法 ({x,y,w,h} 以格为单位; 每模板 96 格整铺, 无洞无叠)
    readonly property var templates: [
        // T0: 四块大板
        [ { x: 0, y: 0, w: 6, h: 4 }, { x: 6, y: 0, w: 6, h: 4 },
          { x: 0, y: 4, w: 4, h: 4 }, { x: 4, y: 4, w: 8, h: 4 } ],
        // T1: 大小混排
        [ { x: 0, y: 0, w: 4, h: 4 }, { x: 4, y: 0, w: 2, h: 4 },
          { x: 6, y: 0, w: 4, h: 4 }, { x: 10, y: 0, w: 2, h: 4 },
          { x: 0, y: 4, w: 4, h: 4 }, { x: 4, y: 4, w: 2, h: 4 },
          { x: 6, y: 4, w: 2, h: 4 }, { x: 8, y: 4, w: 4, h: 4 } ],
        // T2: 三列对分
        [ { x: 0, y: 0, w: 3, h: 4 }, { x: 3, y: 0, w: 3, h: 4 },
          { x: 6, y: 0, w: 6, h: 4 }, { x: 0, y: 4, w: 6, h: 4 },
          { x: 6, y: 4, w: 3, h: 4 }, { x: 9, y: 4, w: 3, h: 4 } ],
        // T3: 竖长条
        [ { x: 0, y: 0, w: 2, h: 8 }, { x: 2, y: 0, w: 4, h: 4 },
          { x: 6, y: 0, w: 2, h: 4 }, { x: 8, y: 0, w: 4, h: 8 },
          { x: 2, y: 4, w: 4, h: 4 }, { x: 6, y: 4, w: 2, h: 4 } ]
    ]

    // ---- 建场 ----
    // 20 块 (bx -2..1 × by -2..2) 铺满视口 ± 相机平移/缩放余量; 初始页签 = 歌单
    function buildScene() {
        var out = []
        for (var by = -2; by <= 2; ++by) {
            for (var bx = -2; bx <= 1; ++bx) {
                var t = ((bx * 3 + by * 7) % 4 + 4) % 4
                var m = (((bx * 73856093) ^ (by * 19349663)) >>> 0) % 4   // 镜像变体
                var flipX = (m & 1) === 1
                var flipY = (m & 2) === 2
                var slots = templates[t]
                var blockX = bx * blockCols * pitch
                var blockY = by * blockRows * pitch
                var blockId = (by + 2) * 8 + (bx + 2)
                for (var s = 0; s < slots.length; ++s) {
                    var sl = slots[s]
                    var cx = flipX ? (blockCols - sl.x - sl.w) : sl.x
                    var cy = flipY ? (blockRows - sl.y - sl.h) : sl.y
                    var gi = blockId * 12 + s
                    out.push({ x: blockX + cx * pitch,
                               y: blockY + cy * pitch,
                               w: sl.w * pitch - gap,
                               h: sl.h * pitch - gap,
                               gi: gi,
                               item: itemFor("playlist", gi) })
                }
            }
        }
        return out
    }

    // gi → 内容 (块序号 × 12 + 槽位; 取模命中库表)
    function itemFor(key, gi) {
        var arr = lib[key]
        var i = ((gi % arr.length) + arr.length) % arr.length
        var e = arr[i]
        var hue = (i * 47 + key.length * 113 + key.charCodeAt(0) * 7) % 360
        return { kind: key,
                 title: e[0],
                 owner: e[1],
                 tracks: e[2],
                 hue: hue,
                 subtitle: e[2] + " 首 · " + e[1] }
    }

    // 角标文案: 「歌单 · 34」
    function badgeFor(face) {
        var lbl = face.kind === "playlist" ? "歌单"
                : face.kind === "album" ? "专辑"
                : face.kind === "artist" ? "歌手" : "本地"
        return lbl + " · " + face.tracks
    }

    // ---- Mock 库表 [题名, 作者/备注, 曲数] ----
    readonly property var lib: ({
        playlist: [
            ["雨夜电台", "我", 34], ["晨间地铁", "小满", 22], ["旧书页", "阿岚", 18],
            ["深夜机房", "北屿", 41], ["海边信号", "我", 27], ["北方列车", "暮川", 33],
            ["午后困意", "小满", 15], ["磁带B面", "阿岚", 24], ["霓虹胡同", "北屿", 29],
            ["山谷回声", "暮川", 36], ["纸上银河", "我", 20], ["晚风档案", "小满", 31],
            ["静电漫步", "阿岚", 26], ["薄暮航线", "北屿", 38], ["无人接听", "暮川", 13],
            ["雪线以上", "我", 45], ["玻璃温室", "小满", 19], ["八点零三分", "阿岚", 28],
            ["潮汐笔记", "北屿", 23], ["小巷琴行", "暮川", 16]
        ],
        album: [
            ["慢速快门", "阿岚", 10], ["候鸟", "北屿", 9], ["白噪音研究", "暮川室内乐团", 12],
            ["环形山", "阿岚", 11], ["夏日残留", "小满", 8], ["潜水日志", "北屿", 10],
            ["半透明", "阿岚", 9], ["午夜配色", "暮川", 13], ["远地点", "北屿", 7],
            ["空气吉他", "小满", 10], ["浅水区", "阿岚", 12], ["降落练习", "暮川", 9],
            ["雾中测绘", "北屿", 11], ["定格", "小满", 8], ["低空飞行", "阿岚", 10],
            ["回声室", "暮川", 14]
        ],
        artist: [
            ["阿岚", "独立流行", 22], ["北屿", "氛围", 31], ["暮川", "器乐", 18],
            ["小满", "民谣", 26], ["旧胶片", "摇滚", 14], ["山海经电台", "电子", 29],
            ["晚灯", "爵士", 21], ["青苔", "后摇", 16], ["折光", "合成器", 12],
            ["半岛", "城市流行", 24], ["纸飞机", "清新", 9], ["砾石", "噪响", 17],
            ["白桦林", "民谣", 20], ["水平线", "缓拍", 15], ["避风港", "蓝调", 13],
            ["第九夜", "暗潮", 11]
        ],
        local: [
            ["下载", "本地", 46], ["无损收藏", "本地", 83], ["2024 归档", "本地", 39],
            ["demo 录音", "本地", 12], ["现场拾音", "本地", 25], ["采样库", "本地", 64],
            ["播客", "本地", 31], ["综艺原声", "本地", 18], ["铃声素材", "本地", 9],
            ["翻唱集", "本地", 27], ["练习片段", "本地", 14], ["演唱会实况", "本地", 22]
        ]
    })
}
