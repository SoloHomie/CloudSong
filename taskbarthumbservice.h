#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QWindow>

struct HICON__;        // = HICON (DECLARE_HANDLE, 免在头文件引入 windows.h)
struct ITaskbarList3;  // 定义于 <shobjidl.h>, cpp 内使用完整类型

// 任务栏缩略图播控条 (2026-10-02 用户拍板"和汽水音乐一样"):
// 悬停任务栏按钮时在缩略图上方弹 上一首/播放暂停/下一首 三按钮 (ITaskbarList3 ThumbBar),
// 按钮自带悬停提示; 点击经 WM_COMMAND 回传 (prevRequested/toggleRequested/nextRequested),
// QML 转发给播放器; enabled 直连 AppCfg (设置页"任务栏播控"开关)。
class TaskbarThumbService : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool playing READ playing WRITE setPlaying NOTIFY playingChanged)
public:
    explicit TaskbarThumbService(QObject* parent = nullptr);
    ~TaskbarThumbService() override;

    // main.cpp 在窗口创建后注入 (需要 HWND 才能挂按钮)
    void setWindow(QWindow* win);

    bool enabled() const;
    void setEnabled(bool on);

    bool playing() const;
    void setPlaying(bool on);

signals:
    void prevRequested();
    void toggleRequested();
    void nextRequested();
    void enabledChanged();
    void playingChanged();

private:
    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override;
    void syncButtons();   // 首次挂载 (ThumbBarAddButtons) 或状态变化刷新 (ThumbBarUpdateButtons)
    void freeIcons();

    QWindow* m_win = nullptr;
    ITaskbarList3* m_taskbar = nullptr;
    bool m_enabled = true;
    bool m_playing = false;
    bool m_attached = false;
    HICON__* m_iconPrev = nullptr;  // HICON
    HICON__* m_iconNext = nullptr;
    HICON__* m_iconPlay = nullptr;
    HICON__* m_iconPause = nullptr;
};
