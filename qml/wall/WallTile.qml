import QtQuick
import "."

pragma ComponentBehavior: Bound

// 墙上一块磁贴 (demo 一律当"集合": 双环堆叠边缘 + 左上角标 + 左下文案)
// 翻牌 = 绕竖轴 0→90° (前半 150ms) → 90° 处换面 → 90→0° (后半 210ms); 由 switchTab 波次触发
// 让位 = 聚焦展开时同块 12 张换挡 (gearTo; 420ms OutCubic 无过冲 — 比参照弹簧快, 用户实测提速)
// 展开态 (expanded): 就地变 6×6 大卡 — 双环收起 + 常态削色退场 + 聚焦文案浮层 (更大字号, 揭示时序 100ms/200ms/升 12px)
// 点击 = activated() (WallHome 接: 聚焦展开; 同卡再点无反应 — 对标参照)
// 提示: 本 demo 不复制任何封面图 — 全部用 hue 回退渐变, 保零素材依赖
Item {
    id: tile

    property var item: null          // 当前内容 { kind, title, owner, tracks, hue, subtitle }
    property int gi: 0               // 场景全局序号 (换页签时按此取新内容)
    property real titlePx: 30        // 标题字号 (世界单位, 随窗口宽 clamp)
    property string slotKey: ""      // 块槽位身份 "col,row,slot" (让位时同块互找)
    property int col: 0
    property int row: 0
    property int slotIdx: 0
    property real restX: 0           // 静止矩形 (建场时由 registerTile 存)
    property real restY: 0
    property real restW: 0
    property real restH: 0
    property bool expanded: false    // 聚焦展开态 (块内 6×6; 由 WallHome 设)
    property var focusOverlay: null  // 聚焦文案浮层 (展开时建, 收起即毁)

    signal activated()

    property var face: item          // 展示面 (旋转 90° 时替换)
    property var pendingItem: null
    property real flipAngle: 0
    property real hoverT: 0
    property bool panning: false     // 墙拖动/滑行中: 抑制 hover 抬升 (参照原型: 拖动中不触发)

    readonly property var grad: WallTheme.gradFor(face !== null ? face.hue : 0)
    readonly property real pop: 1 + (16 / Math.max(1, width)) * hoverT

    function flipTo(d, delay) {
        pendingItem = d
        flipTimer.interval = Math.max(0, delay)
        flipTimer.restart()
    }

    // 屏外磁贴换页签: 免动画直接换面 (省一套 360ms 序列)
    function flipNow(d) {
        flipTimer.stop()
        flipSeq.stop()
        flipAngle = 0
        pendingItem = d
        face = d
    }

    // 让位换挡 (展开/收起: 同块 12 张同参同刻)
    function gearTo(x, y, w, h) {
        gearX.to = x
        gearY.to = y
        gearW.to = w
        gearH.to = h
        gearAnim.restart()
    }

    // 无限墙的窗口回收: 直接落位到新槽位 (调用点必在屏外; 中断一切过渡, 免动画)
    function relocate(s) {
        gearAnim.stop()
        flipTimer.stop()
        flipSeq.stop()
        flipAngle = 0
        col = s.col
        row = s.row
        slotIdx = s.slot
        slotKey = s.key
        gi = s.gi
        restX = s.x
        restY = s.y
        restW = s.w
        restH = s.h
        x = s.x
        y = s.y
        width = s.w
        height = s.h
        item = s.item
        face = s.item
        pendingItem = null
    }

    onExpandedChanged: {
        if (expanded) {
            hoverAnim.to = 0   // 大卡不带 hover 抬升
            hoverAnim.restart()
            if (focusOverlay === null)
                focusOverlay = focusCopyComp.createObject(tile)
        } else if (focusOverlay !== null) {
            focusOverlay.destroy()
            focusOverlay = null
        }
    }

    z: tile.expanded ? 20 : (hoverT > 0.01 ? 3 : 0)

    transform: [
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: tile.flipAngle
            origin.x: tile.width / 2
            origin.y: tile.height / 2
        },
        Scale {
            origin.x: tile.width / 2
            origin.y: tile.height / 2
            xScale: tile.pop
            yScale: tile.pop
        }
    ]

    // ---- 让位补间 (事件驱动; 300ms OutCubic: 起步快、尾段缓, 无过冲 — 参照弹簧的慢起头实测偏拖沓) ----
    ParallelAnimation {
        id: gearAnim
        NumberAnimation {
            id: gearX
            target: tile; property: "x"; duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: gearY
            target: tile; property: "y"; duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: gearW
            target: tile; property: "width"; duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: gearH
            target: tile; property: "height"; duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // ---- 堆叠边缘 (集合专属双环; hover 时收起, 展开时隐去) ----
    Rectangle {
        visible: !tile.expanded
        x: 6 * (1 - tile.hoverT); y: 6 * (1 - tile.hoverT)
        width: tile.width; height: tile.height
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
    }
    Rectangle {
        visible: !tile.expanded
        x: 3 * (1 - tile.hoverT); y: 3 * (1 - tile.hoverT)
        width: tile.width; height: tile.height
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.11); border.width: 1
    }

    // ---- 封面 (回退渐变, 全幅) ----
    // 目标形态为 145° 斜向渐变; QML 的 Gradient 只支持水平/垂直, 用放大旋转的矩形 + 裁切近似
    Item {
        anchors.fill: parent
        clip: true
        Rectangle {
            width: Math.max(tile.width, tile.height) * 1.45
            height: width
            anchors.centerIn: parent
            rotation: -27
            gradient: Gradient {
                GradientStop { position: 0; color: tile.grad[0] }
                GradientStop { position: 1; color: tile.grad[1] }
            }
        }
        // 底部压暗
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: WallTheme.shadeLow }
                GradientStop { position: 0.34; color: WallTheme.shadeLow }
                GradientStop { position: 0.56; color: WallTheme.shadeMid }
                GradientStop { position: 1.0; color: WallTheme.shadeDeep }
            }
        }
    }

    // ---- 常态削色层 (hover 时退场, 展开时全退; 露出封面本色) ----
    Rectangle {
        anchors.fill: parent
        opacity: tile.expanded ? 0 : WallTheme.tintOpacity * (1 - tile.hoverT)
        gradient: Gradient {
            GradientStop { position: 0; color: WallTheme.tintTop }
            GradientStop { position: 1; color: WallTheme.tintBottom }
        }
    }

    // hover 提亮
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.06 * tile.hoverT)
    }

    // ---- 左上角标 ----
    Rectangle {
        x: 14; y: 14
        width: badgeText.implicitWidth + 16
        height: 22
        color: Qt.rgba(0, 0, 0, 0.62)
        Text {
            id: badgeText
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: tile.face !== null ? DemoData.badgeFor(tile.face) : ""
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: WallTheme.fontFamily
            font.pixelSize: 11
            font.weight: 800
            font.letterSpacing: 1.32
        }
    }

    // ---- 左下文案 (展开时让位给聚焦文案浮层) ----
    Column {
        opacity: tile.expanded ? 0 : 1
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            margins: 17
        }
        spacing: 5
        Text {
            width: parent.width
            text: tile.face !== null ? tile.face.title : ""
            color: WallTheme.text
            font.family: WallTheme.fontFamily
            font.pixelSize: tile.titlePx
            font.weight: 800
            font.letterSpacing: -0.045 * tile.titlePx
            lineHeight: 0.96
            lineHeightMode: Text.ProportionalHeight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: tile.face !== null ? tile.face.subtitle : ""
            color: WallTheme.textDim
            font.family: WallTheme.fontFamily
            font.pixelSize: 13
            font.weight: 650
            elide: Text.ElideRight
        }
    }

    // ---- 交互 ----
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onEntered: { if (!tile.expanded && !tile.panning) { hoverAnim.to = 1; hoverAnim.restart() } }
        onExited: {
            // 空退出不上动画 (对标 Folia: 拖动时 capture 让海报收不到 hover): 拖动/滑行中每穿过一张卡
            // exit 都会来, hoverT 恒 0 若仍 restart 一段 0→0 的 300ms NumberAnimation, 每个存活动画
            // 都把渲染循环踢成满速 (2026-10-13 实测: 空闲 ~0fps ↔ 空动画 240fps 连续渲染) —
            // 快速连续拖动时链式空转 = 卡顿; hoverT>0 的真实退出 / 进场动画未落又立刻出 照常回落
            if (tile.hoverT > 0 || hoverAnim.running) {
                hoverAnim.to = 0
                hoverAnim.restart()
            }
        }
        onClicked: tile.activated()   // 聚焦展开 / 再点收起 (进集合页排 M2)
    }
    NumberAnimation {
        id: hoverAnim
        target: tile
        property: "hoverT"
        duration: 300
        easing.type: Easing.OutCubic
    }

    // ---- 聚焦文案浮层 (展开时创建: 更大字号; 揭示 = 100ms 后开始, 200ms 内自下 12px 淡入) ----
    Component {
        id: focusCopyComp
        Item {
            id: fcOverlay
            anchors.fill: parent
            opacity: 0
            Column {
                id: fcCol
                anchors {
                    left: parent.left; right: parent.right; bottom: parent.bottom
                    margins: 30
                }
                spacing: 8
                transform: Translate { id: fcRise; y: 12 }
                Text {
                    width: parent.width
                    text: tile.face !== null ? tile.face.title : ""
                    color: WallTheme.text
                    font.family: WallTheme.fontFamily
                    font.pixelSize: tile.titlePx * 1.55
                    font.weight: 800
                    font.letterSpacing: -0.045 * tile.titlePx * 1.55
                    lineHeight: 0.96
                    lineHeightMode: Text.ProportionalHeight
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: tile.face !== null ? tile.face.subtitle : ""
                    color: WallTheme.textDim
                    font.family: WallTheme.fontFamily
                    font.pixelSize: 16
                    font.weight: 650
                    elide: Text.ElideRight
                }
            }
            SequentialAnimation {
                running: true
                PauseAnimation { duration: 70 }
                ParallelAnimation {
                    NumberAnimation {
                        target: fcOverlay; property: "opacity"
                        from: 0; to: 1; duration: 140; easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: fcRise; property: "y"
                        from: 12; to: 0; duration: 140; easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    // ---- 翻牌 ----
    // Timer 默认 repeat=false (一次即停), restart() 每次重新计时
    Timer { id: flipTimer; onTriggered: flipSeq.restart() }
    SequentialAnimation {
        id: flipSeq
        NumberAnimation {
            target: tile; property: "flipAngle"
            from: 0; to: 90; duration: 150; easing.type: Easing.InCubic
        }
        ScriptAction { script: tile.face = tile.pendingItem }
        NumberAnimation {
            target: tile; property: "flipAngle"
            from: 90; to: 0; duration: 210; easing.type: Easing.OutCubic
        }
    }
}
