import QtQuick
import "../../theme"
import "../../mock"
import "../display"

// ──────────────────────────────────────────────────────────
//  LyricPlayer — 听歌区: 左封面+曲目信息, 右逐行歌词
//  推荐页 / 听歌模式共用; 字号/翻译工具由页面 ToolChip 操作本组件属性
//  歌词行点击跳进度; 同步依赖 MockPlayback 250ms 步进, 无连续动画
// ──────────────────────────────────────────────────────────
Item {
    id: root

    property int lyricFontIdx: 1          // 0/1/2 → 小/中/大
    property bool showTrans: true
    property string subtitleHint: ""      // 曲目为空时的副标题提示 (页面定制)

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
                        text: MockPlayback.artist !== "" ? MockPlayback.artist + " · " + MockPlayback.album : root.subtitleHint
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
}
