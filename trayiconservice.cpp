#include "trayiconservice.h"

#include <QDebug>
#include <QIcon>
#include <QPixmap>
#include <QSystemTrayIcon>

namespace {
// 播放条同族图标 (白填充, 深色任务栏可见)。
// 须经 QPixmap 载入 qrc SVG: QIcon(qrc 路径字符串) 会把路径当本地文件交给
// svg 图标引擎打开 → "Cannot open file" (2026-10-02 实测)
QIcon trayIcon(bool playing)
{
    const QString path = playing
        ? QStringLiteral(":/qt/qml/cloudsong/qml/assets/icons/player/pause.svg")
        : QStringLiteral(":/qt/qml/cloudsong/qml/assets/icons/player/play.svg");
    const QPixmap pm(path);
    if (pm.isNull())
        qWarning() << "TrayIconService: 托盘图标加载失败" << path;
    return QIcon(pm);
}
}

TrayIconService::TrayIconService(QObject* parent)
    : QObject(parent)
    , m_tray(new QSystemTrayIcon(trayIcon(m_playing), this))
{
    connect(m_tray, &QSystemTrayIcon::activated, this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                // Trigger=Windows 左键单击 (双击=DoubleClick 暂不区分, 同为切换)
                if (reason == QSystemTrayIcon::Trigger)
                    emit toggleRequested();
            });
    if (!QSystemTrayIcon::isSystemTrayAvailable())
        qWarning() << "TrayIconService: 系统托盘不可用, 播控图标不显示";
    refresh();
}

bool TrayIconService::enabled() const { return m_enabled; }
void TrayIconService::setEnabled(bool on)
{
    if (m_enabled == on)
        return;
    m_enabled = on;
    refresh();
    emit enabledChanged();
}

bool TrayIconService::playing() const { return m_playing; }
void TrayIconService::setPlaying(bool on)
{
    if (m_playing == on)
        return;
    m_playing = on;
    m_tray->setIcon(trayIcon(m_playing));
    emit playingChanged();
}

QString TrayIconService::title() const { return m_title; }
void TrayIconService::setTitle(const QString& t)
{
    if (m_title == t)
        return;
    m_title = t;
    refresh();
    emit titleChanged();
}

QString TrayIconService::artist() const { return m_artist; }
void TrayIconService::setArtist(const QString& a)
{
    if (m_artist == a)
        return;
    m_artist = a;
    refresh();
    emit artistChanged();
}

void TrayIconService::refresh()
{
    m_tray->setVisible(m_enabled);
    m_tray->setToolTip(m_title.isEmpty()
        ? QStringLiteral("CloudSong")
        : m_artist.isEmpty()
            ? QStringLiteral("CloudSong · %1").arg(m_title)
            : QStringLiteral("CloudSong · %1 - %2").arg(m_title, m_artist));
}
