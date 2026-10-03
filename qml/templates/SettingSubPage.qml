import QtQuick

// ──────────────────────────────────────────────────────────
//  SettingSubPage — 设置子页面外壳
//  滚动容器 (clip/bounds/宽随视口, 内容高=视口子项包围盒;
//  各子页实例常驻, 切换分类保留滚动位置)
//  子页内容放一个居中列 (与旧结构同款):
//     Column {
//         anchors.horizontalCenter: parent.horizontalCenter
//         width: Math.min(parent.width - 48, 680)
//         spacing: 18
//         bottomPadding: 24   // 原 contentHeight+24 的底部留白
//     }
// ──────────────────────────────────────────────────────────
Flickable {
    id: root
    contentWidth: width
    contentHeight: contentItem.childrenRect.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
}
