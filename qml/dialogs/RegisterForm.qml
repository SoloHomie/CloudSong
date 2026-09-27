import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components/controls"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════════════════════
//  RegisterForm — 注册表单 (校验全部走 C++ Validator 单例, QML 不写业务逻辑)
//  C++ 接线: onRegisterClicked / onSendCodeRequested / 由 AuthService 回写 countdown
// ═══════════════════════════════════════════════════════════════════════════════
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 9

    property int countdown: 0
    property bool codeSent: false
    property bool loading: false
    property alias sendingCode: sendCodeBtn.sending

    signal registerClicked(string email, string username, string password, string confirmPassword, string code)
    signal sendCodeRequested(string email)
    signal switchToLogin()

    function reset() { regEmail.text=""; regCode.text=""; regPassword.text=""; regConfirm.text="" }

    // ── 临时校验垫片 (2026-09-28): Glowling 原版调用 C++ Validator 单例, CloudSong 的
    //    C++ 侧尚在用户手中(核心逻辑分工), 先用等价函数占位让注册页可用;
    //    待 C++ Validator 落地后删掉本块, 并把下方 root.xxx 调用改回 Validator.xxx
    //    (规则与 Glowling src/system/Validator.cpp 逐条一致)
    function isValidEmail(email) {
        if (!email || email.length > 254) return false
        if (email.indexOf(" ") >= 0 || email.indexOf("\n") >= 0 || email.indexOf("\t") >= 0) return false
        return /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/.test(email)
    }
    function isValidPassword(password) {
        if (password.length < 6 || password.length > 20) return false
        if (password.indexOf(" ") >= 0) return false
        return /[A-Za-z]/.test(password) && /[0-9]/.test(password)
    }
    function passwordsMatch(a, b) { return a.length > 0 && a === b }
    function passwordStrength(password) {
        if (!password.length) return 0
        var score = 0
        if (password.length >= 8)  score++
        if (password.length >= 12) score++
        if (/[a-z]/.test(password)) score++
        if (/[A-Z]/.test(password)) score++
        if (/[0-9]/.test(password)) score++
        if (/[^A-Za-z0-9]/.test(password)) score++
        if (score <= 1) return 0
        if (score <= 3) return 1
        return 2
    }

    // ── 校验状态（全部委托给 C++ ValidationService）──
    readonly property bool _emailTouched: regEmail.text !== ""
    readonly property bool _emailFormat: _emailTouched && root.isValidEmail(regEmail.text)
    readonly property bool _codeTouched: regCode.text !== ""
    readonly property bool _codeOk: _codeTouched && regCode.text.trim().length >= 4
    readonly property bool _pwTouched: regPassword.text !== ""
    readonly property bool _pwValid: root.isValidPassword(regPassword.text)
    readonly property bool _confirmTouched: regConfirm.text !== ""
    readonly property bool _pwMatch: _confirmTouched && root.passwordsMatch(regPassword.text, regConfirm.text)
    readonly property bool _formValid: _emailFormat && _codeOk && _pwTouched && _pwValid && _pwMatch

    readonly property int _strength: root.passwordStrength(regPassword.text)
    readonly property var _strengthLabel: [qsTr("弱"), qsTr("中"), qsTr("强")]
    readonly property var _strengthColor: [Theme.danger_fg, Theme.warning_fg, Theme.success_fg]

    SuretyTextField { id: regEmail; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("请输入邮箱地址"); customBg: Theme.bg_input; customBorder: Theme.border_standard }
    Text { visible: _emailTouched && !_emailFormat; text: qsTr("· 邮箱格式不正确"); color: Theme.danger_fg; font.pixelSize: 12; font.family: "Microsoft YaHei UI" }

    RowLayout { Layout.fillWidth: true; spacing: 6
        SuretyTextField { id: regCode; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("请输入邮箱验证码"); customBg: Theme.bg_input; customBorder: Theme.border_standard }
        SendCodeButton { id: sendCodeBtn; countdown: root.countdown; onClicked: { if (!_emailFormat || sendingCode) return; root.sendingCode = true; protectTimer.restart(); root.sendCodeRequested(regEmail.text) } }
    }

    // 请求完成后（countdown 开始或变化），解除发送中状态
    onCountdownChanged: { if (countdown > 0) { sendingCode = false; protectTimer.stop() } }

    // 超时保护：15 秒后强制恢复（网络超时等异常情况）
    Timer { id: protectTimer; interval: 15000; onTriggered: { sendingCode = false } }
    Text { visible: _codeTouched && !_codeOk; text: qsTr("· 验证码至少 4 位"); color: Theme.danger_fg; font.pixelSize: 12; font.family: "Microsoft YaHei UI" }

    PasswordField { id: regPassword; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("请输入密码（6-20 位，需含字母+数字）") }

    RowLayout { visible: _pwTouched; Layout.fillWidth: true; spacing: 3
        Repeater { model: 3
            Rectangle { required property int index
                Layout.fillWidth: true; height: 3; radius: 2
                color: index <= root._strength ? root._strengthColor[root._strength] : Theme.border_default
                Behavior on color { ColorAnimation { duration: 200 } } } }
        Text { visible: _pwTouched; text: _strengthLabel[root._strength]; color: _strengthColor[root._strength]
            font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "Microsoft YaHei UI"; Layout.leftMargin: 4 }
    }

    ColumnLayout { visible: _pwTouched && !_pwValid; spacing: 2
        Repeater { model: [
            { ok: regPassword.text.indexOf(" ") < 0, msg: qsTr("· 密码不能包含空格") },
            { ok: regPassword.text.length >= 6 && regPassword.text.length <= 20, msg: qsTr("· 密码长度 6-20 位") },
            { ok: /[a-zA-Z]/.test(regPassword.text), msg: qsTr("· 需包含至少一个字母") },
            { ok: /[0-9]/.test(regPassword.text), msg: qsTr("· 需包含至少一个数字") }
        ]; delegate: Text { required property var modelData
            visible: !modelData.ok; text: modelData.msg; color: Theme.danger_fg; font.pixelSize: 12; font.family: "Microsoft YaHei UI" } }
    }

    SuretyTextField { id: regConfirm; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("请再次输入密码"); echoMode: TextInput.Password; customBg: Theme.bg_input; customBorder: Theme.border_standard }
    Text { visible: _confirmTouched && !_pwMatch; text: qsTr("· 两次输入的密码不一致"); color: Theme.danger_fg; font.pixelSize: 12; font.family: "Microsoft YaHei UI" }

    SuretyBtn { Layout.fillWidth: true; Layout.topMargin: 3; Layout.preferredHeight: 32
        text: (root.loading && _formValid) ? qsTr("注册中...") : qsTr("注册")
        variant: "primary"; enabled: _formValid && !root.loading; font.weight: Font.Bold
        onClicked: root.registerClicked(regEmail.text, regEmail.text, regPassword.text, regConfirm.text, regCode.text) }

    RowLayout { Layout.alignment: Qt.AlignHCenter; spacing: 3
        Text { text: qsTr("已有账号？"); color: Theme.text_secondary; font.pixelSize: 12; font.family: "Microsoft YaHei UI" }
        Text { text: qsTr("登录"); color: Theme.accent_text; font.pixelSize: 12; font.family: "Microsoft YaHei UI"
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.switchToLogin() } }
    }

    Text { Layout.alignment: Qt.AlignHCenter
        text: qsTr("注册即表示同意") + " <a href='#'>" + qsTr("服务条款") + "</a> " + qsTr("和") + " <a href='#'>" + qsTr("隐私政策") + "</a>"
        color: Theme.text_secondary; font.pixelSize: 12; font.family: "Microsoft YaHei UI"; textFormat: Text.RichText }
}
