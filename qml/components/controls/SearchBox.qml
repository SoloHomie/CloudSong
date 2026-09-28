import QtQuick
import "../../theme"
import "../../mock"
import "../display"

// ──────────────────────────────────────────────────────────────
//  SearchBox — 标题栏搜索框 (聚焦展开历史面板, 150ms 延迟收起)
//  历史数据来自 MockData (待接 C++ SearchHistoryService)
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    width: 300
    height: 30
    property alias text: inputField.text
    signal searchRequested(string query)

    property bool panelOpen: false

    // ── 输入框 ──
    Rectangle {
        id: inputBox
        anchors.fill: parent
        radius: 15
        color: Theme.bg_input
        border { width: 1; color: inputField.activeFocus ? Theme.input_border_focus : Theme.border_default }

        Row {
            anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
            spacing: 8

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/search.svg"
                color: Theme.text_hint
                size: 14
            }

            TextInput {
                id: inputField
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 14 - 8 - (clearBtn.visible ? 22 : 0) - 4
                clip: true
                selectByMouse: true
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.input_text

                onActiveFocusChanged: {
                    if (activeFocus) { blurTimer.stop(); panelOpen = true }
                    else blurTimer.restart()
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                        root.commit(text)
                    else if (event.key === Qt.Key_Escape) {
                        panelOpen = false
                        focus = false
                    }
                }
            }

            // 清空按钮
            Item {
                id: clearBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                visible: inputField.text !== ""
                IconImage {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/x.svg"
                    color: Theme.text_hint
                    size: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        inputField.text = ""
                        inputField.focus = true
                    }
                }
            }
        }

        // 占位提示 (TextInput placeholder 系列 API 在 Qt 6.11 已移除, 自绘覆盖层;
        // inputField 在 Row 内非本层兄弟, 须锚 inputBox 并按行内偏移定位)
        Text {
            visible: inputField.text === "" && !inputField.activeFocus
            anchors { left: parent.left; leftMargin: 34; verticalCenter: parent.verticalCenter }
            text: "搜索音乐 / 专辑 / 歌手 / 歌单"
            font { family: Theme.fontFamily; pixelSize: 12 }
            color: Theme.input_placeholder
        }
        MouseArea {
            visible: inputField.text === "" && !inputField.activeFocus
            anchors { left: parent.left; leftMargin: 34; verticalCenter: parent.verticalCenter }
            width: 210
            height: 20
            cursorShape: Qt.IBeamCursor
            onClicked: inputField.forceActiveFocus()
        }
    }

    // ── 历史面板 ──
    Rectangle {
        id: panel
        visible: false
        opacity: 0
        scale: 0.96
        transformOrigin: Item.Top
        anchors { top: inputBox.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
        width: root.width
        height: panelCol.implicitHeight + 24
        radius: 10
        color: Theme.bg_card
        border { width: 1; color: Theme.border_standard }

        // 出现/关闭过渡 (2026-09-28): 原 visible 绑定致关闭瞬间消失, 改 imperative 动画
        Connections {
            target: root
            function onPanelOpenChanged() {
                if (root.panelOpen) {
                    panelHide.stop()
                    panel.visible = true
                    panel.opacity = 0
                    panel.scale = 0.96
                    panelShow.start()
                } else {
                    panelShow.stop()
                    panelHide.start()
                }
            }
        }
        ParallelAnimation {
            id: panelShow
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutBack }
        }
        SequentialAnimation {
            id: panelHide
            ParallelAnimation {
                NumberAnimation { target: panel; property: "opacity"; from: 1; to: 0; duration: 100; easing.type: Easing.InCubic }
                NumberAnimation { target: panel; property: "scale"; from: 1; to: 0.98; duration: 110; easing.type: Easing.InCubic }
            }
            ScriptAction { script: panel.visible = false }
        }

        Column {
            id: panelCol
            anchors { fill: parent; margins: 12 }
            spacing: 10

            Item {
                width: parent.width
                height: 16
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "搜索历史"
                    font { family: Theme.fontFamily; pixelSize: 12; weight: Font.Bold }
                    color: Theme.text_secondary
                }
                Text {
                    visible: MockData.searchHistory.length > 0
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "清空历史"
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    color: Theme.accent_text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MockData.clearSearchHistory()
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: 8
                visible: MockData.searchHistory.length > 0
                Repeater {
                    model: MockData.searchHistory
                    delegate: Rectangle {
                        width: chipText.implicitWidth + 20
                        height: 26
                        radius: 13
                        color: Theme.bg_input
                        border { width: 1; color: Theme.border_default }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            font { family: Theme.fontFamily; pixelSize: 12 }
                            color: Theme.text_primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.commit(modelData)
                        }
                    }
                }
            }

            Text {
                visible: MockData.searchHistory.length === 0
                text: "暂无搜索历史"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_hint
            }
        }
    }

    // ── 收起延迟 (点击历史条目时不会被误关) ──
    Timer {
        id: blurTimer
        interval: 150
        onTriggered: root.panelOpen = false
    }

    function commit(query) {
        var q = String(query).trim()
        if (q === "") return
        MockData.addSearchHistory(q)
        panelOpen = false
        inputField.focus = false
        inputField.text = q
        searchRequested(q)
    }
}
