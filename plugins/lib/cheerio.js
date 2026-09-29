// ═══════════════════════════════════════════════════════════════
//  cheerio shim — 白名单模块, 构建在 node-html-parser 之上
//
//  只实现插件实际用到的 jQuery 风格子集: load(html) 返回可调用的 $,
//  支持 $(sel)/$(node) 选择、.text()/.html()/.attr()/.each()/.map()/
//  .toArray()/.find()/.children()/.eq()/.parent()/for-of 迭代。
//  完整 cheerio 无自包含单文件产物, 此 shim 覆盖当前插件面;
//  新插件需要新 API 时在此扩展。
// ═══════════════════════════════════════════════════════════════

var nhp = require("node-html-parser");

function load(html) {
    var root = nhp.parse(String(html == null ? "" : html));

    function makeSel(nodes) {
        var sel = function (arg) {
            if (arg == null) return makeSel([]);
            if (typeof arg === "string") return makeSel(root.querySelectorAll(arg));
            if (Array.isArray(arg)) return makeSel(arg);
            return makeSel([arg]);
        };
        sel.length = nodes.length;
        sel.nodes = nodes;

        sel.text = function () {
            var t = "";
            for (var i = 0; i < nodes.length; i++)
                if (nodes[i]) t += nodes[i].text || "";
            return t;
        };
        sel.html = function () {
            if (!nodes.length || !nodes[0]) return "";
            return nodes[0].innerHTML !== undefined
                ? nodes[0].innerHTML
                : String(nodes[0]);
        };
        sel.attr = function (name) {
            return nodes.length && nodes[0] && nodes[0].getAttribute
                ? nodes[0].getAttribute(name)
                : undefined;
        };
        sel.toArray = function () { return nodes; };
        sel.each = function (fn) {
            for (var i = 0; i < nodes.length; i++) fn(i, nodes[i]);
            return sel;
        };
        sel.map = function (fn) {
            var r = [];
            for (var i = 0; i < nodes.length; i++) r.push(fn(i, nodes[i]));
            return r;
        };
        sel.find = function (selArg) {
            var found = [];
            for (var i = 0; i < nodes.length; i++)
                if (nodes[i] && nodes[i].querySelectorAll)
                    found = found.concat(nodes[i].querySelectorAll(selArg));
            return makeSel(found);
        };
        sel.children = function () {
            var kids = [];
            for (var i = 0; i < nodes.length; i++)
                if (nodes[i] && nodes[i].childNodes)
                    kids = kids.concat(nodes[i].childNodes);
            return makeSel(kids);
        };
        sel.eq = function (i) { return makeSel(nodes[i] ? [nodes[i]] : []); };
        sel.parent = function () {
            return makeSel(nodes.length && nodes[0] && nodes[0].parentNode
                ? [nodes[0].parentNode] : []);
        };
        sel[Symbol.iterator] = function () { return nodes[Symbol.iterator](); };
        return sel;
    }

    // load(html) 直接当 $(document) 用 (插件有 load(x).text() 用法)
    return makeSel([root]);
}

module.exports = { load: load };
