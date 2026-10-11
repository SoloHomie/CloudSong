# CloudSong 推倒重写方案（对标 Folia）· 2026-10-11

> 依据：用户决策链（完全重构 / 推倒重写 / 触发=产品方向调整 / 以 QML 前端为主 / 对标 Folia 重做 / 四大能力=AI 歌词+分轨·可视化舞台·壁纸模式·Mod+主题生态 / 同仓库原地重写 / 视觉全面重做；"Folia 的首页让我感到很震撼"）。
> 参照物：Folia v0.7.17 源码（桌面 `folia-major-main.zip`，当前解在临时目录）；**实机 `D:\Folia\Folia.exe`**（用户已装，随时可对照）；三张 Playwright 基线截图；bravais/wall 源码常量。
> 既有铁律沿用：《CloudSong服务接口定案_20260929》（C++ 业务层契约，**本次重写不动它**）+ 能 C++ 做的逻辑不放 QML。
> **许可红线：Folia = AGPL-3.0。净室重写——不复制其任何代码 / 素材 / 文案 / 图标 / 字体；只对标产品体验与客观参数（格距、时长这类数值属事实信息）。参照源码存放于仓库外，永不进 CloudSong 仓库。**

---

## 0. 一分钟结论

| 项 | 结论 |
|---|---|
| 做什么 | CloudSong 展示层（全部 QML）推倒，以 Qt 6.11 QML 重做 Folia 产品形态；C++ 业务层继续按《服务接口定案》实装 |
| 震撼点锁定 | 首页 = bravais 海报墙（深色，聚焦集合大卡 + 两侧渐退卡 + 缝 + 翻牌换页签）——已取证，见 §2 |
| 第一步 M1 | 新外壳 + 首页墙（纯 QML + Mock 数据），C++ 零改动 |
| 验收 | 编译零错 + qmllint 零错 + 用户实跑对照 `D:\Folia` 实机"就是那一屏" |
| 参照物固定 | M0 把源码挪到仓库外 `D:\folia-reference`（只读）；我截一组实机深色目标截图存 `docs/refs/` 作验收基准 |

---

## 1. 目标形态（拿什么 / 不拿什么）

**拿（产品范式）**：
1. **极简外壳**：无左侧栏、无常驻播放条、无经典标题栏——顶部一行（品牌 + 齿轮 / 页签胶囊 / 搜索）＋ 自绘窗控；播放时底部中央出迷你播放胶囊。
2. **墙面范式**：一切内容 = 一面海报墙；导航 = 相机在墙上移动 + 给墙上的位置翻牌换内容；信息与操作放在**缝**（墙上裂开的一道竖直开口，三级：full 300 / 首页窄缝 120 / 书脊 64）。
3. **首页**：聚焦集合大卡居中（6×6 格 = 808px），邻近卡逐级缩小渐退，聚焦卡下方大标题 +「N 首 · 副标题」；页签（歌单/电台/专辑/本地/Navidrome）切换 = 整墙翻牌波次。
4. **深色默认**：5-token 主题（bg / 文字三级 / accent）+ 背景 4 层（底色 + 2~3 道径向主题光晕 + 噪点 + 暗角）；封面取色主题化（后期）。
5. **后续形态**：播放页（大词歌词 + 可视化舞台）、命令面板、缝的完整交互（翻面/表单态）、设置、壁纸模式、Mod/主题生态 → 按 §6 里程碑逐项。

**不拿（第一批明确不做）**：Folia 的 906 个组件、14 个可视化器、Mod 系统、壁纸、AI——全部是**自研精简版且排后**；数量级与实现机制对标 Folia 的映射见 §4。

---

## 2. 首页取证（关键章——"震撼的到底是哪一屏"已定案）

**结论：用户被震撼的首页 = Folia 默认 suite「bravais」的海报墙首页，深色主题。** 之前"img/1.png 可能是旧版形态"的怀疑**证伪**：

| 证据 | 内容 |
|---|---|
| A. 默认 suite | `librarySuites.ts:29` `LIBRARY_SUITE_INITIAL_CHOICE_FALLBACK = 'bravais'`——全新安装首启就是 bravais 首页 |
| B. 基线截图 | `test/ui/app.screenshot.spec.ts` 三张 Playwright 基线是**当前代码真实渲染**的首页（test 注释：suite 切换浮层已隐藏）。形态：顶部 [Folia+齿轮] [页签胶囊] [搜索]，中央聚焦集合大卡，右侧两句逐级缩小渐退的卡，聚焦卡下方大标题 +「N Tracks · 副标题」，右下 [图标+箭头] 胶囊 |
| C. img/1.png | 深色 + 真实内容 + 播放态（底部多一条 00:00/03:00 进度胶囊、右下蝴蝶钮）的同构形态。它是旧营销图，**细节以基线/代码为准** |
| D. 代码常量 | `bravaisConstants.ts`：格 128 + 缝 8；缝宽 300/120/64；相机档位 0.52/0.64/0.76（<640 / <1100 / 否则）；翻牌 150+210ms；相机补间 420ms；缝开合 360ms→§7 |

**且用户在实机（D:\Folia）看过它**——M1 起以实机为活的标准答案，逐屏截图对照。

---

## 3. 保留 / 重建 / 删除（surgical 清单）

**保留（不动）**：
- C++：QuickJS 插件运行时 + 酷狗/网易云 JS 插件、AppConfig、InputService、RecommendService、TaskbarBarService（+`shell/TaskbarBar.qml`，用户拍板的自有差异化，与重写解耦）、main.cpp 的 DWM 无边框整套。
- 构建：MiSans 字体 rcc 管线、vcxproj/qml.qrc 清单制、VS2026/Qt6.11.1 工具链。
- 数据：MockData/MockPlayback（M1 的 Mock 数据源，服务实装后按《定案》第 9 节替换）。
- 经验：全部 memory 里的坑（vsync 空转、delegate 匿名化、var-object 改值不提值……）直接适用。

**重建（新写）**：全部 QML 展示层——外壳 main.qml（极简标题行）、新 Theme（5 token、深色默认）、首页墙（M1）、集合页/播放页/搜索/命令面板/设置/账户（M2+）。

**删除**：旧 shell（TitleBar / SideBar / PlayerBar / QueueDrawer / View 页栈）＋旧页面树 16 页——**M1 落地同一提交删掉**（git 历史保底），不留死代码腐烂。

**《服务接口定案》不受影响**：C++ 业务层照定案推进（M2 起落地 Playback 等三件）；本次重写只管展示层。

---

## 4. 技术映射（React / Electron → Qt 6.11 QML）

| Folia | Qt 侧 | 备注 |
|---|---|---|
| React 组件树 | QML 组件树 | 能 C++ 的逻辑一律 C++ service（铁律） |
| zustand 44 个 store | C++ service + context property | 同现有 AppCfg/Playback 模式 |
| framer-motion（tween/spring） | QML NumberAnimation/Behavior + 自绘 | ⚠ 本项目 vsync 空转实锤：连续动画须 Timer 节流（§8.1） |
| DOM transform（translate3d/scale） | Item 世界坐标 + x/y/scale/rotation | 首页墙 = 世界 Item + 显式定位子项 |
| CSS backdrop-blur 玻璃 | QtQuick.Effects `MultiEffect` | 已具备（Qt6QuickEffects） |
| canvas/WebGL/pixi/three 可视化 | ShaderEffect（qsb 烘焙）→ Qt Quick3D | qsb.exe 已就绪，Quick3D+Effects+ParticleEffects 全在 |
| IndexedDB/Dexie | SQLite（《定案》§7 八表） | 不变 |
| electron 主进程（Node 后端/侧车） | C++ 进程内 或 本地子进程 | htdemucs/bbeat_this ONNX 分轨 → M5 拍板 |
| 本地歌词 HTTP API (127.0.0.1:32109) | QTcpServer | 本项目已有 TCP 命令架构经验 |
| Ed25519 Mod 签名 | OpenSSL（Qt 网络栈自带） | M7 |
| 壁纸 WorkerW 挂载（Rust helper） | 纯 C++ SetParent + Raw Input 转发 | M6，机制已吃透 |
| 7 格式歌词 parser/逐字 | C++ LyricService（定案） | 展示层后置 |

**Qt 能力已核**：`C:\Qt\6.11.1\msvc2022_64` 含 Quick3D/QuickEffects/ShaderTools/qsb/Multimedia——可视化舞台与玻璃质感无需新依赖。

---

## 5. 里程碑（每步带可验证验收 + 动码前先述）

> 工作方式：我改码 → **用户按按钮编译/运行**（铁律，我不私自操作）→ 截图/日志回我 → 我对照实机修。每步验收 = 编译零错 + qmllint 零错 + 实跑对照。

**M0 准备（0.5 天，本次拍板后即可执行）**
- 源码解到 `D:\folia-reference`（仓库外只读）；我抓一组实机深色目标截图（用户开 Folia 最大化，我 PowerShell 截）存 `D:\Dev-Cpp\CloudSong\docs\refs\`。
- 验收：参照物就位，方案拍板。

**M1 首页墙（核心，拆 4 步，每步都能跑起来看）**
- **M1a 新外壳**：窗口（沿用 DWM 无边框）+ 新 Theme（5 token、深色默认）+ 顶部行（品牌/齿轮/搜索位/自绘窗控）+ 空壳接线。验收：跑起来是深色空壳，能拖动/缩放/关闭。
- **M1b 墙面引擎**：世界坐标 + 相机（档位 + 420ms 补间）+ 聚焦卡（6×6）+ 邻近卡渐退 + 大标题/元数据区，Mock 数据。验收：静态一屏 ≈ 基线截图。
- **M1c 页签 + 缝**：页签胶囊 + 首页窄缝（120px，页签与入口）+ 切页签 = 整墙翻牌波次。验收：动画对照实机（翻牌 150+210ms、波次错开）。
- **M1d 打磨**：hover 放大一个格隙（300ms）/ 点击进集合（占位）/ 滚轮-相机联动 / 背景 4 层（光晕 + 噪点 0.13 + 暗角）/ 空闲 CPU 检查。验收：肉眼对照实机 + 空闲 CPU≈0（vsync 坑）。

**M2 集合页 + 播放内核**：点开歌单 = 墙面翻成该歌单（聚焦歌曲卡）；PlaybackService（libmpv，《定案》M0 三件：Playback/SearchHistory/Toast）实装；迷你播放胶囊。验收：真放一首歌，进度胶囊与实机同款。

**M3 搜索 / 设置 / 账户 + 缝的完整形态**（full 300 / spine 64、翻面、表单态）。

**M4 可视化舞台**：首批 2~3 款式（ShaderEffect 起步 → Quick3D），对标 Folia 的"5 大渲染机制"里 QML 可实现者，自研画面。

**M5 AI 歌词 + 分轨**：定案 LyricService 先行；AI 歌词走云 API（Gemini/OpenAI 兼容）；分轨（htdemucs/bbeat_this 级）方案当步拍板（ONNX Runtime vs 子进程）。

**M6 壁纸模式**：C++ WorkerW 挂载（双探测）+ Raw Input 键鼠转发 + 看门狗。

**M7 Mod + 主题生态**：插件体系 v2（清单/签名/内容寻址/市场）+ 主题 = token 包。

---

## 6. M1 首页规格草案（数值先落，细节 M1-d1 从源码提取补全）

**几何**
- 世界格：cell 128 + gap 8（= 136 步距）；聚焦卡 6×6 = 808×808；相机档位按视口宽 0.52 / 0.64 / 0.76。
- 邻近卡尺寸递减规则、聚焦卡下方标题/元数据排布、缝在首页的具体位置与布局 → **M1-d1 提取**（读：`bravaisHomeProjection.ts`、`BravaisTile/BravaisFocusCardBody.tsx+css`、`BravaisSeamHome*.tsx`、`bravaisHome.css`、`BravaisStage/useBravaisCamera`、`src/components/wall/*` 墙引擎）。

**动效（数值来自 bravaisConstants.ts，直接可用）**
| 项 | 值 |
|---|---|
| 磁贴翻牌 | 前半 150ms 到 90°，换内容，后半 210ms 转回（cubic-bezier(.55,0,.9,.45) / (.2,.7,.25,1)） |
| 相机移动 | 420ms cubic-bezier(0.22, 1, 0.36, 1) |
| 缝开合 | 360ms |
| hover 放大 | +1 格隙（(w+16)/w），300ms；阴影 600ms |
| 降低动效 | 180ms 淡出→换→淡入（无错开） |

**主题**：深色默认 bg `#09090b` / 主文字 `#f4f4f5`；浅色 `#f5f5f4` / accent `#ea580c`；层级用白色叠加 0.04/0.08/0.15 + 1px 描边；圆角：胶囊 9999 / 面板 24 / 卡 16 / 图标钮 12。

**QML 实现约定**
- 墙 = 一个世界 Item + 每卡显式定位的 Item（**不用 ListView/DelegateModel**，避匿名化坑）；相机 = 根 Item x/y/scale + Behavior；视口外裁剪。
- 封面 = `Image` asynchronous + sourceSize 降采样；Mock 阶段用现有 seed 纯色占位。
- 所有连续动画 Timer 节流（§8.1）。

---

## 7. 风险与已知坑

1. **vsync 空转（本项目实锤）**：QML 连续动画 = 1000fps 空转 → 任何常驻动画/光晕/微动效一律 Timer 手动节流；M1d 验收含空闲 CPU 检查。
2. **墙面 Item 数量**：世界内数百 Item 显式定位可行（Folia 纯 DOM 也是这个量级），但要遮挡剔除 + 避免每帧 JS/QML 重排。
3. **图片异步与内存**：在线封面（M2+）异步加载 + 缓存 + 降采样。
4. **AGPL 净室**：见开头红线；`D:\folia-reference` 永不进仓库；不抄文案（Folia 中文文案如"缝/书脊"等概念词属通用语汇可用，具体句子自写）。
5. **缝的完整交互复杂**（Folia 用 8 个 tsx 承载）：M1 只做窄缝静态 + 页签切换；三级开合/翻面/表单态排到 M3。
6. **像素级对齐靠迭代**：不追求一次成，每步截图与实机并排比。
7. **TaskbarBar**：默认开（`appconfig.h:47`），M1 期间旧设置页删除后暂无法关；不影响主窗对照，M3 设置页重建时恢复开关。

---

## 8. 待拍板（4 项）

| # | 项 | 推荐 |
|---|---|---|
| a | 外壳彻底 Folia 化（去侧栏、去常驻播放条 → 迷你播放胶囊） | **是**（震撼点=整体形态，混合壳会两头不像） |
| b | 深色默认 + 浅色可切 | **是**（实机默认就是深色） |
| c | M1 只做首页一个场景（墙 + 页签 + 缝骨架，Mock 数据） | **是**（先把"那一屏"复现到位） |
| d | 旧 QML 树在 M1 落地时同一提交删除（git 保底） | **删**（防死代码腐烂） |

拍板后我从 M0 开工；M1 期间每步先述后动，C++ 一行不碰。
