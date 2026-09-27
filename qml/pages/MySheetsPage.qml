import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  MySheetsPage — 我的歌单 (自建歌单 + 收藏歌单两组网格 + 新建)
//  新建歌单弹窗为简易占位 (真实对话框待接 C++ SheetService)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var mySheets: [{ id: "p06", title: "我的歌单", subtitle: "我", count: 23, seed: 5, platform: "本地" }]
    property bool newSheetDialogOpen: false

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 4

            PageHeader {
                width: parent.width
                title: "我的歌单"
                subtitle: "自建 " + root.mySheets.length + " · 收藏 " + MockData.starredSheets.length
                SuretyBtn {
                    height: 30
                    text: "新建歌单"
                    variant: "primary"
                    font.pixelSize: 12
                    iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/plus.svg"
                    onClicked: root.newSheetDialogOpen = true
                }
            }

            Text {
                x: 24
                text: "自建歌单"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            MediaGrid {
                x: 24
                width: parent.width - 48
                height: 2 * (cellWidth + 44) - 12
                cellWidth: 160
                model: root.mySheets
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                             count: it.count, platform: it.platform, mine: true })
                }
            }

            Text {
                x: 24
                text: "收藏的歌单"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            MediaGrid {
                x: 24
                width: parent.width - 48
                height: 2 * (cellWidth + 44) - 12
                cellWidth: 160
                model: MockData.starredSheets
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "sheet", id: it.id, title: it.title, seed: it.seed,
                                             count: it.count, desc: it.desc, platform: it.platform })
                }
            }
        }
    }

    // ── 新建歌单 (简易占位弹窗) ──
    Rectangle {
        visible: root.newSheetDialogOpen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent; onClicked: root.newSheetDialogOpen = false }

        Rectangle {
            anchors.centerIn: parent
            width: 360
            height: 150
            radius: 10
            color: Theme.bg_page
            border { width: 1; color: Theme.border_default }

            Text {
                anchors { top: parent.top; topMargin: 18; left: parent.left; leftMargin: 20 }
                text: "新建歌单"
                font { family: "Microsoft YaHei UI"; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            SuretyTextField {
                id: nameInput
                anchors { top: parent.top; topMargin: 48; left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 20 }
                height: 32
                placeholder: "歌单名称"
                font.pixelSize: 13
            }
            Row {
                anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 16 }
                spacing: 10
                SuretyBtn {
                    height: 28
                    text: "取消"
                    variant: "ghost"
                    font.pixelSize: 12
                    onClicked: { root.newSheetDialogOpen = false; nameInput.text = "" }
                }
                SuretyBtn {
                    height: 28
                    text: "创建"
                    variant: "primary"
                    font.pixelSize: 12
                    onClicked: {
                        var n = nameInput.text.trim()
                        if (n !== "") {
                            root.mySheets = root.mySheets.concat([{ id: "m" + Date.now(), title: n,
                                                                    subtitle: "我", count: 0, seed: 2, platform: "本地" }])
                        }
                        root.newSheetDialogOpen = false
                        nameInput.text = ""
                    }
                }
            }
        }
    }
}
