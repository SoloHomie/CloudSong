import QtQuick
import QtQuick.Effects
import QtQuick.Window
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  IconImage — 单色 SVG 图标 (白色源图 + 着色)
//  用法: IconImage { source: "qrc:.../play.svg"; color: Theme.accent; size: 16 }
//  sourceSize 按实际渲染像素 × DPR 逐像素栅格化, 抗锯齿
//  (固定 64px 源再缩小到 21/26px 会因线性滤波缩样出现锯齿)
// ──────────────────────────────────────────────────────────────
Image {
    id: root
    property color color: Theme.text_secondary
    property real size: 16
    property bool tint: true     // false = 保留源图原色 (品牌图标用)
    width: size
    height: size
    sourceSize: Qt.size(Math.max(1, Math.ceil(size * Screen.devicePixelRatio)),
                        Math.max(1, Math.ceil(size * Screen.devicePixelRatio)))
    fillMode: Image.PreserveAspectFit
    smooth: true
    antialiasing: true
    layer.enabled: true
    layer.effect: MultiEffect {
        colorizationColor: root.color
        colorization: root.tint ? 1.0 : 0.0
    }
}
