import QtQuick
import QtQuick.Window
import "wall"
import "shell"

// CloudSong 推倒重写 · M1 demo 外壳 (2026-10-12)
//   新形态: 无经典标题栏 / 无侧栏 / 无常驻播放条 — 首页 = "海报墙"(WallHome), 导航收进中央缝
//   标题栏 = 悬浮式 (TopBar): 平时隐形, 悬停窗口顶部滑出 — 不占墙的版面
//   旧 shell / 页面树已停用 (文件保留待 M1 落地统一删除; git 保底); 无边框仍由 C++ DWM 方案实现
//   (main.cpp applyFrameless; visible:false 由 C++ 应用后统一 show)
Window {
    id: win
    visible: false
    width: 1440
    height: 900
    minimumWidth: 900
    minimumHeight: 600
    title: "CloudSong"
    color: "transparent"

    WallHome {
        id: wall
        anchors.fill: parent
    }

    TopBar {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        appWindow: win
        backdrop: wall
        onSettingsRequested: settingsDialog.open()
    }

    SettingsDialog {
        id: settingsDialog
    }
}
