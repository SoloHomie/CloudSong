import QtQuick
import "../theme"
import "../mock"
import "../dialogs"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/controls"

// ═══════════════════════════════════════════════════════════════
//  MySheetsPage — 我的歌单 (自建歌单 + 收藏歌单两组网格 + 新建)
//  新建歌单 = 共享 CreateSheetDialog (与侧栏＋同源, 数据 MockData.createdSheets)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property var mySheets: MockData.createdSheets   // 默认"我的歌单"也在此列, 与新建歌单同一套模板

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
                    onClicked: newSheetDialog.open()
                }
            }

            Text {
                x: 24
                text: "自建歌单"
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
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
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
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

    // ── 新建歌单 (共享组件; 创建后本页网格与侧栏经 MockData 联动) ──
    CreateSheetDialog {
        id: newSheetDialog
    }
}
