import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../theme"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════════════════════
//  AuthDialog — 登录 / 注册 / 重置密码 浮层 (居中模态, 不占页面)
//
//  ⚠ 零业务逻辑: 所有表单动作只做转发, 由 C++ AuthService 处理:
//      loginRequested / registerRequested / sendCodeRequested / resetRequested ...
//    C++ 处理后: 置 loading / 写 countdown / 成功后关窗 + 回写登录态
//
//  用法:
//    AuthDialog { id: authDialog }
//    authDialog.open()            // 默认登录页
//    authDialog.open("register")  // 直接到注册页
// ═══════════════════════════════════════════════════════════════════════════════
Popup {
    id: root

    // 模式: "login" | "register" | "reset"
    property string mode: "login"
    readonly property bool _isLogin:    mode === "login"
    readonly property bool _isRegister: mode === "register"
    readonly property bool _isReset:    mode === "reset"

    function open(m) {
        if (m !== undefined) mode = m
        visible = true
    }

    // ── 转发给 C++ AuthService 的信号 ──
    signal loginRequested(string email, string password, bool rememberMe)
    signal registerRequested(string email, string username, string password, string confirmPassword, string code)
    signal sendCodeRequested(string email)
    signal resetRequested(string email, string code, string newPassword, string confirmPassword)

    // C++ 回写的状态
    property bool loading: false
    property int  countdown: 0
    property bool rememberMe: true

    width: 380
    anchors.centerIn: Overlay.overlay
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: ModalOverlay { }

    background: Rectangle {
        color: Theme.bg_page
        radius: 12
        border.width: 1
        border.color: Theme.border_standard
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ═══ 头部: 标题 + 关闭 ═══
        Item {
            Layout.fillWidth: true
            // 标题块留白: 上 = 下 = 左 = 20 (2026-09-18 用户指定) —— 高度 = 块高 + 40
            // 无副标题的页面块高自然收缩 (2026-09-19 用户指定: 副标题不占位, 高度直接为 0);
            // smoothH + Behavior 与表单区同参数, 头部收缩也走过渡
            property real smoothH: titleCol.implicitHeight + 40
            Behavior on smoothH { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Layout.preferredHeight: smoothH

            Column {
                id: titleCol
                anchors.left: parent.left
                // 重置页左侧有返回钮, 标题让位 (其余模式保持 上=下=左=20)
                anchors.leftMargin: backBtn.visible ? 48 : 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root._isLogin ? qsTr("登录CloudSong") : root._isRegister ? qsTr("注册账号") : qsTr("重置密码")
                    color: Theme.text_primary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 16; font.weight: Font.Bold
                }
                Text {
                    // 副标题只在登录页显示; 其余模式不占位 (高度 0), 标题块随之上移
                    visible: root._isLogin
                    text: qsTr("登录后可同步存储在云上的音乐与订阅状态")
                    color: Theme.text_secondary
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                }
            }

            // 返回钮 (2026-09-19): 重置页退回登录 —— 返回是"退上一步", 放顶部左侧,
            // 与右上角关闭钮对称。注册页底部的"已有账号？登录"是横向岔路, 语义不同, 不动。
            Rectangle {
                id: backBtn
                visible: root._isReset
                width: 26; height: 26; radius: 6
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: backMouse.containsMouse ? Theme.hover_bg : "transparent"
                // 返回图标 (2026-09-19 用户指定 返回_return.svg): 48 网格 / 4 描边, 与标题栏齿轮同族。
                // 源图自带白描边 → 走 colorization 上色 (与 TitleBar 图标键同法), 悬停换色不换图
                Image {
                    anchors.centerIn: parent
                    width: 16; height: 16
                    source: "qrc:/qt/qml/cloudsong/qml/assets/icons/返回.svg"
                    sourceSize: Qt.size(32, 32)
                    fillMode: Image.PreserveAspectFit
                    smooth: true; antialiasing: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorizationColor: backMouse.containsMouse ? Theme.text_primary : Theme.text_secondary
                        colorization: 1.0
                    }
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mode = "login"
                }
            }

            // 关闭钮 — 重置页隐藏 (2026-09-19 用户指定: 流程中不直接收摊, 用 ← 返回登录;
            // 点弹窗外 / Esc 仍可关)
            Rectangle {
                visible: !root._isReset
                width: 26; height: 26; radius: 6
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: closeAuthMouse.containsMouse ? Theme.hover_bg : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeAuthMouse.containsMouse ? Theme.text_primary : Theme.text_secondary
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeAuthMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                color: Theme.border_default
            }
        }

        // ═══ 表单区 ═══
        Item {
            Layout.fillWidth: true
            // 高度只跟当前表单走 —— StackLayout 的隐式高度取三个表单的最大值 (注册最长),
            // 登录/重置时下方会空出一截 (用户 2026-09-18: "里面好像有 item 弹簧")
            // smoothH + Behavior: 模式切换时高度走过渡, 弹窗跟着平滑变高/变矮 (2026-09-18)
            property real smoothH: formStack.height + 40
            Behavior on smoothH { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Layout.preferredHeight: smoothH
            // 过渡期间裁掉尚未展开 (或正在收回) 的表单部分, 不让它溢出弹窗底
            clip: true

            StackLayout {
                id: formStack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 18
                // StackLayout 会把子项拉伸到自身高度 —— 先把自身钉在当前表单的自然高度上,
                // 子项才不会被拉长出多余空白 (注册页的校验行会随输入出现, 高度自然会变)
                height: root._isLogin ? loginForm.implicitHeight
                      : root._isRegister ? registerCol.implicitHeight
                      : resetForm.implicitHeight
                currentIndex: root._isLogin ? 0 : root._isRegister ? 1 : 2

                LoginForm {
                    id: loginForm
                    loading: root.loading
                    rememberMe: root.rememberMe
                    onLoginClicked: function(email, password, remember) {
                        root.rememberMe = remember
                        root.loginRequested(email, password, remember)
                    }
                    onForgotPassword:  root.mode = "reset"
                    onSwitchToRegister: root.mode = "register"
                }

                // 第三方登录整行已移除 (2026-09-18 用户指定: 只允许账号注册登录);
                // ThirdPartyLogin.qml 组件保留待用, 不再实例化
                ColumnLayout {
                    id: registerCol
                    spacing: 9
                    RegisterForm {
                        id: registerForm
                        loading: root.loading
                        countdown: root.countdown
                        onRegisterClicked: function(email, username, password, confirm, code) {
                            root.registerRequested(email, username, password, confirm, code)
                        }
                        onSendCodeRequested: function(email) { root.sendCodeRequested(email) }
                        onSwitchToLogin: root.mode = "login"
                    }
                }

                ResetPasswordForm {
                    id: resetForm
                    loading: root.loading
                    countdown: root.countdown
                    onResetRequested: function(email, code, newPassword, confirm) {
                        root.resetRequested(email, code, newPassword, confirm)
                    }
                    onSendCodeRequested: function(email) { root.sendCodeRequested(email) }
                }
            }
        }

    }
}
