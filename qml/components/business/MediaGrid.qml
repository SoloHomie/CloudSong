import QtQuick
import "../display"

// ──────────────────────────────────────────────────────────────
//  MediaGrid — 媒体卡片网格 (歌单/专辑/歌手通用)
//  model: JS 数组 [{title,subtitle,seed,platform}]
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property var model: []
    property real cellWidth: 150
    property string emptyTitle: "暂无内容"
    property string emptyMessage: ""
    property string emptyActionText: ""
    signal openRequested(var item)
    signal emptyActionRequested()

    readonly property real cellH: root.cellWidth + 44

    StatusPlaceholder {
        anchors.fill: parent
        visible: root.model.length === 0
        status: "empty"
        title: root.emptyTitle
        message: root.emptyMessage
        actionText: root.emptyActionText
        onActionRequested: root.emptyActionRequested()
    }

    GridView {
        id: grid
        anchors.fill: parent
        model: root.model
        clip: true
        visible: root.model.length > 0
        cellWidth: root.cellWidth
        cellHeight: cellH
        boundsBehavior: Flickable.StopAtBounds
        // 2026-10-02: 命名内联组件裸名 delegate 在 Qt 6.11 静默空列表, 须包匿名 Component;
        // 卡片已提取至同目录 GridCell.qml, 单元宽高与打开动作由宿主注入
        delegate: Component {
            GridCell {
                cellWidth: root.cellWidth
                cellH: root.cellH
                onOpenRequested: function(it) { root.openRequested(it) }
            }
        }
    }
}
