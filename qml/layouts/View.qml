import QtQuick
import QtQuick.Layouts
import "../theme"

/// 内容显示区: 页面挂载点 (四大板块之一; 子项即页面, currentIndex 切换)
Rectangle {
    id: view
    color: Theme.bg_canvas

    property int currentIndex: 0
    default property alias pages: pageStack.data   // main.qml 里直接放 pages/* 作子项

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: view.currentIndex
    }
}
