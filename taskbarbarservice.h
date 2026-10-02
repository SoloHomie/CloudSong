#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QTimer>
#include <QWindow>

// 任务栏播控条 (2026-10-02 用户拍板 MusicBar 同款): 独立无边框置顶小窗贴靠任务栏顶端,
// 常驻显示 封面/歌名·歌手 + 上一首/播放/下一首; 双击信息区=展开/收起主窗口 (MusicBar 行为);
// 设置页"任务栏播控"开关 (AppCfg.taskbarPlayEnabled) 显隐;
// 窗口管理 (贴靠/置顶/explorer 重启重贴/显隐/双击开关) 全在 C++, QML 只画 UI。
class TaskbarBarService : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
public:
    explicit TaskbarBarService(QObject* parent = nullptr);
    ~TaskbarBarService() override;

    void setBarWindow(QWindow* bar);    // main.cpp: 播控条窗口注入
    void setMainWindow(QWindow* main);  // main.cpp: 主窗口注入 (双击展开/收起目标)

    bool enabled() const;
    void setEnabled(bool on);

    Q_INVOKABLE void toggleMain();      // 双击信息区: 展开/收起主窗口

signals:
    void enabledChanged();

private:
    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override;
    void dock();                        // 贴靠任务栏 (Shell_TrayWnd; 任务栏竖排时退到工作区右下)
    void keepAbove();                   // 定时重断言 HWND_TOPMOST (MusicBar 同款防降级)

    QWindow* m_bar = nullptr;
    QWindow* m_main = nullptr;
    QTimer m_zTimer;
    unsigned int m_taskbarCreatedMsg = 0;   // RegisterWindowMessage 结果
    bool m_enabled = true;
};
