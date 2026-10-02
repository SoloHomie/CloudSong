import QtQuick
import "../../theme"
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════════
//  SuretyTagSelector — 单选标签 / 分段选择器
//
//  displayMode:
//    "tag"     — 独立圆角标签（Flow 流式布局）
//    "segment" — 统一分段条（登录/注册 同款）
//
//  用法 — tag 模式:
//    SuretyTagSelector {
//        model: ListModel {
//            ListElement { label: "知识包"; code: "#34D399" }
//            ListElement { label: "脚本";   code: "#34D399" }
//        }
//    }
//
//  用法 — segment 模式:
//    SuretyTagSelector {
//        displayMode: "segment"
//        model: [ { label: "登录" }, { label: "注册" } ]
//    }
// ═══════════════════════════════════════════════════════════════════════════════
Item {
    id: root

    // ═══════════════════════════════════════════════════════════════
    //  公开属性
    // ═══════════════════════════════════════════════════════════════

    // ── 模式 ──
    property string displayMode: "tag"       // "tag" | "segment"

    // ── 数据 ──
    property var   model: [
        { label: "选项A", code: Theme.accent },
        { label: "选项B", code: Theme.success },
        { label: "选项C", code: Theme.warning_fg }
    ]
    property int   selectedIndex: 0

    // ── 通用外观 ──
    property color selectedTextColor:  Theme.text_bright
    property color textColor:          Theme.text_secondary
    property string fontFamily:       Theme.fontFamily
    property int   fontSize:           12
    property bool  enabled:            true
    property int   minimumWidth:       160    // 组件最小宽度，外部可覆盖

    // ── tag 模式外观 ──
    property var   selectedColor:      undefined   // undefined → 使用 model.code
    property color borderColor:        Theme.border_standard
    property color hoverOverlayColor:  Theme.text_bright
    property real  hoverOverlayOpacity: 0.05
    property real  glowOpacity:        0.35
    property int   tagHeight:          28
    property int   tagRadius:          6
    property int   tagMinWidth:        56
    property int   tagSpacing:         8

    // ── segment 模式外观 ──
    property int   segmentHeight:      32
    property int   segmentPadding:     4
    property int   segmentSpacing:     3
    property int   segmentRadius:      6
    property color segmentBg:          Theme.bg_card
    property color segmentBorderColor: Theme.border_standard
    property color segmentSelColor:    Theme.accent

    // ── Layout 尺寸汇报 ──
    Layout.minimumWidth:  root.minimumWidth
    Layout.preferredWidth:  displayMode === "segment"
        ? segmentBar.implicitWidth
        : Math.max(root.minimumWidth, _tagFlow.childrenRect.width)
    Layout.preferredHeight: displayMode === "segment" ? segmentHeight  : Math.max(tagHeight, _tagFlow.childrenRect.height)

    // ── 非 Layout 场景自带尺寸 (2026-09-28 设置页音质行: 组件放进 Row/锚点直接用,
    //    原 Item 根宽高为 0 会溢出; segment 模式取分段条实际尺寸, tag 模式维持原依赖 Layout 拉伸) ──
    width:  displayMode === "segment" ? segmentBar.width : 0
    height: displayMode === "segment" ? segmentHeight : 0

    // ── 信号 ──
    signal tagSelected(int index)

    // ═══════════════════════════════════════════════════════════════
    //  segment 模式 — 统一分段条
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: segmentBar
        visible: root.displayMode === "segment"
        width: segmentRow.implicitWidth + root.segmentPadding * 2
        height: root.segmentHeight
        radius: root.segmentRadius
        color: root.segmentBg
        border.width: 1
        border.color: root.segmentBorderColor

        RowLayout {
            id: segmentRow
            anchors.fill: parent
            anchors.margins: root.segmentPadding
            spacing: root.segmentSpacing

            Repeater {
                model: root.displayMode === "segment" ? root.model : []

                delegate: SegmentItem {
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth
                    segmentRadius: root.segmentRadius - 2
                    segmentLabel: root._getLabel(modelData, model)
                    segmentSelected: root.selectedIndex === index
                    enabled: root.enabled
                    segmentSelColor: root.segmentSelColor
                    selectedTextColor: root.selectedTextColor
                    textColor: root.textColor
                    fontFamily: root.fontFamily
                    fontSize: root.fontSize

                    onSegmentClicked: {
                        root.selectedIndex = index
                        root.tagSelected(index)
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  tag 模式 — 独立圆角标签
    // ═══════════════════════════════════════════════════════════════
    Flow {
        id: _tagFlow
        visible: root.displayMode !== "segment"
        width: parent.width
        spacing: root.tagSpacing

        Repeater {
            model: root.displayMode !== "segment" ? root.model : []

            delegate: Rectangle {
                id: tagBtn
                width:  Math.max(tagLabel.implicitWidth + root.fontSize * 2.67, root.fontSize * 3.5)
                height: root.tagHeight
                radius: root.tagRadius

                readonly property bool  _sel:  root.selectedIndex === index
                readonly property string _label: _getLabel(modelData, model)
                readonly property string _code:  _getCode(modelData, model)
                readonly property color _selBg: root.selectedColor !== undefined ? root.selectedColor : _code

                color: _sel ? _selBg : "transparent"
                border.width: _sel ? 2 : 1
                border.color: _sel ? _selBg : root.borderColor

                Behavior on color       { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // glow 光环
                Rectangle {
                    anchors.fill: parent; anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    border.width: 2; border.color: _selBg
                    opacity: _sel ? root.glowOpacity : 0.0
                    visible: opacity > 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // 文字
                Text {
                    id: tagLabel
                    anchors.centerIn: parent
                    text: _label
                    color: _sel ? root.selectedTextColor : root.textColor
                    font.pixelSize: root.fontSize
                    font.weight: _sel ? Font.Bold : Font.Normal
                    font.family: root.fontFamily
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // hover 覆层
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: root.hoverOverlayColor
                    opacity: !_sel && tagMouse.containsMouse && root.enabled
                        ? root.hoverOverlayOpacity : 0.0
                    visible: opacity > 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // 交互
                MouseArea {
                    id: tagMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.enabled
                    onClicked: {
                        root.selectedIndex = index
                        root.tagSelected(index)
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  工具函数 — 兼容 ListModel 和 JS 数组
    // ═══════════════════════════════════════════════════════════════
    function _getLabel(md, m) {
        if (md && md.label !== undefined) return md.label
        if (m  && m.label  !== undefined) return m.label
        return ""
    }
    function _getCode(md, m) {
        if (md && md.code !== undefined) return md.code
        if (m  && m.code  !== undefined) return m.code
        return Theme.accent
    }

    // ═══════════════════════════════════════════════════════════════
    // (分段条单段 SegmentItem 已提取至同目录 SegmentItem.qml, 2026-10-02)
}
