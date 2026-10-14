import QtQuick
import QtQuick.Shapes
import "."

pragma ComponentBehavior: Bound

// M1 首页墙 (对标参照产品首页的"海报墙"形态, 全部自绘)
//   世界 = 无限: 任意块坐标都能起建 (DemoData.blockSlots), 相机无任何限位 (对标: 无限层的相机无范围);
//   磁贴走"滑动窗口"回收 — 每侧 3×4 块池, 窗口随粗档相机平移, 离场块的磁贴重定位给新进场块,
//   交换一律发生在屏外 (窗口余量 340 世界px > 裁剪余量 100 屏幕px, 各档位均验过)
//   世界按块列 0 分左右两半 (两块池); 相机 = 视口中心世界坐标 (camX/camY) + 档位缩放 camScale
//   点击磁贴 = 就地聚焦展开 (这张变 6×6 大卡, 同块其余 11 张按让位表换小档重铺, 块外一律不动) +
//   相机把大卡拖到窗口正中 (无限墙无界, 不必限位); 同卡再点无反应, 点空白/Esc 收起 (相机不回位)
//   切页签 = 屏内磁贴翻牌波次 (switchTab 保留; 入口待接 — 原书架页签已随书架移除, 2026-10-14)
//   指针拖动: QML 内置 Flickable (2026-10-14 用户"用 qml 自带的滑动策略" — 取代 Folia 移植的
//   锚点相机/4ms 合帧/滑行 Timer 自研链): 相机 = flick.contentX/contentY (1:1 屏幕像素, camX/camY
//   由此推导), 拖动/滑行/惯性速度全走 Qt 内置, 平铺页面 XY 两轴自由
//   中央书架(缝条)+靠边磁吸+边缘标签 已于 2026-10-14 按用户"可以不要这个书架"整条移除
//   动画全部事件驱动 (无常驻动画; Flickable 滑行是内置动画驱动 — 本机 vsync 失效, 手感不对再节流)
Item {
    id: wall

    // ---- 径向柔光底 (QML Quick 无公开的径向 Gradient, 用 QtQuick.Shapes 的 RadialGradient 填满窗矩形) ----
    component SoftRadial: Shape {
        id: radial
        property point corePoint: Qt.point(0, 0)
        property real coreRadius: 100
        property color coreColor: "white"
        property real coreAlpha: 1.0
        property real edgeAlpha: 0.0
        property real innerStop: 0.0
        ShapePath {
            strokeWidth: 0
            fillGradient: RadialGradient {
                centerX: radial.corePoint.x
                centerY: radial.corePoint.y
                centerRadius: 0
                focalX: radial.corePoint.x
                focalY: radial.corePoint.y
                focalRadius: radial.coreRadius
                GradientStop {
                    position: radial.innerStop
                    color: Qt.rgba(radial.coreColor.r, radial.coreColor.g,
                                   radial.coreColor.b, radial.coreAlpha)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(radial.coreColor.r, radial.coreColor.g,
                                   radial.coreColor.b, radial.edgeAlpha)
                }
            }
            startX: 0
            startY: 0
            PathLine { x: radial.width; y: 0 }
            PathLine { x: radial.width; y: radial.height }
            PathLine { x: 0; y: radial.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // ---- 坞图标 (线段自绘, 无素材) ----
    component DockIcon: Item {
        id: icon
        property string kind: ""
        readonly property color iconColor: Qt.rgba(1, 1, 1, 0.62)
        implicitWidth: 18
        implicitHeight: 18

        // search: 圆 + 柄
        Rectangle {
            visible: icon.kind === "search"
            x: 0.5; y: 0.5; width: 12; height: 12; radius: 6
            color: "transparent"
            border.color: icon.iconColor; border.width: 1.5
            antialiasing: true
        }
        Rectangle {
            visible: icon.kind === "search"
            x: 11.9; y: 11.9; width: 2.2; height: 6.4; radius: 1.1
            color: icon.iconColor
            rotation: -45
            transformOrigin: Item.TopLeft
            antialiasing: true
        }

        // queue: 三横条
        Repeater {
            model: [ { y: 4, w: 16 }, { y: 9, w: 11 }, { y: 14, w: 16 } ]
            Rectangle {
                required property var modelData
                visible: icon.kind === "queue"
                x: 1; y: modelData.y
                width: modelData.w; height: 1.8; radius: 0.9
                color: icon.iconColor
                antialiasing: true
            }
        }

        // settings: 三条滑杆
        Repeater {
            model: [ { y: 4, kx: 10 }, { y: 9, kx: 3 }, { y: 14, kx: 7 } ]
            Item {
                id: slider
                required property var modelData
                visible: icon.kind === "settings"
                Rectangle {
                    x: 1; y: slider.modelData.y
                    width: 16; height: 1.8; radius: 0.9
                    color: icon.iconColor
                    antialiasing: true
                }
                Rectangle {
                    x: slider.modelData.kx; y: slider.modelData.y - 1.5
                    width: 4; height: 4; radius: 2
                    color: icon.iconColor
                    antialiasing: true
                }
            }
        }

        // more: 三点
        Repeater {
            model: [1, 7.5, 14]
            Rectangle {
                required property var modelData
                visible: icon.kind === "more"
                x: modelData; y: 7
                width: 4; height: 4; radius: 2
                color: icon.iconColor
                antialiasing: true
            }
        }
    }

    // ---- 世界的一半 (相机一致; 两半 = 两块池, 只按分界分职, 无视觉偏移) ----
    // 池 = 预建 144 张磁贴 (左侧区 = 块列 ≤ -1, 右侧区 = 列 ≥ 0); 位置/内容全部由滑动窗口落位,
    // 声明期一律不绑定坐标 (回收重定位要写 x/y/w/h)
    component WallHalf: Item {
        id: half
        property int side: 0   // -1 = 分界左 / +1 = 分界右 (= 注册入哪个池)
        // 内容坐标常驻 (画布中心 + 视口中心); 相机位移全在 flick.contentX/Y —
        // 视图位置 = half.x − contentX = 视口中心 − camX×camScale
        x: wall.canvasCx + wall.width / 2
        y: wall.canvasCy + wall.height / 2
        scale: wall.camScale
        transformOrigin: Item.TopLeft

        Repeater {
            model: wall.poolPerSide
            delegate: WallTile {
                titlePx: Math.max(22, Math.min(36, 0.02 * wall.width))
                panning: wall.panning   // 拖动/滑行中抑制 hover 抬升 (每穿过一张卡就起一段动画 = 拖动卡顿源)
                dimmed: wall.focusedTile !== null && wall.focusedTile !== this   // 选中期间其余卡内容暗色
                visible: wall.tileInPlay(this)   // 屏外不渲染
                Component.onCompleted: wall.registerTile(this, half.side)
                onActivated: wall.focusTile(this)
            }
        }
    }

    // ---- 相机 (2026-10-14 用户: 滑动策略换 QML 自带 Flickable) ----
    // 档位: 视口宽 <640 → 0.52 / <1100 → 0.64 / 否则 0.76 (客观参数)
    readonly property real tier: width < 640 ? 0.52 : (width < 1100 ? 0.64 : 0.76)
    property real camScale: tier
    readonly property real camHomeY: DemoData.blockRows * DemoData.pitch / 2   // 544 = 块中线
    // 相机 = 视口中心世界坐标; 唯一运动源 = flick.contentX/contentY (内置拖动+滑行),
    // camX/camY 由此推导 (content 坐标 1:1 屏幕像素 → 拖动天然 1:1, 缩放不在这层)
    readonly property real camX: (flick.contentX - wall.canvasCx) / wall.camScale
    readonly property real camY: (flick.contentY - wall.canvasCy) / wall.camScale
    // 巨画布 = 事实无限 (对标"无限, 没有边界"): 离初始位 ±2097152 世界px 的视野,
    // 全速甩到边也要十几分钟, 实际够不到; float 精度在 2^21 处仍 0.25px 级
    readonly property real canvasSize: 4194304
    readonly property real canvasCx: wall.canvasSize / 2
    readonly property real canvasCy: wall.canvasSize / 2
    function contentXOf(cx) { return wall.canvasCx + cx * wall.camScale }
    function contentYOf(cy) { return wall.canvasCy + cy * wall.camScale }
    // 档位缩放期间的相机锚: camScale 参与 camX↔contentX 换算, 变化时用锚保持世界点不动 (缩放绕视口中心)
    property real zoomAnchorCamX: 0
    property real zoomAnchorCamY: 0
    property int activeTab: 0
    property var tiles: []   // 全部磁贴实例 (池成员; 换页签波次用)
    property var tileByKey: ({})   // "块x,块y,槽位" → 磁贴 (让位时按块找齐 12 张; 窗口外的块无键)
    property var freeL: []   // 空闲池 (左侧区; 建位即交池, 由 ensureWindow 领用)
    property var freeR: []
    function registerTile(t, side) {
        wall.tiles.push(t)
        if (side < 0)
            wall.freeL.push(t)
        else
            wall.freeR.push(t)
        // 首屏落位: 各磁贴注册有先后 — callLater 自动去重合并, 池齐后自然一次分配到位
        Qt.callLater(wall.ensureWindow)
    }
    // 视口裁剪: 离屏 (留 100px 屏幕余量) 的磁贴直接不渲染 — 全池 288 张全提交=每帧万级节点, 裁掉后各动画才跑得动
    // 裁剪读"粗档相机" cullX/cullY (移动每满 128px 才更新): 直读 camX 时 288 张卡各自的 visible 绑定
    // 会按每个指针事件全量重算 (高回报率鼠标下就是拖动卡顿大头); 粗档化后拖动/滚轮/滑行/补间全走
    // 同一"每 128px 一档"。余量取 100px 的依据: 窗口按块粒度宽供 (余量 340 世界px) —
    // 各档位下"判为在屏"的块都必然还在窗口里 (只多不少) — 可见性绑定只跟 cullX/cullY 走
    property real cullX: DemoData.blockAnchorX
    property real cullY: wall.camHomeY
    onCamXChanged: {
        // 粗档相机每走一档: 可见性重算 + 滑动窗口跟上 (窗口余量 340 ≫ 档距 128, 进场的块必先在屏外就位)
        if (Math.abs(wall.camX - wall.cullX) >= 128) {
            wall.cullX = wall.camX
            wall.ensureWindow()
        }
    }
    onCamYChanged: {
        if (Math.abs(wall.camY - wall.cullY) >= 128) {
            wall.cullY = wall.camY
            wall.ensureWindow()
        }
    }
    function tileInPlay(t) {
        var s = wall.camScale
        var l = wall.width / 2 - wall.cullX * s + t.x * s
        var tp = wall.height / 2 - wall.cullY * s + t.y * s
        return l + t.width * s > -100 && l < wall.width + 100
                && tp + t.height * s > -100 && tp < wall.height + 100
    }

    // ---- 无限墙的滑动窗口 (每侧 3×4 块 = 12 块 × 12 槽 = 144 张池; 覆盖 视口 + 340 世界px 余量) ----
    // 窗口必须容住 [cull ± (视口半高/s + 340)] 的块区间, 否则最外档缺块会切进视口 (2026-10-14
    // "放大缩小后区域缺失" 根因): 纵向需求 = 2*((h/2)/s + 340)/1088 —— 0.76@1067 为 1.92 (3 行够),
    // 0.52@1067 为 2.51 ⇒ 需 4 行 (3 行时窗口最外档缺块切进屏底 ~110px 条带, 约 1/5 相机相位复现;
    // 0.64@1067 为 2.16 ⇒ 缺块不进屏, 4 行一并覆盖); 横向 0.76@1707 为 1.79 ⇒ 3 列, 本机视口上限
    // (1707×1067 逻辑 = 2560×1600@150%) 下横缺块进屏需 w > 2924*s (>2222) 不可达。若将来跑在更大的
    // 逻辑视口上, 把 winCols/winRows 调大即可 (池随动)
    readonly property int winCols: 3
    readonly property int winRows: 4
    readonly property int poolPerSide: wall.winCols * wall.winRows * DemoData.blockCols
    readonly property real wallBlockW: DemoData.blockCols * DemoData.pitch
    readonly property real wallBlockH: DemoData.blockRows * DemoData.pitch
    property int winLCol: 0   // 左侧窗口原点 (块列; 左侧区 = 列 ≤ -1)
    property int winLRow: 0
    property int winRCol: 0   // 右侧窗口原点 (块列; 右侧区 = 列 ≥ 0)
    property int winRRow: 0
    property bool winReadyL: false
    property bool winReadyR: false

    // 按粗档相机把两侧窗口滑到覆盖 视口+余量 (块粒度; 只动进出窗口的块, 交换全在屏外)
    function ensureWindow() {
        var s = wall.camScale
        var hw = (wall.width / 2) / s + 340
        var hh = (wall.height / 2) / s + 340
        var c0 = Math.floor((wall.cullX - hw) / wall.wallBlockW)
        var c1 = Math.floor((wall.cullX + hw) / wall.wallBlockW)
        var r0 = Math.floor((wall.cullY - hh) / wall.wallBlockH)
        var r1 = Math.floor((wall.cullY + hh) / wall.wallBlockH)
        var wr = Math.min(r0, r1 - (wall.winRows - 1))
        wall.slideSide(-1, c0, Math.min(c1, -1), wr)   // 左侧: 块列 ≤ -1
        wall.slideSide(1, Math.max(c0, 0), c1, wr)     // 右侧: 块列 ≥ 0 (两侧以块列 0 分界)
    }
    function slideSide(side, a, b, wr) {
        if (a > b)
            return   // 该侧不在取景内: 窗口原地停驻 (其磁贴全在屏外, 不动最省)
        var wc = Math.min(a, b - (wall.winCols - 1))   // 3 列窗口必然覆盖 [a..b] (区间宽 ≤ 3, 见覆盖裕度注释)
        if (side > 0)
            wc = Math.max(0, wc)   // 右侧窗口不得越过分界 (块列 0)
        var ready = side < 0 ? wall.winReadyL : wall.winReadyR
        var curCol = side < 0 ? wall.winLCol : wall.winRCol
        var curRow = side < 0 ? wall.winLRow : wall.winRRow
        if (ready && curCol === wc && curRow === wr)
            return
        var free = side < 0 ? wall.freeL : wall.freeR
        var W = wall.winCols
        var H = wall.winRows
        if (ready) {
            // 先释放离场块 (全在屏外) 再领取进场块 — 两窗口容量恒定, 空池数必然正好够
            for (var c = curCol; c < curCol + W; ++c) {
                for (var r = curRow; r < curRow + H; ++r) {
                    if (c >= wc && c < wc + W && r >= wr && r < wr + H)
                        continue
                    wall.releaseBlock(c, r, free)
                }
            }
            for (var c2 = wc; c2 < wc + W; ++c2) {
                for (var r2 = wr; r2 < wr + H; ++r2) {
                    if (c2 >= curCol && c2 < curCol + W && r2 >= curRow && r2 < curRow + H)
                        continue
                    wall.queueBlock(side, c2, r2)   // 摊帧领取 (不再单帧 72 张同步重排 — 见 queueBlock 注释)
                }
            }
        } else {
            if (free.length < W * H * DemoData.blockCols)
                return   // 池还没建齐 (启动序): 等注册期的 callLater 再来
            for (var c3 = wc; c3 < wc + W; ++c3)
                for (var r3 = wr; r3 < wr + H; ++r3)
                    wall.assignBlock(c3, r3, free)
            if (side < 0)
                wall.winReadyL = true
            else
                wall.winReadyR = true
        }
        if (side < 0) {
            wall.winLCol = wc
            wall.winLRow = wr
        } else {
            wall.winRCol = wc
            wall.winRRow = wr
        }
    }
    function releaseBlock(c, r, free) {
        for (var s = 0; s < DemoData.blockCols; ++s) {
            var key = c + "," + r + "," + s
            var t = wall.tileByKey[key]
            if (t === undefined)
                continue
            if (wall.focusedTile === t)
                wall.unfocus()   // 聚焦块滑出窗口: 先收起再回收 (发生在屏外, 不可见)
            delete wall.tileByKey[key]
            free.push(t)
        }
    }
    function assignBlock(c, r, free) {
        var slots = DemoData.blockSlots(c, r)
        for (var s = 0; s < slots.length; ++s) {
            var t = free.pop()
            if (t === undefined)
                return   // 防御: 池配齐后不应发生 (两窗口容量恒定, 释放在前)
            t.expanded = false
            t.relocate(slots[s])
            if (wall.activeTab !== 0)   // 不在初始页签: 新进场块直接上当期内容 (屏外, 免翻牌)
                t.face = DemoData.itemFor(DemoData.tabKey(wall.activeTab), slots[s].gi)
            wall.tileByKey[slots[s].key] = t
        }
    }

    // ---- 换块摊帧 (2026-10-13 用户"移动时卡顿, 可能是刷新板块"): 进场块不再单帧 72 张同步重排
    // (实测单次 1-3ms JS + 同帧场景图注册洪峰 = 快速拖动过每个块列边界的顿点), 改为入队,
    // 每 16ms 领一整列 (winRows 块, ~0.34ms/块): 交换区必在视口外 (340 − 100/s 世界px), 一列
    // 1 拍内排完, 远早于最快滑行到达 (0.52 档也要 ~30ms) — 视觉零影响; 参照 Folia 边缘重钳制
    // 推迟 rAF 批量执行, 等价"每帧摊一点"
    property var pendingBlocks: []
    property int pendingCount: 0
    function queueBlock(side, c, r) {
        wall.pendingBlocks.push({ side: side, c: c, r: r })
        wall.pendingCount = wall.pendingBlocks.length
    }
    function pumpBlocks() {
        if (wall.pendingCount === 0)
            return
        var n = Math.min(wall.winRows, wall.pendingCount)
        while (n-- > 0) {
            var j = wall.pendingBlocks.shift()
            wall.pendingCount = wall.pendingBlocks.length
            var curCol = j.side < 0 ? wall.winLCol : wall.winRCol
            var curRow = j.side < 0 ? wall.winLRow : wall.winRRow
            // 过时 (连续滑动已把窗口挪走) / 重复入队 (折返滑动) — 丢, 磁贴留在空池等下次进场
            if (j.c < curCol || j.c >= curCol + wall.winCols
                    || j.r < curRow || j.r >= curRow + wall.winRows)
                continue
            if (wall.tileByKey[j.c + "," + j.r + ",0"] !== undefined)
                continue
            wall.assignBlock(j.c, j.r, j.side < 0 ? wall.freeL : wall.freeR)
        }
    }
    Timer {
        // 摊帧节拍: 有积压才跑 (闲置零成本); 不依赖渲染回调 (渲染帧停转也不误事)
        interval: 16; repeat: true
        running: wall.pendingCount > 0
        onTriggered: wall.pumpBlocks()
    }
    // 视口宽高/档位变了 → 需要覆盖的范围也变; 推迟到通知潮之后 (同步写吃"绑定环"误报 — 实测)
    onWidthChanged: Qt.callLater(wall.ensureWindow)
    onHeightChanged: Qt.callLater(wall.ensureWindow)
    // 档位缩放: contentX/Y 随 camScale 重标定, 世界点 (zoomAnchor) 停在视口中心 (等价旧"相机不动, 墙缩放")
    onCamScaleChanged: {
        flick.contentX = wall.canvasCx + wall.zoomAnchorCamX * wall.camScale
        flick.contentY = wall.canvasCy + wall.zoomAnchorCamY * wall.camScale
        wall.ensureWindow()
    }

    // 启动期档位落定不做补间 (2026-10-14): Window 的 contentItem 尺寸到窗口显示时才就位 — 构造期
    // wall.width=0 (tier 0.52), 就位后真实宽直接跳档 (如 1440→0.76)。旧行为为这一跳白跑 420ms
    // 相机补间 (本机 vsync 失效下 = 满速渲染风暴 + 每步 ensureWindow 换块), 是启动卡顿来源之一;
    // 构造期 (还没真实尺寸) 不动作 (camScale 仍绑 tier), 首次带真实尺寸的落定直接赋值不补间,
    // 之后的窗口缩放照旧补间
    property bool tierBooted: false
    onTierChanged: {
        if (wall.width <= 0)
            return
        wall.zoomAnchorCamX = wall.camX   // 先锚住世界点 (camScale 一写, camX 推导值就换了)
        wall.zoomAnchorCamY = wall.camY
        if (!wall.tierBooted) {
            wall.tierBooted = true
            wall.camScale = tier
        } else {
            scaleAnim.to = tier
            scaleAnim.restart()
        }
    }
    NumberAnimation {
        id: scaleAnim
        target: wall; property: "camScale"
        duration: 420; easing.type: Easing.OutQuint
    }

    // ---- 背景第 1 层: 底色 ----
    Rectangle { anchors.fill: parent; color: WallTheme.bg }

    // ---- 背景第 2 层: 两道主题光晕 ----
    SoftRadial {
        anchors.fill: parent
        corePoint: Qt.point(wall.width * 0.14, wall.height * 0.12)
        coreRadius: Math.sqrt(Math.pow(wall.width * 0.86, 2) + Math.pow(wall.height * 0.88, 2))
        coreColor: "#f4f4f5"
        coreAlpha: 0.16
        edgeAlpha: 0
    }
    SoftRadial {
        anchors.fill: parent
        corePoint: Qt.point(wall.width * 0.86, wall.height * 0.82)
        coreRadius: Math.sqrt(Math.pow(wall.width * 0.86, 2) + Math.pow(wall.height * 0.82, 2))
        coreColor: "#71717a"
        coreAlpha: 0.20
        edgeAlpha: 0
    }

    // ---- 世界画布 = QML 内置 Flickable (2026-10-14 用户: "用 qml 自带的滑动策略") ----
    // 拖动/滑行/惯性/速度全交 Qt 内置 (取代自研 DragHandler 锚点相机 + 4ms 合帧 + 5ms 收尾 + 滑行 Timer);
    // content 坐标 1:1 屏幕像素 (缩放挂在两半上) → 拖动天然 1:1; camX/camY 由 contentX/Y 推导,
    // 裁剪/滑窗回收/聚焦外围照旧。背景层声明在前=垫底, 噪点/暗角在后=浮面
    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: wall.canvasSize
        contentHeight: wall.canvasSize
        // 初始相机 = 块分界/块中线 (声明绑定; 首次交互即被内置接管作废)
        contentX: wall.canvasCx + DemoData.blockAnchorX * wall.camScale
        contentY: wall.canvasCy + wall.camHomeY * wall.camScale
        maximumFlickVelocity: 2600   // 沿用旧滑行速度上限 (常量可调; 减速曲线用内置默认)

        // 拖动真开始时顺带收掉聚焦相机补间 (旧语义: 拖动激活即 camAnim.stop — 两条 contentX 写不得打架)
        onMovementStarted: camAnim.stop()

        // 滚轮: 挂在 contentItem 上 (比 Flickable 内置滚轮更深, 先手消费 → 沿用旧 90px/格 手感)
        WheelHandler {
            onWheel: function(event) {
                camAnim.stop()
                wall.stopGlide()
                wall.panBy(event.angleDelta.x / 120 * 90, event.angleDelta.y / 120 * 90)
            }
        }

        // 画布底铺满: 空白点击 = 收起聚焦 (声明在磁贴之前 → 磁贴命中优先; 拖动过阈值被 Flickable 收走,
        // 与旧"根 MouseArea 垫底"同构; 点胶囊同效 — 它在上层且不接左键)
        MouseArea {
            anchors.fill: parent
            onClicked: wall.unfocus()
        }

        // ---- 世界两半 (磁贴池; 只按分界分职) ----
        WallHalf { side: -1 }
        WallHalf { side: 1 }

        // ---- 浮面三件 (盖过墙面; 顺序 = 噪点/暗角/发丝) ----
        // 噪点 (自绘 160px 灰度图平铺; x/y 绑 contentX/Y = 钉视口, 屏幕定位与旧根级一致)
        Image {
            x: flick.contentX; y: flick.contentY
            width: wall.width; height: wall.height
            source: "noise.png"
            fillMode: Image.Tile
            smooth: false
            opacity: 0.055
        }

        // ---- 暗角 (同上: 钉视口) ----
        SoftRadial {
            x: flick.contentX; y: flick.contentY
            width: wall.width; height: wall.height
            corePoint: Qt.point(wall.width / 2, wall.height / 2)
            coreRadius: Math.sqrt(Math.pow(wall.width / 2, 2) + Math.pow(wall.height / 2, 2))
            coreColor: "black"
            coreAlpha: 0
            edgeAlpha: 0.52
            innerStop: 0.78
        }

        // ---- 墙面内圈发丝线 (同上: 钉视口) ----
        Rectangle {
            x: flick.contentX; y: flick.contentY
            width: wall.width; height: wall.height
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1
        }
    }

    // ---- 迷你播放胶囊 (底部中央; demo 静态示意) ----
    Rectangle {
        id: pill
        z: 6
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: 380; height: 48; radius: 24
        color: Qt.rgba(23 / 255, 23 / 255, 26 / 255, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            spacing: 10
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28; radius: 14
                color: Qt.rgba(1, 1, 1, 0.10)
                Shape {
                    anchors.centerIn: parent
                    width: 10; height: 12
                    ShapePath {
                        fillColor: WallTheme.text
                        strokeWidth: 0
                        PathSvg { path: "M1 0 L10 6 L1 12 Z" }
                    }
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 38
                spacing: 6
                Text {
                    width: parent.width
                    text: "云端漫游 — 阿岚"
                    color: Qt.rgba(244 / 255, 244 / 255, 245 / 255, 0.92)
                    font.family: WallTheme.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Rectangle {
                    width: parent.width; height: 2; radius: 1
                    color: Qt.rgba(1, 1, 1, 0.14)
                    Rectangle {
                        width: parent.width * 0.35
                        height: 2; radius: 1
                        color: WallTheme.text
                    }
                }
            }
        }
    }

    // ---- 聚焦 (点磁贴 → 块内就地展开 6×6 大卡; 同块 11 张按让位表换小档重铺; 块外不动) ----
    // 语义: 展开 = 换挡 + 相机把大卡拖到窗口正中; 收起 = 换挡还原 (相机不回位); 同卡再点无反应, 点空白/Esc 收起
    property var focusedTile: null

    // 同块 12 张换挡: on→按让位表 (下标 = 磁贴原槽位, 展开那张是 6×6), off→各回各的静止矩形
    // 屏外的不补间直接落位 (看不见还付布局钱; 之后滑进视野时已经是终态)
    function gearBlock(t, on) {
        var rects = on ? DemoData.blockReflowRects(t.col, t.row, t.slotIdx) : null
        for (var s = 0; s < 12; ++s) {
            var tile = wall.tileByKey[t.col + "," + t.row + "," + s]
            if (tile === undefined)
                continue
            var g = on ? rects[s] : { x: tile.restX, y: tile.restY, w: tile.restW, h: tile.restH }
            if (tile.visible) {
                tile.gearTo(g.x, g.y, g.w, g.h)
            } else {
                tile.x = g.x
                tile.y = g.y
                tile.width = g.w
                tile.height = g.h
            }
        }
    }

    // 聚焦相机 = 把展开卡 (世界矩形) 拖到窗口正中 (用户定语义; 无限墙无界, 不必限位)
    function focusCamX(r) {
        return r.x + r.w / 2
    }
    function focusCamY(r) {
        return r.y + r.h / 2
    }

    function focusTile(t) {
        if (t === wall.focusedTile)   // 同卡再点 = 无反应 (对标参照: 展开中再点不收起)
            return
        var old = wall.focusedTile
        if (old !== null) {             // 换卡: 旧块先收档 (同块时随后直接被新挡覆盖)
            old.expanded = false
            wall.gearBlock(old, false)
        }
        wall.focusedTile = t
        t.expanded = true
        wall.gearBlock(t, true)
        // 展开目标矩形 = 这张的新位置 (6×6 档); 相机把大卡拖到窗口正中
        var rects = DemoData.blockReflowRects(t.col, t.row, t.slotIdx)
        var nx = wall.focusCamX(rects[t.slotIdx])
        var ny = wall.focusCamY(rects[t.slotIdx])
        wall.stopGlide()
        if (Math.abs(nx - wall.camX) > 0.5 || Math.abs(ny - wall.camY) > 0.5) {
            camXTo.to = wall.contentXOf(nx)
            camYTo.to = wall.contentYOf(ny)
            camAnim.restart()
        }
    }

    // 收起: 换挡还原; 相机不回位 (对标参照 — 收起只还原卡片)
    function unfocus() {
        var t = wall.focusedTile
        if (t === null)
            return
        wall.focusedTile = null
        t.expanded = false
        wall.gearBlock(t, false)
    }

    Shortcut { sequence: "Escape"; onActivated: wall.unfocus() }

    // 相机补间 (聚焦揭示; 180ms OutQuint — 提速二轮: 相机先到位, 让位 220ms 收尾); 目标 = flick.content 坐标
    ParallelAnimation {
        id: camAnim
        NumberAnimation { id: camXTo; target: flick; property: "contentX"; duration: 180; easing.type: Easing.OutQuint }
        NumberAnimation { id: camYTo; target: flick; property: "contentY"; duration: 180; easing.type: Easing.OutQuint }
    }

    // ---- 相机交互: 滚轮 + 指针拖动 (无界: 无限墙不设任何限位) ----
    // 拖动/滑行本体 = Flickable 内置 (2026-10-14 换装, 用户"用 qml 自带的滑动策略")。
    // 旧自研链 (锚点相机 applyDragCam / 4ms 合帧 / 5ms 收尾 Timer / τ500 指数滑行 Timer) 已整体
    // 移除; 滚轮挂 flick 内 (机制实证 tst_flickmech: 压住内置滚轮, 内容走且只走我们的 90px/格)
    // 屏幕像素增量 → content 1:1 (content 即屏幕像素, 缩放挂在两半上 → 无需除 camScale)
    function panBy(dx, dy) {
        flick.contentX -= dx
        flick.contentY -= dy
    }

    // 墙是否在拖动/滑行 (磁贴据此抑制 hover 抬升 — 参照原型"拖动中不触发", 防动画风暴)
    readonly property bool panning: flick.moving

    // 按下点观察 (TapHandler: 被动抓且设计上不与 Flickable 抢拖动 — 实测判决: DragHandler 就算
    // 阈值天文数字/永不激活, 其被动抓也会挡住内置抢抓, 拖动直接死; TapHandler 无此病)。
    // 按下即停滑行 (旧语义, 不赌内置是否自行停)
    TapHandler {
        id: pressProbe
        onPressedChanged: {
            if (pressProbe.pressed)
                wall.stopGlide()
        }
    }

    // 停滑行: 统一入口 (调用点不变; 滑行本体在内置, 取消即可)
    function stopGlide() {
        flick.cancelFlick()
    }

    // ---- 页签切换 (墙面发翻牌波次; 入口待接 — 原书架页签已随书架移除, 2026-10-14) ----
    // 只翻在屏的 (屏外直接换面, 不付 288 套动画的钱 — 卡顿大头)
    function switchTab(i) {
        if (i === wall.activeTab)
            return
        wall.unfocus()   // 聚焦先收起 (相机留在原处 — 与参照一致)
        wall.activeTab = i
        var key = DemoData.tabKey(i)
        for (var k = 0; k < wall.tiles.length; ++k) {
            var t = wall.tiles[k]
            var d = DemoData.itemFor(key, t.gi)
            if (!t.visible) {
                t.flipNow(d)
                continue
            }
            // 波次按磁贴在屏上的横位 (块坐标无界, 旧的左端常数已无意义): 左→右扫约 160ms
            var sx = wall.width / 2 + (t.x - wall.camX) * wall.camScale
            var delay = Math.max(0, Math.min(160, sx / wall.width * 160))
            t.flipTo(d, delay)
        }
    }
}
