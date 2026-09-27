import QtQuick
import QtQuick.Window
import "theme"
import "layouts"
import "dialogs"
import "pages"

// 应用骨架: 无边框窗口 + 自定义标题栏 + 侧边导航 + 内容区
// 无边框由 C++ DWM 方案实现 (main.cpp applyFrameless): 窗口保留原生样式, 标题栏被挤出可视区,
// 因此 QML 不设 FramelessWindowHint; visible:false 由 C++ 应用 DWM 后统一 show
Window {
    id: win
    visible: false
    width: 960
    height: 640
    title: "CloudSong"
    color: Theme.bg_canvas

    TitleBar {
        id: titleBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        appWindow: win
        onSettingsClicked: { /* 页面系统就绪后切设置页 */ }
        onLoginRequested: authDialog.open("login")
    }

    Row {
        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }

        SideBar {
            id: sideBar
            width: 160
            height: parent.height
            selectedIndex: 0   // 默认选中"推荐"
            model: ListModel {
                ListElement { kind: "item"; page: 0; animated: true; text: "推荐" }   // 声纹动画(SVG无法自带动画, 只能用QML); page=View 中页面下标
                ListElement { kind: "item"; page: 1; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/mode.svg"; text: "听歌模式" }
                ListElement { kind: "header"; headerText: "我的音乐" }
                ListElement { kind: "item"; page: 2; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/fav.svg"; text: "我喜欢的音乐" }
                ListElement { kind: "item"; page: 3; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/recent.svg"; text: "历史播放" }
                ListElement { kind: "header"; headerText: "创建的歌单"; headerBtn: true }   // 小标签, 右侧小＋按钮; 自建歌单动态列在其下
                ListElement { kind: "item"; page: 4; icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/playlist.svg"; text: "我的歌单" }   // 默认歌单条目
                // 服务项(云漫游/歌单迁移/插件)暂不占侧栏, 之后放到不显眼处(如设置页)
                ListElement { kind: "spacer" }   // 弹簧沉底: 选项靠上, 下方留白
            }
            onPageSwitchRequested: function(page) { view.currentIndex = page }   // 选中态 SideBar 自管
            onCreateRequested: { /* 歌单系统就绪后新建歌单 */ }
        }

        // 内容显示区 (页面挂载点: 子项即页面, 由侧栏 pageSwitchRequested 驱动切换)
        View {
            id: view
            width: parent.width - sideBar.width
            height: parent.height

            PlaceholderPage { title: "推荐" }
            PlaceholderPage { title: "听歌模式" }
            PlaceholderPage { title: "我喜欢的音乐" }
            PlaceholderPage { title: "历史播放" }
            PlaceholderPage { title: "我的歌单" }
        }
    }

    // 登录/注册/重置 弹窗 (自 Glowling 移植; 纯 UI, 表单动作全部转发为信号, 待 C++ AuthService 接线)
    AuthDialog {
        id: authDialog
    }
}
