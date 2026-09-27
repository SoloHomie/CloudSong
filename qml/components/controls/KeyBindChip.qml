import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════════════════════
//  KeyBindChip — 快捷键绑定芯片
//  点击进入监听态，按下键盘按键完成绑定
//  用法:
//    KeyBindChip { id: myKey; onKeyBound: console.log("bound:", key) }
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // 当前绑定的按键名 (空字符串 = 未绑定)
    property string boundKey: ""
    // 是否正在监听
    readonly property bool listening: _listening

    // 按键被绑定时触发
    signal keyBound(string key)

    property bool _listening: false

    implicitWidth: keyText.implicitWidth + 28
    implicitHeight: 28

    function startListening() {
        root._listening = true
        root.forceActiveFocus()
        if (typeof Input !== "undefined") Input.setListening(true)
    }

    // 存储名 → 显示名 (方向键存 Qt 键名, 显示回箭头; 设备键 GP:/X1/X2 显示中文)
    function nameToDisplay(name) {
        var map = { "Left":"←", "Right":"→", "Up":"↑", "Down":"↓" }
        if (name.startsWith("GP:")) {
            var gmap = { "A":"手柄A","B":"手柄B","X":"手柄X","Y":"手柄Y",
                         "LB":"手柄LB","RB":"手柄RB","BACK":"手柄BACK","START":"手柄START",
                         "L3":"手柄L3","R3":"手柄R3",
                         "UP":"手柄上","DOWN":"手柄下","LEFT":"手柄左","RIGHT":"手柄右",
                         "LT":"手柄LT","RT":"手柄RT" }
            var b = name.slice(3)
            return (b in gmap) ? gmap[b] : name
        }
        if (name === "X1") return "侧键1"
        if (name === "X2") return "侧键2"
        return (name in map) ? map[name] : name
    }

    Keys.onPressed: function(event) {
        if (!root._listening) { event.accepted = false; return }
        var name = Input.keyToString(event.key)   // 键名表在 C++ (InputUtils, 2026-08-26)
        root.boundKey = name
        root._listening = false
        root.focus = false
        if (typeof Input !== "undefined") Input.setListening(false)
        root.keyBound(name)
        event.accepted = true
    }

    // 监听态设备键捕获 (2026-09-02): 手柄/鼠标侧键按下 → C++ tokenCaptured
    Connections {
        target: typeof Input !== "undefined" ? Input : null
        function onTokenCaptured(tok) {
            if (!root._listening) return
            root.boundKey = tok
            root._listening = false
            root.focus = false
            if (typeof Input !== "undefined") Input.setListening(false)
            root.keyBound(tok)
        }
    }

    Rectangle {
        id: chip
        anchors.fill: parent
        radius: 4
        color: root._listening
            ? Qt.rgba(0.96, 0.62, 0.04, 0.2)
            : (chipMA.containsMouse ? Theme.accent : Qt.rgba(0.12, 0.44, 0.92, 0.15))
        border.width: 1
        border.color: root._listening
            ? "#f59e0b"
            : (chipMA.containsMouse ? Theme.accent : Qt.rgba(0.12, 0.44, 0.92, 0.3))

        Behavior on color        { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            id: keyText
            anchors.centerIn: parent
            text: root._listening ? "..." : (root.boundKey !== "" ? root.nameToDisplay(root.boundKey) : "---")
            color: Theme.accent_text
            font.pixelSize: 12
            font.family: "JetBrains Mono"
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: chipMA
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.startListening()
    }
}
