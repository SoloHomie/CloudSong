import QtQuick
import QtQuick.Shapes
import "."

pragma ComponentBehavior: Bound

// M1 首页墙 (对标参照产品首页的"海报墙 + 中央缝"形态, 全部自绘)
//   世界 = 无限: 任意块坐标都能起建 (DemoData.blockSlots), 相机无任何限位 (对标: 无限层的相机无范围);
//   磁贴走"滑动窗口"回收 — 每侧 3×3 块池, 窗口随粗档相机平移, 离场块的磁贴重定位给新进场块,
//   交换一律发生在屏外 (窗口余量 340 世界px > 裁剪余量 100 屏幕px + 缝让位 ≤63px, 各档位均验过)
//   世界按缝锚点分左右两半; 相机 = 视口中心世界坐标 (camX/camY) + 档位缩放 camScale
//   缝 = 块边界上的 120px 常宽缝: 墙两半各让开半个开口 + 半格 (让位量恒定), 纸条骑世界 1:1 随相机
//   (2026-10-12 取消"贴屏边自动收窄": 参照 follow 耦合同样贴边收窄, 但收窄=让位量随相机位置变 —
//    拖动过缝区时整墙非 1:1 (实测两半错速≈±2.4×/0.38×)、纸条与开口错位, 用户拍板取消, 改恒宽刚性);
//   缝滑出屏不带收窄 — 边缘标签在缝中线离屏边 24px 内淡入常驻, 点它 = 相机把缝拉回该侧边内 154px
//   点击磁贴 = 就地聚焦展开 (这张变 6×6 大卡, 同块其余 11 张按让位表换小档重铺, 块外一律不动) +
//   相机把大卡拖到窗口正中 (缝让位量已补偿; 无限墙无界, 不必限位); 同卡再点无反应, 点空白/Esc 收起 (相机不回位)
//   切页签 = 屏内磁贴翻牌波次 (屏外免动画直接换面; 缝条/选项不翻: 选中态 180ms 丝滑渐变)
//   指针拖动: 完全参照 (Folia) — 按下即停滑行 + 按下快照相机锚点, 每事件以 "锚点 + 屏幕总位移" 绝对定位 (非逐事件累加:
//   丢/并事件自纠正, 零漂移); 应用按 4ms 桶合帧 (Chromium 给参照的 pointermove 自动合帧, Qt 不合并, 等价补齐);
//   拖平铺页面 = XY 平移; 拖缝条(书架) = 只走 X (按下点判档; 1:1 跟手, 松手按参考参数滑行)
//   动画全部事件驱动 (无常驻动画, 规避本项目 vsync 空转实锤)
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

    // ---- 世界的一半 (相机一致, 各自再按 shift 让开缝的半个开口; shift 为屏幕像素) ----
    // 池 = 预建 108 张磁贴 (左侧区 = 块列 ≤ -1, 右侧区 = 列 ≥ 0); 位置/内容全部由滑动窗口落位,
    // 声明期一律不绑定坐标 (回收重定位要写 x/y/w/h)
    component WallHalf: Item {
        id: half
        property real shift: 0
        property int side: 0   // -1 = 缝左 / +1 = 缝右 (裁剪取让位偏移用)
        x: wall.width / 2 - wall.camX * wall.camScale + half.shift
        y: wall.height / 2 - wall.camY * wall.camScale
        scale: wall.camScale
        transformOrigin: Item.TopLeft

        Repeater {
            model: wall.poolPerSide
            delegate: WallTile {
                titlePx: Math.max(22, Math.min(36, 0.02 * wall.width))
                panning: wall.panning   // 拖动/滑行中抑制 hover 抬升 (每穿过一张卡就起一段动画 = 拖动卡顿源)
                dimmed: wall.focusedTile !== null && wall.focusedTile !== this   // 选中期间其余卡内容暗色
                visible: wall.tileInPlay(this, half.side)   // 屏外不渲染
                Component.onCompleted: wall.registerTile(this, half.side)
                onActivated: wall.focusTile(this)
            }
        }
    }

    // ---- 相机 ----
    // 档位: 视口宽 <640 → 0.52 / <1100 → 0.64 / 否则 0.76 (客观参数)
    readonly property real tier: width < 640 ? 0.52 : (width < 1100 ? 0.64 : 0.76)
    property real camScale: tier
    readonly property real camHomeY: DemoData.blockRows * DemoData.pitch / 2   // 544 = 块中线
    property real camX: DemoData.seamAnchorX   // 初始 = 缝锚点 (块列 0 左缘缝中线), 缝落视口正中
    property real camY: camHomeY
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
    // 视口裁剪: 离屏 (留 100px 屏幕余量) 的磁贴直接不渲染 — 全池 216 张全提交=每帧万级节点, 裁掉后各动画才跑得动
    // 裁剪读"粗档相机" cullX/cullY (移动每满 128px 才更新): 直读 camX 时 216 张卡各自的 visible 绑定
    // 会按每个指针事件全量重算 (高回报率鼠标下就是拖动卡顿大头); 粗档化后拖动/滚轮/滑行/补间全走
    // 同一"每 128px 一档"。余量取 100px 的依据: 窗口按块粒度宽供 (余量 340 世界px), 即使算上缝让位
    // (≤63px) 折算, 各档位下"判为在屏"的块都必然还在窗口里 (只多不少); seamShift 现为常量
    // (缝不再随位置收窄, 2026-10-12) — 可见性绑定只跟 cullX/cullY 走
    property real cullX: DemoData.seamAnchorX
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
    function tileInPlay(t, side) {
        var s = wall.camScale
        var l = wall.width / 2 - wall.cullX * s + side * wall.seamShift + t.x * s
        var tp = wall.height / 2 - wall.cullY * s + t.y * s
        return l + t.width * s > -100 && l < wall.width + 100
                && tp + t.height * s > -100 && tp < wall.height + 100
    }

    // ---- 无限墙的滑动窗口 (每侧 3×3 块 = 9 块 × 12 槽 = 108 张池; 覆盖 视口 + 340 世界px 余量) ----
    // 覆盖裕度按本机视口上限 (1707×1067 逻辑 = 2560×1600@150%) 验过: 0.76 档下 3×3 恰好容住
    // 视口 + 余量 (横 ≤3 列 / 纵 ≤3 行); 若将来跑在更大的逻辑视口上, 把 winCols/winRows 调大即可 (池随动)
    readonly property int winCols: 3
    readonly property int winRows: 3
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
        wall.slideSide(1, Math.max(c0, 0), c1, wr)     // 右侧: 块列 ≥ 0 (两侧以缝锚点切分, 让位偏移不同)
    }
    function slideSide(side, a, b, wr) {
        if (a > b)
            return   // 该侧不在取景内: 窗口原地停驻 (其磁贴全在屏外, 不动最省)
        var wc = Math.min(a, b - (wall.winCols - 1))   // 3 列窗口必然覆盖 [a..b] (区间宽 ≤ 3, 见覆盖裕度注释)
        if (side > 0)
            wc = Math.max(0, wc)   // 右侧窗口不得越过缝锚点
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
    // 每 16ms 领 3 块 (~0.34ms/块): 交换区必在视口外 ≥212 世界px, 全排 32ms 内完 (降速后最快滑行
    // 也要 62ms 才追上) — 视觉零影响; 参照 Folia 边缘重钳制推迟 rAF 批量执行, 等价"每帧摊一点"
    property var pendingBlocks: []
    property int pendingCount: 0
    function queueBlock(side, c, r) {
        wall.pendingBlocks.push({ side: side, c: c, r: r })
        wall.pendingCount = wall.pendingBlocks.length
    }
    function pumpBlocks() {
        if (wall.pendingCount === 0)
            return
        var n = Math.min(3, wall.pendingCount)
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
    onCamScaleChanged: wall.ensureWindow()

    onTierChanged: { scaleAnim.to = tier; scaleAnim.restart() }
    NumberAnimation {
        id: scaleAnim
        target: wall; property: "camScale"
        duration: 420; easing.type: Easing.OutQuint
    }

    // ---- 缝的几何 (骑世界, 常宽: 开口不随相机位置变化 — 整墙与相机严格 1:1, 拖动无任何非线性) ----
    readonly property real seamLayoutW: DemoData.seamHomeWidth                  // 内容排版宽 (常宽)
    readonly property real seamCenterX: wall.width / 2 + (DemoData.seamAnchorX - wall.camX) * wall.camScale
    readonly property real seamDist: Math.min(seamCenterX, wall.width - seamCenterX)   // 缝中线→最近屏边
    readonly property real seamW: seamLayoutW
    readonly property real seamShift: seamLayoutW / 2 + (DemoData.gap / 2) * wall.camScale
    // contentOpacity = (开口 / 排版宽 − .35) / .65 (对标公式; 开口恒 120 ⇒ 恒 1)
    readonly property real seamContentOpacity: Math.max(0, Math.min(1, (seamW / seamLayoutW - 0.35) / 0.65))

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

    // ---- 空白点击 = 收起聚焦 (声明在墙面之前: 磁贴命中优先, 点缝/胶囊同效) ----
    MouseArea {
        anchors.fill: parent
        onClicked: wall.unfocus()
    }

    // ---- 世界两半 (磁贴池; 缝让位就是这两层各自偏移 ±seamShift) ----
    WallHalf { shift: -wall.seamShift; side: -1 }
    WallHalf { shift: wall.seamShift; side: 1 }

    // ---- 背景第 3 层: 噪点 (自绘 160px 灰度图平铺, 近似 soft-light 颗粒) ----
    Image {
        anchors.fill: parent
        source: "noise.png"
        fillMode: Image.Tile
        smooth: false
        opacity: 0.055
    }

    // ---- 背景第 4 层: 暗角 ----
    SoftRadial {
        anchors.fill: parent
        corePoint: Qt.point(wall.width / 2, wall.height / 2)
        coreRadius: Math.sqrt(Math.pow(wall.width / 2, 2) + Math.pow(wall.height / 2, 2))
        coreColor: "black"
        coreAlpha: 0
        edgeAlpha: 0.52
        innerStop: 0.78
    }

    // ---- 墙面内圈发丝线 ----
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1
    }

    // ---- 缝 (块边界上的 120px 常驻窄缝, 常宽; 位置随世界锚点 1:1, 墙两半已让位, 纸条落在开口里, 滑出屏被窗口裁掉) ----
    Item {
        id: seam
        visible: wall.seamW >= 1
        x: wall.seamCenterX - wall.seamW / 2
        width: wall.seamW
        height: wall.height
        clip: true
        z: 5

        // 纸面 (主题纸色, 实色; 对标: 实色档的缝 = 纸色纸条)
        Rectangle {
            anchors.fill: parent
            color: WallTheme.seamPaper
            border.color: WallTheme.seamRing
            border.width: 1
        }
        Rectangle { width: 1; height: parent.height; color: WallTheme.hairline }
        Rectangle {
            anchors.right: parent.right
            width: 1; height: parent.height
            color: WallTheme.hairline
        }

        // 内容 (固定排版宽居中; 开口收窄时按 0.35 阈值淡出, 淡到不可见时同时禁用交互)
        Item {
            id: seamBody
            width: DemoData.seamHomeWidth
            height: seam.height
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: wall.seamContentOpacity
            enabled: wall.seamContentOpacity > 0.85

            // 顶部: 标记 (三柱均衡器)
            Item {
                id: mark
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 16
                width: 20; height: 20
                Rectangle { x: 3; y: 6; width: 3; height: 8; radius: 1.5; color: WallTheme.text }
                Rectangle { x: 8.5; y: 2; width: 3; height: 16; radius: 1.5; color: WallTheme.text }
                Rectangle { x: 14; y: 5; width: 3; height: 10; radius: 1.5; color: WallTheme.text }
            }

            // 竖排标题
            Text {
                id: seamTitle
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: mark.bottom
                anchors.topMargin: 14
                text: "曲\n库"
                color: Qt.rgba(1, 1, 1, 0.9)
                horizontalAlignment: Text.AlignHCenter
                font.family: WallTheme.fontFamily
                font.pixelSize: 15
                font.weight: 800
                lineHeight: 1.4
            }

            // 竖排页签
            Column {
                id: tabCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: seamTitle.bottom
                anchors.topMargin: 18
                spacing: 8
                Repeater {
                    model: DemoData.tabs
                    delegate: Rectangle {
                        id: tabBtn
                        required property var modelData
                        required property int index
                        width: 24
                        height: 54
                        radius: 10
                        color: tabBtn.index === wall.activeTab
                               ? Qt.rgba(1, 1, 1, 0.14)
                               : (tabHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        // 选中态丝滑换挡 (旧高亮渐隐 / 新高亮渐显; 时长取参考的非翻转过渡 180ms)
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.InOutQuad }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: tabBtn.modelData.label.split("").join("\n")
                            color: tabBtn.index === wall.activeTab
                                   ? WallTheme.text
                                   : Qt.rgba(244 / 255, 244 / 255, 245 / 255, 0.45)
                            Behavior on color {
                                ColorAnimation { duration: 180; easing.type: Easing.InOutQuad }
                            }
                            horizontalAlignment: Text.AlignHCenter
                            font.family: WallTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: 700
                            lineHeight: 1.15
                        }
                        HoverHandler { id: tabHover }
                        TapHandler { onTapped: wall.switchTab(tabBtn.index) }
                    }
                }
            }

            // 底部: 坞 (搜索/队列/设置/更多) + 账户 + 帮助
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 84
                spacing: 14
                Grid {
                    columns: 2
                    spacing: 4
                    Repeater {
                        model: ["search", "queue", "settings", "more"]
                        delegate: Rectangle {
                            id: dockBtn
                            required property string modelData
                            width: 40; height: 40; radius: 12
                            color: dockHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            HoverHandler { id: dockHover }
                            DockIcon {
                                anchors.centerIn: parent
                                kind: dockBtn.modelData
                            }
                        }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 30; height: 30; radius: 15
                    color: Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.15); border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "我"
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.family: WallTheme.fontFamily
                        font.pixelSize: 12
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 28; height: 28; radius: 14
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.15); border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: WallTheme.fontFamily
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    // ---- 边缘标签 (缝滑近/滑出屏边时常驻屏边; 点它 = 相机把缝拉回该侧边内 154px 处) ----
    // 标签出现/滑入/淡入跟 seamTabT 这一根连续量走 (缝中线离屏边 24px→14px ⇒ 0→1; 与旧收窄式同一时序, 只是不再动墙)
    readonly property real seamTabT: Math.max(0, Math.min(1, (24 - wall.seamDist) / 10))
    readonly property string seamSide: wall.seamCenterX < wall.width / 2 ? "left" : "right"
    // 重新展开的落点: 缝中线停在该侧边内 154px (半开口 60 + 边距 14 + 富余 80)
    readonly property real seamReopenPad: DemoData.seamHomeWidth / 2 + 14 + 80
    function reopenSeam() {
        wall.stopGlide()
        var side = wall.seamSide
        var target = side === "left" ? wall.seamReopenPad : wall.width - wall.seamReopenPad
        var nx = wall.camX - (target - wall.seamCenterX) / wall.camScale
        camXTo.to = nx
        camYTo.to = wall.camY
        camAnim.restart()
    }
    Rectangle {
        id: seamTab
        z: 6
        visible: wall.seamTabT > 0.02
        opacity: wall.seamTabT
        width: 32; height: 64   // 固定尺寸 (13px × 2 行 + padding, 同参照)
        x: wall.seamSide === "left" ? -32 * (1 - wall.seamTabT)
                                    : wall.width - 32 * wall.seamTabT
        y: (wall.height - 64) / 2
        color: WallTheme.seamPaper
        border.color: WallTheme.seamRing
        border.width: 1
        radius: 6
        Text {
            id: tabText
            anchors.centerIn: parent
            text: "曲\n库"
            color: WallTheme.text
            horizontalAlignment: Text.AlignHCenter
            font.family: WallTheme.fontFamily
            font.pixelSize: 13
            font.weight: 800
            font.letterSpacing: 1.56
            lineHeight: 1.25
        }
        TapHandler { onTapped: wall.reopenSeam() }
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
    // 让位量现为常量 (缝不再随位置收窄): 半边偏移一步补偿即可
    function focusCamX(r) {
        var side = (r.x + r.w / 2) < DemoData.seamAnchorX ? -1 : 1
        var cx = r.x + r.w / 2
        return cx + side * wall.seamShift / wall.camScale
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
            camXTo.to = nx
            camYTo.to = ny
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

    // 相机补间 (聚焦揭示; 230ms OutQuint — 提速: 相机先到位, 让位 300ms 收尾)
    ParallelAnimation {
        id: camAnim
        NumberAnimation { id: camXTo; target: wall; property: "camX"; duration: 230; easing.type: Easing.OutQuint }
        NumberAnimation { id: camYTo; target: wall; property: "camY"; duration: 230; easing.type: Easing.OutQuint }
    }

    // ---- 相机交互: 滚轮 + 指针拖动 (无界: 无限墙不设任何限位, 缝滑出屏后由边缘标签拉回) ----
    // 屏幕像素增量 → 相机 (除缩放); 滚轮/滑行用 — 指针拖动走锚点式 applyDragCam (参照 Folia)
    function panBy(dx, dy) {
        wall.camX -= dx / wall.camScale
        wall.camY -= dy / wall.camScale
    }

    // 墙是否在拖动/滑行 (磁贴据此抑制 hover 抬升 — 参照原型"拖动中不触发", 防动画风暴)
    readonly property bool panning: pan.active || glideTimer.running

    WheelHandler {
        onWheel: function(event) {
            camAnim.stop()
            wall.stopGlide()
            wall.panBy(event.angleDelta.x / 120 * 90, event.angleDelta.y / 120 * 90)
        }
    }

    // 指针拖动 (完全参照 Folia): 按下快照相机锚点; 每事件以 "锚点 + 屏幕总位移" 绝对定位 —
    // 不做逐事件累加 (丢/并事件自纠正, 零漂移; 参照 applyCamera(anchor + n));
    // 应用合帧: 4ms 桶内多事件只应用最后一段 (Chromium 给参照的 pointermove 自动合帧, Qt 不合并, 等价补齐);
    // 拖平铺页面 XY 跟手; 拖缝条(书架) 只走 X (按下点落在缝的 x 带内即判档)
    DragHandler {
        id: pan
        target: null
        dragThreshold: 7
        property bool xOnly: false
        property real lastTx: 0
        property real lastTy: 0
        property real velX: 0
        property real velY: 0
        property double moveAt: 0
        property real anchorCamX: 0   // 按下时的相机位置 (参照 down.camera)
        property real anchorCamY: 0

        // 参照: pointerdown 即 stopPan — 按下就停滑行, 不等过阈值 (实测 GrabPassive=按下时刻)
        // 枚举在 QPointingDevice 上 (QML 名 PointerDevice; PointerHandler/DragHandler 上均取不到)
        onGrabChanged: function(transition, point) {
            if (transition === PointerDevice.GrabPassive)
                wall.stopGlide()
        }

        onActiveChanged: {
            if (pan.active) {
                camAnim.stop()
                wall.stopGlide()
                dragFlush.stop()
                pan.xOnly = wall.seamW >= 1
                        && Math.abs(pan.centroid.pressPosition.x - wall.seamCenterX) <= wall.seamW / 2
                pan.anchorCamX = wall.camX
                pan.anchorCamY = wall.camY
                pan.lastTx = 0
                pan.lastTy = 0
                pan.velX = 0
                pan.velY = 0
                // 速度采样起点 = 激活时刻. 实测激活那一发的 translation 值不变 (仍 0) 不发
                // translationChanged, 激活后首个事件的 T 才跳到"距按下总位移" — 若像旧版用 0 当
                // "无样本"哨兵, 只拖一段的快速一甩就永远采不到速度, 松手不滑行
                pan.moveAt = Date.now()
            } else {
                // 收尾: 末段位移立即到位 (滑行起点 = 手最后停留的位置); 必须用 lastTx/lastTy —
                // 实测 DragHandler.translation 在松手 (active→false) 时已归零, 直接读它会把相机弹回锚点
                wall.applyDragCam(pan.lastTx, pan.lastTy)
                wall.glideAfter(pan.velX, pan.velY, pan.xOnly, pan.moveAt)
            }
        }
        onTranslationChanged: {
            if (!pan.active)
                return
            var now = Date.now()
            // dt 下限 1ms (参照原型同款 Math.max(1, ...)): 高回报率鼠标 (1000Hz+) 下同毫秒多事件是常态 —
            // 旧 "dt>0 才记速, 否则清零" 会让这些事件把速度随机清零, 松手滑行忽滑忽停 (连续拖动速度突变)
            var dt = Math.max(1, now - pan.moveAt)
            // 松手滑行以指针最后一段的瞬时速度为起点, 之后只递减 (2026-10-12 用户定案:
            // 不做平滑/不加爬升 — 滑行起步速度必须等于手的速度, 否则滑行与手脱节)
            pan.velX = (pan.translation.x - pan.lastTx) / dt * 1000
            pan.velY = pan.xOnly ? 0 : (pan.translation.y - pan.lastTy) / dt * 1000
            pan.moveAt = now
            pan.lastTx = pan.translation.x
            pan.lastTy = pan.translation.y
            if (now - wall.dragAppliedAt >= 4)
                wall.applyDragCam(pan.lastTx, pan.lastTy)
            else
                dragFlush.restart()   // 桶内余下事件合并到收尾
        }
    }

    // 锚点应用 (参照 applyCamera): 相机 = 按下锚点 − 屏幕位移/缩放; 绝对定位, 无界不限位
    // 位移一律由调用点传入 (lastTx/lastTy 快照), 不读 pan.translation — 实测 Qt 语义: 激活瞬间
    // translation 报 0, 激活后首个事件才跳到"距按下"总位移, 松手 (active→false) 时又已归零
    // 4ms ≈ 本机 240Hz 帧距 (60Hz 机器上仍细于帧距, 只少不会多)
    property double dragAppliedAt: 0
    function applyDragCam(tx, ty) {
        dragFlush.stop()
        wall.dragAppliedAt = Date.now()
        wall.camX = pan.anchorCamX - tx / wall.camScale
        wall.camY = pan.anchorCamY - (pan.xOnly ? 0 : ty) / wall.camScale
    }
    // 单发收尾: 事件流停在桶中间 (拖动中暂停) 时把最后一段位移补上 — 墙不会停在旧位置等下一个事件
    Timer {
        id: dragFlush
        interval: 5
        onTriggered: wall.applyDragCam(pan.lastTx, pan.lastTy)
    }

    // 松手滑行 (参考参数: 速度阈 40px/s, 上限 2600, 距最后一段超过 80ms 算停住不滑)
    // 2026-10-13 用户"限制滑动速度 — 快速滑动就会导致卡顿": 峰值 4000→2600 — 相机越快, 换块/裁剪事件
    // 频率越高 (每块列边界一爆), 峰值降 35% 即把这些事件的总频率压下来; 拖动本体仍 1:1 (定案)
    // 惯性 = 指数衰减 τ=500ms (滑行距离 = 速度 × τ ≈ 0.5s, 初始滑行速度 = 松手速度, 无缝衔接)
    // 60Hz Timer 手动推进 — 本机 vsync 失效, NumberAnimation 驱动的渲染循环会 ~1000fps 空转
    // (帧率不均/撕裂); 同原型 (dev/prototypes/bravais) 的帧循环做法
    property real glideVx: 0
    property real glideVy: 0
    property double glideTickAt: 0
    Timer {
        id: glideTimer
        interval: 16
        repeat: true
        onTriggered: wall.stepGlide()
    }
    function stopGlide() {
        glideTimer.stop()
        wall.glideVx = 0
        wall.glideVy = 0
    }
    function stepGlide() {
        var now = Date.now()
        var dt = Math.max(1, Math.min(40, now - wall.glideTickAt))
        wall.glideTickAt = now
        var decay = Math.exp(-dt / 500)
        wall.glideVx *= decay
        wall.glideVy *= decay
        wall.panBy(wall.glideVx * dt / 1000, wall.glideVy * dt / 1000)
        if (Math.sqrt(wall.glideVx * wall.glideVx + wall.glideVy * wall.glideVy) < 20)
            wall.stopGlide()   // 滑到 20px/s 以下落定
    }
    function glideAfter(vx, vy, xOnly, moveAt) {
        wall.stopGlide()
        if (Date.now() - moveAt > 80)
            return
        var speed = Math.sqrt(vx * vx + vy * vy)
        if (speed < 40)
            return
        var capped = Math.min(speed, 2600)
        wall.glideVx = vx / speed * capped
        wall.glideVy = xOnly ? 0 : vy / speed * capped
        wall.glideTickAt = Date.now()
        glideTimer.restart()
    }

    // ---- 页签切换: 缝条不翻 (选中态由 tabBtn 的 Behavior 丝滑渐变), 墙面发翻牌波次 ----
    // 只翻在屏的 (屏外直接换面, 不付 216 套动画的钱 — 卡顿大头)
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
