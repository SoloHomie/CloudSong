import QtQuick
import "../../theme"
import "../../mock"
import "../../components/business"

// ═══════════════════════════════════════════════════════════════
//  RecommendPage — 推荐页 = 每日推荐"正在播放"页 (2026-10-02 用户拍板)
//  与听歌模式同款听歌页: 氛围背景 + 大封面 + 曲目信息 + 逐行歌词;
//  打开即播 C++ RecommendService 算出的每日推荐队列 (loadQueue+playIndex(0));
//  背景: 画布色 + 当前曲目封面氛围色 (粒子/汽水渐变两模式已移除);
//  听歌区共用 components/business/LyricPlayer (字号/翻译工具操作 lyric.*);
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

    // 打开即播: 加载每日推荐队列并从第一首开始 (用户拍板"直接播放")
    Component.onCompleted: {
        MockPlayback.loadQueue(root.songs)
        MockPlayback.playIndex(0)
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

    // ── 听歌区 (与听歌模式同款, 见 LyricPlayer) ──
    LyricPlayer {
        id: lyric
        anchors.fill: parent
        subtitleHint: "正在为你生成今日歌单"
    }
}
