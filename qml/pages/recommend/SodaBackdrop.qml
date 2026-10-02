import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  SodaBackdrop — 推荐页"汽水"背景 (2026-10-02)
//  取每日推荐前几首封面同源色做斜向渐变 + 柔光气泡 (汽水感);
//  色板与 CoverArt.swatches 镜像 (真实封面落地后随 CoverArt 换源)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var songs: []
    readonly property var swatches: ["#8957e5", "#1f6feb", "#238636", "#b35900", "#d1242f", "#8250df", "#0a7e8c", "#6e40c9"]
    function tintAt(i) {
        var s = root.songs.length > i ? root.songs[i].seed : i
        return root.swatches[s % root.swatches.length]
    }

    // 斜向渐变 (专辑色, 低透明盖在氛围封面上)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.alpha(root.tintAt(0), 0.30) }
            GradientStop { position: 0.45; color: Qt.alpha(root.tintAt(1), 0.14) }
            GradientStop { position: 1.0;  color: Qt.alpha(root.tintAt(2), 0.34) }
        }
    }

    // 汽水气泡 (柔光圆, 位置由序号散列, 静态)
    Repeater {
        model: 6
        delegate: Rectangle {
            width: 46 + 24 * (index % 3)
            height: width
            radius: width / 2
            x: (index * 173) % Math.max(1, parent.width - width)
            y: (index * 97) % Math.max(1, parent.height - height)
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, 0.18) }
                GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 1.0;  color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }
}
