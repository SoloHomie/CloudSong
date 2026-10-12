import QtQuick
import QtQuick.Shapes
import "."

pragma ComponentBehavior: Bound

// M1 首页墙 (对标参照产品首页的"海报墙 + 中央缝"形态, 全部自绘)
//   世界 = 20 块 × 每块 12×8 格自铺场, 按缝锚点分左右两半; 相机 = 视口中心世界坐标 (camX/camY) + 档位缩放 camScale
//   缝 = 块边界上的 120px 窄缝: 墙两半各让开半个开口 + 半格, 纸条落在开口里不压磁贴 (对标 seamPlan 的 split)
//   缝随墙走: 滑近屏幕边时连续收窄(墙两半跟着合拢), 收拢后边缘标签(纸色曲库条)从屏边滑入常驻;
//   点标签 = 相机把缝拉回该侧边内 154px 处, 缝重新展开 — 相机 X 限位只管墙面铺满视口, 不再锁缝
//   点击磁贴 = 就地聚焦展开 (这张变 6×6 大卡, 同块其余 11 张按让位表换小档重铺, 块外一律不动) +
//   相机把大卡拖到窗口正中 (墙面覆盖限位内, 缝让位量已补偿); 同卡再点无反应, 点空白/Esc 收起 (相机不回位)
//   切页签 = 屏内磁贴翻牌波次 (屏外免动画直接换面; 缝条/选项不翻: 选中态 180ms 丝滑渐变)
//   指针拖动: 拖平铺页面 = XY 平移; 拖缝条(书架) = 只走 X (按下点判档; 1:1 跟手, 松手按参考参数滑行)
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
    component WallHalf: Item {
        id: half
        property var source: []
        property real shift: 0
        property int side: 0   // -1 = 缝左 / +1 = 缝右 (裁剪取让位偏移用)
        x: wall.width / 2 - wall.camX * wall.camScale + half.shift
        y: wall.height / 2 - wall.camY * wall.camScale
        scale: wall.camScale
        transformOrigin: Item.TopLeft

        Repeater {
            model: half.source
            delegate: WallTile {
                required property var modelData
                gi: modelData.gi
                item: modelData.item
                slotKey: modelData.key
                col: modelData.col
                row: modelData.row
                slotIdx: modelData.slot
                titlePx: Math.max(22, Math.min(36, 0.02 * wall.width))
                visible: wall.tileInPlay(this, half.side)   // 屏外不渲染
                // 坐标不绑定 (让位补间要写 x/y/w/h): 建场落位后自注册
                Component.onCompleted: {
                    x = modelData.x
                    y = modelData.y
                    width = modelData.w
                    height = modelData.h
                    wall.registerTile(this)
                }
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
    property var tiles: []   // 场景磁贴实例 (Repeater 创建时自注册; 换页签波次用)
    property var tileByKey: ({})   // "块x,块y,槽位" → 磁贴 (让位时按块找齐 12 张)
    // 建场注册: 记静止矩形 (收起还原用) + 进槽位索引
    function registerTile(t) {
        t.restX = t.x
        t.restY = t.y
        t.restW = t.width
        t.restH = t.height
        wall.tileByKey[t.slotKey] = t
        wall.tiles.push(t)
    }
    // 视口裁剪: 离屏 (留 400px 余量) 的磁贴直接不渲染 — 240 张全提交=每帧万级节点, 裁掉后各动画才跑得动
    function tileInPlay(t, side) {
        var s = wall.camScale
        var l = wall.width / 2 - wall.camX * s + side * wall.seamShift + t.x * s
        var tp = wall.height / 2 - wall.camY * s + t.y * s
        return l + t.width * s > -400 && l < wall.width + 400
                && tp + t.height * s > -400 && tp < wall.height + 400
    }

    // 相机 X/Y 限位 = 墙面覆盖视口 (块场 bx -2..1 × by -2..2, 同 buildScene): 缝允许滑到屏外, 贴边收窄成屏边标签
    // (写成函数: 限位随 camScale 变, 调用即取当前值 — 之前写成只读绑定时启动期吃"绑定环"误报)
    readonly property real wallBlockW: DemoData.blockCols * DemoData.pitch
    readonly property real wallBlockH: DemoData.blockRows * DemoData.pitch
    function camMinXAt(s) { return -2 * wall.wallBlockW + (wall.width / 2) / s }
    function camMaxXAt(s) { return 2 * wall.wallBlockW - DemoData.gap - (wall.width / 2) / s }
    // Y 限位与 X 同语义 (原 ±816 定值换成覆盖式: 聚焦居中要拖得动, 平移也不再撞隐形墙)
    function camMinYAt(s) { return -2 * wall.wallBlockH + (wall.height / 2) / s }
    function camMaxYAt(s) { return 3 * wall.wallBlockH - DemoData.gap - (wall.height / 2) / s }
    function clampCamX() {
        var lo = wall.camMinXAt(wall.camScale)
        var hi = wall.camMaxXAt(wall.camScale)
        wall.camX = lo > hi ? DemoData.seamAnchorX : Math.max(lo, Math.min(hi, wall.camX))
    }
    // 限位写回统一推迟到通知潮之后 (同步写 camX 会在 width→tier 级联里吃"绑定环"误报 — 实测)
    onWidthChanged: Qt.callLater(wall.clampCamX)

    readonly property var scene: DemoData.buildScene()
    // 缝锚点左边的 slot 进左半, 右边进右半 (无 slot 跨过锚点 — 模板只在块内铺)
    readonly property var sceneLeft: wall.scene.filter(function (s) { return s.x < DemoData.seamAnchorX })
    readonly property var sceneRight: wall.scene.filter(function (s) { return s.x >= DemoData.seamAnchorX })

    onTierChanged: { scaleAnim.to = tier; scaleAnim.restart(); Qt.callLater(wall.clampCamX) }
    NumberAnimation {
        id: scaleAnim
        target: wall; property: "camScale"
        duration: 420; easing.type: Easing.OutQuint
        onStopped: wall.clampCamX()
    }

    // ---- 缝的几何 (骑世界: 近屏边按 room×2 连续收窄, 收到 <2px 即"收起" → 边缘标签顶上) ----
    readonly property real seamLayoutW: DemoData.seamHomeWidth                  // 内容排版宽 (开合不重排)
    readonly property real seamCenterX: wall.width / 2 + (DemoData.seamAnchorX - wall.camX) * wall.camScale
    readonly property real seamW: Math.max(0, Math.min(seamLayoutW,
                                     (Math.min(seamCenterX, wall.width - seamCenterX) - 14) * 2))
    readonly property real seamShift: seamW / 2
        + (DemoData.gap / 2) * wall.camScale * Math.min(1, seamW / 16)
    // contentOpacity = (开口 / 排版宽 − .35) / .65 (对标公式): 开到三成五以下看不见
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

    // ---- 世界两半 (磁贴场; 缝让位就是这两层各自偏移 ±seamShift) ----
    WallHalf { source: wall.sceneLeft; shift: -wall.seamShift; side: -1 }
    WallHalf { source: wall.sceneRight; shift: wall.seamShift; side: 1 }

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

    // ---- 缝 (块边界上的 120px 常驻窄缝; 位置随世界锚点, 墙两半已让位, 纸条落在开口里) ----
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

    // ---- 边缘标签 (缝滑到屏外收拢后常驻屏边; 点它 = 相机把缝拉回该侧边内, 缝重新展开) ----
    // 标签出现/滑入/淡入都跟 seamTabT 这一根连续量走 (缝宽 20→0 ⇒ 0→1), 与缝的收拢同一根动画
    readonly property real seamTabT: Math.max(0, Math.min(1, (20 - wall.seamW) / 20))
    readonly property string seamSide: wall.seamCenterX < wall.width / 2 ? "left" : "right"
    // 重新展开的落点: 缝中线停在该侧边内 154px (半开口 60 + 边距 14 + 富余 80)
    readonly property real seamReopenPad: DemoData.seamHomeWidth / 2 + 14 + 80
    function reopenSeam() {
        wall.stopGlide()
        var side = wall.seamSide
        var target = side === "left" ? wall.seamReopenPad : wall.width - wall.seamReopenPad
        var nx = wall.camX - (target - wall.seamCenterX) / wall.camScale
        camXTo.to = Math.max(wall.camMinXAt(wall.camScale), Math.min(wall.camMaxXAt(wall.camScale), nx))
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

    // 聚焦相机 = 把展开卡 (世界矩形) 拖到窗口正中 (用户定语义); 只能拖到墙面覆盖限位为止
    function focusCamX(r) {
        var s = wall.camScale
        var side = (r.x + r.w / 2) < DemoData.seamAnchorX ? -1 : 1
        var cx = r.x + r.w / 2
        var nx = cx
        // 磁贴在屏上还带所在半边的缝让位偏移; 让位量随缝宽变、缝宽又随落点变 — 两趟收敛 (开满/收起两常态下两趟即精确)
        for (var pass = 0; pass < 2; ++pass) {
            var scx = wall.width / 2 + (DemoData.seamAnchorX - nx) * s
            var sw = Math.max(0, Math.min(DemoData.seamHomeWidth, (Math.min(scx, wall.width - scx) - 14) * 2))
            var shift = sw / 2 + (DemoData.gap / 2) * s * Math.min(1, sw / 16)
            nx = cx + side * shift / s
        }
        return Math.max(wall.camMinXAt(s), Math.min(wall.camMaxXAt(s), nx))
    }
    function focusCamY(r) {
        var s = wall.camScale
        return Math.max(wall.camMinYAt(s), Math.min(wall.camMaxYAt(s), r.y + r.h / 2))
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

    // ---- 相机交互: 滚轮 + 指针拖动 (X/Y 限位 = 墙面覆盖视口, 缝可滑出屏收成标签) ----
    // 屏幕像素增量 → 相机 (除缩放); 拖缝条时 dy 传 0 = 只走 X
    function panBy(dx, dy) {
        wall.camX = Math.max(wall.camMinXAt(wall.camScale), Math.min(wall.camMaxXAt(wall.camScale), wall.camX - dx / wall.camScale))
        wall.camY = Math.max(wall.camMinYAt(wall.camScale), Math.min(wall.camMaxYAt(wall.camScale), wall.camY - dy / wall.camScale))
    }

    WheelHandler {
        onWheel: function(event) {
            camAnim.stop()
            wall.stopGlide()
            wall.panBy(event.angleDelta.x / 120 * 90, event.angleDelta.y / 120 * 90)
        }
    }

    // 指针拖动: 拖平铺页面 XY 跟手; 拖缝条(书架) 只走 X (按下点落在缝的 x 带内即判档)
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

        onActiveChanged: {
            if (pan.active) {
                camAnim.stop()
                wall.stopGlide()
                pan.xOnly = wall.seamW >= 1
                        && Math.abs(pan.centroid.pressPosition.x - wall.seamCenterX) <= wall.seamW / 2
                pan.lastTx = 0
                pan.lastTy = 0
                pan.velX = 0
                pan.velY = 0
                pan.moveAt = 0
            } else {
                wall.glideAfter(pan.velX, pan.velY, pan.xOnly, pan.moveAt)
            }
        }
        onTranslationChanged: {
            var dx = pan.translation.x - pan.lastTx
            var dy = pan.xOnly ? 0 : (pan.translation.y - pan.lastTy)
            pan.lastTx = pan.translation.x
            pan.lastTy = pan.translation.y
            var now = Date.now()
            var dt = now - pan.moveAt
            if (pan.moveAt > 0 && dt > 0 && dt < 100) {
                pan.velX = dx / dt * 1000
                pan.velY = dy / dt * 1000
            } else {
                pan.velX = 0
                pan.velY = 0
            }
            pan.moveAt = now
            wall.panBy(dx, dy)
        }
    }

    // 松手滑行 (参考参数: 速度阈 40px/s, 上限 4000, 距最后一段超过 80ms 算停住不滑)
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
        var x0 = wall.camX
        var y0 = wall.camY
        wall.panBy(wall.glideVx * dt / 1000, wall.glideVy * dt / 1000)
        if (wall.camX === x0)   // 被限位钳住 → 该轴惯性清零
            wall.glideVx = 0
        if (wall.camY === y0)
            wall.glideVy = 0
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
        var capped = Math.min(speed, 4000)
        wall.glideVx = vx / speed * capped
        wall.glideVy = xOnly ? 0 : vy / speed * capped
        wall.glideTickAt = Date.now()
        glideTimer.restart()
    }

    // ---- 页签切换: 缝条不翻 (选中态由 tabBtn 的 Behavior 丝滑渐变), 墙面发翻牌波次 ----
    // 只翻在屏的 (屏外直接换面, 不付 240 套动画的钱 — 卡顿大头)
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
            var delay = (t.x + 3264) / 6528 * 160   // 左→右波次, 总扫过约 160ms
            t.flipTo(d, delay)
        }
    }
}
