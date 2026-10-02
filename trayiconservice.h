#pragma once

#include <QObject>

class QSystemTrayIcon;

// 任务栏通知区播控图标 (2026-10-02 用户拍板: 先做按钮)
// 播放状态由 QML 播放器侧推入 (playing/title/artist), 图标随播放态切播放/暂停,
// 悬停提示=系统原生托盘 tooltip (歌名-歌手); 单击图标=播放/暂停 (toggleRequested);
// enabled 由 main.cpp 直连 AppCfg.trayEnabled (设置页开关), 关闭时图标隐藏。
class TrayIconService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool playing READ playing WRITE setPlaying NOTIFY playingChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString artist READ artist WRITE setArtist NOTIFY artistChanged)
public:
    explicit TrayIconService(QObject* parent = nullptr);

    bool enabled() const;
    void setEnabled(bool on);

    bool playing() const;
    void setPlaying(bool on);

    QString title() const;
    void setTitle(const QString& t);

    QString artist() const;
    void setArtist(const QString& a);

signals:
    void toggleRequested();
    void enabledChanged();
    void playingChanged();
    void titleChanged();
    void artistChanged();

private:
    void refresh();

    QSystemTrayIcon* m_tray = nullptr;
    bool m_enabled = true;
    bool m_playing = false;
    QString m_title;
    QString m_artist;
};
