# BetterCharacterStats/BCS_PropertiesPanel.lua

类型：modified；新增 754 行，删除 401 行。

基线：10-06 浮动属性扩展首次修改前
基线来源：E:\1.18\addons_tmp\bcs-float-backup-20261006\BCS_PropertiesPanel.lua.original

当前 SHA-256：`bb36de2b5f492926bdeb39c9760d998653991533802fb0904d1e042a9fb515fb`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 17 / 0 | 17 / 7 | insert | `文件顶部 / 表定义` |
| 37 / 10 | 44 / 0 | delete | `GetDefaultDisplayConfig（第29行）` |
| 48 / 2 | 45 / 1 | replace | `GetDefaultDisplayConfig（第29行）` |
| 72 / 0 | 68 / 2 | insert | `GetDefaultDisplayConfig（第29行）` |
| 76 / 0 | 74 / 5 | insert | `GetDefaultDisplayConfig（第29行）` |
| 78 / 0 | 81 / 1 | insert | `GetDefaultDisplayConfig（第29行）` |
| 87 / 1 | 91 / 1 | replace | `GetDefaultDisplayConfig（第29行）` |
| 97 / 21 | 101 / 14 | replace | `ArrayCount（第95行）` |
| 120 / 1 | 117 / 100 | replace | `ArrayCount（第95行）` |
| 122 / 12 | 218 / 4 | replace | `P:GetSelectedKeys（第217行）` |
| 138 / 1 | 226 / 8 | replace | `P:GetTitleKey（第226行）` |
| 140 / 3 | 235 / 14 | replace | `P:IsSpeedShown（第234行）` |
| 147 / 9 | 253 / 5 | replace | `P:GetPropertyText（第252行）` |
| 167 / 0 | 269 / 1 | insert | `P:GetPropertyText（第252行）` |
| 177 / 0 | 280 / 35 | insert | `P:SaveCenterPosition（第280行）` |
| 179 / 0 | 317 / 1 | insert | `P:ApplyCenterPosition（第308行）` |
| 183 / 0 | 322 / 1 | insert | `P:ApplyCenterPosition（第308行）` |
| 184 / 13 | 324 / 3 | replace | `P:ApplyCenterPosition（第308行）` |
| 241 / 1 | 371 / 1 | replace | `P:RefreshNow（第359行）` |
| 303 / 1 | 433 / 1 | replace | `P:RefreshNow（第359行）` |
| 443 / 0 | 573 / 140 | insert | `CreateButton（第535行）` |
| 444 / 1 | 714 / 2 | replace | `P:SelectConfig（第714行）` |
| 447 / 1 | 718 / 1 | replace | `P:SelectConfig（第714行）` |
| 450 / 0 | 721 / 1 | insert | `P:SelectConfig（第714行）` |
| 456 / 3 | 728 / 4 | replace | `P:SelectConfig（第714行）` |
| 460 / 1 | 733 / 1 | replace | `P:SelectConfig（第714行）` |
| 480 / 1 | 753 / 1 | replace | `P:SelectConfig（第714行）` |
| 482 / 4 | 755 / 0 | delete | `P:SelectConfig（第714行）` |
| 543 / 0 | 812 / 1 | insert | `P:Init（第788行）` |
| 544 / 0 | 814 / 4 | insert | `P:Init（第788行）` |
| 547 / 0 | 821 / 9 | insert | `P:Init（第788行）` |
| 550 / 0 | 833 / 3 | insert | `P:Init（第788行）` |
| 553 / 0 | 839 / 1 | insert | `P:Init（第788行）` |
| 585 / 4 | 872 / 1 | replace | `P:RefreshSpeedDisplay（第859行）` |
| 592 / 5 | 876 / 1 | replace | `P:UpdateDisplay（第873行）` |
| 599 / 0 | 879 / 18 | insert | `P:UpdateDisplay（第873行）` |
| 600 / 3 | 898 / 9 | replace | `P:UpdateDisplay（第873行）` |
| 604 / 14 | 908 / 19 | replace | `P:UpdateDisplay（第873行）` |
| 619 / 14 | 928 / 29 | replace | `P:UpdateDisplay（第873行）` |
| 634 / 5 | 958 / 11 | replace | `P:UpdateDisplay（第873行）` |
| 640 / 5 | 970 / 5 | replace | `P:UpdateDisplay（第873行）` |
| 646 / 11 | 976 / 0 | delete | `P:UpdateDisplay（第873行）` |
| 664 / 2 | 983 / 2 | replace | `P:DisplaySpeed（第982行）` |
| 673 / 2 | 992 / 1 | replace | `P:DisplaySpeed（第982行）` |
| 676 / 3 | 994 / 1 | replace | `P:BuildBody（第993行）` |
| 680 / 3 | 996 / 5 | replace | `P:BuildBody（第993行）` |
| 684 / 3 | 1002 / 1 | replace | `P:BuildBody（第993行）` |
| 688 / 10 | 1004 / 3 | replace | `P:BuildBody（第993行）` |
| 699 / 11 | 1008 / 4 | replace | `P:BuildBody（第993行）` |
| 711 / 2 | 1013 / 1 | replace | `P:BuildBody（第993行）` |
| 715 / 3 | 1016 / 0 | delete | `P:GetDisplayLines（第1016行）` |
| 720 / 3 | 1018 / 1 | replace | `P:GetDisplayLines（第1016行）` |
| 724 / 2 | 1020 / 8 | replace | `P:GetDisplayLines（第1016行）` |
| 727 / 16 | 1029 / 1 | replace | `P:GetDisplayLines（第1016行）` |
| 768 / 6 | 1055 / 0 | delete | `P:GetPropertiesForChat（第1034行）` |
| 833 / 2 | 1114 / 2 | replace | `P:GetItemScore（第1113行）` |
| 919 / 1 | 1200 / 1 | replace | `P:DisplayRangedHitRating（第1197行）` |
| 921 / 1 | 1202 / 1 | replace | `P:DisplayRangedHitRating（第1197行）` |
| 929 / 1 | 1210 / 1 | replace | `P:DisplayRangedCritChance（第1206行）` |
| 931 / 1 | 1212 / 1 | replace | `P:DisplayRangedCritChance（第1206行）` |
| 934 / 1 | 1215 / 1 | replace | `P:DisplayRangedCritChance（第1206行）` |
| 1011 / 1 | 1292 / 1 | replace | `P:DisplayAttackSpeed（第1289行）` |
| 1014 / 1 | 1295 / 1 | replace | `P:DisplayAttackSpeed（第1289行）` |
| 1022 / 2 | 1303 / 2 | replace | `P:DisplayDodge（第1302行）` |
| 1030 / 2 | 1311 / 2 | replace | `P:DisplayParry（第1310行）` |
| 1038 / 2 | 1319 / 2 | replace | `P:DisplayBlock（第1318行）` |
| 1046 / 2 | 1327 / 5 | replace | `P:DisplayBlockValue（第1326行）` |
| 1053 / 0 | 1337 / 46 | insert | `P:GetDefenseChance（第1337行）` |
| 1056 / 1 | 1386 / 2 | replace | `P:DisplayArmor（第1383行）` |
| 1080 / 6 | 1411 / 2 | replace | `P:DisplayArmorPenetration（第1402行）` |
| 1087 / 1 | 1414 / 1 | replace | `P:DisplayArmorPenetration（第1402行）` |
| 1090 / 9 | 1417 / 4 | replace | `P:DisplayArmorPenetration（第1402行）` |
| 1107 / 5 | 1429 / 14 | replace | `EditorLabel（第1429行）` |
| 1113 / 5 | 1444 / 3 | replace | `EditorLabel（第1429行）` |
| 1119 / 18 | 1448 / 27 | replace | `P:SetTitleKey（第1448行）` |
| 1140 / 3 | 1478 / 52 | replace | `CreateEditorMenu（第1478行）` |
| 1145 / 22 | 1532 / 10 | replace | `CreateCheckRow（第1527行）` |
| 1168 / 7 | 1543 / 10 | replace | `row:Refresh（第1542行）` |
| 1176 / 1 | 1554 / 0 | delete | `row:Refresh（第1542行）` |
| 1178 / 2 | 1555 / 9 | replace | `row:Refresh（第1542行）` |
| 1181 / 6 | 1565 / 14 | replace | `row:Refresh（第1542行）` |
| 1190 / 1 | 1582 / 0 | delete | `row:Refresh（第1542行）` |
| 1193 / 3 | 1584 / 0 | delete | `row:Refresh（第1542行）` |
| 1198 / 16 | 1586 / 1 | replace | `row:Refresh（第1542行）` |
| 1216 / 14 | 1589 / 10 | replace | `P:ResetCurrentProfile（第1589行）` |
| 1231 / 7 | 1600 / 3 | replace | `P:ResetCurrentProfile（第1589行）` |
| 1241 / 9 | 1606 / 5 | replace | `P:ResetCurrentProfile（第1589行）` |
| 1253 / 4 | 1614 / 6 | replace | `P:ResetCurrentProfile（第1589行）` |
| 1260 / 1 | 1623 / 2 | replace | `P:ResetCurrentProfile（第1589行）` |
| 1262 / 4 | 1626 / 0 | delete | `P:RefreshCustomRows（第1626行）` |
| 1267 / 8 | 1627 / 8 | replace | `P:RefreshCustomRows（第1626行）` |
| 1277 / 1 | 1637 / 0 | delete | `P:ShowCustomWindow（第1637行）` |
| 1280 / 1 | 1639 / 0 | delete | `P:ShowCustomWindow（第1637行）` |
| 1284 / 3 | 1642 / 1 | replace | `P:ShowCustomWindow（第1637行）` |
| 1293 / 0 | 1649 / 2 | insert | `P:ShowCustomWindow（第1637行）` |
| 1318 / 0 | 1676 / 3 | insert | `P:ShowCustomWindow（第1637行）` |
| 1403 / 5 | 1764 / 1 | replace | `HandleSlashCommand（第1700行）` |
| 1409 / 5 | 1766 / 1 | replace | `HandleSlashCommand（第1700行）` |
| 1424 / 1 | 1777 / 1 | replace | `HandleSlashCommand（第1700行）` |
| 1428 / 1 | 1781 / 1 | replace | `HandleSlashCommand（第1700行）` |
| 1432 / 1 | 1785 / 1 | replace | `HandleSlashCommand（第1700行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/BetterCharacterStats/BCS_PropertiesPanel.lua
+++ b/BetterCharacterStats/BCS_PropertiesPanel.lua
@@ -12,10 +12,17 @@
     x_offset = 350,
     y_offset = -100,
     enabled = true,          -- 悬浮窗默认显示
     align = "LEFT",          -- 对齐方式：LEFT/CENTER/RIGHT
     locked = false,          -- 是否锁定（锁定后点击穿透，不可拖动）
+    rowsPerColumn = 0,       -- 0 为自动单列；标题不计入明细行数
+    scale = 1,
+    titleFontSize = 16,
+    detailFontSize = 13,
+    lineGap = 3,
+    columnWidth = 140,
+    colorMode = "label",    -- label / whole / off
     characterPanelEnabled = true, -- 是否在角色面板（按 C）中显示 BCS 属性；关闭后按 C 只显示暴雪原生面板
 }
 
 -- 根据职业返回悬浮窗默认显示配置
 -- 战士/骑士/盗贼/死骑 → 物理；猎人 → 猎人(远程)；牧师/萨满/德鲁伊 → 治疗；法师/术士 → 法系
@@ -32,23 +39,12 @@
     else
         return "防御"
     end
 end
 
--- 辅助函数：获取速度行（仅供悬浮窗使用，失败返回 nil）
-local function GetSpeedLine()
-    local ok, speed1 = pcall(UnitXP, "speed", "player")
-    if ok and speed1 then
-        local percent = speed1 * 100 / 7
-        return string.format("移速: %.1f%%", percent)
-    end
-    return nil
-end
-
 -- ===== 属性注册表 =====
--- 自定义勾选窗口与预设配置共用同一份定义：数组顺序 = 勾选窗口的阅读顺序（行优先，
--- 从左到右、从上到下） = 悬浮窗显示顺序。第一个勾选项作为「大字标题行」。
+-- 编辑器、预设与聊天共用定义；每个配置分别保存显示顺序和大字标题。
 -- get 为取值函数，运行期才调用（此时下方各 Display* 函数均已定义）。
 local PROPERTY_LIST = {
     -- 物理
     { key = "ap",       label = "攻强",     get = function(self) return self:DisplayAP() end },
     { key = "rap",      label = "远程攻强", get = function(self) return self:DisplayRAP() end },
@@ -67,94 +63,200 @@
     { key = "regen",    label = "回蓝",     get = function(self) return self:DisplayManaRegen() end },
     { key = "haste",    label = "急速",     get = function(self) return self:DisplayHaste() end },
     -- 防御
     { key = "armor",    label = "护甲",     get = function(self) return self:DisplayArmor() end },
     { key = "defense",  label = "防御",     get = function(self) return self:DisplayDefense() end },
+    { key = "three",    label = "三维",     get = function(self) return self:DisplayThreeDimensions() end },
+    { key = "armorDR",  label = "减伤",     get = function(self) return self:DisplayArmorReduction() end },
     { key = "dodge",    label = "躲闪",     get = function(self) return self:DisplayDodge() end },
     { key = "parry",    label = "招架",     get = function(self) return self:DisplayParry() end },
     { key = "block",    label = "格挡",     get = function(self) return self:DisplayBlock() end },
     { key = "blockval", label = "格挡值",   get = function(self) return self:DisplayBlockValue() end },
+    { key = "fireRes",  label = "火抗",     get = function(self) return self:DisplayResistance(2, "火抗") end },
+    { key = "natureRes",label = "自然抗",   get = function(self) return self:DisplayResistance(3, "自然抗") end },
+    { key = "frostRes", label = "冰抗",     get = function(self) return self:DisplayResistance(4, "冰抗") end },
+    { key = "shadowRes",label = "暗抗",     get = function(self) return self:DisplayResistance(5, "暗抗") end },
+    { key = "arcaneRes",label = "奥抗",     get = function(self) return self:DisplayResistance(6, "奥抗") end },
     -- 其他
     { key = "score",    label = "装等",     get = function(self) return self:GetItemScore() end },
+    { key = "speed",    label = "移速",     get = function(self) return self:DisplaySpeed() end },
 }
 
 -- 各预设对应的属性 key 列表（与旧版硬编码顺序、内容完全一致）
 local PRESET_KEYS = {
     ["物理"] = {"ap", "hit", "crit", "arpen", "apspeed"},
     ["法系"] = {"sp", "shit", "scrit", "regen", "haste"},
     ["治疗"] = {"heal", "sp", "scrit", "regen", "haste"},
     ["猎人"] = {"rap", "sp", "rhit", "rcrit", "arpen", "spd"},
     ["混伤"] = {"ap", "sp", "hit", "crit", "arpen", "apspeed"},
-    ["防御"] = {"armor", "defense", "hit", "dodge", "parry", "block"},
+    ["防御"] = {"three", "armor", "armorDR", "defense", "dodge", "parry", "block"},
 }
 
 -- 统计数组长度（兼容 Lua 5.0/5.1：不使用 # 运算符，也不用 table.getn）
 local function ArrayCount(t)
     local n = 0
     for _ in pairs(t) do n = n + 1 end
     return n
 end
 
--- 确保自定义勾选表存在；首次创建时以「当前预设」作为初始勾选
+local PROPERTY_BY_KEY = {}
+local PROPERTY_COLORS = {
+    ap="F6B66D", rap="F6B66D", arpen="F6B66D", speed="F6B66D",
+    hit="7ED6C4", rhit="7ED6C4", shit="7ED6C4",
+    crit="FF8A70", rcrit="FF8A70", scrit="FF8A70", parry="FF8A70",
+    apspeed="6BAEFF", spd="6BAEFF", haste="6BAEFF", dodge="6BAEFF",
+    sp="C9A0FF", heal="8FE0A3", regen="8FE0A3",
+    armor="B6BBC7", armorDR="B6BBC7", defense="A5B4FC", three="FFD36B",
+    block="D8B07C", blockval="D8B07C", score="B6BBC7",
+    fireRes="FF8A70", natureRes="8FE0A3", frostRes="6BAEFF",
+    shadowRes="C9A0FF", arcaneRes="D8A7E8",
+}
+for i = 1, ArrayCount(PROPERTY_LIST) do
+    PROPERTY_BY_KEY[PROPERTY_LIST[i].key] = PROPERTY_LIST[i]
+end
+
+local INFINITY = math.huge or (1 / 0) -- Lua 5.0 的 math 库可能没有 huge 常量
+local function IsFiniteNumber(value)
+    return type(value) == "number" and value == value
+        and value ~= INFINITY and value ~= -INFINITY
+end
+
+local function ReadNumber(fn, arg1, arg2)
+    if type(fn) ~= "function" then return nil end
+    local ok, value = pcall(fn, arg1, arg2)
+    if ok and IsFiniteNumber(value) then return value end
+    return nil
+end
+
+local function PanelConfig()
+    BCSConfig = BCSConfig or {}
+    BCSConfig.PropertiesPanel = BCSConfig.PropertiesPanel or {}
+    return BCSConfig.PropertiesPanel
+end
+
+local function Append(list, value)
+    list[ArrayCount(list) + 1] = value
+end
+
+-- 各预设有独立的勾选表、顺序及标题；旧 customProps 只迁移到「自定义」。
+function P:EnsureProfile(name)
+    local panel = PanelConfig()
+    name = name or self.displayConfig or GetDefaultDisplayConfig()
+    if type(panel.profiles) ~= "table" then panel.profiles = {} end
+    local profile = panel.profiles[name]
+    if type(profile) ~= "table" then profile = nil end
+    if not profile then
+        profile = { props = {}, order = {}, titleKey = "auto" }
+        if name == "自定义" and type(panel.customProps) == "table" then
+            for i = 1, ArrayCount(PROPERTY_LIST) do
+                local key = PROPERTY_LIST[i].key
+                local selected = panel.customProps[key] == true
+                if key == "speed" then selected = panel.customProps.speed ~= false end
+                if selected then
+                    profile.props[key] = true
+                    Append(profile.order, key)
+                end
+            end
+        else
+            local seed = PRESET_KEYS[name]
+            if not seed and name == "自定义" and PRESET_KEYS[self.displayConfig] then
+                local source = self:EnsureProfile(self.displayConfig)
+                for i = 1, ArrayCount(source.order) do
+                    local key = source.order[i]
+                    if source.props[key] then
+                        profile.props[key] = true
+                        Append(profile.order, key)
+                    end
+                end
+                profile.titleKey = source.titleKey
+            else
+                seed = seed or PRESET_KEYS[GetDefaultDisplayConfig()]
+                for i = 1, ArrayCount(seed) do
+                    profile.props[seed[i]] = true
+                    Append(profile.order, seed[i])
+                end
+                profile.props.speed = true
+                Append(profile.order, "speed")
+                if name == "防御" then profile.titleKey = "three" end
+            end
+        end
+        panel.profiles[name] = profile
+    end
+    if type(profile.props) ~= "table" then profile.props = {} end
+    if type(profile.order) ~= "table" then profile.order = {} end
+    if type(profile.titleKey) ~= "string" then profile.titleKey = "auto" end
+    -- 丢弃重复/未知顺序项，补回已勾选但缺少顺序的项。
+    local order, seen = {}, {}
+    for i = 1, ArrayCount(profile.order) do
+        local key = profile.order[i]
+        if PROPERTY_BY_KEY[key] and not seen[key] then
+            Append(order, key)
+            seen[key] = true
+        end
+    end
+    for i = 1, ArrayCount(PROPERTY_LIST) do
+        local key = PROPERTY_LIST[i].key
+        if profile.props[key] and not seen[key] then Append(order, key) end
+    end
+    profile.order = order
+    if profile.titleKey ~= "auto" and (not PROPERTY_BY_KEY[profile.titleKey] or not profile.props[profile.titleKey]) then
+        profile.titleKey = "auto"
+    end
+    if name == "自定义" then
+        local legacy = {}
+        for key, selected in pairs(profile.props) do legacy[key] = selected end
+        legacy.speed = profile.props.speed == true
+        panel.customProps = legacy
+    end
+    return profile
+end
+
 function P:EnsureCustomProps()
-    BCSConfig = BCSConfig or {}
-    if not BCSConfig.PropertiesPanel then
-        BCSConfig.PropertiesPanel = {}
-    end
-    local props = BCSConfig.PropertiesPanel.customProps
-    if props then return props end
-
-    props = {}
-    local seed = PRESET_KEYS[self.displayConfig]
-    if not seed then
-        -- displayConfig 尚未就绪（极少数情况）：退回本职业默认预设
-        seed = PRESET_KEYS[GetDefaultDisplayConfig()] or PRESET_KEYS["物理"]
-    end
-    for i = 1, ArrayCount(seed) do
-        props[seed[i]] = true
-    end
-    props.speed = true          -- 移速行默认开启（保持与预设一致）
-    BCSConfig.PropertiesPanel.customProps = props
-    return props
-end
-
--- 当前生效的属性 key 顺序列表（预设走 PRESET_KEYS，自定义按注册表顺序过滤）
+    return self:EnsureProfile().props
+end
+
 function P:GetSelectedKeys()
-    local preset = PRESET_KEYS[self.displayConfig]
-    if preset then return preset end
-
-    local props = self:EnsureCustomProps()
-    local keys = {}
-    local n = 0
-    for i = 1, ArrayCount(PROPERTY_LIST) do
-        local k = PROPERTY_LIST[i].key
-        if props[k] then
-            n = n + 1
-            keys[n] = k
-        end
+    local profile, keys = self:EnsureProfile(), {}
+    for i = 1, ArrayCount(profile.order) do
+        local key = profile.order[i]
+        if profile.props[key] then Append(keys, key) end
     end
     return keys
 end
 
--- 是否显示移速行：预设恒显示，自定义由勾选项决定（默认显示）
+function P:GetTitleKey()
+    local profile = self:EnsureProfile()
+    if profile.titleKey ~= "auto" and profile.props[profile.titleKey] then
+        return profile.titleKey
+    end
+    return self:GetSelectedKeys()[1]
+end
+
 function P:IsSpeedShown()
-    if PRESET_KEYS[self.displayConfig] then return true end
-    local props = self:EnsureCustomProps()
-    return props.speed ~= false
+    return self:EnsureProfile().props.speed == true
+end
+
+function P:FormatPropertyText(key, text)
+    if self.colorMode == "off" then return text end
+    local color = PROPERTY_COLORS[key] or "FFFFFF"
+    if string.find(text, "数据不可用", 1, true) or string.find(text, "获取失败", 1, true) then
+        return "|cFFBBBBBB" .. text .. "|r"
+    end
+    if self.colorMode == "whole" then return "|cFF" .. color .. text .. "|r" end
+    local colon = string.find(text, ":", 1, true)
+    if not colon then return "|cFF" .. color .. text .. "|r" end
+    return "|cFF" .. color .. string.sub(text, 1, colon) .. "|r|cFFFFFFFF"
+        .. string.sub(text, colon + 1) .. "|r"
 end
 
 -- 按 key 取显示串；取值失败时回退为「标签: 数据不可用」，避免自定义模式下整行丢失
 function P:GetPropertyText(key)
-    for i = 1, ArrayCount(PROPERTY_LIST) do
-        local item = PROPERTY_LIST[i]
-        if item.key == key then
-            local ok, text = pcall(item.get, self)
-            if ok and text then return text end
-            return item.label .. ": 数据不可用"
-        end
-    end
-    return nil
+    local item = PROPERTY_BY_KEY[key]
+    if not item then return nil end
+    local ok, text = pcall(item.get, self)
+    if ok and type(text) == "string" then return text end
+    return item.label .. ": 数据不可用"
 end
 
 -- 悬浮窗框架
 P.frame = CreateFrame("Frame", nil, UIParent)
 P.frame:SetMovable(true)
@@ -162,40 +264,68 @@
 P.frame:SetWidth(140)
 P.frame:SetHeight(110)
 P.frame:SetAlpha(.90)
 P.frame:SetPoint("CENTER", 350, -100)
 P.frame:SetFrameStrata("LOW")
+if P.frame.SetClampedToScreen then P.frame:SetClampedToScreen(true) end
 
 -- 标题行（第一行，大字体）
 P.frame.title = P.frame:CreateFontString(nil, "ARTWORK")
 P.frame.title:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
 
 -- 详细信息行（其余行，小字体）
 P.frame.details = P.frame:CreateFontString(nil, "ARTWORK")
 P.frame.details:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
 
 P.frame:RegisterForDrag("LeftButton")
+function P:SaveCenterPosition(snap)
+    local frame = self.frame
+    local point, _, relPoint, x, y = frame:GetPoint()
+    local cx, cy, ux, uy
+    if frame.GetCenter and UIParent.GetCenter then
+        cx, cy = frame:GetCenter()
+        ux, uy = UIParent:GetCenter()
+    end
+    local centered = cx and cy and ux and uy
+    if centered then
+        local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
+        local parentScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
+        x, y = cx - ux * parentScale / frameScale, cy - uy * parentScale / frameScale
+        point, relPoint = "CENTER", "CENTER"
+    end
+    if not point or not x or not y then return false end
+    if snap and x < 20 and x > -20 then x = 0 end
+    local panel = PanelConfig()
+    panel.point, panel.rel_point = point, relPoint
+    panel.x_offset = math.floor(x * 100 + 0.5) / 100
+    panel.y_offset = math.floor(y * 100 + 0.5) / 100
+    if centered then
+        self.pendingCenter = {x=panel.x_offset, y=panel.y_offset}
+        self.centerAfterLayout = false
+    else self.centerAfterLayout = true end
+    return centered and true or false
+end
+
+function P:ApplyCenterPosition()
+    if not self.pendingCenter or self.dragging then return end
+    self.frame:ClearAllPoints()
+    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.pendingCenter.x, self.pendingCenter.y)
+    self.pendingCenter = nil
+end
+
 P.frame:SetScript("OnDragStart", function()
     if P.locked then return end  -- 锁定时禁止拖动
+    P.dragging = true
     P.frame:StartMoving()
 end)
 P.frame:SetScript("OnDragStop", function()
     P.frame:StopMovingOrSizing()
+    P.dragging = false
     if P.locked then return end
-    local point, _, rel_point, x_offset, y_offset = P.frame:GetPoint()
-    if x_offset < 20 and x_offset > -20 then x_offset = 0 end
-
-    -- 确保 BCSConfig.PropertiesPanel 存在
-    if not BCSConfig.PropertiesPanel then
-        BCSConfig.PropertiesPanel = {}
-    end
-
-    -- 保存位置
-    BCSConfig.PropertiesPanel.point = point
-    BCSConfig.PropertiesPanel.rel_point = rel_point
-    BCSConfig.PropertiesPanel.x_offset = math.floor(x_offset)
-    BCSConfig.PropertiesPanel.y_offset = math.floor(y_offset)
+    -- Save the center now; reanchor on the next display refresh, outside
+    -- the native drag-stop callback and before any size changes.
+    P:SaveCenterPosition(true)
 end)
 
 P.frame:Hide()
 
 -- 定时器（用于实时移速刷新）
@@ -236,11 +366,11 @@
 end
 
 -- 主配置窗口
 P.mainFrame = CreateFrame("Frame", "BCSPropertiesPanelMainFrame", UIParent)
 P.mainFrame:SetWidth(450)
-P.mainFrame:SetHeight(120)
+P.mainFrame:SetHeight(360)
 P.mainFrame:SetPoint("CENTER", 0, 0)
 P.mainFrame:EnableMouse(true)
 P.mainFrame:SetMovable(true)
 P.mainFrame:RegisterForDrag("LeftButton")
 P.mainFrame:SetScript("OnDragStart", function() P.mainFrame:StartMoving() end)
@@ -298,11 +428,11 @@
 helpText:SetPoint("CENTER", 0, 0)
 helpText:SetText("?")
 helpText:SetTextColor(1, 0.82, 0)
 
 helpButton:SetScript("OnClick", function()
-    DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开配置窗口，/mb custom 自定义属性勾选窗口，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 1, 1)
+    DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开设置，编辑当前预设可增减属性/设置标题/排序；/mb custom 打开独立自定义，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 1, 1)
 end)
 
 helpButton:SetScript("OnEnter", function()
     helpButton:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
     helpText:SetTextColor(1, 1, 1)
@@ -438,28 +568,171 @@
     end)
 
     return button
 end
 
+local APPEARANCE_LIMITS = {
+    rowsPerColumn={0, 30}, scale={0.75, 1.5}, titleFontSize={12, 24},
+    detailFontSize={10, 20}, lineGap={0, 12}, columnWidth={100, 240},
+}
+
+function P:LoadAppearance()
+    local panel = PanelConfig()
+    for key, limits in pairs(APPEARANCE_LIMITS) do
+        local value = tonumber(panel[key])
+        if not IsFiniteNumber(value) then value = DEFAULT_CONFIG[key] end
+        value = math.max(limits[1], math.min(limits[2], value))
+        if key ~= "scale" then value = math.floor(value + 0.5) end
+        panel[key], self[key] = value, value
+    end
+    local mode = panel.colorMode
+    if mode ~= "label" and mode ~= "whole" and mode ~= "off" then mode = "label" end
+    panel.colorMode, self.colorMode = mode, mode
+    self.layoutDirty = true
+end
+
+function P:SetPanelOption(key, value)
+    PanelConfig()[key] = value
+    self:LoadAppearance()
+    self:SyncSettingsControls()
+    self:RefreshNow()
+end
+
+function P:SetLocked(locked, announce)
+    if self.dragging then
+        self.frame:StopMovingOrSizing()
+        self.dragging = false
+        self:SaveCenterPosition()
+    end
+    self.locked = locked == true
+    PanelConfig().locked = self.locked
+    self.frame:EnableMouse(not self.locked)
+    self:SyncSettingsControls()
+    if announce then
+        local message = self.locked and "悬浮窗已锁定，点击穿透开启" or "悬浮窗已解锁，可拖动"
+        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r " .. message, 1, 1, 1)
+    end
+end
+
+P.editPresetButton = CreateButton("编辑当前预设", P.mainFrame, "TOP", P.mainFrame, -145, -78,
+    function() P:ShowCustomWindow(not P.customFrame:IsShown()) end)
+P.editPresetButton:SetWidth(106)
+P.lockButton = CreateButton("锁定", P.mainFrame, "TOP", P.mainFrame, -43, -78,
+    function() P:SetLocked(true, true) end)
+P.unlockButton = CreateButton("解锁", P.mainFrame, "TOP", P.mainFrame, 29, -78,
+    function() P:SetLocked(false, true) end)
+P.appearanceResetButton = CreateButton("恢复外观", P.mainFrame, "TOP", P.mainFrame, 134, -78,
+    function()
+        local panel = PanelConfig()
+        for key in pairs(APPEARANCE_LIMITS) do
+            panel[key] = DEFAULT_CONFIG[key]
+        end
+        panel.colorMode = DEFAULT_CONFIG.colorMode
+        P:LoadAppearance()
+        P:SyncSettingsControls()
+        P:RefreshNow()
+    end)
+P.appearanceResetButton:SetWidth(92)
+
+local COLOR_MODES = {"label", "whole", "off"}
+local COLOR_LABELS = { label="属性名染色", whole="整行染色", off="关闭染色" }
+P.colorModeButton = CreateButton("属性名染色", P.mainFrame, "TOP", P.mainFrame, -92, -112,
+    function()
+        local nextMode = "label"
+        for i = 1, 3 do
+            if COLOR_MODES[i] == P.colorMode then nextMode = COLOR_MODES[(i == 3) and 1 or (i + 1)] end
+        end
+        P:SetPanelOption("colorMode", nextMode)
+    end)
+P.colorModeButton:SetWidth(130)
+P.alignButton = CreateButton("左对齐", P.mainFrame, "TOP", P.mainFrame, 82, -112,
+    function()
+        if P.align == "LEFT" then P.align = "CENTER"
+        elseif P.align == "CENTER" then P.align = "RIGHT"
+        else P.align = "LEFT" end
+        PanelConfig().align = P.align
+        P:SyncSettingsControls()
+        P:RefreshNow()
+    end)
+P.alignButton:SetWidth(108)
+
+P.optionSliders = {}
+local function CreateOptionSlider(key, label, low, high, step, x, y, multiplier)
+    local name = "BCSPropertiesOption" .. key
+    local slider = CreateFrame("Slider", name, P.mainFrame, "OptionsSliderTemplate")
+    slider:SetWidth(174)
+    slider:SetHeight(16)
+    slider:SetPoint("TOPLEFT", P.mainFrame, "TOPLEFT", x, y)
+    slider:SetMinMaxValues(low, high)
+    slider:SetValueStep(step)
+    local text = getglobal(name .. "Text")
+    if getglobal(name .. "Low") then getglobal(name .. "Low"):SetText("") end
+    if getglobal(name .. "High") then getglobal(name .. "High"):SetText("") end
+    slider.caption, slider.optionLabel, slider.multiplier = text, label, multiplier or 1
+    slider:SetScript("OnValueChanged", function()
+        local value = math.floor(slider:GetValue() / step + 0.5) * step
+        local suffix = key == "scale" and "%" or ""
+        local shown = (key == "rowsPerColumn" and value == 0) and "自动单列" or (value .. suffix)
+        if text then text:SetText(label .. ": " .. shown) end
+        if P.initialized and not P.syncSettings then
+            P:SetPanelOption(key, value / slider.multiplier)
+        end
+    end)
+    P.optionSliders[key] = slider
+end
+CreateOptionSlider("rowsPerColumn", "每列明细行数", 0, 30, 1, 24, -163)
+CreateOptionSlider("scale", "整体缩放", 75, 150, 5, 252, -163, 100)
+CreateOptionSlider("titleFontSize", "标题字号", 12, 24, 1, 24, -218)
+CreateOptionSlider("detailFontSize", "明细字号", 10, 20, 1, 252, -218)
+CreateOptionSlider("lineGap", "行距", 0, 12, 1, 24, -273)
+CreateOptionSlider("columnWidth", "列宽", 100, 240, 10, 252, -273)
+
+local layoutHint = P.mainFrame:CreateFontString(nil, "OVERLAY")
+layoutHint:SetFont(STANDARD_TEXT_FONT, 11)
+layoutHint:SetPoint("TOP", 0, -305)
+layoutHint:SetText("标题不计行数；超出续列，屏幕不足时自动增行")
+layoutHint:SetTextColor(0.75, 0.75, 0.75)
+
+function P:SyncSettingsControls()
+    self.syncSettings = true
+    for key, slider in pairs(self.optionSliders) do
+        slider:SetValue((self[key] or DEFAULT_CONFIG[key]) * slider.multiplier)
+    end
+    self.syncSettings = false
+    self.colorModeButton.label:SetText(COLOR_LABELS[self.colorMode] or COLOR_LABELS.label)
+    local aligns = {LEFT="左对齐", CENTER="居中", RIGHT="右对齐"}
+    self.alignButton.label:SetText(aligns[self.align] or "左对齐")
+    self.lockButton.label:SetText(self.locked and "已锁定" or "锁定")
+    self.unlockButton.label:SetText(self.locked and "解锁" or "已解锁")
+    if self.locked then self.lockButton:Disable(); self.unlockButton:Enable()
+    else self.lockButton:Enable(); self.unlockButton:Disable() end
+end
+
+P.mainFrame:SetScript("OnShow", function() if P.initialized then P:SyncSettingsControls() end end)
+P.mainFrame:SetScript("OnHide", function() if P.customFrame then P.customFrame:Hide() end end)
+
 -- 切换显示配置（预设或自定义）：统一入口，供按钮 / 命令调用
-function P:SelectConfig(name)
+function P:SelectConfig(name, silent)
+    if not PRESET_KEYS[name] and name ~= "自定义" then return false end
     -- 切到「自定义」前先固化初始勾选（以切换前的预设为准）
     if name == "自定义" then
-        self:EnsureCustomProps()
-    end
-
+        self:EnsureProfile("自定义")
+    end
+
+    local editorShown = self.customFrame and self.customFrame:IsShown()
     self.displayConfig = name
     if not BCSConfig.PropertiesPanel then
         BCSConfig.PropertiesPanel = {}
     end
     BCSConfig.PropertiesPanel.displayConfig = name
 
-    -- 自定义模式同时打开勾选窗口，预设模式则收起
-    if name == "自定义" then
-        self:ShowCustomWindow(true)
-    else
-        self:ShowCustomWindow(false)
+    -- 自定义自动打开编辑器；编辑器已打开时切换预设会同步内容。
+    self:EnsureProfile(name)
+    if silent then
+        if editorShown then self:RefreshCustomRows() end
+    else
+        self:ShowCustomWindow(name == "自定义" or editorShown)
     end
 
     self:SyncConfigButtons()
     self:RefreshNow()
     return true
@@ -475,16 +748,12 @@
 P.configButtons = {}
 for i = 1, numButtons do
     local x = -P.mainFrame:GetWidth() / 2 + spacing * i + buttonWidth * (i - 0.5)
     local buttonText = configTypes[i]
 
-    local btn = CreateButton(buttonText, P.mainFrame, "CENTER", P.mainFrame, x, 15 - 20, function()
+    local btn = CreateButton(buttonText, P.mainFrame, "TOP", P.mainFrame, x, -42, function()
         P:SelectConfig(buttonText)
-        -- 预设按钮点完收起主窗口；自定义按钮保留（勾选窗口就开在它右侧）
-        if buttonText ~= "自定义" then
-            P.mainFrame:Hide()
-        end
     end)
     btn:SetWidth(buttonWidth)
     P.configButtons[i] = btn
 end
 
@@ -538,20 +807,38 @@
     -- 设置悬浮窗位置
     local point = panel.point
     local rel_point = panel.rel_point
     local x = panel.x_offset
     local y = panel.y_offset
+    self.frame:ClearAllPoints()
     self.frame:SetPoint(point, UIParent, rel_point, x, y)
+    self.pendingCenter = nil
+    -- Migrate legacy corner anchors after rendering their original preset,
+    -- so adopting a center anchor does not relocate the existing window.
+    self.centerAfterLayout = point ~= "CENTER" or rel_point ~= "CENTER"
 
     -- 设置显示配置到 P.displayConfig
     self.displayConfig = panel.displayConfig
+    if not PRESET_KEYS[self.displayConfig] and self.displayConfig ~= "自定义" then
+        self.displayConfig = GetDefaultDisplayConfig()
+        panel.displayConfig = self.displayConfig
+    end
+
+    self:LoadAppearance()
+    self:EnsureProfile()
+    self.initialized = true
+    self:SyncSettingsControls()
 
     -- 设置对齐方式
     self.align = panel.align
+    if self.align ~= "LEFT" and self.align ~= "CENTER" and self.align ~= "RIGHT" then
+        self.align, panel.align = "LEFT", "LEFT"
+    end
 
     -- 设置锁定状态
     self.locked = panel.locked
+    self:SetLocked(panel.locked == true)
 
     -- 设置显示状态
     self.showWindow = panel.enabled
     if not self.showWindow then
         self.frame:Hide()
@@ -580,168 +867,168 @@
     end
     local firstLine, restLines = self:GetDisplayLines()
     self:UpdateDisplay(1, firstLine, restLines)
 end
 
--- 更新悬浮窗显示（接收第一行和其余行）
--- 为配合 0.2 秒的定时刷新，这里做了两处省开销处理：
---   1) 排版（锚点/宽度/对齐/标题颜色）只在首次或对齐方式变化时重设一次；
---   2) 文本只在内容真正变化时才 SetText，避免无意义的字体排版。
+-- 多列布局只在布局参数/行数变化时重排；移速仍走 0.2 秒节拍。
 function P:UpdateDisplay(show, firstLine, restLines)
     if show ~= 1 then
         self.frame:Hide()
-        -- 隐藏时停止定时器
-        if self.speedUpdater then
-            self.speedUpdater:Cancel()
-            self.speedUpdater = nil
-        end
+        if self.speedUpdater then self.speedUpdater:Cancel(); self.speedUpdater = nil end
         return
     end
-
-    -- 排版只在首次显示或对齐方式变化时重设
-    if self.appliedAlign ~= self.align then
-        -- 清除旧锚点，根据对齐方式重新设置
+    self:ApplyCenterPosition()
+    local lines = {}
+    local iter = string.gfind or string.gmatch
+    for line in iter(restLines or "", "[^\n]+") do Append(lines, line) end
+    local count = ArrayCount(lines)
+    local rows = self.rowsPerColumn or 0
+    if rows == 0 then rows = math.max(1, count) end
+    local width = self.columnWidth or 140
+    local screenWidth = UIParent:GetWidth() / (self.scale or 1)
+    local maxColumns = math.max(1, math.floor((screenWidth - 8) / (width + 12)))
+    rows = math.max(rows, math.ceil(count / maxColumns))
+    local columns = math.max(1, math.ceil(count / rows))
+    local actualRows = math.min(rows, count)
+    local gap = self.lineGap or 3
+    local titleSize = self.titleFontSize or 16
+    local detailSize = self.detailFontSize or 13
+    local signature = table.concat({self.align or "LEFT", rows, columns, actualRows,
+        width, gap, titleSize, detailSize, self.scale or 1, self.colorMode or "label"}, ":")
+
+    self.frame.columns = self.frame.columns or {self.frame.details}
+    for i = 1, columns do
+        if not self.frame.columns[i] then
+            self.frame.columns[i] = self.frame:CreateFontString(nil, "ARTWORK")
+        end
+    end
+    if self.layoutDirty or self.layoutSignature ~= signature then
+        self.frame:SetScale(self.scale or 1)
+        self.frame.title:SetFont("Fonts\\ARIALN.ttf", titleSize, "OUTLINE")
         self.frame.title:ClearAllPoints()
-        self.frame.details:ClearAllPoints()
-
-        local margin = 10  -- 左右边距
-        local frameWidth = self.frame:GetWidth()
-
-        if self.align == "LEFT" then
-            self.frame.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", margin, -10)
-            self.frame.details:SetPoint("TOPLEFT", self.frame, "TOPLEFT", margin, -30)
-        elseif self.align == "RIGHT" then
-            self.frame.title:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -margin, -10)
-            self.frame.details:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -margin, -30)
-        else -- CENTER
-            self.frame.title:SetPoint("TOP", self.frame, "TOP", 0, -10)
-            self.frame.details:SetPoint("TOP", self.frame, "TOP", 0, -30)
-        end
-        self.frame.title:SetWidth(frameWidth - margin * 2)
-        self.frame.details:SetWidth(frameWidth - margin * 2)
-
-        -- 设置对齐方式
-        self.frame.title:SetJustifyH(self.align)
-        self.frame.details:SetJustifyH(self.align)
-
-        -- 根据当前职业设置标题颜色
+        self.frame.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -10)
+        self.frame.title:SetJustifyH(self.align or "LEFT")
         local _, class = UnitClass("player")
-        local color = RAID_CLASS_COLORS[class]
-        if color then
-            self.frame.title:SetTextColor(color.r, color.g, color.b)
-        else
-            self.frame.title:SetTextColor(1, 1, 1)
-        end
-
-        -- 排版变化后强制重写一次文本
-        self.appliedAlign = self.align
-        self.lastFirstLine = nil
-        self.lastRestLines = nil
-    end
-
-    -- 仅在内容变化时写文本
+        local color = self.colorMode == "off" and RAID_CLASS_COLORS[class]
+        if color then self.frame.title:SetTextColor(color.r, color.g, color.b)
+        else self.frame.title:SetTextColor(1, 1, 1) end
+        self.frame:SetWidth(columns * width + (columns - 1) * 12 + 20)
+        self.frame:SetHeight(titleSize + 22 + actualRows * (detailSize + gap))
+        self.frame.title:SetWidth(self.frame:GetWidth() - 20)
+        for i = 1, ArrayCount(self.frame.columns) do
+            local text = self.frame.columns[i]
+            text:SetFont("Fonts\\ARIALN.ttf", detailSize, "OUTLINE")
+            text:SetTextColor(1, 1, 1)
+            text:SetJustifyH(self.align or "LEFT")
+            text:SetJustifyV("TOP")
+            if text.SetSpacing then text:SetSpacing(gap) end
+            text:ClearAllPoints()
+            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (i - 1) * (width + 12), -(titleSize + 18))
+            text:SetWidth(width)
+        end
+        self.layoutSignature, self.layoutDirty = signature, false
+        self.lastFirstLine, self.lastColumnTexts = nil, {}
+        self.measurementDirty = true
+    end
     if self.lastFirstLine ~= firstLine then
-        self.frame.title:SetText(firstLine)
+        self.frame.title:SetText(firstLine or "（未选择属性）")
         self.lastFirstLine = firstLine
-    end
-    if self.lastRestLines ~= restLines then
-        self.frame.details:SetText(restLines)
-        self.lastRestLines = restLines
-    end
-
-    -- 根据锁定状态设置鼠标启用/禁用（锁定则禁用鼠标，实现点击穿透）
+        self.measurementDirty = true
+    end
+    self.lastColumnTexts = self.lastColumnTexts or {}
+    for i = 1, ArrayCount(self.frame.columns) do
+        local text = self.frame.columns[i]
+        if i <= columns and count > 0 then
+            local values = {}
+            for j = (i - 1) * rows + 1, math.min(i * rows, count) do Append(values, lines[j]) end
+            local value = table.concat(values, "\n")
+            if self.lastColumnTexts[i] ~= value then
+                text:SetText(value)
+                self.lastColumnTexts[i] = value
+                self.measurementDirty = true
+            end
+            text:Show()
+        else text:Hide() end
+    end
+    -- 窄列/大字体发生换行时按实际文字高度扩展，防止底部属性被裁切。
+    if self.measurementDirty then
+        local titleHeight = titleSize
+        if self.frame.title.GetStringHeight then
+            titleHeight = math.max(titleHeight, self.frame.title:GetStringHeight() or 0)
+        end
+        local bodyHeight = actualRows * (detailSize + gap)
+        for i = 1, columns do
+            local text = self.frame.columns[i]
+            if count > 0 and text.GetStringHeight then
+                bodyHeight = math.max(bodyHeight, text:GetStringHeight() or 0)
+            end
+            text:ClearAllPoints()
+            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (i - 1) * (width + 12), -(titleHeight + 18))
+        end
+        self.frame:SetHeight(titleHeight + 22 + bodyHeight)
+        self.measurementDirty = false
+    end
     self.frame:EnableMouse(not self.locked)
-
     self.frame:Show()
-
-    -- 启动实时移速刷新定时器（如果尚未启动）
+    if self.centerAfterLayout and not self.dragging then
+        self:SaveCenterPosition()
+        self:ApplyCenterPosition()
+    end
     if not self.speedUpdater then
         self.speedUpdater = C_Timer.NewTicker(FAST_TICK, function() P:RefreshSpeedDisplay() end)
     end
 end
 
 -- 获取移动速度显示字符串（供聊天发送使用，总是返回字符串）
 function P:DisplaySpeed()
-    local ok, speed1 = pcall(UnitXP, "speed", "player")
-    if ok and speed1 then
+    local speed1 = ReadNumber(UnitXP, "speed", "player")
+    if speed1 then
         local percent = speed1 * 100 / 7
         return string.format("移速: %.1f%%", percent)
     else
         return "移速: 数据不可用"
     end
 end
 
--- 真正重建属性内容（会触发 BCS 各重量级取值函数，属于节流对象）
--- 注意：只写入缓存，不含移速行
+-- 一次重建内三项防御概率使用同一快照；聊天发送独立重新取值。
 function P:BuildBody()
-    -- 悬浮窗独立计算：临时绕过 helper.lua 的「按 C 面板当前分页才计算」限制，
-    -- 使显示内容不受角色面板当前选中的分类影响（用完立即还原）
-    local prevForce = BCS.ForceCalculate
+    local previousForce = BCS.ForceCalculate
     BCS.ForceCalculate = true
-
-    -- 统一走属性注册表：预设与自定义共用同一条输出链路，
-    -- 保证勾选窗口里看到的顺序 = 悬浮窗顺序 = 聊天文本顺序
+    self.defenseSnapshot = {
+        dodge = ReadNumber(GetDodgeChance),
+        parry = ReadNumber(GetParryChance),
+        block = ReadNumber(GetBlockChance),
+    }
     local keys = self:GetSelectedKeys()
-    local firstLine = nil          -- 第一个属性作为大字标题行
-    local restLines = ""
-
+    local entries = {}
     for i = 1, ArrayCount(keys) do
-        local text = self:GetPropertyText(keys[i])
-        if text then
-            if firstLine == nil then
-                firstLine = text
-            elseif restLines == "" then
-                restLines = text
-            else
-                restLines = restLines .. "\n" .. text
-            end
-        end
-    end
-
-    if firstLine == nil then
-        firstLine = "（未选择属性）"
-    end
-
-    -- 还原按需计算开关
-    BCS.ForceCalculate = prevForce
-
-    -- 写入缓存并清除脏标记（移速行在 GetDisplayLines 中另行拼接）
-    self.bodyFirstLine = firstLine
-    self.bodyRestLines = restLines
+        local key = keys[i]
+        -- 移速只存位置，实时数值在 GetDisplayLines 中拼接。
+        Append(entries, {key=key, text=key ~= "speed" and self:GetPropertyText(key) or nil})
+    end
+    self.defenseSnapshot = nil
+    BCS.ForceCalculate = previousForce
+    self.bodyEntries = entries
+    self.bodyTitleKey = self:GetTitleKey()
     self.lastBodyRefresh = GetTime()
-    self.bodyDirty = false
-    self.forceNextBuild = false
-end
-
--- 获取悬浮窗显示内容（返回第一行和其余行）
--- 节流：属性内容仅在「脏标记 + 最小间隔」或「超过最大间隔」时重建，
--- 其余刷新只重新拼接移速行（UnitXP 单次调用，开销可忽略）
+    self.bodyDirty, self.forceNextBuild = false, false
+end
+
 function P:GetDisplayLines()
     local elapsed = GetTime() - (self.lastBodyRefresh or 0)
-
-    if self.bodyRestLines == nil
-        or self.forceNextBuild
+    if not self.bodyEntries or self.forceNextBuild
         or (self.bodyDirty and elapsed >= MIN_BODY_REFRESH)
-        or (elapsed >= MAX_BODY_REFRESH) then
-        self:BuildBody()
-    end
-
-    local restLines = self.bodyRestLines or ""
-
-    -- 移速行每拍实时拼接（UnitXP 单次调用，开销可忽略）；自定义模式下可被取消勾选
-    if self:IsSpeedShown() then
-        local speedLine = GetSpeedLine()
-        if speedLine then
-            if restLines == "" then
-                restLines = speedLine
-            else
-                restLines = restLines .. "\n" .. speedLine
-            end
-        end
-    end
-
-    return self.bodyFirstLine, restLines
+        or elapsed >= MAX_BODY_REFRESH then self:BuildBody() end
+    local firstLine, rest = nil, {}
+    for i = 1, ArrayCount(self.bodyEntries) do
+        local entry = self.bodyEntries[i]
+        local text = entry.key == "speed" and self:DisplaySpeed() or entry.text
+        text = self:FormatPropertyText(entry.key, text or "数据不可用")
+        if entry.key == self.bodyTitleKey then firstLine = text
+        else Append(rest, text) end
+    end
+    return firstLine or "（未选择属性）", table.concat(rest, "\n")
 end
 
 -- 以下为原有函数，保持不变（用于聊天和内部调用）
 -- 获取用于聊天的属性字符串
 function P:GetPropertiesForChat()
@@ -765,16 +1052,10 @@
                 parts[n] = text
             end
         end
     end
 
-    -- 移速行：预设恒显示，自定义由勾选项决定
-    if self:IsSpeedShown() then
-        n = n + 1
-        parts[n] = self:DisplaySpeed()
-    end
-
     -- 还原按需计算开关
     BCS.ForceCalculate = prevForce
 
     return playerName .. " (Lv" .. playerLevel .. " " .. playerClass .. "): " .. itemScore ..
            " 当前属性 (" .. self.displayConfig .. "): " .. table.concat(parts, ", ")
@@ -828,12 +1109,12 @@
     self.mainFrame:Hide()
 end
 
 -- 以下为各属性显示函数（均调用BCS函数）
 function P:GetItemScore()
-    if ItemSocre then
-        local playerScore = ItemSocre:ScanUnit("player")
+    if ItemSocre and type(ItemSocre.ScanUnit) == "function" then
+        local playerScore = ReadNumber(ItemSocre.ScanUnit, ItemSocre, "player")
         if playerScore and playerScore > 0 then
             return "装等: " .. playerScore
         end
     end
     return "装等: 数据不可用"
@@ -914,26 +1195,26 @@
 end
 
 function P:DisplayRangedHitRating()
     if BCS and BCS.GetRangedHitRating then
         local hit = BCS:GetRangedHitRating()
-        return "命中: " .. math.floor(hit + 0.5) .. "%"
-    else
-        return "命中: 数据不可用"
+        return "远程命中: " .. math.floor(hit + 0.5) .. "%"
+    else
+        return "远程命中: 数据不可用"
     end
 end
 
 function P:DisplayRangedCritChance()
     if BCS then
         local success, crit = pcall(BCS.GetRangedCritChance, BCS)
         if success and crit then
-            return "暴击: " .. string.format("%.2f", crit) .. "%"
+            return "远程暴击: " .. string.format("%.2f", crit) .. "%"
         else
-            return "暴击: 数据获取失败"
-        end
-    else
-        return "暴击: 数据不可用"
+            return "远程暴击: 数据获取失败"
+        end
+    else
+        return "远程暴击: 数据不可用"
     end
 end
 
 function P:DisplaySpellCrit()
     if BCS then
@@ -1006,56 +1287,106 @@
 end
 
 function P:DisplayAttackSpeed()
     local _, playerClass = UnitClass("player")
     if playerClass == "HUNTER" then
-        local speed = select(1, UnitRangedDamage("player"))
+        local speed = UnitRangedDamage("player")
         return string.format("攻速: %.2f", math.floor(speed * 100 + 0.5) / 100)
     else
-        local speed = select(1, UnitAttackSpeed("player"))
+        local speed = UnitAttackSpeed("player")
         return string.format("攻速: %.2f", speed)
     end
 end
 
 -- 以下三个防御类取值在自定义模式下可能被任意职业勾选，故统一 pcall 兜底，
 -- 避免个别客户端缺少对应全局 API 时整行丢失
 function P:DisplayDodge()
-    local ok, dodge = pcall(GetDodgeChance)
-    if ok and dodge then
+    local dodge = self:GetDefenseChance("dodge")
+    if dodge then
         return "躲闪: " .. string.format("%.2f", dodge) .. "%"
     end
     return "躲闪: 数据不可用"
 end
 
 function P:DisplayParry()
-    local ok, parry = pcall(GetParryChance)
-    if ok and parry then
+    local parry = self:GetDefenseChance("parry")
+    if parry then
         return "招架: " .. string.format("%.2f", parry) .. "%"
     end
     return "招架: 数据不可用"
 end
 
 function P:DisplayBlock()
-    local ok, block = pcall(GetBlockChance)
-    if ok and block then
+    local block = self:GetDefenseChance("block")
+    if block then
         return "格挡: " .. string.format("%.2f", block) .. "%"
     end
     return "格挡: 数据不可用"
 end
 
 function P:DisplayBlockValue()
-    local ok, value = pcall(GetBlockValue)
-    if ok and value then
+    local value = ReadNumber(GetBlockValue)
+    if value == nil and BCS and type(BCS.GetBlockValue) == "function" then
+        value = ReadNumber(BCS.GetBlockValue, BCS)
+    end
+    if value then
         return "格挡值: " .. math.floor(value + 0.5)
     end
     return "格挡值: 数据不可用"
+end
+
+function P:GetDefenseChance(key)
+    if self.defenseSnapshot then return self.defenseSnapshot[key] end
+    if key == "dodge" then return ReadNumber(GetDodgeChance) end
+    if key == "parry" then return ReadNumber(GetParryChance) end
+    if key == "block" then return ReadNumber(GetBlockChance) end
+    return nil
+end
+
+function P:DisplayThreeDimensions()
+    local dodge = self:GetDefenseChance("dodge")
+    local parry = self:GetDefenseChance("parry")
+    local block = self:GetDefenseChance("block")
+    if dodge == nil or parry == nil or block == nil then return "三维: 数据不可用" end
+    return string.format("三维: %.2f%%", dodge + parry + block)
+end
+
+function P:DisplayResistance(school, label)
+    if type(UnitResistance) ~= "function" then return label .. ": 数据不可用" end
+    local ok, base, effective = pcall(UnitResistance, "player", school)
+    if not ok then return label .. ": 数据不可用" end
+    -- 某些扩展客户端只返回一个值；第二返回值存在但无效时不伪装成基础值。
+    local value = effective
+    if value == nil then value = base end
+    if not IsFiniteNumber(value) then return label .. ": 数据不可用" end
+    return label .. ": " .. math.floor(value + 0.5)
+end
+
+function P:DisplayArmorReduction()
+    local _, armor = UnitArmor("player")
+    -- 有目标时以目标等级为准，无目标时以玩家等级为参照。
+    local level = UnitLevel(UnitExists("target") and "target" or "player")
+    -- “？级”目标返回 -1，按玩家等级 + 3 估算，避免将等级标记作为无效数据。
+    if level == -1 then
+        local playerLevel = UnitLevel("player")
+        if IsFiniteNumber(playerLevel) and playerLevel > 0 then
+            level = playerLevel + 3
+        end
+    end
+    if not IsFiniteNumber(armor) or not IsFiniteNumber(level) or level <= 0 then
+        return "减伤: 数据不可用"
+    end
+    armor = math.max(0, armor)
+    local reduction = math.min(0.75, armor / (armor + 400 + 85 * level)) * 100
+    return string.format("减伤: %.2f%%", reduction)
 end
 
 function P:DisplayArmor()
     if BCS then
         local base, effectiveArmor, armor = UnitArmor("player")
-        return "护甲: " .. armor
+        if not IsFiniteNumber(effectiveArmor) then return "护甲: 数据不可用" end
+        return "护甲: " .. math.floor(effectiveArmor + 0.5)
     else
         return "护甲: 数据不可用"
     end
 end
 
@@ -1075,223 +1406,250 @@
     else
         return "破甲: 数据不可用"
     end
 end
 
--- ===== 自定义属性勾选窗口 =====
--- 与主配置窗口并排显示；勾选即时生效（只标脏，走节流路径）
-local CBOX_ROW_H = 18          -- 每行高度
-local CBOX_COLS  = 2           -- 列数
-local CBOX_COL_W = 132         -- 每列宽度
-
+-- ===== 当前预设属性编辑器 =====
+local CBOX_ROW_H, CBOX_COLS, CBOX_COL_W = 20, 2, 166
 local itemCount = ArrayCount(PROPERTY_LIST)
-local rowCount  = math.ceil(itemCount / CBOX_COLS)
+local rowCount = math.ceil(itemCount / CBOX_COLS)
 
 P.customFrame = CreateFrame("Frame", "BCSPropertiesPanelCustomFrame", UIParent)
-P.customFrame:SetWidth(CBOX_COL_W * CBOX_COLS + 24)
-P.customFrame:SetHeight(112 + rowCount * CBOX_ROW_H)
-P.customFrame:SetBackdrop({
-    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
-    tile = true,
-    tileSize = 16,
-})
-P.customFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
-P.customFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)
+P.customFrame:SetWidth(CBOX_COL_W * CBOX_COLS + 28)
+P.customFrame:SetHeight(194 + rowCount * CBOX_ROW_H)
+P.customFrame:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize=16})
+P.customFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.94)
 P.customFrame:SetMovable(true)
 P.customFrame:EnableMouse(true)
 P.customFrame:RegisterForDrag("LeftButton")
 P.customFrame:SetScript("OnDragStart", function() P.customFrame:StartMoving() end)
 P.customFrame:SetScript("OnDragStop", function() P.customFrame:StopMovingOrSizing() end)
 P.customFrame:SetFrameStrata("DIALOG")
 P.customFrame:Hide()
 
-local customTitle = P.customFrame:CreateFontString(nil, "OVERLAY")
-customTitle:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
-customTitle:SetPoint("TOP", 0, -8)
-customTitle:SetText("自定义属性")
-customTitle:SetTextColor(1, 0.82, 0)
-
-local customHint = P.customFrame:CreateFontString(nil, "OVERLAY")
-customHint:SetFont(STANDARD_TEXT_FONT, 11)
-customHint:SetPoint("TOP", 0, -27)
-customHint:SetText("勾选即时生效，第一项显示为大字标题")
-customHint:SetTextColor(0.7, 0.7, 0.7)
-
--- 避让排版：右侧放不下就改放左侧，避免小分辨率下被裁切
+local function EditorLabel(text, x, y, size)
+    local label = P.customFrame:CreateFontString(nil, "OVERLAY")
+    label:SetFont(STANDARD_TEXT_FONT, size or 12)
+    label:SetPoint("TOPLEFT", x, y)
+    label:SetText(text)
+    return label
+end
+P.editorTitle = EditorLabel("编辑预设", 14, -10, 14)
+P.editorTitle:SetTextColor(1, 0.82, 0)
+EditorLabel("各预设分别保存，标题项不重复显示", 14, -32, 11):SetTextColor(0.75, 0.75, 0.75)
+EditorLabel("大字标题", 14, -61)
+EditorLabel("排序属性", 14, -91)
+EditorLabel("减伤参照", 14, -122)
+EditorLabel("当前目标；无目标时按自身等级计算", 86, -122, 10)
+
+local editorClose = CreateButton("关闭", P.customFrame, "TOPRIGHT", P.customFrame, -12, -8,
+    function() P.customFrame:Hide() end)
+editorClose:SetWidth(46)
+
+function P:SetTitleKey(key)
+    local profile = self:EnsureProfile()
+    if key ~= "auto" and not profile.props[key] then return end
+    profile.titleKey = key
+    self:RefreshCustomRows()
+    self:RefreshNow()
+end
+
+function P:MoveProperty(key, direction)
+    local profile = self:EnsureProfile()
+    local keys = self:GetSelectedKeys()
+    for i = 1, ArrayCount(keys) do
+        if keys[i] == key then
+            local nextIndex = i + direction
+            if nextIndex < 1 or nextIndex > ArrayCount(keys) then return end
+            keys[i], keys[nextIndex] = keys[nextIndex], keys[i]
+            -- 未选项保留在尾部，之后重新勾选时可恢复。
+            local seen = {}
+            for j = 1, ArrayCount(keys) do seen[keys[j]] = true end
+            for j = 1, ArrayCount(profile.order) do
+                if not seen[profile.order[j]] then Append(keys, profile.order[j]) end
+            end
+            profile.order = keys
+            self:RefreshCustomRows()
+            self:RefreshNow()
+            return
+        end
+    end
+end
+
+local function CreateEditorMenu(name, y, titleMenu)
+    local menu = CreateFrame("Frame", name, P.customFrame, "UIDropDownMenuTemplate")
+    menu:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", 86, y)
+    UIDropDownMenu_SetWidth(130, menu)
+    UIDropDownMenu_Initialize(menu, function()
+        if not P.initialized then return end
+        local profile = P:EnsureProfile()
+        if titleMenu then
+            local info = {text="自动（第一项）", value="auto", checked=profile.titleKey == "auto"}
+            info.func = function() P:SetTitleKey("auto") end
+            UIDropDownMenu_AddButton(info)
+        end
+        local keys = P:GetSelectedKeys()
+        for i = 1, ArrayCount(keys) do
+            local key = keys[i]
+            local info = {text=PROPERTY_BY_KEY[key].label, value=key}
+            if titleMenu then
+                info.checked = profile.titleKey == key
+                info.func = function() P:SetTitleKey(key) end
+            else
+                info.checked = P.sortKey == key
+                info.func = function() P.sortKey = key; P:RefreshCustomRows() end
+            end
+            UIDropDownMenu_AddButton(info)
+        end
+    end)
+    return menu
+end
+P.titleMenu = CreateEditorMenu("BCSPropertiesTitleMenu", -51, true)
+P.sortMenu = CreateEditorMenu("BCSPropertiesSortMenu", -81, false)
+local upButton = CreateButton("上移", P.customFrame, "TOPLEFT", P.customFrame, 254, -84,
+    function() if P.sortKey then P:MoveProperty(P.sortKey, -1) end end)
+upButton:SetWidth(40)
+local downButton = CreateButton("下移", P.customFrame, "TOPLEFT", P.customFrame, 304, -84,
+    function() if P.sortKey then P:MoveProperty(P.sortKey, 1) end end)
+downButton:SetWidth(40)
+
 local function PositionCustomWindow()
     local f = P.customFrame
-    local screenW = 1024
-    if GetScreenWidth then
-        local ok, w = pcall(GetScreenWidth)
-        if ok and w and w > 0 then screenW = w end
-    end
+    local screenW = UIParent:GetWidth()
+    local right, left = P.mainFrame:GetRight(), P.mainFrame:GetLeft()
     f:ClearAllPoints()
-    local frameRight = nil
-    if P.mainFrame.GetRight then
-        local ok, right = pcall(P.mainFrame.GetRight, P.mainFrame)
-        if ok and right then frameRight = right end
-    end
-    if frameRight and (frameRight + f:GetWidth() + 10 > screenW - 4) then
+    if right and right + f:GetWidth() + 10 <= screenW - 4 then
+        f:SetPoint("TOPLEFT", P.mainFrame, "TOPRIGHT", 10, 0)
+    elseif left and left - f:GetWidth() - 10 >= 4 then
         f:SetPoint("TOPRIGHT", P.mainFrame, "TOPLEFT", -10, 0)
-    else
-        f:SetPoint("TOPLEFT", P.mainFrame, "TOPRIGHT", 10, 0)
-    end
-end
-
--- 单个勾选行（点击整行切换；左侧方框用官方勾选贴图表示状态）
-local function CreateCheckRow(parent, label, x, y, isChecked, onToggle)
-    local row = CreateFrame("Button", nil, parent)
+    else f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
+end
+
+local function CreateCheckRow(item, x, y)
+    local key = item.key
+    local row = CreateFrame("Button", nil, P.customFrame)
     row:SetWidth(CBOX_COL_W)
     row:SetHeight(CBOX_ROW_H)
-    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
-
-    local box = row:CreateTexture(nil, "ARTWORK")
-    box:SetWidth(14)
-    box:SetHeight(14)
-    box:SetPoint("LEFT", 0, 0)
-
-    local hl = row:CreateTexture(nil, "HIGHLIGHT")
-    hl:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
-    hl:SetWidth(14)
-    hl:SetHeight(14)
-    hl:SetPoint("LEFT", 0, 0)
-    if hl.SetBlendMode then hl:SetBlendMode("ADD") end
-
-    local text = row:CreateFontString(nil, "OVERLAY")
-    text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
-    text:SetPoint("LEFT", box, "RIGHT", 3, 0)
-    text:SetText(label)
-
-    row.box = box
-    row.text = text
-
+    row:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", x, y)
+    row.box = row:CreateTexture(nil, "ARTWORK")
+    row.box:SetWidth(14)
+    row.box:SetHeight(14)
+    row.box:SetPoint("LEFT", 0, 0)
+    row.text = row:CreateFontString(nil, "OVERLAY")
+    row.text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
+    row.text:SetPoint("LEFT", row.box, "RIGHT", 3, 0)
+    row.text:SetText(item.label)
+    row.key = key
     function row:Refresh()
-        if isChecked() then
-            box:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
-            text:SetTextColor(1, 1, 1)
-        else
-            box:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
-            text:SetTextColor(0.6, 0.6, 0.6)
-        end
-    end
-
+        local selected = P:EnsureProfile().props[key]
+        row.box:SetTexture(selected and "Interface\\Buttons\\UI-CheckBox-Check" or "Interface\\Buttons\\UI-CheckBox-Up")
+        local label = item.label
+        if P:GetTitleKey() == key then label = label .. "（标题）" end
+        row.text:SetText(label)
+        if selected then
+            local color = PROPERTY_COLORS[key]
+            if P.colorMode ~= "off" and color then row.text:SetText("|cFF" .. color .. label .. "|r") end
+            row.text:SetTextColor(1, 1, 1)
+        else row.text:SetTextColor(0.6, 0.6, 0.6) end
+    end
     row:SetScript("OnClick", function()
-        onToggle()
-        row:Refresh()
+        local profile = P:EnsureProfile()
+        profile.props[key] = not profile.props[key] or nil
+        if profile.props[key] then
+            local found = false
+            for i = 1, ArrayCount(profile.order) do if profile.order[i] == key then found = true end end
+            if not found then Append(profile.order, key) end
+        elseif profile.titleKey == key then profile.titleKey = "auto" end
+        P:RefreshCustomRows()
+        P:MarkDirty()
     end)
-    row:SetScript("OnEnter", function() text:SetTextColor(1, 0.82, 0) end)
-    row:SetScript("OnLeave", function() row:Refresh() end)
-
-    -- 注意：此处不要 Refresh()。本函数在文件加载期被调用，那时 BCSConfig /
-    -- displayConfig 尚未就绪，提前读取会污染保存配置（勾选表被错误种子创建）。
-    -- 外观统一由 P:RefreshCustomRows() 在窗口显示前刷新。
+    row:SetScript("OnEnter", function()
+        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
+        if key == "three" then
+            GameTooltip:SetText("三维：躲闪概率 + 招架概率 + 格挡概率")
+            GameTooltip:AddLine("使用原始百分比求和后保留两位小数。", 0.8, 0.8, 0.8, 1)
+        elseif key == "armorDR" then
+            GameTooltip:SetText("减伤（经典规则估算）")
+            GameTooltip:AddLine("按有效护甲与当前目标等级计算，上限 75%。", 0.8, 0.8, 0.8, 1)
+            GameTooltip:AddLine("无目标时按自身等级计算；？级目标按自身等级 + 3 估算。", 0.8, 0.8, 0.8, 1)
+            GameTooltip:AddLine("不包含姿态、天赋、技能减伤或魔法抗性。", 0.8, 0.8, 0.8, 1)
+        else GameTooltip:SetText(item.label) end
+        GameTooltip:Show()
+    end)
+    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
     return row
 end
 
--- 按注册表生成所有属性勾选项（行优先两列：阅读顺序 = 显示顺序）
 P.customRows = {}
 for i = 1, itemCount do
-    local item = PROPERTY_LIST[i]
-    local key = item.key
-    -- 不用 % 运算符，兼容 Lua 5.0
     local r = math.floor((i - 1) / CBOX_COLS)
     local col = (i - 1) - r * CBOX_COLS
-    local x = 12 + col * CBOX_COL_W
-    local y = -(46 + r * CBOX_ROW_H)
-
-    P.customRows[i] = CreateCheckRow(P.customFrame, item.label, x, y,
-        function()
-            return P:EnsureCustomProps()[key] == true
-        end,
-        function()
-            local props = P:EnsureCustomProps()
-            if props[key] then
-                props[key] = nil
-            else
-                props[key] = true
-            end
-            P:MarkDirty()   -- 只标脏，连点也不会触发多轮重扫
-        end)
-end
-
--- 移速行（仍在 0.2 秒节拍上实时刷新，仅受勾选开关控制）
-P.customSpeedRow = CreateCheckRow(P.customFrame, "移速（实时）", 12, -(46 + rowCount * CBOX_ROW_H + 4),
-    function()
-        return P:EnsureCustomProps().speed ~= false
-    end,
-    function()
-        local props = P:EnsureCustomProps()
-        if props.speed == false then
-            props.speed = true
-        else
-            props.speed = false
-        end
-        P:MarkDirty()
-    end)
-
--- 全选
-local selectAllBtn = CreateButton("全选", P.customFrame, "BOTTOM", P.customFrame, -95, 10, function()
-    local props = P:EnsureCustomProps()
-    for i = 1, itemCount do
-        props[PROPERTY_LIST[i].key] = true
-    end
-    props.speed = true
+    P.customRows[i] = CreateCheckRow(PROPERTY_LIST[i], 14 + col * CBOX_COL_W, -(150 + r * CBOX_ROW_H))
+end
+
+function P:ResetCurrentProfile()
+    local panel = PanelConfig()
+    local name = self.displayConfig
+    panel.profiles[name] = nil
+    if name == "自定义" then panel.customProps = nil end
+    self:EnsureProfile(name)
+    self.sortKey = nil
+    self:RefreshCustomRows()
+    self:RefreshNow()
+end
+
+local selectAll = CreateButton("全选", P.customFrame, "BOTTOM", P.customFrame, -126, 10, function()
+    local profile = P:EnsureProfile()
+    for i = 1, itemCount do profile.props[PROPERTY_LIST[i].key] = true end
     P:RefreshCustomRows()
     P:MarkDirty()
 end)
-selectAllBtn:SetWidth(78)
-
--- 清空
-local clearAllBtn = CreateButton("清空", P.customFrame, "BOTTOM", P.customFrame, 0, 10, function()
-    local props = P:EnsureCustomProps()
-    for i = 1, itemCount do
-        props[PROPERTY_LIST[i].key] = nil
-    end
-    props.speed = false
+selectAll:SetWidth(56)
+local clearAll = CreateButton("清空", P.customFrame, "BOTTOM", P.customFrame, -52, 10, function()
+    local profile = P:EnsureProfile()
+    for key in pairs(profile.props) do profile.props[key] = nil end
+    profile.titleKey = "auto"
     P:RefreshCustomRows()
     P:MarkDirty()
 end)
-clearAllBtn:SetWidth(78)
-
--- 完成：立即刷新一次并收起窗口
-local doneBtn = CreateButton("完成", P.customFrame, "BOTTOM", P.customFrame, 95, 10, function()
+clearAll:SetWidth(56)
+local reset = CreateButton("恢复预设", P.customFrame, "BOTTOM", P.customFrame, 32, 10,
+    function() P:ResetCurrentProfile() end)
+reset:SetWidth(76)
+local done = CreateButton("完成", P.customFrame, "BOTTOM", P.customFrame, 126, 10, function()
+    ApplyReductionLevel()
     P:RefreshNow()
     P.customFrame:Hide()
 end)
-doneBtn:SetWidth(78)
-
--- 供外部/测试访问
-P.customButtons = { selectAll = selectAllBtn, clearAll = clearAllBtn, done = doneBtn }
-
--- 刷新所有勾选框外观（读配置表，与显示状态对齐）
+done:SetWidth(56)
+P.customButtons = {selectAll=selectAll, clearAll=clearAll, reset=reset, done=done}
+
 function P:RefreshCustomRows()
-    if self.customRows then
-        for i = 1, ArrayCount(self.customRows) do
-            self.customRows[i]:Refresh()
-        end
-    end
-    if self.customSpeedRow then
-        self.customSpeedRow:Refresh()
-    end
-end
-
--- 显示/隐藏勾选窗口
+    local profile = self:EnsureProfile()
+    self.editorTitle:SetText("编辑预设：" .. (self.displayConfig or "自定义"))
+    for i = 1, ArrayCount(self.customRows) do self.customRows[i]:Refresh() end
+    local title = profile.titleKey == "auto" and "自动（第一项）" or PROPERTY_BY_KEY[profile.titleKey].label
+    UIDropDownMenu_SetText(title, self.titleMenu)
+    local keys = self:GetSelectedKeys()
+    if not self.sortKey or not profile.props[self.sortKey] then self.sortKey = keys[1] end
+    UIDropDownMenu_SetText(self.sortKey and PROPERTY_BY_KEY[self.sortKey].label or "未选择属性", self.sortMenu)
+end
+
 function P:ShowCustomWindow(show)
     if show then
-        self:EnsureCustomProps()
         self:RefreshCustomRows()
         PositionCustomWindow()
         self.customFrame:Show()
-    else
-        self.customFrame:Hide()
-    end
+    else self.customFrame:Hide() end
 end
 
 -- 事件处理
 P.frame:RegisterEvent("ADDON_LOADED")
 P.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
 P.frame:RegisterEvent("UNIT_AURA")
+P.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
+P.frame:RegisterEvent("UNIT_LEVEL")
 
 P.frame:SetScript("OnEvent", function(self, event, arg1)
     -- 兼容两种 SetScript 回调约定：
     --   A) 现代写法：回调收到 (self, event, arg1)
     --   B) 香草 1.12：回调不传参，事件名与参数只在全局 event / arg1 上
@@ -1313,10 +1671,13 @@
         -- 调用初始化函数
         P:Init()
 
         DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已加载，输入 /mb 呼出配置选择窗口", 1, 1, 1)
     end
+
+    -- 切换目标时立即更新减伤参照，其余事件保留节流。
+    if event == "PLAYER_TARGET_CHANGED" then P.forceNextBuild = true end
 
     -- 事件只标记「需要重建」，具体重建时机交给节流逻辑（最小间隔 + 最大间隔），
     -- 避免战斗中光环频繁变化时每 0.2 秒重扫一遍全部装备
     -- 另：本面板只显示玩家自身数值，UNIT_AURA 只需响应 player（arg1 为 nil 时保守放行）
     if event ~= "UNIT_AURA" or not arg1 or arg1 == "player" then
@@ -1398,40 +1759,32 @@
         if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
         BCSConfig.PropertiesPanel.align = "RIGHT"
         P:RefreshNow()
         DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 对齐方式设置为右对齐", 1, 1, 1)
     elseif arg == "lock" then
-        P.locked = true
-        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
-        BCSConfig.PropertiesPanel.locked = true
-        P:RefreshNow()
-        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已锁定，点击穿透开启", 1, 1, 1)
+        P:SetLocked(true, true)
     elseif arg == "unlock" then
-        P.locked = false
-        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
-        BCSConfig.PropertiesPanel.locked = false
-        P:RefreshNow()
-        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已解锁，可拖动", 1, 1, 1)
+        P:SetLocked(false, true)
     elseif arg == "togglelock" then
         if P.locked then
             HandleSlashCommand("unlock")
         else
             HandleSlashCommand("lock")
         end
     elseif arg == "custom" or arg == "自定义" then
         -- 切换到自定义模式并打开勾选窗口
         P:SelectConfig("自定义")
         P.mainFrame:Show()
-        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已切换到自定义属性，请在勾选窗口中勾选要显示的条目", 1, 1, 1)
+        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已切换到自定义属性，可勾选属性、选择大字标题和调整顺序", 1, 1, 1)
     elseif arg == "panel" or arg == "charpanel" or arg == "角色面板" then
         -- 切换「是否在角色面板中显示 BCS 属性」
         P:SetCharacterPanelEnabled(P.characterPanelEnabled == false)
-    elseif arg:match("^align ") then
+    elseif string.find(arg, "^align ") then
         DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 未知的对齐方式，可用：left, center, right", 1, 0, 0)
     else
         -- 未知参数，提示用法
-        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开配置窗口，/mb custom 自定义属性勾选窗口，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 0, 0)
+        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开设置，编辑当前预设可增减属性/设置标题/排序；/mb custom 打开独立自定义，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 0, 0)
     end
 end
 
 SLASH_PROPERTIESPANEL1 = "/mb"
 SlashCmdList["PROPERTIESPANEL"] = HandleSlashCommand
```
