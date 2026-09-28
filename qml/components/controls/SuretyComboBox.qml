import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../layout"
import "../overlay"

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    // currentText 不绑定 _textAt(): ListModel.get() 的 JS 属性访问不被绑定引擎
    // 追踪, 绑定只依赖 currentIndex → model.clear()+append 后 currentIndex 值不变
    // 就不刷新 → 支付方式获取后下拉框空白。改信号手动刷新 (2026-08-24)。
    property string currentText: ""
    property int fontSize: 12
    property int iconSize: 10
    property bool textCenter: false
    property bool fontBold: false

    readonly property int _rowH: root.fontSize + 18
    readonly property int _panelW: btnRow.width
    // 弹层高度上限: 条目多时封顶到窗口 60%, ListView 内部滚动 (2026-08-15 列表过高超出屏幕不可见)
    readonly property int _popMaxH: Window.window
        ? Math.max(140, Math.floor(Window.window.height * 0.6))
        : 320
    readonly property int _popH: Math.min(_modelCount() * root._rowH + 16, root._popMaxH)

    signal itemSelected(int index, string text)

    // 注意: Component.onCompleted / onModelChanged 只注册一次, 处理器内做两件事
    // (上次修复版在此重复注册同信号 → "属性值设置多次" → 组件编译失败 → App.qml 加载失败)
    Component.onCompleted: { _recalcMaxWidth(); _refreshCurrentText() }
    onFontSizeChanged: _recalcMaxWidth()
    onModelChanged: { _recalcMaxWidth(); _refreshCurrentText() }
    onCurrentIndexChanged: _refreshCurrentText()

    // ListModel.clear()/append() 不改 model 引用 → onModelChanged 不触发;
    // 监听 count (Q_PROPERTY, 可观察) 补上内容变化 (2026-08-24 支付方式获取后空白根因)
    Connections {
        target: root.model instanceof ListModel ? root.model : null
        function onCountChanged() { root._refreshCurrentText() }
    }

    implicitWidth: Layout.preferredWidth > 0 ? Layout.preferredWidth : maxTextWidth
    implicitHeight: Layout.preferredHeight > 0 ? Layout.preferredHeight : root._rowH

    property int maxTextWidth: 56

    Text {
        id: measure
        visible: false
        font.pixelSize: root.fontSize
        font.family: "Microsoft YaHei UI"
    }

    function _recalcMaxWidth() {
        var maxW = 40
        for (var i = 0; i < _modelCount(); i++) {
            measure.text = _textAt(i)
            if (measure.implicitWidth > maxW) maxW = measure.implicitWidth
        }
        maxTextWidth = maxW + 28 + root.iconSize
    }

    function _refreshCurrentText() { root.currentText = root._textAt(root.currentIndex) }

    function _modelCount() {
        if (model instanceof ListModel) return model.count
        if (Array.isArray(model)) return model.length
        return 0
    }

    function _textAt(idx) {
        if (model instanceof ListModel) {
            var el = model.get(idx)
            return el ? el.text : ""
        }
        if (Array.isArray(model))
            return (idx >= 0 && idx < model.length) ? (model[idx].text || "") : ""
        return ""
    }

    function _selY() {
        var y = 8
        for (var i = 0; i < root.currentIndex; i++) y += _rowH
        y += _rowH / 2
        return y
    }

    // ── 按钮 ──
    Rectangle {
        id: btnRow
        anchors.fill: parent
        radius: 6
        color: btnMouse.containsMouse ? Theme.hover_bg : Theme.bg_card
        border { width: 1; color: _open ? Theme.accent : Theme.border_standard }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
            spacing: 6

            Text {
                id: btnText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.currentText
                color: Theme.text_primary
                font.pixelSize: root.fontSize
                font.weight: root.fontBold ? Font.Bold : Font.Normal
                font.family: "Microsoft YaHei UI"
                elide: Text.ElideRight
                horizontalAlignment: root.textCenter ? Text.AlignHCenter : Text.AlignLeft
            }

            Image {
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                Layout.alignment: Qt.AlignVCenter
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/arrow-up.svg"
                fillMode: Image.PreserveAspectFit
                rotation: _open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (_open) {
                    popup.close()
                } else {
                    var pt = btnRow.mapToItem(null, 0, 0)
                    var popH = root._popH
                    var winH = Window.window ? Window.window.height : 9999
                    var idealY = pt.y + btnRow.height / 2 - _selY()
                    if (idealY < 0) popup.y = 0
                    else if (idealY + popH > winH) popup.y = winH - popH
                    else popup.y = idealY
                    popup.x = Math.max(0, Math.min(pt.x, (Window.window ? Window.window.width : 9999) - popup.width))
                    popup.open()
                    _open = true
                }
            }
        }
    }

    // ── 下拉 ──
    Popup {
        id: popup
        parent: Overlay.overlay
        width: root._panelW
        height: root._popH
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: EnterFade {}
        exit: ExitFade {}
        transformOrigin: Item.Top

        background: Rectangle {
            color: Theme.bg_page
            border { width: 1; color: Theme.accent }
            radius: 6
        }

        ListView {
            id: listView
            anchors.fill: parent
            model: root.model
            currentIndex: root.currentIndex
            spacing: 2
            clip: true
            ScrollBar.vertical: SuretyScrollBar { }

            delegate: ItemDelegate {
                width: listView.width
                height: root._rowH

                background: Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: index === root.currentIndex ? Theme.bg_card
                           : (parent.hovered ? Theme.hover_bg : "transparent")
                    radius: 4
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                contentItem: Text {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: Text.AlignVCenter
                    text: model.text
                    color: Theme.text_primary
                    font.pixelSize: root.fontSize
                    font.weight: root.fontBold ? Font.Bold : Font.Normal
                    font.family: "Microsoft YaHei UI"
                }

                onClicked: {
                    root.currentIndex = index
                    root.currentText = root._textAt(index)
                    root.itemSelected(index, model.text)
                    popup.close()
                    _open = false
                }
            }
        }

        onClosed: _open = false
    }

    property bool _open: false
}
