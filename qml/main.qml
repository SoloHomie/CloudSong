import QtQuick
import QtQuick.Window
import "wall"

// CloudSong 推倒重写 · M1 demo 外壳 (2026-10-12)
//   新形态: 无标题栏 / 无侧栏 / 无常驻播放条 — 首页 = "海报墙"(WallHome), 导航收进中央缝
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
        anchors.fill: parent
    }
}
