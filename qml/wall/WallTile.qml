import QtQuick
import "."

// 墙上一块磁贴 (demo 一律当"集合": 双环堆叠边缘 + 左上角标 + 左下文案)
// 翻牌 = 绕竖轴 0→90° (前半 150ms) → 90° 处换面 → 90→0° (后半 210ms); 由 switchTab 波次触发
// 提示: 本 demo 不复制任何封面图 — 全部用 hue 回退渐变, 保零素材依赖
Item {
    id: tile

    property var item: null          // 当前内容 { kind, title, owner, tracks, hue, subtitle }
    property int gi: 0               // 场景全局序号 (换页签时按此取新内容)
    property real titlePx: 30        // 标题字号 (世界单位, 随窗口宽 clamp)

    property var face: item          // 展示面 (旋转 90° 时替换)
    property var pendingItem: null
    property real flipAngle: 0
    property real hoverT: 0

    readonly property var grad: WallTheme.gradFor(face !== null ? face.hue : 0)
    readonly property real pop: 1 + (16 / Math.max(1, width)) * hoverT

    function flipTo(d, delay) {
        pendingItem = d
        flipTimer.interval = Math.max(0, delay)
        flipTimer.restart()
    }

    z: hoverT > 0.01 ? 3 : 0

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

    // ---- 堆叠边缘 (集合专属双环; hover 时收起) ----
    Rectangle {
        x: 6 * (1 - tile.hoverT); y: 6 * (1 - tile.hoverT)
        width: tile.width; height: tile.height
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
    }
    Rectangle {
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

    // ---- 常态削色层 (hover 时退场, 露出封面本色) ----
    Rectangle {
        anchors.fill: parent
        opacity: WallTheme.tintOpacity * (1 - tile.hoverT)
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

    // ---- 左下文案 ----
    Column {
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
        onEntered: { hoverAnim.to = 1; hoverAnim.restart() }
        onExited: { hoverAnim.to = 0; hoverAnim.restart() }
        onClicked: {}   // 占位: 进集合页排 M2
    }
    NumberAnimation {
        id: hoverAnim
        target: tile
        property: "hoverT"
        duration: 300
        easing.type: Easing.OutCubic
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
