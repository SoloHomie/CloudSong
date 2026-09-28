import QtQuick
import "../../../theme"
import "../../../mock"
import "../../display"

// ──────────────────────────────────────────────────────────────
//  SearchBox — 标题栏搜索框
//  2026-09-29 按桌面《CloudSong搜索框_逻辑规格_20260929.md》§2.2 重写:
//    状态机: 聚焦·空输入 = 历史面板 / 聚焦·输入中 = 建议面板 (本地历史前缀匹配)
//    键盘: ↑↓ 选中行 · Enter 采纳选中或提交原文 · Esc 三级 (收面板→清文字→失焦)
//    commit: trim 前后空白 (含全角空格 U+3000), 空则忽略; 写历史去重置顶 (上限 20)
//    焦点 (2026-09-29 用户定调): 点击输入框=聚焦开面板; 点击其他地方=失焦收面板
//    (SearchPanel 全窗口点击捕获层, propagateComposedEvents 穿透, 不吞下层点击)
//  面板 UI 拆至 SearchPanel (窗口级挂载), 行拆至 SearchRow
// ──────────────────────────────────────────────────────────────
Item {
    id: root
    width: 300
    height: 30
    property alias text: inputField.text
    signal searchRequested(string query)

    property bool panelOpen: false
    property int selected: -1           // 键盘/鼠标选中行 (历史/建议两模式共用)
    readonly property bool inHistory: inputField.text === ""
    readonly property var rowModel: root.inHistory ? MockData.searchHistory
                                                   : MockData.suggestHistory(inputField.text)

    // ── 输入框 ──
    Rectangle {
        id: inputBox
        anchors.fill: parent
        radius: 15
        color: Theme.bg_input
        border { width: 1; color: inputField.activeFocus ? Theme.input_border_focus : Theme.border_default }

        // 输入框点击层 (最底层): 点击即聚焦+开面板。
        // 覆盖"点击别处后再次点击输入框"场景 — QML 点击不转移焦点, 焦点未变时
        // onActiveFocusChanged 不触发, 面板不会自己重开 (2026-09-29)
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: {
                inputField.forceActiveFocus()
                root.panelOpen = true
            }
        }

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
                maximumLength: 64
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.input_text

                onActiveFocusChanged: {
                    if (activeFocus) { blurTimer.stop(); root.panelOpen = true }
                    else blurTimer.restart()
                }
                onTextChanged: {
                    root.selected = -1
                    // Esc 收起面板后继续输入: 面板重新展开 (状态3)
                    if (text !== "" && activeFocus && !root.panelOpen) root.panelOpen = true
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        // Enter: 有选中行则采纳该行, 否则提交原文
                        if (root.selected >= 0 && root.selected < root.rowModel.length)
                            root.commit(root.rowModel[root.selected])
                        else
                            root.commit(text)
                    } else if (event.key === Qt.Key_Up) {
                        if (!root.panelOpen || root.rowModel.length === 0) return
                        root.selected = Math.max(0, root.selected - 1)
                    } else if (event.key === Qt.Key_Down) {
                        if (!root.panelOpen || root.rowModel.length === 0) return
                        root.selected = Math.min(root.rowModel.length - 1, root.selected + 1)
                    } else if (event.key === Qt.Key_Escape) {
                        if (root.panelOpen) root.panelOpen = false        // 第一下: 收面板, 文字保留
                        else if (text !== "") text = ""                    // 第二下: 清空文字 (面板保持收起)
                        else focus = false                                 // 第三下: 失焦
                    }
                }
            }

            // 清空按钮 (有文字即显; 清空后焦点保留 → 面板自动切回历史模式)
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

    // ── 下拉面板 (UI 全在 SearchPanel; 本文件只做状态接线) ──
    SearchPanel {
        id: panel
        width: root.width
        anchorItem: inputBox   // 定位锚必接: 未接时面板 onOpenChanged 直接 return, 面板永不显示 (2026-09-29)
        open: root.panelOpen
        mode: root.inHistory ? "history" : "suggest"
        model: root.rowModel
        selected: root.selected
        onItemActivated: function(q) { root.commit(q) }
        onItemRemoved: function(q) {
            MockData.removeSearchHistory(q)
            if (root.selected >= root.rowModel.length) root.selected = -1
        }
        onClearRequested: {
            MockData.clearSearchHistory()
            root.selected = -1
        }
        // 点击别处 = 失焦 (2026-09-29 用户定调: 点输入框焦点进, 点其他地方焦点出)
        onDismissRequested: {
            root.panelOpen = false
            inputField.focus = false
        }
    }

    // ── 收起延迟 (失焦 150ms; 点击面板行不会误关 — 点击不夺焦点) ──
    Timer {
        id: blurTimer
        interval: 150
        onTriggered: root.panelOpen = false
    }

    function commit(query) {
        // 清洗: 前后空白 + 全角空格一并 (JS trim 不含 U+3000)
        var q = String(query).replace(/^[\s　]+|[\s　]+$/g, "")
        if (q === "") return
        MockData.addSearchHistory(q)
        panelOpen = false
        selected = -1
        inputField.focus = false
        inputField.text = q
        searchRequested(q)
    }
}
