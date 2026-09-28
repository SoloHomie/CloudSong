import QtQuick
pragma Singleton

QtObject {
    // =========================================================================
    //  界面字体 (2026-09-28 抽离统一入口: 全部组件 family 引用此 token,
    //  换字体只改这里 / 由设置页「界面字体」赋值; 非 readonly, 待 C++ ConfigService 持久化)
    //  字体资源 = qml/assets/fonts/MiSans-Regular.ttf + MiSans-Bold.ttf (qrc 内嵌),
    //  main.qml FontLoader 注册; 新增字体 = 加资源 + FontLoader + 此处选项
    // =========================================================================
    property string fontFamily: "MiSans VF"

    // =========================================================================
    //  Active Scheme — 0=浅色 1=深色 2=跟随系统
    // =========================================================================
    readonly property bool isDark: {
        switch (AppCfg.themeIndex) {
            case 0: return false
            case 1: return true
            // 跟随系统。注意 ColorScheme 是 scoped 枚举, 必须 Qt.ColorScheme.Light;
            // 无作用域的 Qt.Light 恒 undefined → !== 恒真 → 永远深色 (2026-09-29 修复)。
            // (qmllint 报 styleHints 无 colorScheme member = builtins 把 QStyleHints 标成
            // QObject 的类型信息缺漏, 运行时 Q_PROPERTY 正常可取, 忽略该告警)
            case 2: return Qt.styleHints.colorScheme !== Qt.ColorScheme.Light
            default: return true
        }
    }

    // =========================================================================
    //  深色基元 (Dark Primitives) — 保持现有色值不变
    // =========================================================================
    readonly property color d0: "#010409"   // 画布底
    readonly property color d1: "#0d1117"   // 表面 / 按钮底
    readonly property color d2: "#161b22"   // 卡片 / 按下态
    readonly property color d3: "#1c2128"   // 悬停态
    readonly property color d4: "#21262d"   // 微弱边框
    readonly property color d5: "#30363d"   // 标准边框
    readonly property color d6: "#484f58"   // 强调边框 / 聚焦环
    readonly property color d7: "#6e7681"   // 水印 / 分割线文字
    readonly property color d8: "#8b949e"   // 辅助文字 / 图标
    readonly property color d9: "#c9d1d9"   // 正文

    readonly property color d_accent:       "#1f6feb"
    readonly property color d_accent_hover: "#388bfd"
    readonly property color d_accent_press: "#1158c7"

    readonly property color d_success:    "#238636"
    readonly property color d_success_fg: "#3fb950"
    readonly property color d_warning:    "#9e6a03"
    readonly property color d_warning_fg: "#d29922"
    readonly property color d_danger:     "#da3633"
    readonly property color d_danger_fg:  "#f85149"
    readonly property color d_purple:     "#8957e5"
    readonly property color d_purple_fg:  "#a371f7"

    // =========================================================================
    //  浅色基元 (Light Primitives) — GitHub 风格灰阶翻转
    // =========================================================================
    readonly property color l0: "#ffffff"   // 画布底
    readonly property color l1: "#f6f8fa"   // 表面
    readonly property color l2: "#eef1f5"   // 卡片 / 按下态
    readonly property color l3: "#e1e4e8"   // 悬停态
    readonly property color l4: "#d0d7de"   // 微弱边框
    readonly property color l5: "#afb8c1"   // 标准边框
    readonly property color l6: "#8c959f"   // 强调边框
    readonly property color l7: "#656d76"   // 水印
    readonly property color l8: "#57606a"   // 辅助文字
    readonly property color l9: "#1f2328"   // 正文

    readonly property color l_accent:       "#0969da"
    readonly property color l_accent_hover: "#0550ae"
    readonly property color l_accent_press: "#033d8b"

    readonly property color l_success:    "#1a7f37"
    readonly property color l_success_fg: "#116329"
    readonly property color l_warning:    "#9a6700"
    readonly property color l_warning_fg: "#7d4e00"
    readonly property color l_danger:     "#cf222e"
    readonly property color l_danger_fg:  "#a40e26"
    readonly property color l_purple:     "#8250df"
    readonly property color l_purple_fg:  "#6e40c9"

    // =========================================================================
    //  色阶基元 (Active Primitive Scale)
    // =========================================================================
    property color neutral0: isDark ? d0 : l0
    property color neutral1: isDark ? d1 : l1
    property color neutral2: isDark ? d2 : l2
    property color neutral3: isDark ? d3 : l3
    property color neutral4: isDark ? d4 : l4
    property color neutral5: isDark ? d5 : l5
    property color neutral6: isDark ? d6 : l6
    property color neutral7: isDark ? d7 : l7
    property color neutral8: isDark ? d8 : l8
    property color neutral9: isDark ? d9 : l9

    // ---- 品牌蓝 ----
    property color accent:        isDark ? d_accent       : l_accent
    property color accent_hover:  isDark ? d_accent_hover : l_accent_hover
    property color accent_press:  isDark ? d_accent_press : l_accent_press

    // ---- 功能色 ----
    property color success:    isDark ? d_success    : l_success
    property color success_fg: isDark ? d_success_fg : l_success_fg
    property color warning:    isDark ? d_warning    : l_warning
    property color warning_fg: isDark ? d_warning_fg : l_warning_fg
    property color danger:     isDark ? d_danger     : l_danger
    property color danger_fg:  isDark ? d_danger_fg  : l_danger_fg
    property color purple:     isDark ? d_purple     : l_purple
    property color purple_fg:  isDark ? d_purple_fg  : l_purple_fg

    // ---- 基础色 ----
    readonly property color white: "#ffffff"
    readonly property color black: "#000000"

    // =========================================================================
    //  语义层 (Semantic Tokens)
    // =========================================================================

    // ---- 背景 ----
    property color bg_canvas:   neutral0
    property color bg_page:     neutral1
    property color bg_card:     neutral2
    property color bg_input:    neutral0
    property color bg_disabled: neutral4
    property color bg_acrylic:  isDark ? "#4d0d1117" : "#4df6f8fa"   // 30% opacity: 材质缺失时截图显示主题色而非白底
    property color bg_mica:     isDark ? "#1a0d1117" : "#1af6f8fa"   // 10% opacity (仓库原实现 957d9a0: 原生 Mica + 极淡主题色)

    // ---- 文字 ----
    property color text_primary:   neutral9
    property color text_secondary: neutral8
    property color text_hint:      neutral7
    property color text_disabled:  neutral6
    property color text_bright:    white

    // ---- 边框 ----
    property color border_default:  neutral4
    property color border_standard: neutral5
    property color border_emphasis: neutral6
    property color border_accent:   accent

    // ---- 交互态 ----
    property color hover_bg: neutral3
    property color press_bg: neutral2

    // ---- 按钮 ----
    property color btn_primary_bg:     accent
    property color btn_primary_hover:  accent_hover
    property color btn_primary_press:  accent_press
    property color btn_primary_text:   white
    property color btn_default_bg:     neutral1
    property color btn_default_border: neutral4
    property color btn_default_text:   neutral9
    property color btn_hover_bg:       neutral3
    property color btn_press_bg:       neutral2
    property color btn_danger_bg:      danger
    property color btn_danger_hover:   danger_fg
    property color btn_danger_press:   isDark ? "#b62324" : "#a40e26"
    property color btn_danger_text:    white

    // ---- 输入控件 ----
    property color input_bg:           neutral0
    property color input_border:       neutral4
    property color input_border_hover: neutral5
    property color input_border_focus: accent
    property color input_text:         neutral9
    property color input_placeholder:  neutral6
    property color input_readonly_bg:  isDark ? "#0a0e13" : "#f0f2f5"

    // ---- 滚动条 ----
    property color scrollbar_track:       neutral1
    property color scrollbar_thumb:       neutral5
    property color scrollbar_thumb_hover: neutral6

    // ---- 蒙层 ----
    property color overlay_bg:   neutral1
    property color shadow_color: black
    property real  shadow_alpha: isDark ? 0.5 : 0.15

    // ---- 链接 / 轻量强调 ----
    property color accent_text: isDark ? "#58a6ff" : "#0969da"

    // ---- 选中态 ----
    property color selected_bg:     isDark ? "#1a2332" : "#ddf4ff"
    property color selected_border: accent

    // ---- 标签 ----
    property color tag_preset_bg: isDark ? "#1a3a5c" : "#ddf4ff"
    property color tag_preset_fg: isDark ? "#58a6ff" : "#0969da"
    property color tag_custom_bg: isDark ? "#2d1f4e" : "#fbefff"
    property color tag_custom_fg: isDark ? "#a371f7" : "#8250df"
}
