// Lua 语法检查（WoW 1.12 / Lua 5.0 兼容）
// 用法: node check_lua.js [文件...]   不传参数则检查 Outfitter 全部主 lua
// 注意 luaparse 只支持到 5.1，用 5.1 模式解析；`break;` 在 5.0 是历史残留
// （本客户端文件里有），luaparse 会报错，这里静默忽略。
const fs = require("fs");
const luaparse = require("luaparse");

const DEFAULT_FILES = [
    "D:/twmoa_1172/Interface/AddOns/Outfitter/Outfitter.lua",
    "D:/twmoa_1172/Interface/AddOns/Outfitter/QuickSwap.lua",
    "D:/twmoa_1172/Interface/AddOns/Outfitter/pfui-skin.lua",
    "D:/twmoa_1172/Interface/AddOns/Outfitter/BossTrash.lua",
];

const files = process.argv.slice(2).length ? process.argv.slice(2) : DEFAULT_FILES;

let totalErr = 0;
for (const f of files) {
    let src;
    try {
        src = fs.readFileSync(f, "utf8");
    } catch (e) {
        console.error("[SKIP] " + f + "  (" + e.code + ")");
        continue;
    }
    // 预处理：Lua 5.0 的 `break;`（带分号）在 5.1 里非法（5.1 要求 break 后紧跟
    // end/else/until，多余的 ; 会被报成 "'end' expected near ';'")。统一归一成
    // `break` 再解析——否则遇到第一个 break; 就中断，后面的代码根本校验不到。
    const normalized = src.replace(/\bbreak\s*;/g, "break");
    try {
        luaparse.parse(normalized, { luaVersion: "5.1" });
        console.log("[OK]   " + f);
    } catch (e) {
        console.error("[FAIL] " + f + "  " + e.message);
        totalErr++;
    }
}
process.exit(totalErr);
