import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components/controls"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════════════════════
//  LoginForm — 登录表单 (纯 UI, 零后端依赖)
//  C++ AuthService 就绪后: 接线 onLoginClicked / 置 loading / forgotPassword() 对接
// ═══════════════════════════════════════════════════════════════════════════════
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 10

    signal loginClicked(string email, string password, bool rememberMe)
    signal forgotPassword()
    signal switchToRegister()
    property alias rememberMe: rememberSwitch.checked
    property bool loading: false

    function clear() {
        loginEmail.text = ""
        loginPassword.text = ""
        rememberSwitch.checked = true
    }

    SuretyTextField {
        id: loginEmail
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        placeholder: qsTr("邮箱地址")
        customBg: Theme.bg_input
        customBorder: Theme.border_standard
    }

    PasswordField {
        id: loginPassword
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        placeholder: qsTr("密码")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 32

        Text {
            text: qsTr("保存登录信息")
            color: Theme.text_secondary; font.pixelSize: 12
            font.family: Theme.fontFamily
            Layout.alignment: Qt.AlignVCenter
        }
        SuretySwitch {
            id: rememberSwitch
            trackWidth: 38
            Layout.preferredHeight: 20
            checked: true  // 默认记住
        }
        Item { Layout.fillWidth: true }
        Text {
            text: qsTr("忘记密码？")
            color: Theme.accent_text; font.pixelSize: 12
            font.family: Theme.fontFamily
            Layout.alignment: Qt.AlignVCenter
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: root.forgotPassword()
            }
        }
    }

    SuretyBtn {
        Layout.fillWidth: true
        Layout.topMargin: 3
        Layout.preferredHeight: 30
        text: root.loading ? qsTr("登录中...") : qsTr("登录")
        variant: "primary"
        enabled: !root.loading
        font.pixelSize: 14; font.weight: Font.Bold
        onClicked: root.loginClicked(loginEmail.text, loginPassword.text, rememberSwitch.checked)
    }

    RowLayout { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 3; spacing: 3
        Text { text: qsTr("还没有账号？"); color: Theme.text_secondary; font.pixelSize: 12; font.family: Theme.fontFamily }
        Text { text: qsTr("去注册"); color: Theme.accent_text; font.pixelSize: 12; font.family: Theme.fontFamily
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.switchToRegister() } }
    }
}
