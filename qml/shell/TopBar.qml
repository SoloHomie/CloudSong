import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "../wall"

// 悬浮标题栏 (M1 外壳): 平时隐形, 悬停窗口顶部 12px 滑出; 指针留在条内 (44px) 保持, 离开即收
// 左 = 品牌字标; 右 = 自绘窗控 (最小化 / 最大化-还原 / 关闭; 深色专用图标, 不引旧 Theme)
// 条内空白可拖窗 (startSystemMove), 双击最大化/还原
// 隐藏态内容层 enabled:false — 点击穿透给墙, 不挡拖墙 (悬停判定挂根 Item, 不受此影响)
// (齿轮 / 搜索位留到 M2/M3 有页面可开再挂; 旧 shell TitleBar 已停用, 此为按新主题新写)
Item {
    id: root

    property Window appWindow: null
    property bool revealed: false
    property Item backdrop: null   // 玻璃底板模糊源 (main.qml 传墙; null 时退化为纯着色)

    signal settingsRequested()

    height: 44
    z: 1000

    // 悬停判定 (挂根 Item — 指针悬停窗控钮时 HoverHandler 依然 hovered, 不会被按钮 MouseArea 抢走):
    //   进入顶部 12px → 展开; 指针离开整个条 (≤44px) → 收起; 条内移动不再收起
    // 用 point.position 的绑定 (HandlerPoint.position 带 NOTIFY, 官方推荐用法), 不依赖信号逐帧派发
    HoverHandler {
        id: hh
        onHoveredChanged: { if (!hh.hovered) root.revealed = false }
    }
    readonly property bool nearTop: hh.hovered && hh.point.position.y <= 12
    onNearTopChanged: { if (root.nearTop) root.revealed = true }

    // 毛玻璃底板 (悬停滑出时与内容同步淡入): 抓墙顶条带 → MultiEffect 模糊 → 深色玻璃着色
    //   只在展开时 live (闲置/收起零开销); 走独立 MultiEffect 项 — 本机实锤浮层 layer.effect 会白板, 勿用
    Item {
        id: glass
        anchors.fill: parent
        opacity: root.revealed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ShaderEffectSource {
            id: barGrab
            sourceItem: root.backdrop
            live: root.revealed
            sourceRect: Qt.rect(0, 0, root.width, root.height)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: barGrab
            blurEnabled: true
            blur: 0.9
            blurMax: 28
        }
        // 深色玻璃着色 (+底缘发丝线)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(9 / 255, 9 / 255, 11 / 255, 0.52)
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: WallTheme.hairline
            }
        }
    }

    // 内容层: 隐藏时禁用输入 + 透明; 展开 = 一次性 160ms 淡入 (非连续动画)
    Item {
        id: content
        anchors.fill: parent
        enabled: root.revealed
        opacity: root.revealed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // 拖窗区 (整条热区; 窗控钮在其上层)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: { if (root.appWindow) root.appWindow.startSystemMove() }
            onDoubleClicked: {
                if (!root.appWindow)
                    return
                if (root.appWindow.visibility === Window.Maximized)
                    root.appWindow.showNormal()
                else
                    root.appWindow.showMaximized()
            }
        }

        Text {
            id: brandText
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "CloudSong"
            color: WallTheme.text
            font.family: WallTheme.fontFamily
            font.pixelSize: 13
            font.weight: 800
            font.letterSpacing: 0.6
            opacity: 0.92
        }

        // 设置入口 (齿轮; 措辞同窗控: 0.6→1.0 hover) — 打开设置弹窗 (SettingsDialog)
        Rectangle {
            id: btnGear
            width: 32; height: 32
            radius: 8
            anchors.left: brandText.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: gearArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            Image {
                anchors.centerIn: parent
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/setting.svg"
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectFit
                smooth: true; antialiasing: true
                width: 18; height: 18
                opacity: gearArea.containsMouse ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            MouseArea {
                id: gearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsRequested()
            }
        }

        // ---- 窗控三钮 (44×44 热区; sourceSize 128 高清栅格降采样到 14 — 旧 WinBtn 现成模式) ----
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height

            Rectangle {
                id: btnMin
                width: 44; height: 44
                color: minArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/cloudsong/qml/assets/window/win-minimize.svg"
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectFit
                    smooth: true; antialiasing: true
                    width: 14; height: 14
                    opacity: minArea.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    id: minArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (root.appWindow) root.appWindow.showMinimized() }
                }
            }

            Rectangle {
                id: btnMax
                width: 44; height: 44
                color: maxArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                Image {
                    anchors.centerIn: parent
                    source: root.appWindow !== null && root.appWindow.visibility === Window.Maximized
                            ? "qrc:/qt/qml/cloudsong/qml/assets/window/win-restore.svg"
                            : "qrc:/qt/qml/cloudsong/qml/assets/window/win-maximize.svg"
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectFit
                    smooth: true; antialiasing: true
                    width: 14; height: 14
                    opacity: maxArea.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    id: maxArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.appWindow)
                            return
                        if (root.appWindow.visibility === Window.Maximized)
                            root.appWindow.showNormal()
                        else
                            root.appWindow.showMaximized()
                    }
                }
            }

            Rectangle {
                id: btnClose
                width: 44; height: 44
                color: closeArea.containsMouse ? Qt.rgba(232 / 255, 17 / 255, 35 / 255, 0.85) : "transparent"
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/cloudsong/qml/assets/window/win-close.svg"
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectFit
                    smooth: true; antialiasing: true
                    width: 14; height: 14
                    opacity: closeArea.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (root.appWindow) root.appWindow.close() }
                }
            }
        }
    }
}
