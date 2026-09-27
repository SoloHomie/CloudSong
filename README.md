# CloudSong 云谣

Qt/C++ 重制的 PC 音乐播放器, 目标兼容 MusicFree 插件协议 (仅核心: 插件加载 + 播放器, 不含 Electron/React UI)。

## 技术栈

- Qt 6.11.1 (MSVC 2022 x64) + QML
- Visual Studio 2026 (v145)

## 构建

用 Visual Studio 打开 `CloudSong.slnx`, 或命令行:

```
MSBuild CloudSong.vcxproj -p:Configuration=Release -p:Platform=x64
```

## 目录结构

- `qml/theme/` 主题令牌 (函数注入式配色)
- `qml/components/` 公共组件 (controls/buttons/display/layout/overlay/cards)
- `qml/layouts/` 四大板块: TitleBar / SideBar / View / (PlayBar 待建)
- `qml/pages/` 页面 (当前为占位页, 待逐个实装)
- `qml/dialogs/` 弹窗 (AuthDialog: 登录/注册/重置, 纯 UI 待 C++ AuthService 接线)

## 当前状态

骨架期: 无边框窗口 (DWM 方案, 保留系统阴影/贴靠/最大化动画)、侧栏导航 + 页面切换、认证弹窗、组件库 (自 Glowling 移植)。

待开发: 插件加载器 (QuickJS 候选)、播放核心 (libmpv 候选)、歌单/下载 (SQLite)、账号与订阅服务。
