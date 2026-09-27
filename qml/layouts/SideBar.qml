import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQml.Models
import "../theme"

/// ──────────────────────────────────────────────────────────
///  侧边导航 (自 BallsHackPro 移植: 福利块与硬编码导航已剥离,
///  model 属性注入; 支持 header 角色渲染分组标签)
/// ──────────────────────────────────────────────────────────
Rectangle {
    id: sideBar
    width: 160
    color: "transparent"   // 原: AppCfg.materialIndex===0 ? Theme.neutral0 : transparent (materialIndex 产品专属已剥离)

    property int selectedIndex: 0
    property var model: []   // ListModel, 角色: kind("header"=分组标签/headerText/headerBtn右侧小＋, "spacer"=弹性占位, "item"=导航项/icon/text/badge/badgeText/page(页面下标), "action"=底部操作按钮/icon/text)
    signal pageSwitchRequested(int page)
    signal createRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 5

        Repeater {
            model: sideBar.model
            delegate: DelegateChooser {
                role: "kind"
                // 分组标签
                DelegateChoice {
                    roleValue: "header"
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.bottomMargin: 1
                        height: 20
                        color: "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: headerText
                            color: Theme.text_hint
                            font { family: "Microsoft YaHei UI"; pixelSize: 12; weight: Font.Bold }
                        }
                        // 标签右侧小添加按钮 (headerBtn: true 时显示, 如"创建的歌单"; 无背景, 仅图标)
                        Rectangle {
                            visible: typeof headerBtn !== "undefined" && headerBtn
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            width: 18; height: 18
                            color: "transparent"
                            Image {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                source: "qrc:/qt/qml/cloudsong/qml/assets/icons/sidebar/add.svg"
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                layer.enabled: true   // 默认与标题同色, hover 变白
                                layer.effect: MultiEffect {
                                    colorizationColor: headerBtnMouse.containsMouse ? "#ffffff" : Theme.text_hint
                                    colorization: 1.0
                                }
                            }
                            MouseArea {
                                id: headerBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sideBar.createRequested()
                            }
                        }
                    }
                }
                // 弹性占位 (把后续项推到侧栏底部)
                DelegateChoice {
                    roleValue: "spacer"
                    Item { Layout.fillHeight: true }
                }
                // 导航项
                DelegateChoice {
                    SideBarDelegate {
                        Layout.fillWidth: true
                        iconImage: icon
                        sideText: qsTr(text)
                        isSelected: index === sideBar.selectedIndex
                        showBeta: typeof badge !== "undefined" && badge
                        badgeText: typeof badgeText !== "undefined" && badgeText !== "" ? badgeText : "BETA"
                        animatedBars: typeof animated !== "undefined" && animated
                        onClicked: { sideBar.selectedIndex = index; sideBar.pageSwitchRequested(page) }
                    }
                }
                // 底部操作按钮 (如"新建歌单")
                DelegateChoice {
                    roleValue: "action"
                    SideBarDelegate {
                        Layout.fillWidth: true
                        iconImage: icon
                        sideText: qsTr(text)
                        isSelected: false
                        showBeta: false
                        onClicked: sideBar.createRequested()
                    }
                }
            }
        }
    }
}
