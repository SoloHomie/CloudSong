import QtQuick
import "../../theme"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  RoamSwitchRow — 漫游开关行 (标题+副标题 + 右侧开关)
//  2026-10-02 自 RoamPanel 内联组件提取
// ═══════════════════════════════════════════════════════════════
Item {
    id: rsr
    width: parent.width
    height: 48
    property string title: ""
    property string desc: ""
    property bool checked: false
    signal toggled(bool v)

    Column {
        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
        spacing: 3
        Text {
            text: rsr.title
            font { family: Theme.fontFamily; pixelSize: 13 }
            color: Theme.text_primary
        }
        Text {
            text: rsr.desc
            font { family: Theme.fontFamily; pixelSize: 11 }
            color: Theme.text_hint
        }
    }
    SuretySwitch {
        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
        checked: rsr.checked
        onToggled: function(v) { rsr.checked = v; rsr.toggled(v) }
    }
}
