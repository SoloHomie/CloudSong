import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  ParticleBackdrop — 推荐页 3D 粒子背景 (2026-10-02)
//  GPU 星场: 100 粒子 4 层深度循环漂移 + 闪烁, 近大远小透视即"3D"感;
//  Timer 33ms 步进驱动 (VSYNC 失效, 不能依赖连续动画)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property real t: 0
    Timer {
        interval: 33
        running: root.visible
        repeat: true
        onTriggered: root.t = (root.t + 0.033) % 60.0
    }

    ShaderEffect {
        anchors.fill: parent
        property real uTime: root.t
        property real uW: width
        property real uH: height
        property color uAccent: Theme.accent
        property real uAlpha: 0.55
        // Qt 6 要求 qsb 预编译产物 (.qsb; 源码 particles.frag 不随包, 改动后须重跑 qsb 再编译)
        fragmentShader: "particles.frag.qsb"
    }
}
