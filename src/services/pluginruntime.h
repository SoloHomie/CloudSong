#pragma once

#include <QObject>
#include <QThread>
#include <QVariant>

// ═══════════════════════════════════════════════════════════════
//  PluginRuntime — QuickJS-ng 插件运行时 (M0.5, 定案 §4.7)
//
//  内部类, 不暴露给 QML: 公开面只有 invoke() 与三个信号,
//  QML 永不接触 JS 值 (定案 §2.4: QuickJS 在独立线程执行)。
//
//  线程模型: Worker (QObject) 活在 m_thread, JSRuntime/JSContext 归它;
//  GUI 线程 invoke → queued 进 Worker → JS 执行 → 结果 queued 回 GUI。
//  同一时刻最多一个 invoke 在执行 (JS 单线程, 多余的排队)。
//
//  插件与白名单模块从 <exe 目录>/plugins 加载:
//    plugins/kugou.js netease.js …    (module.exports = IPluginDefine)
//    plugins/lib/*.js                 (CommonJS 白名单模块, require 解析)
// ═══════════════════════════════════════════════════════════════
class PluginRuntime : public QObject
{
    Q_OBJECT
public:
    static PluginRuntime* instance();
    explicit PluginRuntime(QObject* parent = nullptr);
    ~PluginRuntime() override;

    // GUI 线程可调 (queued 进 Worker, 结果按 requestId 配对回):
    //   platform: 插件 platform 名 (如 "酷狗"); method: 插件方法名 (如 "search")
    Q_INVOKABLE void invoke(int requestId, const QString& platform, const QString& method,
                            const QVariantList& args);

    // 重新扫描 plugins/ 目录并加载 (启动时由构造自动触发一次)
    Q_INVOKABLE void reload();

signals:
    // 加载完成后: [{platform,version,hash,srcUrl,cacheControl,
    //               methods:[], searchTypes:[], defaultSearchType, primaryKey:[]}]
    void pluginsReady(const QVariantList& plugins);
    void invokeFinished(int requestId, const QVariant& result);
    void invokeFailed(int requestId, const QString& code, const QString& message);

private:
    class Worker;  // 定义在 pluginruntime_worker.h, 实现在 pluginruntime.cpp
    QThread m_thread;
    Worker* m_worker = nullptr;
};
