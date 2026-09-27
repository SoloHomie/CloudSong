import QtQuick
import QtQuick.Effects
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  IconImage — 单色 SVG 图标 (白色源图 + 着色)
//  用法: IconImage { source: "qrc:.../play.svg"; color: Theme.accent; size: 16 }
// ──────────────────────────────────────────────────────────────
Image {
    id: root
    property color color: Theme.text_secondary
    property real size: 16
    width: size
    height: size
    sourceSize: Qt.size(64, 64)
    fillMode: Image.PreserveAspectFit
    smooth: true
    antialiasing: true
    layer.enabled: true
    layer.effect: MultiEffect {
        colorizationColor: root.color
        colorization: 1.0
    }
}
