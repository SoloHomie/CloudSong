#include "taskbarthumbservice.h"

#include <QCoreApplication>
#include <QDebug>
#include <QImage>
#include <QPixmap>
#include <windows.h>
#include <shobjidl.h>

namespace {
// 按钮 id (点击经 WM_COMMAND LOWORD(wParam) 回传; 取生僻值防与菜单等命令撞)
enum { THUMB_ID_PREV = 1001, THUMB_ID_PLAY = 1002, THUMB_ID_NEXT = 1003 };

// qrc SVG → 32×32 HICON (2026-10-02 教训: 须 QPixmap 载入且用 :/ 前缀, QIcon(qrc 串) 会当本地文件)
HICON loadIcon(const wchar_t* res)
{
    const QPixmap pm(QString::fromWCharArray(res));
    if (pm.isNull()) {
        qWarning() << "TaskbarThumb: 图标加载失败" << QString::fromWCharArray(res);
        return nullptr;
    }
    return pm.scaled(32, 32, Qt::KeepAspectRatio, Qt::SmoothTransformation)
            .toImage().toHICON();
}
}

TaskbarThumbService::TaskbarThumbService(QObject* parent)
    : QObject(parent)
{
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    const HRESULT hr = CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                                        IID_ITaskbarList3, reinterpret_cast<void**>(&m_taskbar));
    if (FAILED(hr) || !m_taskbar) {
        qWarning() << "TaskbarThumb: ITaskbarList3 创建失败" << Qt::hex << uint(hr);
        m_taskbar = nullptr;
        return;
    }
    m_iconPrev  = loadIcon(L":/qt/qml/cloudsong/qml/assets/icons/player/prev.svg");
    m_iconNext  = loadIcon(L":/qt/qml/cloudsong/qml/assets/icons/player/next.svg");
    m_iconPlay  = loadIcon(L":/qt/qml/cloudsong/qml/assets/icons/player/play.svg");
    m_iconPause = loadIcon(L":/qt/qml/cloudsong/qml/assets/icons/player/pause.svg");
    QCoreApplication::instance()->installNativeEventFilter(this);
}

TaskbarThumbService::~TaskbarThumbService()
{
    if (m_taskbar)
        m_taskbar->Release();
    freeIcons();
}

void TaskbarThumbService::freeIcons()
{
    for (HICON ic : { m_iconPrev, m_iconNext, m_iconPlay, m_iconPause })
        if (ic)
            DestroyIcon(ic);
    m_iconPrev = m_iconNext = m_iconPlay = m_iconPause = nullptr;
}

void TaskbarThumbService::setWindow(QWindow* win)
{
    if (m_win == win)
        return;
    m_win = win;
    syncButtons();
}

bool TaskbarThumbService::enabled() const { return m_enabled; }
void TaskbarThumbService::setEnabled(bool on)
{
    if (m_enabled == on)
        return;
    m_enabled = on;
    syncButtons();
    emit enabledChanged();
}

bool TaskbarThumbService::playing() const { return m_playing; }
void TaskbarThumbService::setPlaying(bool on)
{
    if (m_playing == on)
        return;
    m_playing = on;
    syncButtons();
    emit playingChanged();
}

void TaskbarThumbService::syncButtons()
{
    if (!m_taskbar)
        return;
    if (!m_attached && !m_enabled)
        return;   // 关闭状态下无需挂载
    if (!m_win)
        return;

    const HWND hwnd = reinterpret_cast<HWND>(m_win->winId());

    THUMBBUTTON btns[3] = {};
    const auto fill = [&](int idx, UINT id, HICON icon, const QString& tip) {
        btns[idx].dwMask = THB_ICON | THB_TOOLTIP | THB_FLAGS;
        btns[idx].iId = id;
        btns[idx].hIcon = icon;
        wcscpy_s(btns[idx].szTip, tip.toStdWString().c_str());
        btns[idx].dwFlags = m_enabled ? THBF_ENABLED : THBF_HIDDEN;
    };
    fill(0, THUMB_ID_PREV, m_iconPrev, QStringLiteral("上一首"));
    fill(1, THUMB_ID_PLAY, m_playing ? m_iconPause : m_iconPlay,
         m_playing ? QStringLiteral("暂停") : QStringLiteral("播放"));
    fill(2, THUMB_ID_NEXT, m_iconNext, QStringLiteral("下一首"));

    if (!m_attached) {
        if (FAILED(m_taskbar->ThumbBarAddButtons(hwnd, 3, btns))) {
            qWarning() << "TaskbarThumb: ThumbBarAddButtons 失败";
            return;
        }
        m_attached = true;
    } else {
        m_taskbar->ThumbBarUpdateButtons(hwnd, 3, btns);
    }
}

bool TaskbarThumbService::nativeEventFilter(const QByteArray&, void* message, qintptr*)
{
    const MSG* msg = static_cast<MSG*>(message);
    if (msg->message != WM_COMMAND)
        return false;
    // 只认挂载窗口回传的命令 (缩略图按钮点击 = WM_COMMAND, LOWORD(wParam)=按钮 id)
    if (!m_win || msg->hwnd != reinterpret_cast<HWND>(m_win->winId()))
        return false;
    switch (LOWORD(msg->wParam)) {
    case THUMB_ID_PREV: emit prevRequested(); return true;
    case THUMB_ID_PLAY: emit toggleRequested(); return true;
    case THUMB_ID_NEXT: emit nextRequested(); return true;
    default: return false;
    }
}
