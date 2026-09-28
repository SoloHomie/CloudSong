import QtQuick

// ═══════════════════════════════════════════════════════════════════════════════
//  LoadingDots — 8 点波浪加载动画 (无光晕描边, 圆形点 + 透明度呼吸)
//  用法:
//    LoadingDots { running: true }
//    LoadingDots { running: true; dotColor: "#c5ff00" }   // 荧光黄
//
//  2026-09-28 打磨: 原实现为每点一个无限 SequentialAnimation,
//  本机垂直同步全局关闭 → 连续动画驱动渲染循环空转吃满 CPU;
//  改为 33ms Timer 手动推进全局相位, 各点按相位差计算形态 (同 SoundBars 方案)。
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    property bool  running:  true
    property color dotColor: "#7bed9f"
    property int   dotSize:  8
    property int   dotCount: 8

    implicitWidth:  dotCount * dotSize + (dotCount - 1) * 4
    implicitHeight: dotSize * 3 + 7

    // ── 节拍 (与原动画节奏一致) ──
    // 总周期 = 单点起落 240+240ms + 首尾停顿各 (dotCount-1)*120ms
    readonly property int periodMs: 480 + (dotCount - 1) * 120
    readonly property real riseFrac: 240 / periodMs
    readonly property real fallFrac: 240 / periodMs
    property int tMs: 0

    function ease(x) { return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2 }

    // 点 i 在 tMs 时刻的振幅 k ∈ [0,1] (0=静止, 1=峰值)
    function ampAt(i, t) {
        var p = ((t / periodMs) - i * 120 / periodMs) % 1
        if (p < 0) p += 1
        if (p < riseFrac) return ease(p / riseFrac)
        if (p < riseFrac + fallFrac) return ease(1 - (p - riseFrac) / fallFrac)
        return 0
    }

    Timer {
        interval: 33
        running: root.running
        repeat: true
        onTriggered: { root.tMs += 33; if (root.tMs >= root.periodMs) root.tMs -= root.periodMs }
    }

    Row {
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.dotCount

            Rectangle {
                id: dot
                width:  root.dotSize
                height: root.dotSize
                radius: root.dotSize / 2
                color: root.dotColor

                readonly property real k: root.ampAt(index, root.tMs)
                opacity: 0.45 + 0.55 * k
                // 与原实现一致: 只纵向拉伸 (yScale), 横向不变
                transform: Scale {
                    origin.x: dot.width / 2
                    origin.y: dot.height / 2
                    xScale: 1
                    yScale: 1 + dot.k
                }
            }
        }
    }
}
