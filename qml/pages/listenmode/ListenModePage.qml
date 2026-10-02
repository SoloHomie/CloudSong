import QtQuick
import "../../theme"
import "../../mock"
import "../../components/display"

// ═══════════════════════════════════════════════════════════════
//  ListenModePage — 听歌模式 (原版 FullscreenPlayer 页面化)
//   氛围背景 + 大封面 + 逐行歌词高亮; 字号/翻译/桌面歌词工具
//   歌词行点击跳进度; 同步依赖 MockPlayback 250ms 步进, 无连续动画
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int lyricFontIdx: 1          // 0/1/2 → 小/中/大
    property bool showTrans: true
    readonly property int lyricFontSize: [14, 18, 24][lyricFontIdx]
    readonly property int curLyric: (MockPlayback.duration > 0 && MockPlayback.playing)
        ? Math.min(MockData.lyrics.length - 1, Math.floor(MockPlayback.position / MockPlayback.duration * MockData.lyrics.length))
        : -1

    function rowH(i) {
        var t = MockData.lyrics[i]
        var base = root.lyricFontSize * 1.7 + 14
        if (root.showTrans && t.tt !== "") base += 26
        return base
    }

    // ── 背景: 画布 + 封面氛围色 ──
    Rectangle { anchors.fill: parent; color: Theme.bg_canvas }
    CoverArt {
        anchors.fill: parent
        seed: MockPlayback.seed
        radius: 0
        opacity: 0.22
    }

    // ── 顶部: 返回 + 曲目信息 (左) / 歌词工具 (右) ──
    Row {
        anchors { top: parent.top; topMargin: 16; left: parent.left; leftMargin: 24 }
        spacing: 12
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: backMouse.containsMouse ? Theme.hover_bg : "transparent"
            IconImage {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-left.svg"
                color: Theme.text_primary
                size: 18
            }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.navigate("$back")
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: MockPlayback.title !== "" ? MockPlayback.title + " · " + MockPlayback.artist : "听歌模式"
            font { family: Theme.fontFamily; pixelSize: 14 }
            color: Theme.text_primary
        }
    }

    Row {
        anchors { top: parent.top; topMargin: 16; right: parent.right; rightMargin: 24 }
        spacing: 8

        // 字号
        ToolChip { text: "A-"; active: false; onClicked: root.lyricFontIdx = Math.max(0, root.lyricFontIdx - 1) }
        ToolChip { text: "A+"; active: false; onClicked: root.lyricFontIdx = Math.min(2, root.lyricFontIdx + 1) }
        // 翻译
        ToolChip { text: "翻译"; active: root.showTrans; onClicked: root.showTrans = !root.showTrans }
        // 桌面歌词
        ToolChip { text: "桌面歌词"; active: MockPlayback.desktopLyric; onClicked: MockPlayback.desktopLyric = !MockPlayback.desktopLyric }
    }

    // ── 主体: 左封面, 右歌词 ──
    Row {
        anchors { top: parent.top; topMargin: 64; left: parent.left; leftMargin: 48; right: parent.right; rightMargin: 48; bottom: parent.bottom; bottomMargin: 20 }
        spacing: 48

        // 封面 + 信息
        Column {
            width: 300
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
            CoverArt {
                width: 280
                height: 280
                anchors.horizontalCenter: parent.horizontalCenter
                seed: MockPlayback.seed
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                spacing: 12
                Column {
                    width: 230
                    spacing: 6
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: MockPlayback.title !== "" ? MockPlayback.title : "未在播放"
                        font { family: Theme.fontFamily; pixelSize: 18; weight: Font.Bold }
                        color: Theme.text_primary
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: MockPlayback.artist !== "" ? MockPlayback.artist + " · " + MockPlayback.album : "从下方播放条选择歌曲"
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        color: Theme.text_secondary
                    }
                }
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 20
                    source: MockPlayback.favorite ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart-fill.svg"
                                                 : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/heart.svg"
                    color: MockPlayback.favorite ? Theme.accent : Theme.text_hint
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MockPlayback.toggleFavorite()
                    }
                }
            }
        }

        // 歌词
        ListView {
            id: lyricList
            width: parent.width - 348
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            model: MockData.lyrics
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                width: lyricList.width
                height: root.rowH(index)
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.t
                        font { family: Theme.fontFamily; pixelSize: root.lyricFontSize; weight: index === root.curLyric ? Font.Bold : Font.Normal }
                        color: index === root.curLyric ? Theme.accent_text : Theme.text_primary
                        opacity: index === root.curLyric ? 1.0 : 0.5
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.showTrans && modelData.tt !== ""
                        text: modelData.tt
                        font { family: Theme.fontFamily; pixelSize: 13 }
                        color: Theme.text_secondary
                        opacity: index === root.curLyric ? 1.0 : 0.45
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (MockPlayback.duration > 0)
                            MockPlayback.seek(MockPlayback.duration * index / MockData.lyrics.length)
                    }
                }
            }
        }
    }

    // 当前歌词行居中 (position 250ms 步进; 用户手动滚动时会被拉回, 待接防抖)
    onCurLyricChanged: {
        if (root.curLyric >= 0)
            lyricList.positionViewAtIndex(root.curLyric, ListView.Center)
    }

    // (工具小圆片 ToolChip 已提取至同目录 ToolChip.qml, 2026-10-02)
}
