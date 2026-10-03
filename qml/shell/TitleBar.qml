import QtQuick
import QtQuick.Effects
import "../theme"
import "../components/buttons"
import "../components/controls/search"
import "../components/display"

/// ──────────────────────────────────────────────────────────
///  自定义标题栏 (自 BallsHackPro 移植: 保留骨架+窗口控制
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
            iconSource: "qrc:/qt/qml/cloudsong/qml/assets/icons/login.svg"
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

    // ── 窗口控制按钮 (WinBtn 已提取至同目录 WinBtn.qml, 2026-10-02) ──
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
            icon: "qrc:/qt/qml/cloudsong/qml/assets/window/win-minimize.svg"
            hoverBg: root.winBtnHover
            onClicked: { if (root.appWindow) root.appWindow.showMinimized() }
        }
        WinBtn {
            icon: root.appWindow && root.appWindow.visibility === Window.Maximized
                ? "qrc:/qt/qml/cloudsong/qml/assets/window/win-restore.svg"
                : "qrc:/qt/qml/cloudsong/qml/assets/window/win-maximize.svg"
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
            icon: "qrc:/qt/qml/cloudsong/qml/assets/window/win-close.svg"
            hoverBg: Qt.rgba(0.82, 0.14, 0.14, 0.9)
            onClicked: { if (root.appWindow) root.appWindow.close() }
        }
    }
    // (NavBtn 已提取至同目录 NavBtn.qml, 2026-10-02)
}
