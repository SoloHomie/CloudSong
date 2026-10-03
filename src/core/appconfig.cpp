#include "appconfig.h"

AppConfig* AppConfig::instance()
{
    static AppConfig inst;
    return &inst;
}

AppConfig::AppConfig(QObject* parent)
    : QObject(parent)
    , m_settings(QStringLiteral("CloudSong"), QStringLiteral("CloudSong"))
    , m_themeIndex(m_settings.value(QStringLiteral("themeIndex"), 2).toInt())
    , m_materialIndex(m_settings.value(QStringLiteral("materialIndex"), 0).toInt())
    , m_recommendBackdropIndex(m_settings.value(QStringLiteral("recommendBackdropIndex"), 0).toInt())
    , m_taskbarPlayEnabled(m_settings.value(QStringLiteral("taskbarPlayEnabled"), true).toBool())
{
}

int AppConfig::themeIndex() const
{
    return m_themeIndex;
}

void AppConfig::setThemeIndex(int index)
{
    if (m_themeIndex == index)
        return;
    m_themeIndex = index;
    m_settings.setValue(QStringLiteral("themeIndex"), index);
    emit themeIndexChanged();
}

int AppConfig::materialIndex() const
{
    return m_materialIndex;
}

void AppConfig::setMaterialIndex(int index)
{
    if (m_materialIndex == index)
        return;
    m_materialIndex = index;
    m_settings.setValue(QStringLiteral("materialIndex"), index);
    emit materialIndexChanged();
}

int AppConfig::recommendBackdropIndex() const
{
    return m_recommendBackdropIndex;
}

void AppConfig::setRecommendBackdropIndex(int index)
{
    if (m_recommendBackdropIndex == index)
        return;
    m_recommendBackdropIndex = index;
    m_settings.setValue(QStringLiteral("recommendBackdropIndex"), index);
    emit recommendBackdropIndexChanged();
}

bool AppConfig::taskbarPlayEnabled() const
{
    return m_taskbarPlayEnabled;
}

void AppConfig::setTaskbarPlayEnabled(bool on)
{
    if (m_taskbarPlayEnabled == on)
        return;
    m_taskbarPlayEnabled = on;
    m_settings.setValue(QStringLiteral("taskbarPlayEnabled"), on);
    emit taskbarPlayEnabledChanged();
}
