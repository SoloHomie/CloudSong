#include "taskbarbarservice.h"

#include <QCoreApplication>
#include <QScreen>
#include <windows.h>

TaskbarBarService::TaskbarBarService(QObject* parent)
    : QObject(parent)
{
    // explorer 重启后任务栏重建 → 收到广播重新贴靠 (MusicBar 同款)
    m_taskbarCreatedMsg = RegisterWindowMessageW(L"TaskbarCreated");
    QCoreApplication::instance()->installNativeEventFilter(this);
    m_zTimer.setInterval(750);
    connect(&m_zTimer, &QTimer::timeout, this, &TaskbarBarService::keepAbove);
}

TaskbarBarService::~TaskbarBarService()
{
    m_zTimer.stop();
}

void TaskbarBarService::setBarWindow(QWindow* bar)
{
    if (m_bar == bar)
        return;
    m_bar = bar;
    dock();
}

void TaskbarBarService::setMainWindow(QWindow* main)
{
    m_main = main;
}

bool TaskbarBarService::enabled() const { return m_enabled; }
void TaskbarBarService::setEnabled(bool on)
{
    if (m_enabled == on)
        return;
    m_enabled = on;
    dock();
    emit enabledChanged();
}

void TaskbarBarService::toggleMain()
{
    if (!m_main)
        return;
    if (m_main->isVisible()) {
        m_main->hide();
    } else {
        m_main->show();
        m_main->raise();
        m_main->requestActivate();
    }
}

void TaskbarBarService::dock()
{
    if (!m_bar)
        return;
    if (!m_enabled) {
        m_bar->hide();
        m_zTimer.stop();
        return;
    }

    // MusicBar 同款定位: Shell_TrayWnd 物理矩形 × (96/dpi) 折回逻辑坐标
    const HWND tray = FindWindowW(L"Shell_TrayWnd", nullptr);
    if (tray) {
        RECT b {};
        if (GetWindowRect(tray, &b)) {
            UINT dpi = 96;
            static UINT (WINAPI* pfnGetDpiForWindow)(HWND) = nullptr;
            if (!pfnGetDpiForWindow)
                pfnGetDpiForWindow = reinterpret_cast<UINT (WINAPI*)(HWND)>(
                    GetProcAddress(GetModuleHandleW(L"user32.dll"), "GetDpiForWindow"));
            if (pfnGetDpiForWindow)
                dpi = pfnGetDpiForWindow(tray);
            const qreal s = qreal(96) / dpi;
            const qreal tw = (b.right - b.left) * s;
            const qreal th = (b.bottom - b.top) * s;
            if (tw >= th) {   // 任务栏横向: 贴顶端; 竖排则退到工作区右下 (MusicBar 同)
                m_bar->setHeight(qBound<qreal>(40, th, 64));
                m_bar->setWidth(qBound<qreal>(400, qMin<qreal>(484, tw - 16), 604));
                m_bar->setPosition(int(b.left * s) + 8, int(b.top * s));
            } else if (QScreen* scr = m_bar->screen()) {
                const QRectF wa = scr->availableGeometry();
                m_bar->setHeight(48);
                m_bar->setPosition(int(wa.left() + 8), int(wa.bottom() - 48));
            }
        }
    }

    m_bar->show();
    keepAbove();
    m_zTimer.start();
}

void TaskbarBarService::keepAbove()
{
    if (!m_bar || !m_bar->isVisible() || !m_enabled)
        return;
    const HWND hwnd = reinterpret_cast<HWND>(m_bar->winId());
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOOWNERZORDER);
}

bool TaskbarBarService::nativeEventFilter(const QByteArray&, void* message, qintptr*)
{
    const MSG* msg = static_cast<MSG*>(message);
    if (m_taskbarCreatedMsg && msg->message == m_taskbarCreatedMsg)
        dock();
    return false;
}
