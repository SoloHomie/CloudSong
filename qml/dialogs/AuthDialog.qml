import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"
import "../components/overlay"

// ═══════════════════════════════════════════════════════════════════════════════
//  AuthDialog — 登录 / 注册 / 重置密码 浮层 (统一窗体 DialogShell, 仅内容不同)
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
DialogShell {
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

    // ── 窗体头部 ──
    title: root._isLogin ? qsTr("登录CloudSong") : root._isRegister ? qsTr("注册账号") : qsTr("重置密码")
    // 副标题只在登录页显示; 其余模式空串 → 不占位, 标题块随之上移 (2026-09-19 用户指定)
    subtitle: root._isLogin ? qsTr("登录后可同步存储在云上的音乐与订阅状态") : ""
    // 重置页隐藏关闭钮 (2026-09-19 用户指定: 流程中不直接收摊, 用 ← 返回登录; 点弹窗外 / Esc 仍可关)
    showClose: !root._isReset

    // 返回钮 (2026-09-19): 重置页退回登录 —— 返回是"退上一步", 放顶部左侧,
    // 与右上角关闭钮对称。注册页底部的"已有账号？登录"是横向岔路, 语义不同, 不动。
    headerLeft: Component {
        Rectangle {
            visible: root._isReset
            width: 26; height: 26; radius: 6
            color: backMouse.containsMouse ? Theme.hover_bg : "transparent"
            // 返回图标 (2026-09-19 用户指定 返回_return.svg): 48 网格 / 4 描边, 与标题栏齿轮同族。
            // 源图自带白描边 → 走 colorization 上色 (与 TitleBar 图标键同法), 悬停换色不换图
            Image {
                anchors.centerIn: parent
                width: 16; height: 16
                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/back.svg"
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
    }

    // ── 表单区 ──
    // 经壳的 content Loader 注入, Layout 附加属性不生效 → 用 implicitHeight 驱动窗体高度。
    // 高度只跟当前表单走 —— StackLayout 的隐式高度取三个表单的最大值 (注册最长),
    // 须把自身钉在当前表单自然高度上; smoothH + Behavior: 模式切换时高度走过渡,
    // 弹窗跟着平滑变高/变矮 (2026-09-18 用户指定)
    content: Component {
        Item {
            implicitHeight: smoothH
            property real smoothH: formStack.height + 40
            Behavior on smoothH { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
