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
    Q_PROPERTY(int materialIndex READ materialIndex WRITE setMaterialIndex NOTIFY materialIndexChanged)
    Q_PROPERTY(int recommendBackdropIndex READ recommendBackdropIndex WRITE setRecommendBackdropIndex NOTIFY recommendBackdropIndexChanged)
public:
    static AppConfig* instance();
    explicit AppConfig(QObject* parent = nullptr);

    // 主题模式：0=浅色 1=深色 2=跟随系统（默认）
    int themeIndex() const;
    void setThemeIndex(int index);

    // 窗口材质：0=不透明 1=云母(Mica) 2=亚克力(Acrylic)（默认不透明; DWM 挂载在 main.cpp）
    int materialIndex() const;
    void setMaterialIndex(int index);

    // 推荐页背景样式: 0=常规 1=3D粒子 2=汽水渐变(专辑封面同源色)（默认常规; 标题栏切换）
    int recommendBackdropIndex() const;
    void setRecommendBackdropIndex(int index);

signals:
    void themeIndexChanged();
    void materialIndexChanged();
    void recommendBackdropIndexChanged();

private:
    QSettings m_settings;
    int m_themeIndex = 2;
    int m_materialIndex = 0;
    int m_recommendBackdropIndex = 0;
};
