import QtQuick
import QtQuick.Shapes
import "."

pragma ComponentBehavior: Bound

// M1 首页墙 (对标参照产品首页的"海报墙 + 中央缝"形态, 全部自绘)
//   世界 = 20 块 × 每块 12×8 格自铺场; 相机 = 视口中心世界坐标 (camX/camY) + 档位缩放 camScale
//   缝 = 中央 120px 常驻导航条 (竖标 + 页签 + 坞 + 账户); 切页签 = 缝翻 90° + 全墙翻牌波次
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

    // ---- 相机 ----
    // 档位: 视口宽 <640 → 0.52 / <1100 → 0.64 / 否则 0.76 (客观参数)
    readonly property real tier: width < 640 ? 0.52 : (width < 1100 ? 0.64 : 0.76)
    property real camScale: tier
    readonly property real camHomeY: DemoData.blockRows * DemoData.pitch / 2   // 544 = 块中线
    property real camX: 0          // 初始 = 缝锚点 (块列边界 x=0)
    property real camY: camHomeY
    property int activeTab: 0
    property var tiles: []   // 场景磁贴实例 (Repeater 创建时自注册; 换页签波次用)

    readonly property var scene: DemoData.buildScene()

    onTierChanged: { scaleAnim.to = tier; scaleAnim.restart() }
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

    // ---- 世界 (磁贴场; 相机写入 x/y/scale) ----
    Item {
        id: world
        x: wall.width / 2 - wall.camX * wall.camScale
        y: wall.height / 2 - wall.camY * wall.camScale
        scale: wall.camScale
        transformOrigin: Item.TopLeft

        Repeater {
            model: wall.scene
            delegate: WallTile {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h
                gi: modelData.gi
                item: modelData.item
                titlePx: Math.max(22, Math.min(36, 0.02 * wall.width))
                Component.onCompleted: wall.tiles.push(this)
            }
        }
    }

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

    // ---- 缝 (中央 120px 常驻导航) ----
    Item {
        id: seam
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 120
        height: wall.height
        z: 5
        property real flipAngle: 0

        transform: Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: seam.flipAngle
            origin.x: seam.width / 2
            origin.y: seam.height / 2
        }

        // 两侧软影 (贴地感)
        Rectangle {
            x: -34; width: 34; height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.42) }
            }
        }
        Rectangle {
            anchors.right: parent.right
            width: 34; height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.42) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
            }
        }

        // 纸面 (半透, 无模糊)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(WallTheme.seamPaper.r, WallTheme.seamPaper.g,
                           WallTheme.seamPaper.b, WallTheme.seamAlpha)
            border.color: WallTheme.seamRing
            border.width: 1
        }
        Rectangle { width: 1; height: parent.height; color: WallTheme.hairline }
        Rectangle {
            anchors.right: parent.right
            width: 1; height: parent.height
            color: WallTheme.hairline
        }

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
                    Text {
                        anchors.centerIn: parent
                        text: tabBtn.modelData.label.split("").join("\n")
                        color: tabBtn.index === wall.activeTab
                               ? WallTheme.text
                               : Qt.rgba(244 / 255, 244 / 255, 245 / 255, 0.45)
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

    // ---- 相机交互: 滚轮平移 (钳制 ±816 世界像素, 墙面始终铺满视口) ----
    WheelHandler {
        onWheel: function(event) {
            var step = 90 / wall.camScale
            wall.camX = Math.max(-816, Math.min(816,
                        wall.camX - event.angleDelta.x / 120 * step))
            wall.camY = Math.max(wall.camHomeY - 816, Math.min(wall.camHomeY + 816,
                        wall.camY - event.angleDelta.y / 120 * step))
        }
    }

    // ---- 页签切换: 缝翻 90° → 换内容并发全墙翻牌波次 → 翻回 ----
    property int pendingTab: -1

    function switchTab(i) {
        if (i === wall.activeTab || seamFlip.running)
            return
        wall.pendingTab = i
        seamFlip.restart()
    }

    function commitTab() {
        wall.activeTab = wall.pendingTab
        var key = DemoData.tabKey(wall.activeTab)
        for (var k = 0; k < wall.tiles.length; ++k) {
            var t = wall.tiles[k]
            var delay = (t.x + 3264) / 6528 * 160   // 左→右波次, 总扫过约 160ms
            t.flipTo(DemoData.itemFor(key, t.gi), delay)
        }
    }

    SequentialAnimation {
        id: seamFlip
        NumberAnimation {
            target: seam; property: "flipAngle"
            from: 0; to: 90; duration: 160; easing.type: Easing.InCubic
        }
        ScriptAction { script: wall.commitTab() }
        NumberAnimation {
            target: seam; property: "flipAngle"
            from: 90; to: 0; duration: 240; easing.type: Easing.OutCubic
        }
    }
}
