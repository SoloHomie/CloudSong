import QtQuick
import QtQuick.Window
import "theme"
import "layouts"
import "dialogs"
import "mock"

// 应用骨架: main.qml 只负责模块布局与跨模块接线 (各模块内容归各模块自己管理):
//   标题栏 / 侧栏(条目自管) / 内容区(View 页面栈) / 播放条 / 队列抽屉 + 顶层弹窗
// 无边框由 C++ DWM 方案实现 (main.cpp applyFrameless, BallsHackPro 同款): NCCALCSIZE 仅恢复 top,
// 标题栏区域并入客户区, 左右下三边保留原生边框; QML 不设 FramelessWindowHint;
// visible:false 由 C++ 应用后统一 show
Window {
    id: win
    visible: false
    width: 960
    height: 640
    // SongTable 固定列宽约 538 + 侧栏 160 + 余量; 再窄列宽会挤成负数
    minimumWidth: 800
    minimumHeight: 500
    title: "CloudSong"
    color: Theme.bg_canvas

    TitleBar {
        id: titleBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        appWindow: win
        navigation: view
        onSettingsClicked: view.push("settings")
        onSearchRequested: function(q) { view.push("search", { query: q }) }
        onLoginRequested: authDialog.open("login")
    }

    Row {
        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: playerBar.top }

        SideBar {
            id: sideBar
            width: 160
            height: parent.height
            onPageSwitchRequested: function(page) { view.switchRoot(page) }
            onCreateRequested: view.switchRoot(4)   // 我的歌单页内建弹窗
        }

        // 内容显示区 (页面栈挂载点)
        View {
            id: view
            width: parent.width - sideBar.width
            height: parent.height
            onAuthRequested: authDialog.open("login")
        }
    }

    // 底部播放条 (状态全部来自注入的 playback; 当前 MockPlayback, 待换 C++ PlaybackService)
    PlayerBar {
        id: playerBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        playback: MockPlayback
        onOpenQueueRequested: queueDrawer.open = !queueDrawer.open
        onShowListenModeRequested: view.push("listen")
    }

    // 播放队列抽屉 (右侧滑入; 遮罩覆盖内容区)
    QueueDrawer {
        id: queueDrawer
        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: playerBar.top }
        playback: MockPlayback
    }

    // 登录/注册/重置 弹窗 (自 Glowling 移植; 纯 UI, 表单动作全部转发为信号, 待 C++ AuthService 接线)
    AuthDialog {
        id: authDialog
    }
}
