#include "pluginruntime.h"
#include "pluginruntime_worker.h"

#include <QCoreApplication>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QJsonDocument>
#include <QJsonValue>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QTimer>
#include <QDebug>
#include <vector>

// ═══════════════════════════════════════════════════════════════
//  PluginRuntime 实现 — QuickJS-ng 独立线程运行时 (定案 §4.7)
//
//  要点:
//  - Worker 活在 m_thread, JSRuntime/JSContext/QNAM 全部归线程所有
//  - 插件 = CommonJS 包装求值: (function(module, exports, require){…})
//  - 白名单模块 = plugins/lib/*.js 同款包装, require(name) 查注册表
//  - 原生 fetch C 桥: JS Promise ↔ QNAM; 网络回来 resolve 后唤醒等待循环
//  - 同一时刻只跑一个 invoke (JS 单线程), 其余排队 (m_queue)
//  - Worker 声明在 pluginruntime_worker.h (QtMsBuild 不支持 cpp 内 Q_OBJECT)
// ═══════════════════════════════════════════════════════════════

namespace {

// ── JS 值 ↔ Qt 值 (JSON 编解码, 定案 §2.2 透传原则) ──

QByteArray jsToUtf8(JSContext* ctx, JSValueConst v)
{
    size_t len = 0;
    const char* s = JS_ToCStringLen(ctx, &len, v);
    QByteArray out(s ? QByteArray(s, int(len)) : QByteArray());
    if (s) JS_FreeCString(ctx, s);
    return out;
}

QString jsExceptionMessage(JSContext* ctx)
{
    JSValue ex = JS_GetException(ctx);
    QString msg = QString::fromUtf8(jsToUtf8(ctx, ex));
    JS_FreeValue(ctx, ex);
    return msg;
}

QVariant jsToVariant(JSContext* ctx, JSValueConst v)
{
    if (JS_IsUndefined(v) || JS_IsNull(v)) return QVariant();
    QVariant out;
    JSValue json = JS_JSONStringify(ctx, v, JS_NULL, JS_NULL);
    if (!JS_IsException(json)) {
        const QByteArray bytes = jsToUtf8(ctx, json);
        out = QJsonDocument::fromJson(bytes).toVariant();
    }
    JS_FreeValue(ctx, json);
    return out;
}

JSValue variantToJs(JSContext* ctx, const QVariant& v)
{
    const QByteArray json = QJsonDocument::fromVariant(v).toJson(QJsonDocument::Compact);
    return JS_ParseJSON(ctx, json.constData(), json.size(), "<variant>");
}

QByteArray propStr(JSContext* ctx, JSValueConst obj, const char* key)
{
    JSValue v = JS_GetPropertyStr(ctx, obj, key);
    QByteArray out = JS_IsUndefined(v) ? QByteArray() : jsToUtf8(ctx, v);
    JS_FreeValue(ctx, v);
    return out;
}

QStringList propStringArray(JSContext* ctx, JSValueConst obj, const char* key)
{
    QStringList out;
    JSValue v = JS_GetPropertyStr(ctx, obj, key);
    if (JS_IsArray(v)) {
        int64_t len = 0;
        JS_GetLength(ctx, v, &len);
        for (int64_t i = 0; i < len; i++) {
            JSValue e = JS_GetPropertyUint32(ctx, v, uint32_t(i));
            out << QString::fromUtf8(jsToUtf8(ctx, e));
            JS_FreeValue(ctx, e);
        }
    }
    JS_FreeValue(ctx, v);
    return out;
}

} // namespace

// ── Worker 实现 (线程私有, 声明见 pluginruntime_worker.h) ──

PluginRuntime::Worker::~Worker()
{
    if (!m_ctx) return;
    for (JSValue v : std::as_const(m_modules)) JS_FreeValue(m_ctx, v);
    for (JSValue v : std::as_const(m_pluginObjs)) JS_FreeValue(m_ctx, v);
    if (!JS_IsUndefined(m_await.promise)) JS_FreeValue(m_ctx, m_await.promise);
    JS_FreeContext(m_ctx);
    JS_FreeRuntime(m_rt);
}

JSValue PluginRuntime::Worker::loadCommonJs(const char* name, const QByteArray& src, bool amd)
{
    QByteArray pre;
    if (amd)
        pre = "var define = function(deps, factory) {"
              "  var args = deps.map(function(d) {"
              "    return d === 'exports' ? module.exports : undefined; });"
              "  factory.apply(null, args);"
              "};\n";
    const QByteArray wrapped = "(function(module, exports, require, __filename) {\n" + pre + src + "\n})";
    JSValue fn = JS_Eval(m_ctx, wrapped.constData(), wrapped.size(), name, JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(fn)) {
        qWarning() << "[PluginRuntime] 模块求值失败" << name << jsExceptionMessage(m_ctx);
        JS_FreeValue(m_ctx, fn);
        return JS_UNDEFINED;
    }
    JSValue global = JS_GetGlobalObject(m_ctx);
    JSValue requireFn = JS_GetPropertyStr(m_ctx, global, "__require");
    JS_FreeValue(m_ctx, global);

    JSValue moduleObj = JS_NewObject(m_ctx);
    JSValue exportsObj = JS_NewObject(m_ctx);
    JS_SetPropertyStr(m_ctx, moduleObj, "exports", JS_DupValue(m_ctx, exportsObj));
    JSValue argv[4] = { moduleObj, JS_DupValue(m_ctx, exportsObj), requireFn,
                        JS_NewString(m_ctx, name) };
    JSValue ret = JS_Call(m_ctx, fn, JS_UNDEFINED, 4, argv);
    JS_FreeValue(m_ctx, argv[1]);
    JS_FreeValue(m_ctx, argv[2]);
    JS_FreeValue(m_ctx, argv[3]);
    JS_FreeValue(m_ctx, fn);
    JS_FreeValue(m_ctx, exportsObj);
    if (JS_IsException(ret)) {
        qWarning() << "[PluginRuntime] 模块执行失败" << name << jsExceptionMessage(m_ctx);
        JS_FreeValue(m_ctx, ret);
        JS_FreeValue(m_ctx, moduleObj);
        return JS_UNDEFINED;
    }
    JS_FreeValue(m_ctx, ret);
    JSValue result = JS_GetPropertyStr(m_ctx, moduleObj, "exports");
    JS_FreeValue(m_ctx, moduleObj);
    return result; // 调用方登记时 dup, 不再需要则 free
}

QVariantMap PluginRuntime::Worker::extractMeta(const QString& file, JSValueConst obj)
{
    QVariantMap m;
    m["platform"] = QString::fromUtf8(propStr(m_ctx, obj, "platform"));
    m["version"]  = QString::fromUtf8(propStr(m_ctx, obj, "version"));
    m["srcUrl"]   = QString::fromUtf8(propStr(m_ctx, obj, "srcUrl"));
    m["cacheControl"] = QString::fromUtf8(propStr(m_ctx, obj, "cacheControl"));
    m["hash"] = QStringLiteral("local:") + file;
    m["primaryKey"] = propStringArray(m_ctx, obj, "primaryKey");
    QStringList searchTypes = propStringArray(m_ctx, obj, "supportedSearchType");
    if (searchTypes.isEmpty()) searchTypes << QStringLiteral("music");
    m["searchTypes"] = searchTypes;
    QByteArray def = propStr(m_ctx, obj, "defaultSearchType");
    m["defaultSearchType"] = def.isEmpty() ? QStringLiteral("music") : QString::fromUtf8(def);
    // 可调方法 = 导出对象上所有函数成员
    QStringList methods;
    JSPropertyEnum* tab = nullptr;
    uint32_t len = 0;
    if (JS_GetOwnPropertyNames(m_ctx, &tab, &len, obj,
                               JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
        for (uint32_t i = 0; i < len; i++) {
            const char* key = JS_AtomToCString(m_ctx, tab[i].atom);
            JSValue v = JS_GetProperty(m_ctx, obj, tab[i].atom);
            if (JS_IsFunction(m_ctx, v)) methods << QString::fromUtf8(key);
            JS_FreeValue(m_ctx, v);
            if (key) JS_FreeCString(m_ctx, key);
        }
        JS_FreePropertyEnum(m_ctx, tab, len);
    }
    m["methods"] = methods;
    return m;
}

void PluginRuntime::Worker::runInvoke(int requestId, const QString& platform, const QString& method,
                                      const QVariantList& args)
{
    auto it = m_pluginObjs.find(platform);
    if (it == m_pluginObjs.end()) {
        emit invokeFailed(requestId, QStringLiteral("plugin.missing"),
                          QStringLiteral("插件未加载: %1").arg(platform));
        pumpQueue();
        return;
    }
    JSValue fn = JS_GetPropertyStr(m_ctx, it.value(), method.toUtf8().constData());
    if (!JS_IsFunction(m_ctx, fn)) {
        JS_FreeValue(m_ctx, fn);
        emit invokeFailed(requestId, QStringLiteral("plugin.noCapability"),
                          QStringLiteral("插件 %1 未实现 %2").arg(platform, method));
        pumpQueue();
        return;
    }
    std::vector<JSValue> jargs;
    jargs.reserve(args.size());
    for (const QVariant& a : args) jargs.push_back(variantToJs(m_ctx, a));
    JSValue ret = JS_Call(m_ctx, fn, JS_DupValue(m_ctx, it.value()),
                          int(jargs.size()), jargs.data());
    JS_FreeValue(m_ctx, fn);
    for (JSValue v : jargs) JS_FreeValue(m_ctx, v);

    if (JS_IsException(ret)) {
        const QString msg = jsExceptionMessage(m_ctx);
        JS_FreeValue(m_ctx, ret);
        emit invokeFailed(requestId, QStringLiteral("plugin.error"), msg);
        pumpQueue();
        return;
    }
    if (JS_IsPromise(ret)) {
        m_await.reqId = requestId;
        m_await.promise = ret;
        drainAndWait();
        return;
    }
    // 同步返回 (协议上全 async, 但容错)
    const QVariant res = jsToVariant(m_ctx, ret);
    JS_FreeValue(m_ctx, ret);
    emit invokeFinished(requestId, res);
    pumpQueue();
}

void PluginRuntime::Worker::drainAndWait()
{
    for (;;) {
        for (;;) {
            JSContext* jc = nullptr;
            if (JS_ExecutePendingJob(m_rt, &jc) <= 0) break;
        }
        if (JS_PromiseState(m_ctx, m_await.promise) != JS_PROMISE_PENDING) {
            settleCurrent();
            return;
        }
        QEventLoop loop;
        m_wait = &loop;
        loop.exec();
        m_wait = nullptr;
    }
}

void PluginRuntime::Worker::settleCurrent()
{
    const int reqId = m_await.reqId;
    JSValue p = m_await.promise;
    m_await.reqId = 0;
    m_await.promise = JS_UNDEFINED;
    const JSPromiseStateEnum st = JS_PromiseState(m_ctx, p);
    if (st == JS_PROMISE_FULFILLED) {
        JSValue v = JS_PromiseResult(m_ctx, p);
        const QVariant res = jsToVariant(m_ctx, v);
        JS_FreeValue(m_ctx, v);
        JS_FreeValue(m_ctx, p);
        emit invokeFinished(reqId, res);
    } else {
        JSValue r = JS_PromiseResult(m_ctx, p);
        JSValue m = JS_GetPropertyStr(m_ctx, r, "message");
        const QString msg = QString::fromUtf8(jsToUtf8(m_ctx, JS_IsUndefined(m) ? r : m));
        JS_FreeValue(m_ctx, m);
        JS_FreeValue(m_ctx, r);
        JS_FreeValue(m_ctx, p);
        // fetch 层超时统一标记 → facade 映射 net.timeout
        const QString code = msg.contains(QStringLiteral("timeout"))
                                 ? QStringLiteral("net.timeout")
                                 : QStringLiteral("plugin.error");
        emit invokeFailed(reqId, code, msg);
    }
    pumpQueue();
}

void PluginRuntime::Worker::pumpQueue()
{
    if (m_queue.isEmpty()) return;
    const QPair<int, QByteArray> next = m_queue.takeFirst();
    const QVariantMap pkt = QJsonDocument::fromJson(next.second).toVariant().toMap();
    runInvoke(next.first, pkt.value("platform").toString(),
              pkt.value("method").toString(), pkt.value("args").toList());
}

void PluginRuntime::Worker::init()
{
    m_rt = JS_NewRuntime();
    m_ctx = JS_NewContext(m_rt);
    JS_SetContextOpaque(m_ctx, this);
    m_nam = new QNetworkAccessManager(this);

    JSValue global = JS_GetGlobalObject(m_ctx);
    JS_SetPropertyStr(m_ctx, global, "fetch", JS_NewCFunction(m_ctx, jsFetch, "fetch", 2));
    JS_SetPropertyStr(m_ctx, global, "__require", JS_NewCFunction(m_ctx, jsRequire, "require", 1));
    JSValue console = JS_NewObject(m_ctx);
    JS_SetPropertyStr(m_ctx, console, "log",   JS_NewCFunction(m_ctx, jsConsole, "log", 1));
    JS_SetPropertyStr(m_ctx, console, "warn",  JS_NewCFunction(m_ctx, jsConsole, "warn", 1));
    JS_SetPropertyStr(m_ctx, console, "error", JS_NewCFunction(m_ctx, jsConsole, "error", 1));
    JS_SetPropertyStr(m_ctx, global, "console", console);
    JS_FreeValue(m_ctx, global);

    doReload();
}

void PluginRuntime::Worker::doReload()
{
    for (JSValue v : std::as_const(m_pluginObjs)) JS_FreeValue(m_ctx, v);
    m_pluginObjs.clear();
    m_pluginMeta.clear();

    const QDir dir(QCoreApplication::applicationDirPath() + QStringLiteral("/plugins"));

    // 白名单模块 (幂等: 已注册名跳过)
    const QDir libDir(dir.filePath(QStringLiteral("lib")));
    for (const QString& f : libDir.entryList({ QStringLiteral("*.js") },
                                             QDir::Files, QDir::Name)) {
        const QString name = f.chopped(3);
        if (m_modules.contains(name)) continue;
        QFile file(libDir.filePath(f));
        if (!file.open(QIODevice::ReadOnly)) continue;
        JSValue mod = loadCommonJs(qPrintable(name), file.readAll(),
                                   name == QLatin1String("node-html-parser"));
        if (!JS_IsUndefined(mod))
            m_modules.insert(name, mod); // registry 持有一份
        else
            JS_FreeValue(m_ctx, mod);
    }

    // 插件 (platform 重名后者覆盖, 兼容热重载)
    QVariantList metaList;
    for (const QString& f : dir.entryList({ QStringLiteral("*.js") },
                                          QDir::Files, QDir::Name)) {
        QFile file(dir.filePath(f));
        if (!file.open(QIODevice::ReadOnly)) continue;
        JSValue mod = loadCommonJs(qPrintable(f), file.readAll(), false);
        if (JS_IsUndefined(mod)) {
            JS_FreeValue(m_ctx, mod);
            continue;
        }
        const QString platform = QString::fromUtf8(propStr(m_ctx, mod, "platform"));
        if (platform.isEmpty()) {
            JS_FreeValue(m_ctx, mod);
            continue;
        }
        auto old = m_pluginObjs.find(platform);
        if (old != m_pluginObjs.end()) JS_FreeValue(m_ctx, old.value());
        m_pluginObjs.insert(platform, mod);
        m_pluginMeta.append(extractMeta(f, mod));
        metaList.append(m_pluginMeta.last());
    }
    qInfo() << "[PluginRuntime] 插件加载完成:" << m_pluginObjs.size();
    emit pluginsReady(metaList);
}

void PluginRuntime::Worker::doInvoke(int requestId, const QString& platform, const QString& method,
                                     const QVariantList& args)
{
    if (!JS_IsUndefined(m_await.promise)) {
        // 串行执行: 打包进队列, 当前请求落定后依次续跑
        QVariantMap pkt;
        pkt.insert(QStringLiteral("platform"), platform);
        pkt.insert(QStringLiteral("method"), method);
        pkt.insert(QStringLiteral("args"), args);
        m_queue.append(qMakePair(requestId,
            QJsonDocument::fromVariant(pkt).toJson(QJsonDocument::Compact)));
        return;
    }
    runInvoke(requestId, platform, method, args);
}

JSValue PluginRuntime::Worker::jsFetch(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv)
{
    auto* w = static_cast<Worker*>(JS_GetContextOpaque(ctx));
    const QByteArray url = jsToUtf8(ctx, argv[0]);
    QByteArray method = "GET";
    QByteArray body;
    QHash<QByteArray, QByteArray> headers;
    int timeoutMs = 8000;
    if (argc >= 2 && JS_IsObject(argv[1])) {
        JSValue m = JS_GetPropertyStr(ctx, argv[1], "method");
        if (!JS_IsUndefined(m)) method = jsToUtf8(ctx, m).toUpper();
        JS_FreeValue(ctx, m);
        JSValue h = JS_GetPropertyStr(ctx, argv[1], "headers");
        if (JS_IsObject(h)) {
            JSPropertyEnum* tab = nullptr;
            uint32_t len = 0;
            if (JS_GetOwnPropertyNames(ctx, &tab, &len, h, JS_GPN_STRING_MASK) == 0) {
                for (uint32_t i = 0; i < len; i++) {
                    const char* key = JS_AtomToCString(ctx, tab[i].atom);
                    JSValue v = JS_GetProperty(ctx, h, tab[i].atom);
                    headers.insert(QByteArray(key).toLower(), jsToUtf8(ctx, v));
                    JS_FreeValue(ctx, v);
                    if (key) JS_FreeCString(ctx, key);
                }
                JS_FreePropertyEnum(ctx, tab, len);
            }
        }
        JS_FreeValue(ctx, h);
        JSValue b = JS_GetPropertyStr(ctx, argv[1], "body");
        if (!JS_IsUndefined(b)) body = jsToUtf8(ctx, b);
        JS_FreeValue(ctx, b);
        JSValue t = JS_GetPropertyStr(ctx, argv[1], "timeout");
        if (JS_IsNumber(t)) {
            double ms = 0;
            JS_ToFloat64(ctx, &ms, t);
            timeoutMs = int(ms);
        }
        JS_FreeValue(ctx, t);
    }

    JSValue resolving[2];
    JSValue promise = JS_NewPromiseCapability(ctx, resolving);
    if (JS_IsException(promise)) {
        JS_FreeValue(ctx, promise);
        return JS_EXCEPTION;
    }

    QNetworkRequest req(QUrl(QString::fromUtf8(url)));
    for (auto it = headers.begin(); it != headers.end(); ++it)
        req.setRawHeader(it.key(), it.value());

    const int seq = ++w->m_fetchSeq;
    QNetworkReply* reply = method == "POST"
        ? w->m_nam->post(req, body)
        : w->m_nam->get(req);
    w->m_replies.insert(seq, reply);

    QTimer* timer = new QTimer(w);
    timer->setSingleShot(true);
    timer->start(timeoutMs);
    QObject::connect(timer, &QTimer::timeout, w, [w, seq] {
        if (QNetworkReply* r = w->m_replies.take(seq)) r->abort();
    });

    QObject::connect(reply, &QNetworkReply::finished, w,
        [w, ctx, seq, reply, timer, resolving] {
            timer->stop();
            timer->deleteLater();
            w->m_replies.remove(seq);

            JSValue e = JS_UNDEFINED;
            if (reply->error() != QNetworkReply::NoError) {
                e = JS_NewError(ctx);
                QByteArray msg = reply->error() == QNetworkReply::OperationCanceledError
                    ? QByteArray("timeout")
                    : QStringLiteral("network: %1").arg(reply->errorString()).toUtf8();
                JS_DefinePropertyValueStr(ctx, e, "message",
                    JS_NewStringLen(ctx, msg.constData(), msg.size()),
                    JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE);
                JS_Call(ctx, resolving[1], JS_UNDEFINED, 1, &e);
                JS_FreeValue(ctx, e);
            } else {
                const QByteArray respBody = reply->readAll();
                JSValue resp = JS_NewObject(ctx);
                JS_SetPropertyStr(ctx, resp, "status", JS_NewInt32(ctx,
                    reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()));
                JSValue hobj = JS_NewObject(ctx);
                const auto pairs = reply->rawHeaderPairs();
                for (const auto& p : pairs) {
                    const QByteArray k = p.first.toLower();
                    JS_SetPropertyStr(ctx, hobj, k.constData(),
                        JS_NewStringLen(ctx, p.second.constData(), p.second.size()));
                }
                JS_SetPropertyStr(ctx, resp, "headers", hobj);
                JS_SetPropertyStr(ctx, resp, "body",
                    JS_NewStringLen(ctx, respBody.constData(), respBody.size()));
                JS_Call(ctx, resolving[0], JS_UNDEFINED, 1, &resp);
                JS_FreeValue(ctx, resp);
            }
            JS_FreeValue(ctx, resolving[0]);
            JS_FreeValue(ctx, resolving[1]);
            reply->deleteLater();
            if (w->m_wait) w->m_wait->quit();  // 唤醒等待循环
        });
    return promise;
}

JSValue PluginRuntime::Worker::jsRequire(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv)
{
    auto* w = static_cast<Worker*>(JS_GetContextOpaque(ctx));
    const QByteArray name = jsToUtf8(ctx, argv[0]);
    auto it = w->m_modules.find(QString::fromUtf8(name));
    if (it == w->m_modules.end())
        return JS_ThrowReferenceError(ctx, "Cannot find module '%s'", name.constData());
    return JS_DupValue(ctx, it.value());
}

JSValue PluginRuntime::Worker::jsConsole(JSContext* ctx, JSValueConst, int argc, JSValueConst* argv)
{
    const QByteArray s = argc > 0 ? jsToUtf8(ctx, argv[0]) : QByteArray();
    qDebug().noquote() << "[plugin]" << QString::fromUtf8(s);
    return JS_UNDEFINED;
}

// ── PluginRuntime (GUI 线程门面) ──

PluginRuntime* PluginRuntime::instance()
{
    static PluginRuntime* inst = new PluginRuntime();
    return inst;
}

PluginRuntime::PluginRuntime(QObject* parent)
    : QObject(parent)
    , m_worker(new Worker())
{
    m_worker->moveToThread(&m_thread);
    connect(&m_thread, &QThread::started, m_worker, &Worker::init);
    connect(&m_thread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &Worker::pluginsReady, this, &PluginRuntime::pluginsReady);
    connect(m_worker, &Worker::invokeFinished, this, &PluginRuntime::invokeFinished);
    connect(m_worker, &Worker::invokeFailed, this, &PluginRuntime::invokeFailed);
    m_thread.start();
}

PluginRuntime::~PluginRuntime()
{
    m_thread.quit();
    m_thread.wait();
}

void PluginRuntime::invoke(int requestId, const QString& platform, const QString& method,
                           const QVariantList& args)
{
    QMetaObject::invokeMethod(m_worker, "doInvoke", Qt::QueuedConnection,
                              Q_ARG(int, requestId), Q_ARG(QString, platform),
                              Q_ARG(QString, method), Q_ARG(QVariantList, args));
}

void PluginRuntime::reload()
{
    QMetaObject::invokeMethod(m_worker, "doReload", Qt::QueuedConnection);
}
