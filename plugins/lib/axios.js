// ═══════════════════════════════════════════════════════════════
//  axios shim — 白名单模块, 构建在原生 fetch (C 桥) 之上
//
//  支持插件实际用到的面: axios(config) / axios.get(url, cfg) /
//  axios.post(url, data, cfg); config = {method,url,headers,params,
//  data,timeout}; 响应 {data(JSON 自动解析, 失败回退原文), status,
//  headers, config}。
//  编译产物经 rollup interop 访问 .default, 故 self 挂 default。
// ═══════════════════════════════════════════════════════════════

function buildQuery(params) {
    if (!params || typeof params !== "object") return "";
    var parts = [];
    for (var k in params) {
        if (!Object.prototype.hasOwnProperty.call(params, k)) continue;
        parts.push(encodeURIComponent(k) + "=" + encodeURIComponent(String(params[k])));
    }
    return parts.length ? "?" + parts.join("&") : "";
}

function parseBody(text) {
    if (typeof text !== "string") return text;
    try { return JSON.parse(text); } catch (e) { return text; }
}

function axios(config) {
    var opts = config || {};
    var method = String(opts.method || "get").toUpperCase();
    var url = String(opts.url || "");
    if (method === "GET" && opts.params) url += buildQuery(opts.params);

    var fetchOpts = { method: method, headers: opts.headers || {} };
    if (opts.data !== undefined && opts.data !== null) {
        if (typeof opts.data === "string") fetchOpts.body = opts.data;
        else fetchOpts.body = buildQuery(opts.data).slice(1); // x-www-form-urlencoded
    }
    if (opts.timeout) fetchOpts.timeout = opts.timeout;

    return fetch(url, fetchOpts).then(function (resp) {
        return {
            data: parseBody(resp.body),
            status: resp.status,
            statusText: "",
            headers: resp.headers || {},
            config: config
        };
    });
}

axios.get = function (url, config) {
    return axios(Object.assign({}, config, { method: "get", url: url }));
};
axios.post = function (url, data, config) {
    return axios(Object.assign({}, config, { method: "post", url: url, data: data }));
};
axios.request = axios;
axios.default = axios;

module.exports = axios;
