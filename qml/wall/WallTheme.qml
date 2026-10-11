import QtQuick
pragma Singleton

// M1 墙面主题 token (推倒重写 demo 专用, 独立于旧 theme/Theme; 旧树停用保留待删)
// 深色默认: 5 token (bg / 文字三级 / accent) + 缝与磁贴的派生色 (数值 = 设计定案, 不引自参照项目素材)
QtObject {
    readonly property string fontFamily: "MiSans VF"

    // ---- 5 token ----
    readonly property color bg: "#09090b"
    readonly property color text: "#f4f4f5"
    readonly property color textDim: Qt.rgba(244 / 255, 244 / 255, 245 / 255, 0.78)
    readonly property color secondary: "#71717a"
    readonly property color accent: "#f4f4f5"

    // ---- 缝 ----
    // paper = mix(bg 90%, text) ≈ #212122; 实色纸条 (对标: 实色档缝 = 主题纸色; 墙两半为缝让位, 不再半透压磁贴)
    readonly property color seamPaper: "#212122"
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.12)
    readonly property color seamRing: Qt.rgba(1, 1, 1, 0.06)

    // ---- 磁贴遮罩 ----
    // 底部压暗 (保证左下文案可读); 常态削色层, hover 时退场露出封面本色
    readonly property color shadeLow: Qt.rgba(0, 0, 0, 0.05)
    readonly property color shadeMid: Qt.rgba(0, 0, 0, 0.24)
    readonly property color shadeDeep: Qt.rgba(0, 0, 0, 0.92)
    readonly property color tintTop: Qt.rgba(61 / 255, 61 / 255, 63 / 255, 1)
    readonly property color tintBottom: Qt.rgba(26 / 255, 26 / 255, 29 / 255, 1)
    readonly property real tintOpacity: 0.5

    // 封面回退渐变: hue 决定两停 (亮顶 / 暗底), 无图也有色彩
    function gradFor(hue) {
        var h = ((hue % 360) + 360) % 360
        return [Qt.hsla(h / 360, 0.68, 0.58, 1),
                Qt.hsla(((h + 52) % 360) / 360, 0.62, 0.18, 1)]
    }
}
