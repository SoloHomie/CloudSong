#include "recommendservice.h"

#include <QDate>
#include <QHash>
#include <QStringList>

#include <algorithm>
#include <utility>
#include <vector>

RecommendService::RecommendService(QObject *parent)
    : QObject(parent)
{
}

QVariantMap RecommendService::recommendDaily(const QVariantList &catalog, int limit) const
{
    // ── 口味画像: 仅统计 liked 歌曲的歌手/标签次数 ──
    QHash<QString, int> artistCount;
    QHash<QString, int> tagCount;
    for (const QVariant &v : catalog) {
        const QVariantMap s = v.toMap();
        if (!s.value(QStringLiteral("liked")).toBool())
            continue;
        artistCount[s.value(QStringLiteral("artist")).toString()] += 1;
        const QVariantList tags = s.value(QStringLiteral("tags")).toList();
        for (const QVariant &t : tags)
            tagCount[t.toString()] += 1;
    }

    // ── 打分排序 (同分保持目录序, 稳定排序) ──
    const int day = QDate::currentDate().day();
    struct Scored { QVariantMap song; int score; };
    std::vector<Scored> pool;
    pool.reserve(catalog.size());
    for (const QVariant &v : catalog) {
        const QVariantMap s = v.toMap();
        int score = s.value(QStringLiteral("liked")).toBool() ? 3 : 0;
        const QVariantList tags = s.value(QStringLiteral("tags")).toList();
        for (const QVariant &t : tags)
            score += tagCount.value(t.toString(), 0);
        score += artistCount.value(s.value(QStringLiteral("artist")).toString(), 0);
        const QString id = s.value(QStringLiteral("id")).toString();
        if (!id.isEmpty())
            score += (id.back().unicode() * day) % 5;
        pool.push_back({ s, score });
    }
    std::stable_sort(pool.begin(), pool.end(),
                     [](const Scored &a, const Scored &b) { return a.score > b.score; });

    QVariantList songs;
    const int take = std::min<int>(limit > 0 ? limit : 15, int(pool.size()));
    for (int i = 0; i < take; ++i)
        songs.append(pool[i].song);

    // ── 画像可见化: 常听歌手 top3 / 偏好标签 top5 (次数降序, 同分按名) ──
    auto topOf = [](const QHash<QString, int> &counts, int n) {
        std::vector<std::pair<int, QString>> arr;
        arr.reserve(counts.size());
        for (auto it = counts.cbegin(); it != counts.cend(); ++it)
            arr.emplace_back(it.value(), it.key());
        std::stable_sort(arr.begin(), arr.end(), [](const auto &a, const auto &b) {
            return a.first != b.first ? a.first > b.first : a.second < b.second;
        });
        QStringList out;
        for (int i = 0; i < n && i < int(arr.size()); ++i)
            out.append(arr[i].second);
        return out;
    };

    QVariantMap result;
    result.insert(QStringLiteral("songs"), songs);
    result.insert(QStringLiteral("artists"), topOf(artistCount, 3));
    result.insert(QStringLiteral("tags"), topOf(tagCount, 5));
    return result;
}
