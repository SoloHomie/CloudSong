import QtQuick
import "../../theme"
import "../../components/display"

// ═══════════════════════════════════════════════════════════════
//  SettingRow — 设置行 (设置子页面共用, 2026-10-02 自 SettingsPage 内联组件提取)
//
//  2026-09-28 用户拍板: 行本体不接任何鼠标事件, 只有行内组件可交互。
//  2026-09-29 增补: clickable 导航行(云漫游/迁移/主题/插件等)行体全行可点+悬停反馈,
//  点击层声明在最底层, 不抢行内组件; 含交互控件(开关/下拉)的行 clickable=false,
//  点击层不激活, 铁律照旧。
// ═══════════════════════════════════════════════════════════════
Item {
    id: rs
    width: parent.width
    height: 52
    property string title: ""
    property string subtitle: ""
    property int ctrlReserve: 170   // 右侧控件保留宽度 (音质等横向分段选择需更大)
    property bool clickable: false
    signal clicked()
    default property alias ctrl: ctrlRow.data

    // 全行点击层 (最底层; 仅 clickable 行激活, 含交互控件的行不可见不拦截)
    Rectangle {
        visible: rs.clickable
        anchors.fill: parent
        radius: 8
        color: rowMouse.containsMouse ? Theme.hover_bg : "transparent"
    }
    MouseArea {
        id: rowMouse
        visible: rs.clickable
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rs.clicked()
    }

    Column {
        anchors { left: rs.left; leftMargin: 14; right: rs.right; rightMargin: rs.ctrlReserve; verticalCenter: rs.verticalCenter }
        spacing: 2
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: rs.title
            font { family: Theme.fontFamily; pixelSize: 14 }
            color: Theme.text_primary
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: rs.subtitle !== ""
            text: rs.subtitle
            font { family: Theme.fontFamily; pixelSize: 12 }
            color: Theme.text_secondary
        }
    }
    Row {
        id: ctrlRow
        // clickable 时给箭头让出右侧位置
        anchors { right: rs.right; rightMargin: rs.clickable ? 38 : 14; verticalCenter: rs.verticalCenter }
        spacing: 8
    }
    // 进入箭头 (视觉提示; 行体同样可点, 两者都发 clicked)
    IconImage {
        visible: rs.clickable
        anchors { right: rs.right; rightMargin: 14; verticalCenter: rs.verticalCenter }
        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
        color: Theme.text_hint
        size: 14
        MouseArea {
            z: 1
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: rs.clicked()
        }
    }
}
