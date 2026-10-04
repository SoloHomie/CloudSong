import QtQuick
import "../buttons"
import "../controls"

// ──────────────────────────────────────────────────────────────
//  SongToolbar — 歌曲列表工具栏 (原版 MusicFree SongToolbar 同构)
//  左: 播放全部 + 操作按钮插槽; 右: 列表内搜索框
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    height: 40
    property string searchPlaceholder: ""
    property string searchText: ""
    property bool disabled: false
    signal playAllRequested()
    signal searchChanged(string text)
    default property alias content: leftRow.data

    Row {
        id: leftRow
        anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 10

        SuretyBtn {
            height: 32
            variant: "primary"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
            text: "播放全部"
            enabled: !root.disabled
            onClicked: root.playAllRequested()
        }
    }

    SuretyTextField {
        visible: root.searchPlaceholder !== ""
        anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
        width: 200
        height: 32
        font.pixelSize: 12
        placeholder: root.searchPlaceholder
        text: root.searchText
        contentLeftPadding: 10
        contentRightPadding: 10
        onTextChanged: root.searchChanged(text)
    }
}
