#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QAbstractNativeEventFilter>
#include <QFontDatabase>
#include <QResource>
#include <windows.h>
#include <windowsx.h>
#include "appconfig.h"
#include "inputservice.h"

namespace {
// ── 无边框窗口 (BallsHackPro 同款 DWM 方法) ──
// 保留原生 WS_CAPTION/WS_THICKFRAME → 系统阴影/贴靠/缩放手感/最大化动画全保留;
// WM_NCCALCSIZE: DefWindowProc 正常收缩四边后仅恢复 top —— 标题栏区域并入客户区
// (只把上边"挤出去"), 左右下三边保留原生边框; 不用 DwmExtendFrameIntoClientArea
// (旧版全窗负边距在部分环境渲染黑边, 已废弃); 由自定义 TitleBar 接管拖拽/按钮
struct FrameFilter : QAbstractNativeEventFilter {
    bool nativeEventFilter(const QByteArray &, void *message, qintptr *result) override
    {
        MSG *msg = static_cast<MSG *>(message);

        // ── 消除标题栏但保留三边边框 (与 BallsHackPro 一致) ──
        if (msg->message == WM_NCCALCSIZE) {
            const bool maxed = IsZoomed(msg->hwnd);
            // 最大化: 客户区=显示器工作区, 防止三边边框伸出屏幕外
            auto fitWorkArea = [&](RECT &r) {
                if (!maxed) return;
                MONITORINFO mi { sizeof(mi) };
                HMONITOR mon = MonitorFromWindow(msg->hwnd, MONITOR_DEFAULTTONEAREST);
                if (GetMonitorInfo(mon, &mi)) {
                    r.top    = mi.rcWork.top;
                    r.bottom = mi.rcWork.bottom;
                    r.left   = mi.rcWork.left;
                    r.right  = mi.rcWork.right;
                }
            };
            if (msg->wParam) {
                NCCALCSIZE_PARAMS *p = reinterpret_cast<NCCALCSIZE_PARAMS *>(msg->lParam);
                LONG top = p->rgrc[0].top;
                DefWindowProc(msg->hwnd, WM_NCCALCSIZE, msg->wParam, msg->lParam);
                p->rgrc[0].top = top;
                fitWorkArea(p->rgrc[0]);
            } else {
                RECT *r = reinterpret_cast<RECT *>(msg->lParam);
                LONG top = r->top;
                DefWindowProc(msg->hwnd, WM_NCCALCSIZE, msg->wParam, msg->lParam);
                r->top = top;
                fitWorkArea(*r);
            }
            *result = 0;
            return true;
        }

        // ── 缩放手柄 (最大化时跳过, 系统全权处理) ──
        if (msg->message == WM_NCHITTEST && !IsZoomed(msg->hwnd)) {
            POINT pt { GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam) };
            RECT rc {};
            GetWindowRect(msg->hwnd, &rc);
            const int x = pt.x - rc.left;
            const int y = pt.y - rc.top;
            const int w = rc.right  - rc.left;
            const int h = rc.bottom - rc.top;

            // 手柄宽度按 DPI 缩放 (高 DPI 下 6px 太难抓, 与 BallsHackPro 一致)
            UINT dpi = 96;
            {
                static UINT (WINAPI *pfnGetDpiForWindow)(HWND) = nullptr;
                if (!pfnGetDpiForWindow)
                    pfnGetDpiForWindow = reinterpret_cast<UINT (WINAPI *)(HWND)>(
                        GetProcAddress(GetModuleHandleW(L"user32.dll"), "GetDpiForWindow"));
                if (pfnGetDpiForWindow)
                    dpi = pfnGetDpiForWindow(msg->hwnd);
            }
            const int B = qMax(4, int((6 * dpi + 48) / 96));

            LRESULT hit = 0;
            if      (x < B && y < B)          hit = HTTOPLEFT;
            else if (x > w - B && y < B)      hit = HTTOPRIGHT;
            else if (x < B && y > h - B)      hit = HTBOTTOMLEFT;
            else if (x > w - B && y > h - B)  hit = HTBOTTOMRIGHT;
            else if (x < B)                   hit = HTLEFT;
            else if (x > w - B)               hit = HTRIGHT;
            else if (y < B)                   hit = HTTOP;
            else if (y > h - B)               hit = HTBOTTOM;
            if (hit) { *result = hit; return true; }
        }
        return false;
    }
};

void applyFrameless(QQuickWindow *win)
{
    static FrameFilter filter;
    QGuiApplication::instance()->installNativeEventFilter(&filter);
    // 提前创建原生窗口 (显示前生效, 无闪帧) + 触发 NCCALCSIZE 重算, 首帧即挤掉标题栏
    HWND hwnd = reinterpret_cast<HWND>(win->winId());
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
        SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
}
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    // ── 全局 UI 字体 (2026-09-28 用户拍板 MiSans; C++ 加载, QML 只按 Theme.fontFamily 引用) ──
    // 可变字体 wght 轴不被 Qt 驱动 → 实例化 Regular/Bold 两份静态同 family, 按 usWeightClass 匹配;
    // 字体约 18MB, 内嵌 qml.qrc 会撑爆 32 位 cl 前端堆 (C1060) → 外挂 fonts.rcc
    // (PreBuildEvent rcc -binary 生成到输出目录), 运行时注册; 文件缺失则回退系统字体
    const QString rccPath = QCoreApplication::applicationDirPath() + QStringLiteral("/fonts.rcc");
    if (QResource::registerResource(rccPath)) {
        QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/qml/assets/fonts/MiSans-Regular.ttf"));
        QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/qml/assets/fonts/MiSans-Bold.ttf"));
    }
    // 全局默认字体: 未显式写 family 的组件 (Qt 内建控件等) 也走 MiSans;
    // QML 侧显式 family 由 Theme.fontFamily token 控制
    app.setFont(QFont(QStringLiteral("MiSans VF")));

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
