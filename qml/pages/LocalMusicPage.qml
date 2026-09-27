import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/business"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  LocalMusicPage — 本地音乐 (4 tab: 全部/歌手/专辑/文件夹)
//   文件夹 tab = 树形目录: 展平为带深度的行数组后单层渲染
//   (QML 组件不允许递归自引用, 故不做递归 delegate; 扫描待接 C++ LocalService)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int activeTab: 0
    property var localSongs: MockData.songs.slice(0, 6)
    property var flatFolders: []

    // 树展平: [{name, depth, hasKids, expanded, node}], 展开态回写 MockData 树节点
    function rebuildTree() {
        var out = []
        function walk(node, depth) {
            var hasKids = node.children !== undefined && node.children.length > 0
            out.push({ name: node.name, depth: depth, hasKids: hasKids,
                       expanded: node.expanded === true, node: node })
            if (node.expanded === true && hasKids) {
                for (var i = 0; i < node.children.length; i++)
                    walk(node.children[i], depth + 1)
            }
        }
        for (var i = 0; i < MockData.folders.length; i++)
            walk(MockData.folders[i], 0)
        root.flatFolders = out
    }
    Component.onCompleted: root.rebuildTree()

    PageHeader {
        id: header
        title: "本地音乐"
        subtitle: "共 " + root.localSongs.length + " 首 · 本地播放不走网络"
        SuretyBtn {
            height: 28
            text: "扫描本地"
            variant: "outline"
            font.pixelSize: 12
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/folder.svg"
        }
    }

    TabBar {
        id: tabs
        anchors { top: header.bottom; left: parent.left; leftMargin: 24 }
        items: [{ text: "全部" }, { text: "歌手" }, { text: "专辑" }, { text: "文件夹" }]
        onActivated: function(i) { root.activeTab = i }
    }

    // ══ Tab 0-2: 歌曲 / 歌手 / 专辑 (歌手与专辑为占位分组, 数据待接) ══
    Column {
        anchors { top: tabs.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.activeTab <= 2

        SongToolbar {
            width: parent.width
            onPlayAllRequested: MockPlayback.loadQueue(root.localSongs)
        }
        SongTable {
            width: parent.width
            height: parent.height - 40
            model: root.activeTab === 0 ? root.localSongs : []
            emptyTitle: root.activeTab === 0 ? "未扫描到本地歌曲" : "分组视图待数据服务接入"
            emptyMessage: root.activeTab === 0 ? "点击右上角「扫描本地」选择音乐文件夹" : ""
            emptyActionText: root.activeTab === 0 ? "去下载页看看" : ""
            onEmptyActionRequested: root.navigate("downloads")
            onPlayRequested: function(s, i) {
                MockPlayback.loadQueue(root.localSongs)
                MockPlayback.playIndex(i)
            }
        }
    }

    // ══ Tab 3: 文件夹树 (扁平化渲染) ══
    Flickable {
        anchors { top: tabs.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentWidth: width
        contentHeight: folderCol.height + 20
        clip: true
        visible: root.activeTab === 3
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: folderCol
            x: 24
            width: parent.width - 48
            spacing: 2

            Repeater {
                model: root.flatFolders
                delegate: Item {
                    width: folderCol.width
                    height: 36
                    property var node: modelData
                    property bool hover: rowMouse.containsMouse

                    Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }
                    IconImage {
                        visible: modelData.hasKids
                        anchors { left: parent.left; leftMargin: 6 + modelData.depth * 18; verticalCenter: parent.verticalCenter }
                        size: 12
                        source: modelData.expanded ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-down.svg"
                                                   : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
                        color: Theme.text_hint
                    }
                    IconImage {
                        anchors { left: parent.left; leftMargin: 26 + modelData.depth * 18; verticalCenter: parent.verticalCenter }
                        size: 14
                        source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/folder.svg"
                        color: Theme.accent
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 48 + modelData.depth * 18; verticalCenter: parent.verticalCenter }
                        text: modelData.name
                        font { family: "Microsoft YaHei UI"; pixelSize: 13 }
                        color: Theme.text_primary
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.hasKids) {
                                modelData.node.expanded = !modelData.node.expanded
                                root.rebuildTree()
                            }
                        }
                    }
                }
            }
        }
    }
}
