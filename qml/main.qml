import QtQuick
import QtQuick.Window
import "theme"
import "layouts"
import "dialogs"

// 应用骨架: main.qml 只负责模块布局与跨模块接线 (各模块内容归各模块自己管理):
//   标题栏 / 侧栏(条目自管) / 内容区(页面自管) / (播放条待建) + 顶层弹窗
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
        onSettingsClicked: { /* 设置页就绪后接入 */ }
        onLoginRequested: authDialog.open("login")
    }

    Row {
        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }

        SideBar {
            id: sideBar
            width: 160
            height: parent.height
            onPageSwitchRequested: function(page) { view.currentIndex = page }
            onCreateRequested: { /* 歌单系统就绪后新建歌单 */ }
        }

        // 内容显示区 (页面挂载点)
        View {
            id: view
            width: parent.width - sideBar.width
            height: parent.height
        }
    }

    // 登录/注册/重置 弹窗 (自 Glowling 移植; 纯 UI, 表单动作全部转发为信号, 待 C++ AuthService 接线)
    AuthDialog {
        id: authDialog
    }
}
