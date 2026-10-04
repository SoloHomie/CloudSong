import QtQuick
import "../../components/display"
import "../../components/controls"

// ═══════════════════════════════════════════════════════════════
//  SettingsPage — 设置页外壳 (上侧分类栏 + 分类子页面容器)
//
//  2026-09-28 重做: 原单列全分组改为顶部分段分类栏(服务/通用/播放/
//  下载/数据/插件/关于), 内容区最大宽度 680 居中, 独立滚动;
//  分组标题由分类栏承担, 内容不再重复显示组标题
//  2026-10-02 拆分: 原单文件 589 行按分类拆为 qml/pages/settings/
//  七子页面, 行组件提取为同目录 SettingRow; 本页只剩页头+分类栏+
//  子页容器。各子页独立 Flickable, 切换分类保留各自滚动位置与折叠状态
//  2026-10-04 懒加载: 子页首访才实例化(Loader active), 之后常驻保留状态
//  持久化待接 C++ ConfigService; 当前仅内存态
// ═══════════════════════════════════════════════════════════════
Item {
    id: root
    property var params: ({})
    signal navigate(string name, var params)

    property int catIdx: 0                // 0服务 1通用 2播放 3下载 4数据 5插件 6关于

    // ── 页头 ──
    PageHeader {
        id: pageHead
        anchors { top: parent.top; left: parent.left; right: parent.right }
        title: "设置"
        subtitle: "所有设置仅保存在本地"
    }

    // ── 顶部分类栏 (2026-09-28 换 CategoryBar tab 下划线导航; 分段控件语义=值选择,
    //    分类栏语义=视图切换, 不再复用 SuretyTagSelector) ──
    CategoryBar {
        id: catBar
        anchors { top: pageHead.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
        selectedIndex: root.catIdx
        model: [
            { label: "服务" }, { label: "通用" }, { label: "播放" },
            { label: "下载" }, { label: "数据" }, { label: "插件" }, { label: "关于" }
        ]
        onTagSelected: function(i) { root.catIdx = i }
    }

    // ── 内容区: 七分类子页面 (qml/pages/settings/), 仅当前分类可见 ──
    //  懒加载: active 随首访置真, item 常驻后不再卸载 → 首次切换时才实例化,
    //  滚动位置与折叠状态保留; visible 单独控制显隐
    Item {
        id: contentHost
        anchors { top: catBar.bottom; topMargin: 18; left: parent.left; right: parent.right; bottom: parent.bottom }

        Loader {
            anchors.fill: parent
            visible: root.catIdx === 0
            active: root.catIdx === 0 || item !== null
            sourceComponent: serviceComp
            onLoaded: root.wireNav(item)
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 1
            active: root.catIdx === 1 || item !== null
            sourceComponent: generalComp
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 2
            active: root.catIdx === 2 || item !== null
            sourceComponent: playbackComp
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 3
            active: root.catIdx === 3 || item !== null
            sourceComponent: downloadComp
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 4
            active: root.catIdx === 4 || item !== null
            sourceComponent: dataComp
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 5
            active: root.catIdx === 5 || item !== null
            sourceComponent: pluginComp
        }
        Loader {
            anchors.fill: parent
            visible: root.catIdx === 6
            active: root.catIdx === 6 || item !== null
            sourceComponent: aboutComp
        }
    }

    // 子页 navigate 接线 (参数无类型 → qmllint 不查成员, 与 PageSwitch pageLoaded(var) 同法)
    function wireNav(it) { it.navigate.connect(function(name, params) { root.navigate(name, params) }) }

    // ── 子页面组件源 (懒加载用) ──
    Component { id: serviceComp;  ServiceSettings {} }
    Component { id: generalComp;  GeneralSettings {} }
    Component { id: playbackComp; PlaybackSettings {} }
    Component { id: downloadComp; DownloadSettings {} }
    Component { id: dataComp;     DataSettings {} }
    Component { id: pluginComp;   PluginSettings {} }
    Component { id: aboutComp;    AboutSettings {} }
}
