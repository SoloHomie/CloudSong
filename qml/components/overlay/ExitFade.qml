import QtQuick

// ──────────────────────────────────────────────────────────────
//  ExitFade — 弹窗/浮层关闭过渡: 淡出 + 轻微收缩
//  用法: Popup { exit: ExitFade {} }
// ──────────────────────────────────────────────────────────────
Transition {
    ParallelAnimation {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.92; duration: 150; easing.type: Easing.InCubic }
    }
}
