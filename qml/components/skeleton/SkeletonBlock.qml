import QtQuick
import "../../theme"

// ──────────────────────────────────────────────────────────────
//  SkeletonBlock — 骨架屏占位块 (扫光渐变)
//  形状即用法: 文本行=窄块, 封面=方块+大圆角, 圆点=半径取半,
//  按钮/分段条=相应尺寸圆角块; 页面骨架用本组件拼装
//
//  动画铁律: QML 连续动画 1000fps 空转吃 CPU (CloudSong 实证
//  2026-09-28), 必须 Timer 手动节流; running 绑定 visible,
//  骨架隐藏即停, 不占任何渲染
// ──────────────────────────────────────────────────────────────
Rectangle {
    id: root
    width: 100; height: 14
    radius: 4
    color: Theme.skeleton_bg
    clip: true

    property real sweepPeriod: 1300   // 扫光一个来回周期 (ms)

    // 扫光条 (透明→高光→透明, 左→右循环)
    Rectangle {
        id: shine
        width: root.width * 0.6
        height: parent.height
        x: root.phase
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.skeleton_shine }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    property real phase: -shine.width

    Timer {
        interval: 33   // ~30fps, 仅骨架可见期间运行
        running: root.visible
        repeat: true
        onTriggered: {
            root.phase += (root.width + shine.width) / (root.sweepPeriod / interval)
            if (root.phase > root.width) root.phase = -shine.width
        }
    }
}
