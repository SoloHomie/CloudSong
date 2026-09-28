import QtQuick
import "../../../theme"

// ──────────────────────────────────────────────────────────────
//  SearchPanel — 搜索框下拉面板窗体 (窗口级挂载, 同 overlay/Popover 路径:
//  打开时面板本体挂 Window.contentItem 顶层, 避开祖先裁剪与兄弟 z 遮挡)
//  历史/建议两模式共用: 标题随 mode 切; 行列表上限 240px(8行)超则滚动,
//  键盘选中自动滚入视野; 历史模式带"清空历史"与行级单删; 空态文案随模式切;
//  打开时同步挂全窗口点击捕获层(点输入框/面板本体除外)发 dismissRequested
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    property bool open: false
    property Item anchorItem: null      // 定位锚 (输入框本体), 面板挂其正下方
    property string mode: "history"     // "history" 历史 / "suggest" 建议
    property var model: []              // 行数据 (string 数组)
    property int selected: -1           // 高亮行 (键盘 ↑↓ / 鼠标 hover)
    signal itemActivated(string label)
    signal itemRemoved(string label)
    signal clearRequested()
    signal dismissRequested()           // 点击输入框以外任何地方 (2026-09-29 用户定调的失焦语义)

    width: 1
    height: 1

    // ── 面板本体 (打开时挂到窗口顶层; 关闭后归还本组件以随树销毁) ──
    Rectangle {
        id: panel
        z: 2147483647
        visible: false
        opacity: 0
        scale: 0.96
        transformOrigin: Item.Top
        width: root.width
        height: col.implicitHeight + 24
        radius: 10
        color: Theme.bg_card
        border { width: 1; color: Theme.border_standard }

        Column {
            id: col
            anchors { fill: parent; margins: 12 }
            spacing: 10

            // 标题行 (随模式切换; 历史模式带"清空历史")
            Item {
                id: headerItem
                width: parent.width
                height: 16
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root.mode === "history" ? "搜索历史" : "搜索建议"
                    font { family: Theme.fontFamily; pixelSize: 12; weight: Font.Bold }
                    color: Theme.text_secondary
                }
                Text {
                    visible: root.mode === "history" && root.model.length > 0
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "清空历史"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.accent_text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearRequested()
                    }
                }
            }

            // 行列表 (上限 240 = 8 行, 超出滚动)
            Flickable {
                id: flick
                width: parent.width
                height: Math.min(root.model.length * 30, 240)
                clip: true
                contentHeight: rowCol.implicitHeight
                interactive: contentHeight > height
                Column {
                    id: rowCol
                    width: flick.width
                    spacing: 2
                    Repeater {
                        model: root.model
                        delegate: SearchRow {
                            label: modelData
                            selected: index === root.selected
                            deletable: root.mode === "history"
                            onHoverEntered: root.selected = index
                            onActivated: root.itemActivated(modelData)
                            onRemoveRequested: root.itemRemoved(modelData)
                        }
                    }
                }
            }

            // 空态
            Text {
                visible: root.model.length === 0
                text: root.mode === "history" ? "暂无搜索历史" : "无匹配建议"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_hint
            }
        }

    }

    // ── 点击别处捕获层 (2026-09-29 用户定调: 点击输入框=焦点进, 点击其他地方=焦点出;
    //    打开时挂窗口顶层、位于面板 z 之下, propagateComposedEvents 把点击继续传给
    //    下层 UI 不吞交互; 点在输入框本体上不算"别处", 输入框点击层自己负责开面板) ──
    Item {
        id: dismissLayer
        z: 2147483646
        visible: false
        width: Window.window ? Window.window.width : 0
        height: Window.window ? Window.window.height : 0
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: function(mouse) {
                if (!root.anchorItem) return
                var p = root.anchorItem.mapToItem(dismissLayer, 0, 0)
                if (mouse.x >= p.x && mouse.x <= p.x + root.anchorItem.width
                    && mouse.y >= p.y && mouse.y <= p.y + root.anchorItem.height)
                    return   // 点在输入框本体: 输入框点击层自己处理 (聚焦/开面板)
                var pp = panel.mapToItem(dismissLayer, 0, 0)
                if (mouse.x >= pp.x && mouse.x <= pp.x + panel.width
                    && mouse.y >= pp.y && mouse.y <= pp.y + panel.height)
                    return   // 点在面板本体 (含内边距): 非交互区不关 (Rectangle 不吃点击会穿透到这)
                root.dismissRequested()
            }
        }
    }

    // ── 开合过渡 (沿用旧面板参数: 140/180 出现, 100/110 收起) ──
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: panel; property: "opacity"; from: 1; to: 0; duration: 100; easing.type: Easing.InCubic }
            NumberAnimation { target: panel; property: "scale"; from: 1; to: 0.98; duration: 110; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { panel.visible = false; panel.parent = root } }
    }

    onOpenChanged: {
        if (open) {
            hideAnim.stop()
            if (!root.anchorItem || !Window.window) return
            var p = root.anchorItem.mapToItem(Window.window.contentItem, 0, 0)
            panel.parent = Window.window.contentItem
            panel.x = p.x
            panel.y = p.y + root.anchorItem.height + 8
            flick.contentY = 0
            panel.visible = true
            panel.opacity = 0
            panel.scale = 0.96
            showAnim.start()
            // 点击捕获层同挂窗口顶层 (面板 z 之下、其余 UI 之上)
            dismissLayer.parent = Window.window.contentItem
            dismissLayer.x = 0
            dismissLayer.y = 0
            dismissLayer.visible = true
        } else {
            showAnim.stop()
            hideAnim.start()
            dismissLayer.visible = false
        }
    }

    // 键盘选中行滚入视野 (行节距 = 30 行高 + 2 间距)
    function ensureSelectedVisible() {
        if (root.selected < 0 || root.selected >= root.model.length) return
        var top = headerItem.height + col.spacing + root.selected * 32
        if (top < flick.contentY) flick.contentY = top
        else if (top + 30 > flick.contentY + flick.height) flick.contentY = top + 30 - flick.height
    }
    onSelectedChanged: ensureSelectedVisible()

    // 面板还挂在窗口上时本组件被销毁: 一并销毁, 防孤儿面板引用已毁对象
    Component.onDestruction: {
        if (panel.parent !== root) panel.destroy()
        if (dismissLayer.parent !== root) dismissLayer.destroy()
    }
}
