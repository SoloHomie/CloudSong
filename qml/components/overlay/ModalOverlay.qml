import QtQuick

/// ──────────────────────────────────────────────────────────
///  模态遮罩层 — 弹窗背景暗化
///  用法：Popup { Overlay.modal: ModalOverlay {} }
/// ──────────────────────────────────────────────────────────
Rectangle {
    color: "#000000"
    opacity: 0.65
    radius: 6
    Behavior on opacity { NumberAnimation { duration: 200 } }
}
