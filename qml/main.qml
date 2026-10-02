import QtQuick
import QtQuick.Window
import "theme"
import "shell"
import "dialogs"
import "mock"
import "components/controls"

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
    color: "transparent"   // 透明清屏→窗口表面带 alpha, 材质可运行时切换; 实际底色由下方背景层画

    // 全局 UI 字体: main.cpp QFontDatabase::addApplicationFont 加载 (MiSans Regular/Bold 两份),
    // QML 侧全部组件经 Theme.fontFamily token 引用

    // 窗口背景层: 不透明=bg_canvas; 云母/亚克力=原生系统材质+主题淡色层 (Theme.bg_window);
    // DWM 材质由 main.cpp applyBackdrop 挂载, 材质切换时 QML 只换颜色
    Rectangle {
        anchors.fill: parent
        color: Theme.bg_window
    }

    TitleBar {
        id: titleBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        appWindow: win
        navigation: view
        onSettingsClicked: view.push("settings")
        onSearchRequested: function(q) { view.push("search", { query: q }) }
        onLoginRequested: authDialog.open("login")

        // 任务栏播控快捷按钮 (2026-10-02 用户拍板放标题栏; 播放/暂停 + 悬停提示, 其他逻辑先不做)
        BarBtn {
            icon: MockPlayback.playing ? "qrc:/qt/qml/cloudsong/qml/assets/icons/player/pause.svg"
                                       : "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
            tip: MockPlayback.playing ? "暂停" : "播放"
            onClicked: MockPlayback.playPause()
        }

        // 推荐页背景选择 (仅推荐页显示; 常规/3D粒子/汽水渐变, 2026-10-02)
        SuretyTagSelector {
            visible: view.currentName === "recommend"
            anchors.verticalCenter: parent.verticalCenter
            displayMode: "segment"
            selectedIndex: AppCfg.recommendBackdropIndex
            segmentHeight: 26
            fontSize: 11
            minimumWidth: 0
            model: [ { label: "常规" }, { label: "3D粒子" }, { label: "汽水" } ]
            onTagSelected: function(i) { AppCfg.recommendBackdropIndex = i }
        }
    }

    Row {
        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: playerBar.top }

        SideBar {
            id: sideBar
            width: 160
            height: parent.height
            onPageSwitchRequested: function(page) { view.switchRoot(page) }
            onCreateRequested: createSheetDialog.open()   // 直接弹新建歌单窗, 不跳页
            onSheetRequested: function(sheet) { view.push("sheet", sheet) }
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

    // 任务栏播控: 播放状态推入 C++ TrayIconService (托盘图标/悬停提示), 单击托盘图标=播放/暂停 (2026-10-02)
    // 用 Binding 而非 "TrayIcon.playing:" 限定名绑定: 编译期看不到 context property,
    // 限定名绑定会被当成附着类型解析 → "Non-existent attached object" (2026-10-02 实测)
    Binding { target: TrayIcon; property: "playing"; value: MockPlayback.playing }
    Binding { target: TrayIcon; property: "title";   value: MockPlayback.title }
    Binding { target: TrayIcon; property: "artist";  value: MockPlayback.artist }
    Connections {
        target: TrayIcon
        function onToggleRequested() { MockPlayback.playPause() }
    }

    // 登录/注册/重置 弹窗 (自 Glowling 移植; 纯 UI, 表单动作全部转发为信号, 待 C++ AuthService 接线)
    AuthDialog {
        id: authDialog
    }

    // 新建歌单弹窗 (侧栏"创建的歌单"＋触发; 创建后侧栏与我的歌单页经 MockData 联动)
    CreateSheetDialog {
        id: createSheetDialog
    }
}
