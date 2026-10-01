import QtQuick
import "../theme"
import "../mock"
import "../dialogs"
import "../components/display"
import "../components/business"
import "../components/buttons"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════
//  SheetDetailPage — 歌单/榜单详情 (params.kind = sheet | toplist | daily)
//   头部: 封面 + 信息 + 播放全部/收藏/更多; 主体: 歌曲表
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property string kind: params.kind !== undefined ? params.kind : "sheet"
    property string sheetId: params.id !== undefined ? params.id : ""
    // 自建歌单标题从 MockData 实时取 (重命名后页头即时刷新); 其余用 params
    property string title: {
        for (var i = 0; i < MockData.createdSheets.length; i++)
            if (MockData.createdSheets[i].id === root.sheetId) return MockData.createdSheets[i].title
        return params.title !== undefined ? params.title : "歌单"
    }
    property int seed: params.seed !== undefined ? params.seed : 0
    property int count: params.count !== undefined ? params.count : 8
    property string desc: params.desc !== undefined ? params.desc : ""
    property string platform: params.platform !== undefined ? params.platform : ""
    property bool mine: params.mine === true
    property bool ownSheet: {
        for (var i = 0; i < MockData.createdSheets.length; i++)
            if (MockData.createdSheets[i].id === root.sheetId) return true
        return false
    }
    property bool starred: false
    // kind "daily" = 每日推荐 (推荐页个性化): 歌单直接由口味生成, 不走 seed 切段
    property var songs: root.kind === "daily" ? MockData.dailyMix() : MockData.songsForSheet(root.seed, root.count)

    // ── 头部 ──
    Row {
        id: headRow
        anchors { top: parent.top; topMargin: 20; left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24 }
        height: 160
        spacing: 20

        CoverArt {
            width: 160
            height: 160
            seed: root.seed
        }

        Column {
            width: parent.width - 180
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: typeText.implicitWidth + 12
                    radius: 9
                    color: Theme.tag_preset_bg
                    Text {
                        id: typeText
                        anchors.centerIn: parent
                        text: root.kind === "toplist" ? "榜单" : (root.kind === "daily" ? "每日推荐" : (root.ownSheet ? "自建歌单" : "歌单"))
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.platform !== ""
                    height: 18
                    width: pfText.implicitWidth + 12
                    radius: 9
                    color: Theme.tag_preset_bg
                    Text {
                        id: pfText
                        anchors.centerIn: parent
                        text: root.platform
                        font { family: Theme.fontFamily; pixelSize: 10 }
                        color: Theme.tag_preset_fg
                    }
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.title
                font { family: Theme.fontFamily; pixelSize: 22; weight: Font.Bold }
                color: Theme.text_primary
            }
            Text {
                width: parent.width
                text: "共 " + root.songs.length + " 首" + (root.desc !== "" ? " · " + root.desc : "")
                elide: Text.ElideRight
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: Theme.text_secondary
            }

            Row {
                spacing: 10
                SuretyBtn {
                    height: 32
                    variant: "primary"
                    font.pixelSize: 12
                    iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                    text: "播放全部"
                    enabled: root.songs.length > 0   // 空歌单无内容可播
                    onClicked: MockPlayback.loadQueue(root.songs)
                }
                SuretyBtn {
                    visible: !root.ownSheet   // 自建歌单不显示收藏自己
                    height: 32
                    variant: root.starred ? "default" : "outline"
                    font.pixelSize: 12
                    iconSource: root.starred ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                                             : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
                    text: root.starred ? "已收藏" : "收藏"
                    onClicked: root.starred = !root.starred
                }
                // 更多 (自建歌单=重命名/删除; 其它=下载全部/分享占位)
                Item {
                    id: moreWrap
                    width: moreBtn.width
                    height: moreBtn.height
                    SuretyBtn {
                        id: moreBtn
                        height: 32
                        variant: "outline"
                        font.pixelSize: 12
                        iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/more.svg"
                        text: "更多"
                        onClicked: morePop.open = !morePop.open
                    }
                    Popover {
                        id: morePop
                        panelWidth: 140
                        placement: "below"
                        anchors { top: parent.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                        PopoverOption { text: "下载全部"; visible: !root.ownSheet; onSelected: morePop.open = false }
                        PopoverOption { text: "重命名"; visible: root.ownSheet; onSelected: { morePop.open = false; renameSheetDialog.open() } }
                        PopoverOption { text: "删除歌单"; visible: root.ownSheet; onSelected: { morePop.open = false; deleteSheetDialog.open() } }
                        PopoverOption { text: "分享"; visible: !root.ownSheet; onSelected: morePop.open = false }
                    }
                }
            }
        }
    }

    // ── 歌曲表 ──
    SongToolbar {
        anchors { top: headRow.bottom; topMargin: 8; left: parent.left; right: parent.right }
        searchPlaceholder: "搜索歌单内歌曲"
        disabled: root.songs.length === 0   // 空歌单停用工具栏播放
        onPlayAllRequested: MockPlayback.loadQueue(root.songs)
    }
    SongTable {
        anchors { top: headRow.bottom; topMargin: 48; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.songs
        emptyTitle: "歌单是空的"
        emptyMessage: "从搜索或其它歌单添加歌曲"
        emptyActionText: root.ownSheet ? "去搜索找歌" : ""
        onEmptyActionRequested: root.navigate("search")
        onPlayRequested: function(s, i) {
            MockPlayback.loadQueue(root.songs)
            MockPlayback.playIndex(i)
        }
    }

    // ── 自建歌单 重命名/删除 弹窗 (更多菜单) ──
    CreateSheetDialog {
        id: renameSheetDialog
        sheetId: root.sheetId
        initialName: root.title
    }
    DeleteSheetDialog {
        id: deleteSheetDialog
        sheetId: root.sheetId
        sheetTitle: root.title
    }
}
