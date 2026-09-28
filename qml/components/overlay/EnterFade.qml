import QtQuick

// ──────────────────────────────────────────────────────────────
//  EnterFade — 弹窗/浮层出现过渡: 淡入 + 轻微放大回弹
//  用法: Popup { enter: EnterFade {} }
//  缩放原点由使用方设 transformOrigin (不设即 Center)
// ──────────────────────────────────────────────────────────────
Transition {
    ParallelAnimation {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 220; easing.type: Easing.OutBack }
    }
}
