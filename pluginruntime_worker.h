#pragma once

#include <QByteArray>
#include <QEventLoop>
#include <QHash>
#include <QList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QPair>
#include <QStringList>
#include <QVariant>
#include <QVector>

#include "pluginruntime.h"
#include "quickjs.h"

// ═══════════════════════════════════════════════════════════════
//  PluginRuntime::Worker — 运行时线程私有执行体 (内部类, 不进 QML)
//
//  为什么是独立头文件: QtMsBuild 对 .cpp 内的 Q_OBJECT 生成的
//  moc_xxx.cpp 不包含类定义 include, 单独编译报 C2065 类未声明
//  (2026-09-30 实锤); 头文件 moc 产物自带 include, 与 appconfig.h
//  同构。实现全部在 pluginruntime.cpp。
// ═══════════════════════════════════════════════════════════════
class PluginRuntime::Worker : public QObject
{
    Q_OBJECT
public:
    struct Await { int reqId = 0; JSValue promise = JS_UNDEFINED; };

    JSRuntime* m_rt = nullptr;
    JSContext* m_ctx = nullptr;
    QNetworkAccessManager* m_nam = nullptr;
    QHash<QString, JSValue> m_modules;       // require 名 → exports (dup 持有)
    QHash<QString, JSValue> m_pluginObjs;    // platform → 插件 exports
    QVector<QVariantMap> m_pluginMeta;
    Await m_await;                           // 当前等待的 promise
    QEventLoop* m_wait = nullptr;            // 等待网络期间的嵌套循环
    QList<QPair<int, QByteArray>> m_queue;   // 排队 invoke: reqId + 打包 JSON
    int m_fetchSeq = 0;
    QHash<int, QNetworkReply*> m_replies;    // seq → reply (超时 abort 用)

    ~Worker() override;

    // ── 模块加载 (CommonJS 包装求值) ──
    JSValue loadCommonJs(const char* name, const QByteArray& src);
    QVariantMap extractMeta(const QString& file, JSValueConst obj);
    void runInvoke(int requestId, const QString& platform, const QString& method,
                   const QVariantList& args);
    // 微任务抽干 → promise 未决则嵌套循环等网络 (fetch 回调 resolve 后唤醒)
    void drainAndWait();
    void settleCurrent();
    void pumpQueue();

signals:
    void pluginsReady(const QVariantList& plugins);
    void invokeFinished(int requestId, const QVariant& result);
    void invokeFailed(int requestId, const QString& code, const QString& message);

public slots:
    void init();
    void doReload();
    void doInvoke(int requestId, const QString& platform, const QString& method,
                  const QVariantList& args);

private:
    // ── 原生 fetch 桥 (JS Promise ↔ QNAM) ──
    static JSValue jsFetch(JSContext* ctx, JSValueConst thisVal, int argc, JSValueConst* argv);
    static JSValue jsRequire(JSContext* ctx, JSValueConst thisVal, int argc, JSValueConst* argv);
    static JSValue jsConsole(JSContext* ctx, JSValueConst thisVal, int argc, JSValueConst* argv);
};
