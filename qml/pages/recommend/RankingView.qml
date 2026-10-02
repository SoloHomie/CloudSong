import QtQuick
import "../../theme"
import "../../mock"
import "../../components/business"
import "../../components/display"

// ═══════════════════════════════════════════════════════════════
//  RankingView — 推荐页子页面: 排行榜 (官方榜 + 更多榜单)
//  全局内容, 不参与个性化
//  2026-10-02 自 RecommendPage 拆分
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    signal navigate(string name, var params)

    // 榜单条目补 subtitle (top3 串联展示)
    property var topListItems: MockData.toplists.map(function(t) {
        return Object.assign({}, t, { subtitle: t.top3.join(" / ") })
    })

    Flickable {
        id: topFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: topCol.height + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: topCol
            width: parent.width
            spacing: 4

            Text {
                x: 24
                text: "官方榜"
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            MediaGrid {
                x: 24
                width: parent.width - 48
                height: 2 * (cellWidth + 44) - 12
                cellWidth: 160
                model: root.topListItems
                onOpenRequested: function(it) {
                    root.navigate("sheet", { kind: "toplist", id: it.id, title: it.title,
                                             seed: it.seed, platform: it.platform })
                }
            }

            Text {
                x: 24
                text: "更多榜单"
                font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                color: Theme.text_primary
            }
            Column {
                x: 24
                width: parent.width - 48
                Repeater {
                    model: MockData.toplists
                    delegate: Item {
                        width: parent.width
                        height: 44
                        property var t: modelData
                        property bool hover: rowMouse.containsMouse

                        Rectangle { anchors.fill: parent; color: hover ? Theme.hover_bg : "transparent" }
                        Text {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            width: 24
                            text: index + 1
                            horizontalAlignment: Text.AlignHCenter
                            font { family: Theme.fontFamily; pixelSize: 13; weight: Font.Bold }
                            color: index < 3 ? Theme.accent : Theme.text_hint
                        }
                        Column {
                            anchors { left: parent.left; leftMargin: 48; verticalCenter: parent.verticalCenter }
                            width: parent.width - 48 - 60
                            spacing: 2
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: t.title
                                font { family: Theme.fontFamily; pixelSize: 13 }
                                color: Theme.text_primary
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: t.top3.join(" / ")
                                font { family: Theme.fontFamily; pixelSize: 11 }
                                color: Theme.text_secondary
                            }
                        }
                        IconImage {
                            visible: hover
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            source: "qrc:/qt/qml/cloudsong/qml/assets/icons/player/play.svg"
                            color: Theme.text_primary
                            size: 14
                            MouseArea {
                                z: 1   // 行级 rowMouse 声明在后会压住本图标, 抬升 z 才能收到点击
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { MockPlayback.loadQueue(MockData.songsForSheet(t.seed, 10)) }
                            }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.navigate("sheet", { kind: "toplist", id: t.id, title: t.title,
                                                                seed: t.seed, platform: t.platform })
                        }
                    }
                }
            }
        }
    }
}
