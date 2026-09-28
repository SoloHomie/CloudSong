import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  Tooltip — 窗口级浮层提示
//
//  外部保持轻量占位 <Item>，内部用 createObject 将真正的提示框
//  挂到 Window.contentItem 上，彻底避开祖先 clip。定位智能避让屏幕边缘。
//
//  暴露属性:
//    text           提示文字
//    shown          显示/隐藏
//    fontSize       字号 (默认 14)
//    maxWidth       最大宽度 (默认 280)
//    radius         圆角 (默认 4, PlayerBar 悬停提示覆为 8)
//    delay          悬停延迟 ms (默认 0)
//    duration       自动消失 ms (0=手动)
//    anchorItem     锚定目标
//    placement      偏好: above / below / auto
//    arrowVisible   三角箭头
//    offsetX / Y    微调偏移
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // ── 公开属性 ──
    property string text:          ""
    property bool   shown:         false
    property int    fontSize:      14
    property font   labelFont:     Qt.font({ pixelSize: 11, family: Theme.fontFamily })
    property int    maxWidth:      280
    property int    maxLines:      8
    property color  bgColor:       Theme.border_default
    property color  borderColor:   Theme.border_standard
    property int    radius:        4
    property int    delay:         0
    property int    duration:      0
    property var    anchorItem:    null
    property int    placement:     Tooltip.above
    property bool   arrowVisible:  true
    property real   offsetX:       0
    property real   offsetY:       0

    readonly property int above:   0
    readonly property int below:   1
    readonly property int auto:    2

    // ── 内部 ──
    property var _tip:    null
    property var _timer:  null

    function _target() { return root.anchorItem || root.parent }

    // ═══════════════════════════════════════════════════════
    //  真正的提示框组件 (挂到 Window.contentItem 上)
    // ═══════════════════════════════════════════════════════
    Component {
        id: tipComp

        Rectangle {
            id: bg

            z: 2147483647
            clip: false
            color: root.bgColor
            radius: root.radius
            border.width: 1
            border.color: root.borderColor

            property bool _shown: false

            function _doShow()   { _shown = true  }
            function _doHide()   { _shown = false }

            opacity: _shown ? 1 : 0
            scale:   _shown ? 1 : 0.92

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            // ── 文字 ──
            Text {
                id: lbl
                text: root.text
                color: Theme.text_primary
                font.pixelSize: root.fontSize
                font.family: root.labelFont.family
                font.weight: root.labelFont.weight
                font.italic: root.labelFont.italic
                wrapMode: Text.Wrap
                maximumLineCount: root.maxLines
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.maxWidth - 24)
                anchors.centerIn: parent
            }

            width:  Math.min(lbl.implicitWidth + 24, root.maxWidth)
            height: lbl.implicitHeight + 14

            // ── 定位 ──
            function _updatePos() {
                var t = root._target()
                if (!t || !Window.window) return

                var p = t.mapToItem(Window.window.contentItem, t.width / 2, 0)
                var fw = Window.window.width
                var fh = Window.window.height

                // 水平: 居中锚点, 贴边
                var cx = p.x - bg.width / 2 + root.offsetX
                if (cx < 8) cx = 8
                if (cx + bg.width > fw - 8) cx = fw - bg.width - 8
                bg.x = cx

                // 垂直: auto 优先上面, 不够换下面
                var spaceAbove = p.y - 4
                var spaceBelow = fh - (p.y + t.height) - 4
                var preferAbove = (root.placement === Tooltip.above) ||
                    (root.placement === Tooltip.auto && spaceAbove >= bg.height + 6)

                if (preferAbove && spaceAbove >= bg.height + 6) {
                    bg.y = p.y - bg.height - 6 + root.offsetY
                } else if (spaceBelow >= bg.height + 6) {
                    bg.y = p.y + t.height + 6 + root.offsetY
                } else {
                    bg.y = p.y - bg.height - 6 + root.offsetY  // 兜底
                }
            }

            Component.onCompleted: {
                _doShow()
                _updatePos()
            }

            // 窗口 resize 时重算
            Connections {
                target: Window.window
                function onWidthChanged()  { bg._updatePos() }
                function onHeightChanged() { bg._updatePos() }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    //  显示 / 隐藏
    // ═══════════════════════════════════════════════════════
    function _dismiss() {
        // 2026-09-28 打磨: 原实现只置 null 不销毁, 每次显示都在 contentItem 上残留隐形 tip
        if (root._tip) { root._tip._doHide(); root._tip.destroy(); root._tip = null }
        if (root._timer) { root._timer.stop(); root._timer.destroy(); root._timer = null }
    }

    function _show() {
        if (!root._target() || root.text === "" || !Window.window) return

        // 延迟调度
        if (root.delay > 0 && !root._tip) {
            if (!root._timer) {
                root._timer = timerHelper.createObject(root)
            }
            root._timer.interval = root.delay
            root._timer.triggered.connect(function() { root._doShow() })
            root._timer.restart()
            return
        }
        root._doShow()
    }

    function _doShow() {
        if (root._tip) return

        root._tip = tipComp.createObject(Window.window.contentItem)
        if (!root._tip) return

        // 自动消失
        if (root.duration > 0) {
            var dt = timerHelper.createObject(root._tip)
            dt.interval = root.duration
            dt.triggered.connect(function() { root.shown = false })
            dt.running = true
        }
    }

    // ── 轻量 Timer 工厂 ──
    Component {
        id: timerHelper
        Timer { running: false; repeat: false }
    }

    // ═══════════════════════════════════════════════════════
    //  状态驱动
    // ═══════════════════════════════════════════════════════
    onShownChanged: {
        if (root.shown) root._show()
        else            root._dismiss()
    }

    onAnchorItemChanged: {
        if (root._tip) root._tip._updatePos()
    }

    Component.onDestruction: root._dismiss()
}
