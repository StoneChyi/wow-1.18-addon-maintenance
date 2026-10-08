-- 生成 db/items-vanillafix.lua：把本地对基础库 pfQuest/db/items.lua 的掉率修订
-- 迁移成 turtle 层记录（patchtable 整条替换，运行时与直接改基础库等价）。
-- 用法: lua gen-items-vanillafix.lua <原版items.lua> <修订版items.lua> <items-turtle.lua> <输出文件>
-- 原版取自上游 pfQuest 发行版（本仓库里是 git show 76db38b:pfQuest/db/items.lua）。
-- turtle db 升级后需对新上游重新评估：若新导出已带正确掉率，重生成会自动收缩。

local pristine_path, current_path, turtle_path, out_path = arg[1], arg[2], arg[3], arg[4]
assert(pristine_path and current_path and turtle_path and out_path,
  "usage: lua gen-items-vanillafix.lua <pristine> <current> <turtle> <out>")

local function load_items(path)
  pfDB = { items = {} }
  local f = assert(loadfile(path), "cannot load " .. path)
  f()
  return pfDB.items.data or pfDB.items["data-turtle"]
end

-- 确定性序列化：键排序、数字用 %.14g（能无损往返 db 里的所有掉率值）
local function fmtnum(v)
  local s = string.format("%.14g", v)
  return s
end
local function ser(v, out)
  if type(v) ~= "table" then out[#out+1] = fmtnum(v) return end
  local ks = {}
  for k in pairs(v) do ks[#ks+1] = k end
  table.sort(ks, function(a, b)
    if type(a) == type(b) then
      if type(a) == "number" then return a < b end
      return tostring(a) < tostring(b)
    end
    return type(a) < type(b)
  end)
  out[#out+1] = "{"
  for _, k in ipairs(ks) do
    if type(k) == "number" then out[#out+1] = "[" .. fmtnum(k) .. "]="
    else out[#out+1] = '["' .. k .. '"]=' end
    ser(v[k], out)
    out[#out+1] = ","
  end
  out[#out+1] = "}"
end
local function sig(rec)
  local out = {}
  ser(rec, out)
  return table.concat(out)
end

local pristine = load_items(pristine_path)
local current  = load_items(current_path)
local turtle   = load_items(turtle_path)

-- 找差异记录
local ids, removed = {}, {}
for id, rec in pairs(current) do
  local old = pristine[id]
  if old == nil or sig(old) ~= sig(rec) then ids[#ids+1] = id end
end
for id in pairs(pristine) do
  if current[id] == nil then removed[#removed+1] = id end
end
table.sort(ids)
table.sort(removed)

-- 被 turtle 层遮蔽的基础层改动运行时不生效，丢弃
local kept, shadowed = {}, 0
for _, id in ipairs(ids) do
  if turtle[id] ~= nil then shadowed = shadowed + 1 else kept[#kept+1] = id end
end
local removed_kept = {}
for _, id in ipairs(removed) do
  if turtle[id] ~= nil then shadowed = shadowed + 1 else removed_kept[#removed_kept+1] = id end
end

-- 输出（CRLF，与 db 目录其它文件一致）
local EOL = "\r\n"
local f = assert(io.open(out_path, "wb"))
f:write("-- 本文件由 toolbox/gen-items-vanillafix.lua 生成，勿手改。" .. EOL)
f:write("-- 内容：本地对基础库 items 掉率的修订，以 turtle 层记录承载，patchtable 整条替换后生效。" .. EOL)
f:write("-- 修订 " .. #kept .. " 条 / 删除 " .. #removed_kept .. " 条（另 " .. shadowed .. " 条被 turtle 层遮蔽，无需承载）。" .. EOL)
local function emit_record(id, rec)
  local ks = {}
  for k in pairs(rec) do ks[#ks+1] = k end
  table.sort(ks)
  f:write('pfDB["items"]["data-turtle"][' .. id .. "] = {" .. EOL)
  for _, k in ipairs(ks) do
    local sub = rec[k]
    local sids = {}
    for s in pairs(sub) do sids[#sids+1] = s end
    table.sort(sids)
    f:write('  ["' .. k .. '"] = {' .. EOL)
    local line = {}
    for i, s in ipairs(sids) do
      line[#line+1] = "[" .. fmtnum(s) .. "] = " .. fmtnum(sub[s])
      if #line == 5 or i == #sids then
        f:write("    " .. table.concat(line, ", ") .. "," .. EOL)
        line = {}
      end
    end
    f:write("  }," .. EOL)
  end
  f:write("}" .. EOL)
end
for _, id in ipairs(kept) do emit_record(id, current[id]) end
for _, id in ipairs(removed_kept) do
  f:write('pfDB["items"]["data-turtle"][' .. id .. '] = "_"' .. EOL)
  f:write('if pfDB["items"]["enUS-turtle"] then pfDB["items"]["enUS-turtle"][' .. id .. '] = "_" end' .. EOL)
  f:write('if pfDB["items"]["zhCN-turtle"] then pfDB["items"]["zhCN-turtle"][' .. id .. '] = "_" end' .. EOL)
end
f:close()
print(string.format("修订 %d 条 + 删除 %d 条 -> %s（遮蔽丢弃 %d 条）",
  #kept, #removed_kept, out_path, shadowed))
