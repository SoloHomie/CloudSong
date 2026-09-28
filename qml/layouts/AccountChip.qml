import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components/buttons"
import "../components/display"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════════════════════
//  AccountChip — 顶栏账户入口 + 账户菜单 (纯 UI 骨架)
//
//  未登录: 「登录」文字按钮   → 点击 loginRequested → 主窗口弹 AuthDialog
//  已登录: 头像 + 会员角标 + 到期色点 → 点击弹账户菜单
//
//  ⚠ 全部状态由 C++ 回写 (AccountService/AppConfig):
//      loggedIn / userName / email / pro / daysLeft / planName
//    菜单动作全部只是信号, 由 C++ 处理 (本文件零业务逻辑)
// ═══════════════════════════════════════════════════════════════════════════════
Item {
    id: root

    // ── 外部写入的状态 (C++ bind) ──
    property bool   loggedIn: false
    property string userName: "用户"
    property string email:    ""
    property bool   pro:      false
    property int    daysLeft: 0          // 会员剩余天数 (pro=false 时忽略)
    property string planName: ""         // 当前套餐名 (如 "Pro 月付")

    // ── 发给 C++ 的信号 ──
    signal loginRequested()
    signal logoutRequested()
    signal accountClicked()
    signal subscriptionClicked()
    signal redeemClicked()
    signal orderClicked()
    signal upgradeClicked(string planId)

    implicitWidth:  loggedIn ? chipRow.implicitWidth + 16 : 48
    implicitHeight: 28

    // 角标颜色: 30 天+ 正常 / 7 天内提醒 / 已过期
    readonly property color badgeColor: !pro ? Theme.text_secondary
                                      : daysLeft <= 0  ? Theme.danger_fg
                                      : daysLeft <= 7  ? Theme.warning_fg
                                      : Theme.success_fg
    readonly property string badgeTip: !pro ? "免费版"
                                    : daysLeft <= 0 ? "会员已过期"
                                    : ("会员剩余 " + daysLeft + " 天")

    // ───────────────────────────────────────────────────────────
    //  未登录态: 文字按钮
    // ───────────────────────────────────────────────────────────
    SuretyBtn {
        id: loginBtn
        visible: !root.loggedIn
        anchors.centerIn: parent
        width: 48; height: 26
        text: "登录"
        variant: "outline"
        cornerRadius: 6
        font.pixelSize: 13
        onClicked: root.loginRequested()
    }

    // ───────────────────────────────────────────────────────────
    //  已登录态: 头像 + 角标 + 箭头
    // ───────────────────────────────────────────────────────────
    Row {
        id: chipRow
        visible: root.loggedIn
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter

            Avatar {
                anchors.fill: parent
                name: root.userName
                radius: 11
                fontSize: 13
                accentColor: root.pro ? Theme.purple_fg : Theme.accent_text
            }

            // 会员角标点 (右下角)
            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: root.badgeColor
                border.width: 1.5
                border.color: Theme.bg_page
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.userName
            color: Theme.text_secondary
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 90)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "⌄"
            color: Theme.text_secondary
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        visible: root.loggedIn
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: accountMenu.visible ? accountMenu.close() : accountMenu.open()
    }

    Tooltip {
        text: root.loggedIn ? root.badgeTip : ""
        anchorItem: root
        // 注: placement 用字面量 0(=above), 不用 Tooltip.above
        //     —— 该枚举声明在 Tooltip.qml 内部属性之后, 组件尾部才可见, 引用它会报
        //     "Unable to assign [undefined] to int" (组件自身顺序问题, 勿改回)
        placement: 0
        shown: root.loggedIn && chipMouse.containsMouse && !accountMenu.visible
    }

    // ═══════════════════════════════════════════════════════════
    //  账户菜单 (下拉浮层)
    // ═══════════════════════════════════════════════════════════
    Popup {
        id: accountMenu
        y: root.height + 6
        x: root.width - width
        width: 240
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        transformOrigin: Item.TopRight   // 右对齐下拉, 缩放锚定触发钮右上角
        enter: EnterFade {}
        exit: ExitFade {}

        background: Rectangle {
            color: Theme.bg_card
            radius: 10
            border.width: 1
            border.color: Theme.border_standard
        }

        contentItem: Column {
            spacing: 0

            // ── 头部: 头像 + 邮箱 + 会员状态 ──
            Rectangle {
                width: parent.width
                height: headerCol.implicitHeight + 24
                color: "transparent"

                Column {
                    id: headerCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Row {
                        spacing: 8
                        Avatar {
                            width: 32; height: 32
                            radius: 8
                            name: root.userName
                            fontSize: 16
                            accentColor: root.pro ? Theme.purple_fg : Theme.accent_text
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: root.userName
                                color: Theme.text_primary
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 14; font.weight: Font.Bold
                            }
                            Text {
                                text: root.email
                                color: Theme.text_secondary
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: 160
                            }
                        }
                    }

                    // 会员状态条
                    Rectangle {
                        width: parent.width
                        height: 26
                        radius: 6
                        color: root.pro ? Qt.rgba(0.54, 0.34, 0.9, 0.12) : Theme.bg_input
                        border.width: 1
                        border.color: root.pro ? Theme.purple_fg : Theme.border_default

                        Text {
                            anchors.centerIn: parent
                            text: root.pro
                                  ? (root.planName || "Pro") + " · " + root.badgeTip
                                  : "免费版 · 升级解锁云漫游"
                            color: root.pro ? Theme.purple_fg : Theme.text_secondary
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 13
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border_default }

            // ── 菜单项 ──
            component MenuRow: Rectangle {
                id: menuItem
                width: parent ? parent.width : 240
                height: 34
                color: itemMouse.containsMouse ? Theme.hover_bg : "transparent"

                property string label: ""
                property string hint:  ""
                signal activated()

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: menuItem.label
                    color: Theme.text_primary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 13
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: menuItem.hint
                    color: Theme.text_secondary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { accountMenu.close(); menuItem.activated() }
                }
            }

            // 升级入口 (仅免费用户)
            Rectangle {
                visible: !root.pro
                width: parent.width
                height: visible ? 42 : 0
                color: "transparent"

                SuretyBtn {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: "升级云漫游 · 多端同步"
                    variant: "primary"
                    cornerRadius: 6
                    font.pixelSize: 13; font.weight: Font.Bold
                    onClicked: { accountMenu.close(); root.upgradeClicked("pro_monthly") }
                }
            }

            MenuRow { label: "账户管理"; hint: "›"; onActivated: root.accountClicked() }
            MenuRow { label: "我的订阅"; hint: root.pro ? root.badgeTip : "未订阅"; onActivated: root.subscriptionClicked() }
            MenuRow { label: "兑换码";   hint: "›"; onActivated: root.redeemClicked() }
            MenuRow { label: "订单记录"; hint: "›"; onActivated: root.orderClicked() }

            Rectangle { width: parent.width; height: 1; color: Theme.border_default }

            MenuRow {
                label: "退出登录"
                onActivated: root.logoutRequested()
            }

            Item { width: 1; height: 6 }
        }
    }
}
