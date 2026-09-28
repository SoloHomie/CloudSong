import QtQuick
import "../../../theme"
import "../../display"

// ──────────────────────────────────────────────────────────────
//  SearchRow — 搜索面板列表行 (历史/建议两模式共用, 属 SearchPanel)
//  hover 变亮; 键盘选中 (selected) 同款高亮; 长词中间省略 + tooltip 完整词;
//  历史模式 hover/选中 行尾出 × 单删 (× 的 MouseArea 声明在行 MouseArea 之后,
//  否则被吞 — 见行级 MouseArea 吞内层图标老坑)
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property string label: ""
    property bool selected: false      // 键盘/鼠标选中高亮
    property bool deletable: false     // 历史行可单删
    signal activated()
    signal removeRequested()
    signal hoverEntered()

    width: parent.width
    height: 30

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (rowMouse.containsMouse || root.selected) ? Theme.hover_bg : "transparent"
    }

    Text {
        id: labelText
        anchors { left: parent.left; leftMargin: 10;
                  right: delBtn.visible ? delBtn.left : parent.right; rightMargin: 8;
                  verticalCenter: parent.verticalCenter }
        text: root.label
        font { family: Theme.fontFamily; pixelSize: 12 }
        color: Theme.text_primary
        elide: Text.ElideMiddle
    }

    // 完整词 tooltip (仅截断时 hover 显示; Tooltip 窗口级挂载, 不受列表 clip 影响)
    Tooltip {
        text: root.label
        shown: rowMouse.containsMouse && labelText.truncated
        delay: 400
        radius: 8
        bgColor: Theme.bg_card
        borderColor: Theme.border_standard
        placement: 1   // 1 = below (枚举未导出, 字面量同 AccountChip 先例)
        anchorItem: root
    }

    // 单删按钮 (历史模式; hover 或键盘选中时出现)
    Item {
        id: delBtn
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width: 18
        height: 18
        visible: root.deletable && (rowMouse.containsMouse || root.selected)
        IconImage {
            anchors.centerIn: parent
            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/x.svg"
            color: Theme.text_hint
            size: 12
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.removeRequested()
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoverEntered()
        onClicked: root.activated()
    }
}
