import QtQuick
import QtQuick.Layouts
import "../theme"
import "../pages"

/// 内容显示区: 页面挂载点 (四大板块之一; 页面内容归本模块管理, main.qml 只传 currentIndex)
Rectangle {
    id: view
    color: Theme.bg_canvas

    property int currentIndex: 0

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: view.currentIndex

        // 占位页逐个替换为真实页面
        PlaceholderPage { title: "推荐" }
        PlaceholderPage { title: "听歌模式" }
        PlaceholderPage { title: "我喜欢的音乐" }
        PlaceholderPage { title: "历史播放" }
        PlaceholderPage { title: "我的歌单" }
    }
}
