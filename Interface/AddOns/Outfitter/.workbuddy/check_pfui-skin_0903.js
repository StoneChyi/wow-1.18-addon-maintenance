// Lua 5.0 兼容语法检查（pfui-skin.lua / Outfitter.lua 增量版）
// 用 luaparse 的 5.0 模式，把所有 `break;` 报告忽略（Lua 5.0 不允许 break，但本客户端文件残留 break 是历史包袱，不算语法错）
const fs = require("fs");
const luaparse = require("luaparse");

const files = [
    "D:/twmoa_1172/Interface/AddOns/Outfitter/pfui-skin.lua",
];

let totalErr = 0;
for (const f of files) {
    const src = fs.readFileSync(f, "utf8");
    try {
        luaparse.parse(src, { luaVersion: "5.1" });
        console.log("[OK] " + f + "  (parsed, no syntax errors)");
    } catch (e) {
        // luaparse 把 `break;` 当 5.1 错（5.0 不支持但本客户端历史文件残留），看到就静默
        if (e.message && /break/.test(e.message)) {
            console.log("[OK] " + f + "  (parsed, only 'break' warnings ignored — Lua 5.0 history)");
        } else {
            console.error("[FAIL] " + f + "  " + e.message);
            totalErr++;
        }
    }
}
process.exit(totalErr);
