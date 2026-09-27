import QtQuick
import QtQuick.Effects
import "../theme"
import "../components/buttons"
import "../components/controls"
import "../components/display"

/// ──────────────────────────────────────────────────────────
///  自定义标题栏 (自 BallsHackPro 移植: 保留骨架+窗口控制,
///  产品专属按钮[注入神力/更新/设备切换/登录]已剥离)
/// ──────────────────────────────────────────────────────────
Item {
    id: root
    property Window appWindow: null
    default property alias content: contentRow.data
    property alias rightContent: rightRow.data
    signal settingsClicked()
    signal searchRequested(string query)
    property var navigation: null   // View 页面栈: {back(), forward(), canGoBack, canGoForward}
    height: 44
    z: 20   // 搜索历史面板需盖住内容区

    // ── 账户状态 (C++ 回写; 移植自 Glowling) ──
    property bool   loggedIn: false
    property string userName: "用户"
    property string email:    ""
    property bool   pro:      false
    property int    daysLeft: 0
    property string planName: ""

    // ── 账户交互信号 (主窗口接线; 移植自 Glowling) ──
    signal loginRequested()
    signal logoutRequested()
    signal accountClicked()
    signal subscriptionClicked()
    signal redeemClicked()
    signal orderClicked()
    signal upgradeClicked(string planId)
    readonly property color winBtnHover: Theme.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.08)

    // ── 拖拽 + 双击最大/还原 ──
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton && root.appWindow)
                root.appWindow.startSystemMove()
        }
        onDoubleClicked: {
            if (!root.appWindow) return
            if (root.appWindow.visibility === Window.Maximized)
                root.appWindow.showNormal()
            else
                root.appWindow.showMaximized()
        }
    }

    // ── 后退/前进 (绑定 View 页面栈) ──
    Row {
        id: navRow
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 2
        NavBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-left.svg"
            enabled: root.navigation !== null && root.navigation.canGoBack
            onClicked: if (root.navigation) root.navigation.back()
        }
        NavBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/chevron-right.svg"
            enabled: root.navigation !== null && root.navigation.canGoForward
            onClicked: if (root.navigation) root.navigation.forward()
        }
    }

    // ── 自定义内容区 ──
    Row {
        id: contentRow
        anchors.left: navRow.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 3
    }

    // ── 全局搜索 (居中) ──
    SearchBox {
        id: searchBox
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        width: 300
        height: 30
        onSearchRequested: function(q) { root.searchRequested(q) }
    }

    // ── 右侧自定义内容区 ──
    Row {
        id: rightRow
        anchors.right: winRow.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 6

        // 登录/账号 (BallsHackPro 版按钮, 2026-09-28 用户换回): 未登录=primary"登录",
        // 已登录=ghost 用户名; 点击 loginRequested → 主窗口弹 AuthDialog
        SuretyBtn {
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 11; font.weight: Font.Bold
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/登录.svg"
            text: root.loggedIn ? root.userName : "登录"
            variant: root.loggedIn ? "ghost" : "primary"
            onClicked: root.loginRequested()
        }

        // 设置入口 (内置: 图标默认灰与文字同色, hover 变白; 无背景)
        Item {
            width: 28
            height: parent.height
            Image {
                anchors.centerIn: parent
                width: 20; height: 20
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/setting.svg"
                sourceSize: Qt.size(80, 80)
                fillMode: Image.PreserveAspectFit
                smooth: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: setMouse.containsMouse ? "#ffffff" : Theme.text_secondary
                    colorization: 1.0
                }
            }
            MouseArea {
                id: setMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsClicked()
            }
        }
    }

    // ── 窗口控制按钮 ──
    component WinBtn: Rectangle {
        width: 44; height: parent.height
        color: mouseArea.containsMouse ? hoverBg : "transparent"
        radius: 0
        property string icon: ""
        property color hoverBg: Qt.rgba(1, 1, 1, 0.1)
        signal clicked()
        Image {
            id: btnIcon
            anchors.centerIn: parent
            source: parent.icon
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectFit
            smooth: true; antialiasing: true
            width: 14; height: 14
            opacity: mouseArea.containsMouse ? 1.0 : 0.6
            Behavior on opacity { NumberAnimation { duration: 150 } }
            layer.enabled: !Theme.isDark
            layer.effect: MultiEffect {
                colorizationColor: Theme.text_primary
                colorization: 1.0
            }
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    Row {
        id: winRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 0

        Rectangle {
            width: 1; height: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
        }

        Item { width: 6; height: 1 }

        WinBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/window/窗体-最小化.svg"
            hoverBg: root.winBtnHover
            onClicked: { if (root.appWindow) root.appWindow.showMinimized() }
        }
        WinBtn {
            icon: root.appWindow && root.appWindow.visibility === Window.Maximized
                ? "qrc:/qt/qml/cloudsong/qml/assets/window/窗体-向下还原.svg"
                : "qrc:/qt/qml/cloudsong/qml/assets/window/窗体-最大化.svg"
            hoverBg: root.winBtnHover
            onClicked: {
                if (!root.appWindow) return
                if (root.appWindow.visibility === Window.Maximized)
                    root.appWindow.showNormal()
                else
                    root.appWindow.showMaximized()
            }
        }
        WinBtn {
            icon: "qrc:/qt/qml/cloudsong/qml/assets/window/窗体-关闭.svg"
            hoverBg: Qt.rgba(0.82, 0.14, 0.14, 0.9)
            onClicked: { if (root.appWindow) root.appWindow.close() }
        }
    }

    // ── 圆形图标按钮 (导航用, 28×28) ──
    component NavBtn: Item {
        width: 28
        height: 28
        property string icon: ""
        property bool enabled: true
        signal clicked()

        Rectangle {
            visible: navMouse.containsMouse && parent.enabled
            anchors.fill: parent
            radius: 14
            color: Theme.hover_bg
        }
        IconImage {
            anchors.centerIn: parent
            source: parent.icon
            size: 16
            color: parent.enabled ? Theme.text_primary : Theme.text_disabled
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (parent.enabled) parent.clicked()
        }
    }
}
