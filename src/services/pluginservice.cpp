#include "pluginservice.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QUrl>
#include <QVariantList>

#include "pluginruntime.h"

// ═══════════════════════════════════════════════════════════════
//  PluginService 实现 — 14 方法同一条泛化链:
//   组装参数 → PluginRuntime.invoke(platform, method, args)
//   → invokeFinished/invokeFailed → 按 requestId 查回 MethodId
//   → 映射到附录A 对应信号对。
//  搜索结果的每个条目注入 platform (§4.7 聚合与 Library 键控依赖)。
// ═══════════════════════════════════════════════════════════════

PluginService::PluginService(QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    auto* runtime = PluginRuntime::instance();
    connect(runtime, &PluginRuntime::pluginsReady, this, [this](const QVariantList& plugins) {
        m_plugins.clear();
        for (const QVariant& p : plugins)
            m_plugins.append(p.toMap());
        emit pluginsLoaded();
    });
    connect(runtime, &PluginRuntime::invokeFinished, this,
            [this](int requestId, const QVariant& result) {
        const QPair<MethodId, QString> rec = m_requests.take(requestId);
        const MethodId mid = rec.first;
        const QString platform = rec.second;
        switch (mid) {
        case M_search: {
            const QVariantMap res = result.toMap();
            QVariantList data = res.value("data").toList();
            for (int i = 0; i < data.size(); i++) {
                QVariantMap item = data.at(i).toMap();
                if (item.value("platform").toString().isEmpty())
                    item.insert("platform", platform);
                data[i] = item;
            }
            emit searchFinished(requestId, res.value("isEnd").toBool(), data);
            break;
        }
        case M_getMediaSource: {
            if (!result.isValid() || result.toMap().isEmpty()) {
                emit sourceFailed(requestId, QStringLiteral("plugin.noSource"),
                                  QStringLiteral("未找到可用音源"));
            } else {
                emit sourceResolved(requestId, result.toMap());
            }
            break;
        }
        case M_getMusicInfo: {
            if (!result.isValid() || result.toMap().isEmpty())
                emit musicInfoFailed(requestId, QStringLiteral("data.empty"),
                                     QStringLiteral("未获取到歌曲信息"));
            else
                emit musicInfoFinished(requestId, result.toMap());
            break;
        }
        case M_getLyric: {
            if (!result.isValid() || result.toMap().isEmpty())
                emit lyricFailed(requestId, QStringLiteral("data.empty"),
                                 QStringLiteral("未找到歌词"));
            else
                emit lyricFetched(requestId, result.toMap());
            break;
        }
        case M_getAlbumInfo: {
            const QVariantMap res = result.toMap();
            emit albumInfoFinished(requestId, res.value("isEnd").toBool(),
                                   res.value("albumItem").toMap(),
                                   res.value("musicList").toList());
            break;
        }
        case M_getMusicSheetInfo: {
            const QVariantMap res = result.toMap();
            emit sheetInfoFinished(requestId, res.value("isEnd").toBool(),
                                   res.value("sheetItem").toMap(),
                                   res.value("musicList").toList());
            break;
        }
        case M_getArtistWorks: {
            const QVariantMap res = result.toMap();
            emit artistWorksFinished(requestId, res.value("isEnd").toBool(),
                                     res.value("data").toList());
            break;
        }
        case M_importMusicSheet: {
            const QVariantList list = result.toList();
            if (list.isEmpty() && !result.isValid())
                emit importSheetFailed(requestId, QStringLiteral("data.empty"),
                                       QStringLiteral("未导入任何歌曲"));
            else
                emit importSheetFinished(requestId, list);
            break;
        }
        case M_importMusicItem: {
            if (!result.isValid() || result.toMap().isEmpty())
                emit importItemFailed(requestId, QStringLiteral("data.empty"),
                                      QStringLiteral("未识别歌曲"));
            else
                emit importItemFinished(requestId, result.toMap());
            break;
        }
        case M_getTopLists:
            emit topListsFinished(requestId, result.toList());
            break;
        case M_getTopListDetail: {
            const QVariantMap res = result.toMap();
            emit topListDetailFinished(requestId, res.value("isEnd").toBool(),
                                       res.value("topListItem").toMap(),
                                       res.value("musicList").toList());
            break;
        }
        case M_getRecommendSheetTags: {
            const QVariantMap res = result.toMap();
            emit sheetTagsFinished(requestId, res.value("pinned").toList(),
                                   res.value("data").toList());
            break;
        }
        case M_getRecommendSheetsByTag: {
            const QVariantMap res = result.toMap();
            emit recommendSheetsFinished(requestId, res.value("isEnd").toBool(),
                                         res.value("data").toList());
            break;
        }
        case M_getMusicComments: {
            const QVariantMap res = result.toMap();
            emit commentsFinished(requestId, res.value("isEnd").toBool(),
                                  res.value("data").toList());
            break;
        }
        }
    });
    connect(runtime, &PluginRuntime::invokeFailed, this,
            [this](int requestId, const QString& code, const QString& message) {
        const MethodId mid = m_requests.take(requestId).first;
        switch (mid) {
        case M_search:               emit searchFailed(requestId, code, message); break;
        case M_getMediaSource:       emit sourceFailed(requestId, code, message); break;
        case M_getMusicInfo:         emit musicInfoFailed(requestId, code, message); break;
        case M_getLyric:             emit lyricFailed(requestId, code, message); break;
        case M_getAlbumInfo:         emit albumInfoFailed(requestId, code, message); break;
        case M_getMusicSheetInfo:    emit sheetInfoFailed(requestId, code, message); break;
        case M_getArtistWorks:       emit artistWorksFailed(requestId, code, message); break;
        case M_importMusicSheet:     emit importSheetFailed(requestId, code, message); break;
        case M_importMusicItem:      emit importItemFailed(requestId, code, message); break;
        case M_getTopLists:          emit topListsFailed(requestId, code, message); break;
        case M_getTopListDetail:     emit topListDetailFailed(requestId, code, message); break;
        case M_getRecommendSheetTags: emit sheetTagsFailed(requestId, code, message); break;
        case M_getRecommendSheetsByTag: emit recommendSheetsFailed(requestId, code, message); break;
        case M_getMusicComments:     emit commentsFailed(requestId, code, message); break;
        }
    });
}

QStringList PluginService::platforms() const
{
    QStringList out;
    for (const QVariantMap& m : m_plugins)
        out << m.value("platform").toString();
    return out;
}

QVariantList PluginService::plugins() const
{
    QVariantList out;
    for (const QVariantMap& m : m_plugins)
        out.append(m);
    return out;
}

// ── 插件管理面 (2026-10-01) ──

void PluginService::setPluginEnabled(const QString& platform, bool enabled)
{
    QStringList disabled = m_settings.value(QStringLiteral("plugins/disabled")).toStringList();
    if (enabled)
        disabled.removeAll(platform);
    else if (!disabled.contains(platform))
        disabled.append(platform);
    m_settings.setValue(QStringLiteral("plugins/disabled"), disabled);
    PluginRuntime::instance()->reload();
}

void PluginService::installPluginFromFile(const QString& filePath)
{
    // QML FileDialog 传的是 file:/// URL 字符串; 裸路径直用
    QString local = filePath;
    const QUrl asUrl(filePath);
    if (asUrl.isLocalFile()) local = asUrl.toLocalFile();
    const QFileInfo src(local);
    if (!src.exists() || src.suffix().compare(QStringLiteral("js"), Qt::CaseInsensitive) != 0) {
        emit pluginOpFinished(false, QStringLiteral("请选择 .js 插件文件"));
        return;
    }
    QDir dir(QCoreApplication::applicationDirPath() + QStringLiteral("/plugins"));
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        emit pluginOpFinished(false, QStringLiteral("plugins 目录创建失败"));
        return;
    }
    const QString dest = dir.filePath(src.fileName());
    if (QFile::exists(dest) && !QFile::remove(dest)) {
        emit pluginOpFinished(false, QStringLiteral("已存在同名文件且被占用, 覆盖失败"));
        return;
    }
    if (!QFile::copy(filePath, dest)) {
        emit pluginOpFinished(false, QStringLiteral("复制失败, 请检查磁盘权限"));
        return;
    }
    PluginRuntime::instance()->reload();
    emit pluginOpFinished(true, QStringLiteral("已安装 %1").arg(src.fileName()));
}

void PluginService::installPluginFromUrl(const QString& url)
{
    const QUrl u(url);
    if (!u.isValid() || (u.scheme() != QStringLiteral("http")
                         && u.scheme() != QStringLiteral("https"))) {
        emit pluginOpFinished(false, QStringLiteral("请输入 http/https 链接"));
        return;
    }
    // 文件名取自链接路径并消毒 (防路径注入), 要求 .js 结尾
    QString name = QUrl::fromPercentEncoding(u.fileName().toUtf8());
    name.remove(QRegularExpression(QStringLiteral("[^A-Za-z0-9._-]")));
    if (!name.endsWith(QStringLiteral(".js"), Qt::CaseInsensitive)) {
        emit pluginOpFinished(false, QStringLiteral("链接需指向 .js 文件"));
        return;
    }

    QNetworkRequest req(u);
    req.setTransferTimeout(15000);
    QNetworkReply* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, name] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit pluginOpFinished(false, QStringLiteral("下载失败: %1").arg(reply->errorString()));
            return;
        }
        const QByteArray body = reply->readAll();
        if (body.isEmpty() || !body.contains("module.exports")) {
            emit pluginOpFinished(false, QStringLiteral("内容不是有效的插件文件"));
            return;
        }
        QDir dir(QCoreApplication::applicationDirPath() + QStringLiteral("/plugins"));
        if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
            emit pluginOpFinished(false, QStringLiteral("plugins 目录创建失败"));
            return;
        }
        const QString dest = dir.filePath(name);
        if (QFile::exists(dest) && !QFile::remove(dest)) {
            emit pluginOpFinished(false, QStringLiteral("已存在同名文件且被占用, 覆盖失败"));
            return;
        }
        QFile f(dest);
        if (!f.open(QIODevice::WriteOnly) || f.write(body) != body.size()) {
            emit pluginOpFinished(false, QStringLiteral("写入失败, 请检查磁盘权限"));
            return;
        }
        f.close();
        PluginRuntime::instance()->reload();
        emit pluginOpFinished(true, QStringLiteral("已安装 %1").arg(name));
    });
}

QStringList PluginService::searchablePlatforms(const QString& type) const
{
    QStringList out;
    for (const QVariantMap& m : m_plugins)
        if (m.value("searchTypes").toStringList().contains(type))
            out << m.value("platform").toString();
    return out;
}

QVariantMap PluginService::pluginInfo(const QString& platform) const
{
    for (const QVariantMap& m : m_plugins)
        if (m.value("platform").toString() == platform)
            return m;
    return {};
}

// 显式 platform → 条目自带 platform → 插件偏好记忆 plugin.perType.<type> (§4.7)
// → "自动" = 第一个支持该类型的插件 → 兜底第一个插件
QString PluginService::resolvePlatform(const QString& typeKey, const QString& explicitPlatform) const
{
    if (!explicitPlatform.isEmpty()) return explicitPlatform;
    const QVariant remembered = m_settings.value(QStringLiteral("plugin.perType.") + typeKey);
    if (remembered.isValid() && !remembered.toString().isEmpty()) {
        for (const QVariantMap& m : m_plugins)
            if (m.value("platform").toString() == remembered.toString())
                return remembered.toString();
    }
    for (const QVariantMap& m : m_plugins)
        if (m.value("searchTypes").toStringList().contains(typeKey))
            return m.value("platform").toString();
    return m_plugins.isEmpty() ? QString() : m_plugins.first().value("platform").toString();
}

// ── 14 方法 ──

int PluginService::search(const QString& query, int page, const QString& type,
                          const QString& platform)
{
    const QString target = resolvePlatform(type, platform);
    const int id = m_seq++;
    m_requests.insert(id, { M_search, target });
    PluginRuntime::instance()->invoke(id, target, QStringLiteral("search"),
                                      { query, page, type });
    return id;
}

int PluginService::getMediaSource(const QVariantMap& musicItem, const QString& qualityKey,
                                  const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : musicItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getMediaSource, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("music"), target),
                                      QStringLiteral("getMediaSource"),
                                      { musicItem, qualityKey });
    return id;
}

int PluginService::getMusicInfo(const QVariantMap& mediaBase, const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : mediaBase.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getMusicInfo, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("music"), target),
                                      QStringLiteral("getMusicInfo"), { mediaBase });
    return id;
}

int PluginService::getLyric(const QVariantMap& musicItem, const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : musicItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getLyric, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("music"), target),
                                      QStringLiteral("getLyric"), { musicItem });
    return id;
}

int PluginService::getAlbumInfo(const QVariantMap& albumItem, int page, const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : albumItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getAlbumInfo, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("album"), target),
                                      QStringLiteral("getAlbumInfo"), { albumItem, page });
    return id;
}

int PluginService::getMusicSheetInfo(const QVariantMap& sheetItem, int page, const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : sheetItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getMusicSheetInfo, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), target),
                                      QStringLiteral("getMusicSheetInfo"), { sheetItem, page });
    return id;
}

int PluginService::getArtistWorks(const QVariantMap& artistItem, int page, const QString& type,
                                  const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : artistItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getArtistWorks, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(type, target),
                                      QStringLiteral("getArtistWorks"),
                                      { artistItem, page, type });
    return id;
}

int PluginService::importMusicSheet(const QString& urlLike, const QString& platform)
{
    const int id = m_seq++;
    m_requests.insert(id, { M_importMusicSheet, platform });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), platform),
                                      QStringLiteral("importMusicSheet"), { urlLike });
    return id;
}

int PluginService::importMusicItem(const QString& urlLike, const QString& platform)
{
    const int id = m_seq++;
    m_requests.insert(id, { M_importMusicItem, platform });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("music"), platform),
                                      QStringLiteral("importMusicItem"), { urlLike });
    return id;
}

int PluginService::getTopLists(const QString& platform)
{
    const int id = m_seq++;
    m_requests.insert(id, { M_getTopLists, platform });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), platform),
                                      QStringLiteral("getTopLists"), {});
    return id;
}

int PluginService::getTopListDetail(const QVariantMap& topListItem, int page,
                                    const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : topListItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getTopListDetail, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), target),
                                      QStringLiteral("getTopListDetail"), { topListItem, page });
    return id;
}

int PluginService::getRecommendSheetTags(const QString& platform)
{
    const int id = m_seq++;
    m_requests.insert(id, { M_getRecommendSheetTags, platform });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), platform),
                                      QStringLiteral("getRecommendSheetTags"), {});
    return id;
}

int PluginService::getRecommendSheetsByTag(const QVariantMap& tag, int page,
                                           const QString& platform)
{
    const int id = m_seq++;
    m_requests.insert(id, { M_getRecommendSheetsByTag, platform });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("sheet"), platform),
                                      QStringLiteral("getRecommendSheetsByTag"), { tag, page });
    return id;
}

int PluginService::getMusicComments(const QVariantMap& musicItem, int page,
                                    const QString& platform)
{
    const QString target = !platform.isEmpty() ? platform
                           : musicItem.value("platform").toString();
    const int id = m_seq++;
    m_requests.insert(id, { M_getMusicComments, target });
    PluginRuntime::instance()->invoke(id, resolvePlatform(QStringLiteral("music"), target),
                                      QStringLiteral("getMusicComments"), { musicItem, page });
    return id;
}
