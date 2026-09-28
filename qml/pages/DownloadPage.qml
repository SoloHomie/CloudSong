import QtQuick
import "../theme"
import "../mock"
import "../components/display"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  DownloadPage — 下载管理 (进行中/已完成 两 tab + 进度条)
//  真实下载任务待接 C++ DownloadManager; 本页纯展示 MockData.downloads
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int activeTab: 0
    property var activeTasks: MockData.downloads.filter(function(d) {
        return root.activeTab === 0 ? d.status !== "done" : d.status === "done"
    })

    PageHeader {
        id: header
        title: "下载管理"
        subtitle: "本地下载与播放历史均不上传"
    }

    TabBar {
        id: tabs
        anchors { top: header.bottom; left: parent.left; leftMargin: 24 }
        items: [{ text: "进行中" }, { text: "已完成" }]
        onActivated: function(i) { root.activeTab = i }
    }

    // ── 空态 ──
    StatusPlaceholder {
        anchors { top: tabs.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root.activeTasks.length === 0
        status: "empty"
        title: root.activeTab === 0 ? "没有进行中的下载" : "还没有完成的下载"
        message: root.activeTab === 0 ? "在歌曲列表 hover 行尾点击下载图标即可开始" : "下载完成的歌曲会出现在这里"
    }

    // ── 任务列表 ──
    ListView {
        anchors { top: tabs.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
        model: root.activeTasks
        clip: true
        visible: root.activeTasks.length > 0
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            width: ListView.view.width
            height: 56
            property var t: modelData
            property bool hover: rowMouse.containsMouse

            Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }

            IconImage {
                anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                size: 16
                source: t.status === "done" ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/music.svg"
                                            : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/download.svg"
                color: t.status === "error" ? Theme.danger : Theme.text_secondary
            }

            Column {
                anchors { left: parent.left; leftMargin: 56; right: parent.right; rightMargin: 100; verticalCenter: parent.verticalCenter }
                spacing: 5
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: t.name
                    font { family: Theme.fontFamily; pixelSize: 13 }
                    color: Theme.text_primary
                }
                // 进行中: 进度条; 已完成: 大小/路径; 暂停/失败: 状态说明
                Rectangle {
                    visible: t.status === "downloading"
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.border_default
                    Rectangle {
                        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                        width: parent.width * t.progress / 100
                        radius: 2
                        color: Theme.accent
                    }
                }
                Text {
                    visible: t.status !== "downloading"
                    text: t.status === "done" ? t.size + " · 已下载到本地目录"
                         : t.status === "paused" ? t.size + " · 已暂停"
                         : t.status === "error" ? t.size + " · 下载失败, 点击重试" : ""
                    font { family: Theme.fontFamily; pixelSize: 11 }
                    color: t.status === "error" ? Theme.danger : Theme.text_secondary
                }
            }

            // 状态/操作
            Text {
                anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                text: t.status === "downloading" ? t.progress + "%"
                    : t.status === "done" ? "打开文件夹" : "重试"
                font { family: Theme.fontFamily; pixelSize: 12 }
                color: t.status === "done" ? Theme.text_secondary : Theme.accent_text
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
