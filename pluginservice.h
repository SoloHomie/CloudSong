#pragma once

#include <QObject>
#include <QSettings>
#include <QStringList>
#include <QVariantMap>
#include <QVector>
#include <QHash>

// ═══════════════════════════════════════════════════════════════
//  PluginService — 插件服务 facade (定案 §4.7, QML context "Plugins")
//
//  M0.5: 14 方法 facade 全量定死 (走 PluginRuntime 泛化 invoke),
//        首批插件实装 search/getMediaSource; 管理面 (pluginModel/
//        安装/卸载/排序) 与插件偏好设置页留 P0。
//  参数 QVariantMap 透传原则 (§2.2), requestId 异步模式 (§2.1),
//  错误码表见定案 §2.3。
// ═══════════════════════════════════════════════════════════════
class PluginRuntime;

class PluginService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY pluginsLoaded)
    Q_PROPERTY(QStringList platforms READ platforms NOTIFY pluginsLoaded)
public:
    explicit PluginService(QObject* parent = nullptr);

    bool ready() const { return !m_plugins.isEmpty(); }
    QStringList platforms() const;

    // 某搜索类型下可用的插件 platform 列表 (chip/tab 用)
    Q_INVOKABLE QStringList searchablePlatforms(const QString& type) const;
    // 插件元数据: {platform,version,hash,srcUrl,cacheControl,methods,searchTypes,defaultSearchType,primaryKey}
    Q_INVOKABLE QVariantMap pluginInfo(const QString& platform) const;

    // ── 14 方法 facade (附录A 载荷; platform 缺省 = 上次使用/首个支持者) ──
    Q_INVOKABLE int search(const QString& query, int page, const QString& type,
                           const QString& platform = {});
    Q_INVOKABLE int getMediaSource(const QVariantMap& musicItem, const QString& qualityKey,
                                   const QString& platform = {});
    Q_INVOKABLE int getMusicInfo(const QVariantMap& mediaBase, const QString& platform = {});
    Q_INVOKABLE int getLyric(const QVariantMap& musicItem, const QString& platform = {});
    Q_INVOKABLE int getAlbumInfo(const QVariantMap& albumItem, int page, const QString& platform = {});
    Q_INVOKABLE int getMusicSheetInfo(const QVariantMap& sheetItem, int page, const QString& platform = {});
    Q_INVOKABLE int getArtistWorks(const QVariantMap& artistItem, int page, const QString& type,
                                   const QString& platform = {});
    Q_INVOKABLE int importMusicSheet(const QString& urlLike, const QString& platform = {});
    Q_INVOKABLE int importMusicItem(const QString& urlLike, const QString& platform = {});
    Q_INVOKABLE int getTopLists(const QString& platform = {});
    Q_INVOKABLE int getTopListDetail(const QVariantMap& topListItem, int page,
                                     const QString& platform = {});
    Q_INVOKABLE int getRecommendSheetTags(const QString& platform = {});
    Q_INVOKABLE int getRecommendSheetsByTag(const QVariantMap& tag, int page,
                                            const QString& platform = {});
    Q_INVOKABLE int getMusicComments(const QVariantMap& musicItem, int page,
                                     const QString& platform = {});

signals:
    void pluginsLoaded();
    // 每对 finished/failed 与定案附录A 一一对应
    void searchFinished(int requestId, bool isEnd, QVariantList data);
    void searchFailed(int requestId, const QString& code, const QString& message);
    void sourceResolved(int requestId, QVariantMap source);
    void sourceFailed(int requestId, const QString& code, const QString& message);
    void musicInfoFinished(int requestId, QVariantMap info);
    void musicInfoFailed(int requestId, const QString& code, const QString& message);
    void lyricFetched(int requestId, QVariantMap lyric);
    void lyricFailed(int requestId, const QString& code, const QString& message);
    void albumInfoFinished(int requestId, bool isEnd, QVariantMap albumItem, QVariantList musicList);
    void albumInfoFailed(int requestId, const QString& code, const QString& message);
    void sheetInfoFinished(int requestId, bool isEnd, QVariantMap sheetItem, QVariantList musicList);
    void sheetInfoFailed(int requestId, const QString& code, const QString& message);
    void artistWorksFinished(int requestId, bool isEnd, QVariantList data);
    void artistWorksFailed(int requestId, const QString& code, const QString& message);
    void importSheetFinished(int requestId, QVariantList musicList);
    void importSheetFailed(int requestId, const QString& code, const QString& message);
    void importItemFinished(int requestId, QVariantMap item);
    void importItemFailed(int requestId, const QString& code, const QString& message);
    void topListsFinished(int requestId, QVariantList data);
    void topListsFailed(int requestId, const QString& code, const QString& message);
    void topListDetailFinished(int requestId, bool isEnd, QVariantMap topListItem, QVariantList musicList);
    void topListDetailFailed(int requestId, const QString& code, const QString& message);
    void sheetTagsFinished(int requestId, QVariantList pinned, QVariantList groups);
    void sheetTagsFailed(int requestId, const QString& code, const QString& message);
    void recommendSheetsFinished(int requestId, bool isEnd, QVariantList data);
    void recommendSheetsFailed(int requestId, const QString& code, const QString& message);
    void commentsFinished(int requestId, bool isEnd, QVariantList data);
    void commentsFailed(int requestId, const QString& code, const QString& message);

private:
    enum MethodId {
        M_search, M_getMediaSource, M_getMusicInfo, M_getLyric, M_getAlbumInfo,
        M_getMusicSheetInfo, M_getArtistWorks, M_importMusicSheet, M_importMusicItem,
        M_getTopLists, M_getTopListDetail, M_getRecommendSheetTags,
        M_getRecommendSheetsByTag, M_getMusicComments
    };
    QString resolvePlatform(const QString& typeKey, const QString& explicitPlatform) const;

    QVector<QVariantMap> m_plugins;   // 与 PluginRuntime 元数据同步 (pluginsReady)
    QSettings m_settings;
    int m_seq = 1;
    QHash<int, QPair<MethodId, QString>> m_requests;  // requestId → (方法, platform)
};
