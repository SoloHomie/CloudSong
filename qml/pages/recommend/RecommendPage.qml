import QtQuick
import "../../theme"
import "../../mock"
import "../../components/display"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  RecommendPage — 推荐页 = 每日推荐"正在播放"页 (2026-10-02 用户拍板)
//  与听歌模式同款听歌页: 氛围背景 + 大封面 + 曲目信息 + 逐行歌词;
//  打开即播 C++ RecommendService 算出的每日推荐队列 (loadQueue+playIndex(0));
//  背景三模式 (常规/3D粒子/汽水渐变) 由标题栏选择器切换 (AppCfg.recommendBackdropIndex);
//  原 TabBar 模块化首页 (为你推荐/排行榜) 整体移除
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    // ── 每日推荐队列 (C++ 算法) ──
    property var recDaily: Recommend.recommendDaily(MockData.songs, 15)
    property var songs: recDaily.songs
    property string dateText: (new Date().getMonth() + 1) + "月" + new Date().getDate() + "日"
    property int backdropMode: AppCfg.recommendBackdropIndex   // 0=常规 1=3D粒子 2=汽水

    // ── 歌词工具 (听歌模式同款) ──
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

    // 打开即播: 加载每日推荐队列并从第一首开始 (用户拍板"直接播放")
    Component.onCompleted: {
        MockPlayback.loadQueue(root.songs)
        MockPlayback.playIndex(0)
    }

    // ── 背景: 画布 + 当前曲目封面氛围色 ──
    Rectangle { anchors.fill: parent; color: Theme.bg_canvas }
    CoverArt {
        anchors.fill: parent
        seed: MockPlayback.seed
        radius: 0
        opacity: 0.22
    }
    // 背景模式层 (常规=无附加层; 标题栏切换)
    SodaBackdrop {
        anchors.fill: parent
        visible: root.backdropMode === 2
        songs: root.songs
    }
    ParticleBackdrop {
        anchors.fill: parent
        visible: root.backdropMode === 1
    }

    // ── 顶部: 每日推荐徽标 + 曲目信息 (左) / 歌词工具 (右) ──
    Row {
        anchors { top: parent.top; topMargin: 16; left: parent.left; leftMargin: 24 }
        spacing: 12
        Rectangle {
            height: 30; radius: 15
            width: badgeTxt.implicitWidth + 24
            color: Theme.tag_preset_bg
            Text {
                id: badgeTxt
                anchors.centerIn: parent
                text: "每日推荐 · " + root.dateText
                font { family: Theme.fontFamily; pixelSize: 12; weight: Font.Bold }
                color: Theme.tag_preset_fg
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: MockPlayback.title !== "" ? MockPlayback.title + " · " + MockPlayback.artist : "为你生成每日歌单"
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
                        text: MockPlayback.artist !== "" ? MockPlayback.artist + " · " + MockPlayback.album : "正在为你生成今日歌单"
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
