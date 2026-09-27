#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QAbstractNativeEventFilter>
#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>
#include "appconfig.h"
#include "inputservice.h"

#pragma comment(lib, "Dwmapi.lib")

namespace {
// ── 无边框窗口 (FramelessWindowHint 的替代方案) ──
// 保留原生 WS_CAPTION/WS_THICKFRAME → 系统阴影/贴靠/任务栏缩略图/最大化动画/边缘 resize 全保留;
// WM_NCCALCSIZE 让客户区铺满整窗, DWM 负边距把系统标题栏向上挤出可视区, 由自定义 TitleBar 接管
struct FrameFilter : QAbstractNativeEventFilter {
    bool nativeEventFilter(const QByteArray &, void *message, qintptr *result) override
    {
        MSG *msg = static_cast<MSG *>(message);
        if (msg->message == WM_NCCALCSIZE && msg->wParam) {
            *result = 0;   // 客户区 = 整个窗口, 不再为系统标题栏/边框预留
            return true;
        }
        if (msg->message == WM_NCHITTEST) {
            // 客户区铺满后边缘 resize 条被覆盖, 四边+四角 6px 手动映射回 resize 命中区
            POINT pt { GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam) };
            RECT rc {};
            GetWindowRect(msg->hwnd, &rc);
            const int m = 6;
            bool left   = pt.x >= rc.left        && pt.x < rc.left + m;
            bool right  = pt.x >= rc.right - m   && pt.x < rc.right;
            bool top    = pt.y >= rc.top         && pt.y < rc.top + m;
            bool bottom = pt.y >= rc.bottom - m  && pt.y < rc.bottom;
            LRESULT hit = 0;
            if (top && left)          hit = HTTOPLEFT;
            else if (top && right)    hit = HTTOPRIGHT;
            else if (bottom && left)  hit = HTBOTTOMLEFT;
            else if (bottom && right) hit = HTBOTTOMRIGHT;
            else if (top)             hit = HTTOP;
            else if (bottom)          hit = HTBOTTOM;
            else if (left)            hit = HTLEFT;
            else if (right)           hit = HTRIGHT;
            if (hit) { *result = hit; return true; }
        }
        return false;
    }
};

void applyFrameless(QQuickWindow *win)
{
    static FrameFilter filter;
    QGuiApplication::instance()->installNativeEventFilter(&filter);
    HWND hwnd = reinterpret_cast<HWND>(win->winId());   // 提前创建原生窗口 (显示前生效, 无闪帧)
    MARGINS margins { -1, -1, -1, -1 };                 // 负边距: 框架(含标题栏)整体挤出窗口可视范围
    DwmExtendFrameIntoClientArea(hwnd, &margins);
}
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("AppCfg", AppConfig::instance());
    engine.rootContext()->setContextProperty("Input", new InputService(&app));
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/cloudsong/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    // 无边框窗口: QML 侧 visible:false, C++ 应用 DWM 挤出后统一显示
    QQuickWindow *win = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
    if (win) {
        applyFrameless(win);
        win->show();
    }

    return app.exec();
}
