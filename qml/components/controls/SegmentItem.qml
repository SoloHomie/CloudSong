import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  SegmentItem — 分段条中的单段 (SuretyTagSelector segment 模式)
//  2026-10-02 自 SuretyTagSelector 内联组件提取
// ═══════════════════════════════════════════════════════════════
Rectangle {
    id: root
    property int   segmentRadius:  6
    property string segmentLabel:  ""
    property bool   segmentSelected: false
    property color  segmentSelColor: Theme.accent
    property color  selectedTextColor: Theme.text_bright
    property color  textColor:    Theme.text_secondary
    property string fontFamily:   Theme.fontFamily
    property int   fontSize:      12

    signal segmentClicked()

    // 宽度由文字内容 + 字宽比例留白决定
    implicitWidth: segText.implicitWidth + fontSize * 3
    implicitHeight: fontSize * 2.4

    radius: segmentRadius
    color: segmentSelected ? segmentSelColor : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.segmentClicked()
    }

    Text {
        id: segText
        anchors.centerIn: parent
        text: segmentLabel
        color: segmentSelected ? selectedTextColor : textColor
        font.pixelSize: fontSize
        font.weight: Font.DemiBold
        font.family: fontFamily
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
