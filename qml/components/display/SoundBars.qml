import QtQuick
import "../../theme"

/// 声纹动画: 三根竖条按固定节奏步进跳变 (每根一条循环旋律, 相位错开, 像均衡器跟节拍)
/// 注: 本机垂直同步全局关闭→Behavior动画会驱动渲染循环空转1000fps吃满CPU,
///     故用 33ms 定时器手动推进缓动(30fps), 渲染次数有上限
Item {
    id: root
    property bool running: true
    property color barColor: Theme.isDark ? "#ffffff" : Theme.text_secondary
    property int step: 0
    property var seq: [[12, 6, 9, 6], [6, 9, 6, 12], [9, 6, 12, 6]]
    property real t: 0   // 0..1 拍内进度

    Timer {
        interval: 33
        running: root.running
        repeat: true
        onTriggered: {
            root.t += 0.18   // 约 5.5 拍/秒, 与 180ms 节拍一致
            if (root.t >= 1) {
                root.t -= 1
                root.step = (root.step + 1) % 4
            }
        }
    }

    function ease(x) {   // InOutQuad: 快进慢出, 跳变平滑
        return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2
    }

    Repeater {
        model: 3
        Rectangle {
            x: 1.7 + index * 5.2
            y: parent.height / 2 - height / 2
            width: 1.6; radius: 0.8
            height: {
                var cur = root.seq[index][root.step]
                var next = root.seq[index][(root.step + 1) % 4]
                return cur + (next - cur) * root.ease(root.t)
            }
            color: root.barColor
            antialiasing: true
        }
    }
}
