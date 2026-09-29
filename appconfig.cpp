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
