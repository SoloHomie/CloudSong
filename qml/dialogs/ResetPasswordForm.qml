import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components/controls"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════════════════════
//  ResetPasswordForm — 忘记密码 / 重置密码 (纯 UI)
// ═══════════════════════════════════════════════════════════════════════════════
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 9

    property int countdown: 0
    property bool codeSent: false
    property bool loading: false
    property alias sendingCode: sendCodeBtn.sending

    signal resetRequested(string email, string code, string newPassword, string confirmPassword)
    signal sendCodeRequested(string email)

    function clear() { resetEmail.text=""; resetCode.text=""; resetNewPassword.text=""; resetConfirm.text="" }

    Text { text: qsTr("请输入您的邮箱，获取验证码后即可在本页面重置密码。")
        color: Theme.text_secondary; font.pixelSize: 12; font.family: "Microsoft YaHei UI"
        wrapMode: Text.WordWrap; Layout.fillWidth: true }

    SuretyTextField { id: resetEmail; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("邮箱地址"); customBg: Theme.bg_input; customBorder: Theme.border_standard }

    RowLayout { Layout.fillWidth: true; spacing: 6
        SuretyTextField { id: resetCode; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("请输入验证码"); customBg: Theme.bg_input; customBorder: Theme.border_standard }
        SendCodeButton { id: sendCodeBtn; countdown: root.countdown; onClicked: { if (sendingCode) return; root.sendingCode = true; protectTimer.restart(); root.sendCodeRequested(resetEmail.text) } }
    }

    // 请求完成后（countdown 开始或变化），解除发送中状态
    onCountdownChanged: { if (countdown > 0) { sendingCode = false; protectTimer.stop() } }

    // 超时保护：15 秒后强制恢复（网络超时等异常情况）
    Timer { id: protectTimer; interval: 15000; onTriggered: { sendingCode = false } }

    PasswordField { id: resetNewPassword; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("新密码（6-20 位，需含字母+数字）") }
    SuretyTextField { id: resetConfirm; Layout.fillWidth: true; Layout.preferredHeight: 36; placeholder: qsTr("确认新密码"); echoMode: TextInput.Password; customBg: Theme.bg_input; customBorder: Theme.border_standard }

    SuretyBtn { Layout.fillWidth: true; Layout.topMargin: 3; Layout.preferredHeight: 32
        text: root.loading ? qsTr("重置中...") : qsTr("重置密码")
        variant: "primary"; enabled: !root.loading; font.weight: Font.Bold
        onClicked: root.resetRequested(resetEmail.text, resetCode.text, resetNewPassword.text, resetConfirm.text) }
}
