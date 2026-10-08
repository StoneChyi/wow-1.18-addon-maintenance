const fs = require('fs');
let luaparse;
try { luaparse = require('C:/Users/Administrator/.workbuddy/binaries/node/workspace/node_modules/luaparse'); } catch (e) { fs.writeFileSync(__dirname + '\\check_result.txt', 'NO_LUAPARSE: ' + e.message); process.exit(0); }
try {
  luaparse.parse(fs.readFileSync('D:/twmoa_1172/Interface/AddOns/OneBag/OneBag.lua', 'utf8'), { luaVersion: '5.1' });
  fs.writeFileSync(__dirname + '\\check_result.txt', 'SYNTAX_OK');
} catch (e) {
  fs.writeFileSync(__dirname + '\\check_result.txt', 'SYNTAX_ERR: ' + e.message);
}
