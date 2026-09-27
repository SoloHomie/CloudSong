import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  CoverArt — 封面占位图 (seed 决定渐变底色 + 音符水印)
//  真实封面图服务落地后: 加 cover 属性, 有值渲染 Image 即可
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    property int seed: 0
    radius: 6
    clip: true
    // swatches 而非 palette: QQuickItem 基类已有 palette 属性, 同名会遮蔽
    readonly property var swatches: ["#8957e5", "#1f6feb", "#238636", "#b35900", "#d1242f", "#8250df", "#0a7e8c", "#6e40c9"]
    readonly property color tint: swatches[seed % swatches.length]

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(root.tint, 1.15) }
        GradientStop { position: 1.0; color: Qt.darker(root.tint, 1.35) }
    }

    IconImage {
        anchors.centerIn: parent
        size: Math.max(14, root.height * 0.36)
        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
        color: Qt.rgba(1, 1, 1, 0.8)
    }
}
