#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// ═══════════════════════════════════════════════════════════════
//  RecommendService — 客户端内容推荐算法 (2026-10-02 自 QML
//  MockData.dailyMix 迁移; 用户拍板"后端推荐算法"= C++ 业务层)
//   口味画像 = 我喜欢的音乐 (liked) 的歌手/标签计数
//   打分 = liked×3 + 标签加权 + 歌手加权 + 日期盐轮换
//   (id 尾字符码 × 日号 取模: 同一天结果稳定、跨天轮换)
//   纯内存同步计算无 IO → 直接 Q_INVOKABLE 返回, 不走 requestId 异步;
//   数据源现为 Mock 目录, Library 服务落地后换真数据 (接口不变)
// ═══════════════════════════════════════════════════════════════
class RecommendService : public QObject
{
    Q_OBJECT
public:
    explicit RecommendService(QObject *parent = nullptr);

    // catalog: [{id,title,artist,album,duration,platform,liked,seed,tags}]
    // 返回 { songs: [按口味分降序], artists: [常听歌手 top3], tags: [偏好标签 top5] }
    Q_INVOKABLE QVariantMap recommendDaily(const QVariantList &catalog, int limit = 15) const;
};
