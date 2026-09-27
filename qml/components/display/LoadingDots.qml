import QtQuick

// ═══════════════════════════════════════════════════════════════════════════════
//  LoadingDots — 8 点波浪加载动画 (无光晕描边, 圆形点 + 透明度呼吸)
//  用法:
//    LoadingDots { running: true }
//    LoadingDots { running: true; dotColor: "#c5ff00" }   // 荧光黄
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root

    property bool  running:  true
    property color dotColor: "#7bed9f"
    property int   dotSize:  8
    property int   dotCount: 8

    implicitWidth:  dotCount * dotSize + (dotCount - 1) * 4
    implicitHeight: dotSize * 3 + 7

    Row {
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.dotCount

            Rectangle {
                id: dot
                width:  root.dotSize
                height: root.dotSize
                radius: root.dotSize / 2
                color: root.dotColor
                opacity: 0.45   // 静止时半透明, 波浪推进时提亮

                transform: Scale {
                    id: stretch
                    origin.x: dot.width  / 2
                    origin.y: dot.height / 2
                    xScale: 1
                }

                SequentialAnimation {
                    running: root.running
                    loops: Animation.Infinite

                    PauseAnimation { duration: index * 120 }

                    PropertyAction { target: stretch; property: "yScale"; value: 1 }
                    PropertyAction { target: dot;     property: "opacity"; value: 0.45 }

                    ParallelAnimation {
                        NumberAnimation {
                            target: stretch; property: "yScale"
                            to: 2.0; duration: 240
                            easing.type: Easing.InOutCubic
                        }
                        NumberAnimation {
                            target: dot; property: "opacity"
                            to: 1.0; duration: 240
                            easing.type: Easing.InOutCubic
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: stretch; property: "yScale"
                            to: 1.0; duration: 240
                            easing.type: Easing.InOutCubic
                        }
                        NumberAnimation {
                            target: dot; property: "opacity"
                            to: 0.45; duration: 240
                            easing.type: Easing.InOutCubic
                        }
                    }

                    PauseAnimation { duration: (root.dotCount - 1 - index) * 120 }
                }
            }
        }
    }
}
