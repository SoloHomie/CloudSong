import QtQuick
import "../../theme"

// ═══════════════════════════════════════════════════════════════
//  PageSwitch — 统一页面转场容器 (页面栈装载层, 2026-10-01 抽离)
//
//  用法 (替换 View 里的 Loader):
//    PageSwitch {
//        sourceComponent: 当前页组件
//        direction: 1 = 前进 (新页右滑入) / -1 = 后退 (左滑入)
//                   0 = 原地淡入 (首屏 / 根页面切换)
//        onPageLoaded: function(item) { ... }   // 新页实例就绪: 接 navigate / 注 params
//    }
//
//  机制: 双层 Loader 进退场 — 旧页淡出 + 反向轻移, 新页侧滑淡入,
//  动画结束销毁旧页实例 (状态不复用, 与原单 Loader 语义一致)。
//  快速连点会打断进行中的转场, 收尾后直接开新场, 不会叠加卡死。
//  曲线/时长/位移统一取 Theme 动效 token, 全软件页面动画只此一处定义。
//  动画为一次性 (220ms 即停), 不触碰"连续动画 1000fps 空转"红线。
// ═══════════════════════════════════════════════════════════════
Item {
    id: root

    property Component sourceComponent: null
    property int direction: 1
    property Item item: null          // 当前页实例 (外部注 params 用)
    signal pageLoaded(var item)

    // 双层 Loader: front = 活动层 (z 2), back = 退场层 (z 1), 每次切换互换成对
    // 不用锚点: x 参与转场位移, 锚点与显式 x 互斥 (BallsHackPro 实证)
    Loader {
        id: backLayer
        width: parent.width
        height: parent.height
        z: 1
        onLoaded: publishFrom(backLayer)
    }
    Loader {
        id: frontLayer
        width: parent.width
        height: parent.height
        z: 2
        onLoaded: publishFrom(frontLayer)
    }
    property bool frontActive: true

    // 实例发布: 只发新创建的页面实例 (清空 sourceComponent 时 item 为 null, 自动忽略;
    // 同一实例只发一次, 供 View 接 navigate 与注入 params — 在动画开始前完成, 滑入期间即可交互)
    function publishFrom(layer) {
        if (layer.item !== null && root.item !== layer.item) {
            root.item = layer.item
            root.pageLoaded(layer.item)
        }
    }

    onSourceComponentChanged: swap()
    function swap() {
        // 快速连点: 打断进行中的转场, 收尾后直接开新场
        if (swapAnim.running) { swapAnim.stop(); finishSwap() }

        var outgoing = frontActive ? frontLayer : backLayer
        var incoming = frontActive ? backLayer : frontLayer

        incoming.sourceComponent = root.sourceComponent
        incoming.z = 2
        outgoing.z = 1

        // 进场层: 按方向侧移 + 淡入
        var dir = root.direction
        incoming.x = dir === 0 ? 0 : dir * Theme.motion_page_distance
        incoming.opacity = 0
        inAnim.target = incoming
        inAnim.from = incoming.x
        inAnim.to = 0
        inFade.target = incoming
        inFade.from = 0
        inFade.to = 1

        // 退场层: 淡出 + 反向轻移 (首屏无退场层, 跳过)
        var hasOut = outgoing.item !== null
        if (hasOut) {
            outgoing.x = 0
            outgoing.opacity = 1
            outAnim.target = outgoing
            outAnim.from = 0
            outAnim.to = -dir * Theme.motion_page_distance * 0.4
            outFade.target = outgoing
            outFade.from = 1
            outFade.to = 0
            outAnim.enabled = true
            outFade.enabled = true
        } else {
            outAnim.enabled = false
            outFade.enabled = false
        }
        swapAnim.restart()
    }

    function finishSwap() {
        var outgoing = frontActive ? frontLayer : backLayer
        outgoing.sourceComponent = null   // 销毁旧页实例
        frontActive = !frontActive
        var cur = frontActive ? frontLayer : backLayer
        cur.x = 0
        cur.opacity = 1
    }

    ParallelAnimation {
        id: swapAnim
        NumberAnimation { id: inAnim;  property: "x";       duration: Theme.motion_page_duration; easing.type: Theme.motion_curve }
        NumberAnimation { id: outAnim; property: "x";       duration: Theme.motion_page_duration; easing.type: Theme.motion_curve }
        NumberAnimation { id: inFade;  property: "opacity"; duration: Theme.motion_page_duration; easing.type: Theme.motion_curve }
        NumberAnimation { id: outFade; property: "opacity"; duration: Theme.motion_page_duration; easing.type: Theme.motion_curve }
        onFinished: finishSwap()
    }
}
