import QtQuick
import "../theme"
import "../components/display"
import "../components/buttons"

// ═══════════════════════════════════════════════════════════════
//  ThemePage — 主题设置 (浅色/深色/跟随系统 三预设)
//  选择即时写入 AppCfg.themeIndex (Theme.qml isDark 联动)
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    PageHeader {
        id: header
        title: "主题"
        subtitle: "跟随系统由 AppCfg.themeIndex=2 驱动, 切换即时生效"
    }

    Row {
        anchors { top: header.bottom; topMargin: 8; left: parent.left; leftMargin: 24 }
        spacing: 16

        Repeater {
            model: [{ name: "浅色", desc: "明亮清爽, 适合白天" },
                    { name: "深色", desc: "暗色护眼, 适合夜间" },
                    { name: "跟随系统", desc: "随 Windows 深浅色自动切换" }]
            delegate: Rectangle {
                width: 170
                height: 150
                radius: 10
                property bool sel: index === AppCfg.themeIndex
                color: Theme.bg_card
                border { width: sel ? 2 : 1; color: sel ? Theme.accent : Theme.border_default }

                // 预览色板
                Rectangle {
                    anchors { top: parent.top; topMargin: 14; left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14 }
                    height: 70
                    radius: 6
                    color: index === 0 ? "#f6f8fa" : "#161b22"
                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Rectangle { width: 26; height: 26; radius: 5; color: index === 0 ? "#ffffff" : "#1c2128"; border { width: 1; color: index === 0 ? "#d0d7de" : "#30363d" } }
                        Rectangle { width: 26; height: 26; radius: 5; color: index === 2 ? "#6e40c9" : "#0969da" }
                        Rectangle { width: 26; height: 26; radius: 5; color: index === 2 ? "#1f6feb" : "#238636" }
                    }
                }

                Column {
                    anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 12 }
                    spacing: 2
                    Text {
                        text: modelData.name
                        font { family: "Microsoft YaHei UI"; pixelSize: 13; weight: sel ? Font.Bold : Font.Normal }
                        color: Theme.text_primary
                    }
                    Text {
                        text: modelData.desc
                        font { family: "Microsoft YaHei UI"; pixelSize: 11 }
                        color: Theme.text_secondary
                    }
                }

                // 选中勾
                Rectangle {
                    visible: sel
                    anchors { right: parent.right; rightMargin: 12; bottom: parent.bottom; bottomMargin: 14 }
                    width: 20
                    height: 20
                    radius: 10
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font { family: "Microsoft YaHei UI"; pixelSize: 12 }
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppCfg.themeIndex = index
                }
            }
        }
    }
}
