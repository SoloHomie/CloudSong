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

```
CloudSong/
├── src/
│   ├── app/       程序入口 (main.cpp)
│   ├── core/      基础配置 (AppConfig)
│   └── services/  业务服务, 每功能一对 h/cpp: Input / Plugin / PluginRuntime / Recommend / TaskbarBar
├── 3rdparty/quickjs/   vendored QuickJS-ng (插件运行时, 勿改)
├── qml/
│   ├── theme/         主题令牌 (函数注入式配色)
│   ├── components/    公共组件 (controls/buttons/display/layout/overlay/cards/business)
│   ├── shell/         骨架: TitleBar / SideBar / View / PlayerBar / QueueDrawer
│   ├── pages/         页面 (按功能分类, 见下)
│   ├── dialogs/       统一弹窗 (DialogShell 窗体 + AuthDialog 登录/注册/重置 等)
│   └── mock/          MockData / MockPlayback 模拟数据 (与 C++ Service 同名, 待整体替换)
├── plugins/           JS 插件载荷 (构建时 xcopy 到输出目录, 运行时加载; 停用名单走 QSettings)
├── fonts.qrc / qml.qrc 资源清单 (留根不动: 资源 URL 是运行时契约)
└── CloudSong.vcxproj / .filters   (filters 虚拟目录与磁盘目录镜像)
```

## 添加新功能

1. `src/services/` 加一对 `xxxservice.h/.cpp` (QObject + 信号, 在 main.cpp 注册上下文属性)
2. `qml/pages/` 加页面 (同结构页面复用 `qml/templates/` 模板, 不要复制粘贴)
3. 页面登记进 `qml.qrc`; 新增 h/cpp 在 VS 里右键"添加现有项"进工程 (vcxproj 显式列举文件, filters 同步加条目)

## 当前状态

UI 全量实装: 无边框窗口 (DWM 方案, 保留系统阴影/贴靠/最大化动画)、16 页 + 播放条 (进度 / 播放控制 / 竖向音量调节 / 音质 / 队列) + 队列抽屉 + 统一弹窗体系, 当前由 Mock 数据驱动。

待开发: C++ 服务接线 (Playback / Config / Auth / Roam / Migrate / Updater, 与 Mock 同名属性对换)、插件加载器 (QuickJS 候选)、播放核心 (libmpv 候选)、歌单/下载 (SQLite)。
