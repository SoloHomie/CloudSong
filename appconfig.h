#pragma once

#include <QObject>
#include <QSettings>

// 应用配置单例（C++ 侧）。
// 目前只有主题模式一项，后续云漫游/播放设置等在此扩展。
// QML 通过 context property "AppCfg" 访问，Theme.qml 依赖 themeIndex。
class AppConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int themeIndex READ themeIndex WRITE setThemeIndex NOTIFY themeIndexChanged)
public:
    static AppConfig* instance();
    explicit AppConfig(QObject* parent = nullptr);

    // 主题模式：0=浅色 1=深色 2=跟随系统（默认）
    int themeIndex() const;
    void setThemeIndex(int index);

signals:
    void themeIndexChanged();

private:
    QSettings m_settings;
    int m_themeIndex = 2;
};
