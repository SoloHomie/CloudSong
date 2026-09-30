# CloudSong 云谣

Qt/C++ 重制的 PC 音乐播放器, 目标兼容 MusicFree 插件协议 (仅核心: 插件加载 + 播放器, 不含 Electron/React UI)。

## 技术栈

- Qt 6.11.1 (MSVC 2022 x64) + QML
- Visual Studio 2026 (v145)
- 全局字体 MiSans (外挂 fonts.rcc, 构建时自动生成)

## 构建

用 Visual Studio 打开 `CloudSong.slnx`, 或命令行:

```
MSBuild CloudSong.vcxproj -p:Configuration=Release -p:Platform=x64
```

字体资源由 PreBuildEvent 自动打包为 `fonts.rcc` 输出到目标目录, 无需手动处理。

## 目录结构

- `qml/theme/` 主题令牌 (函数注入式配色)
- `qml/components/` 公共组件 (controls/buttons/display/layout/overlay/cards/business)
- `qml/shell/` 骨架: TitleBar / SideBar / View / PlayerBar / QueueDrawer
- `qml/pages/` 16 页全量: 推荐 / 听歌模式 / 我喜欢 / 历史 / 我的歌单 / 本地音乐 / 下载 / 搜索 / 歌单详情 / 专辑详情 / 歌手详情 / 设置 / 主题 / 插件管理 / 云漫游 / 迁移
- `qml/dialogs/` 统一弹窗 (DialogShell 窗体 + AuthDialog 登录/注册/重置 等)
- `qml/mock/` MockData / MockPlayback 模拟数据 (与未来 C++ Service 同名, 待整体替换)

## 当前状态

UI 全量实装: 无边框窗口 (DWM 方案, 保留系统阴影/贴靠/最大化动画)、16 页 + 播放条 (进度 / 播放控制 / 竖向音量调节 / 音质 / 队列) + 队列抽屉 + 统一弹窗体系, 当前由 Mock 数据驱动。

待开发: C++ 服务接线 (Playback / Config / Auth / Roam / Migrate / Updater, 与 Mock 同名属性对换)、插件加载器 (QuickJS 候选)、播放核心 (libmpv 候选)、歌单/下载 (SQLite)。
