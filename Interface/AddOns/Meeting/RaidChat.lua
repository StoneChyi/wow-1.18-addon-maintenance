-- Raid-only world recruitment recognition. No timers, UI, network or saved chat log.
-- Kept separate from LFT activity codes: WORLD/HARDCORE still use whisper/60s expiry.
local R = {}
Meeting.RaidChat = R

R.catalog = {
    { code = "MC", name = "熔火之心", aliases = { "熔火之心", "融火之心", "熔火", "molten core", "mc" } },
    { code = "ONY", name = "奥妮克希亚的巢穴", aliases = { "奥妮克希亚的巢穴", "奧妮克希亞的巢穴", "奥妮克希亚", "奧妮克希亞", "黑龙公主", "黑龍公主", "onyxia's lair", "onyxia", "黑龙", "黑龍", "ony" } },
    { code = "BWL", name = "黑翼之巢", aliases = { "黑翼之巢", "blackwing lair", "黑翼", "bwl" } },
    { code = "AQ40", name = "安其拉神殿", aliases = { "安其拉神殿", "安其拉神庙", "安其拉神廟", "40人安其拉", "temple of ahn'qiraj", "ahn'qiraj temple", "aq40", "taq" } },
    { code = "NAXX", name = "纳克萨玛斯", aliases = { "纳克萨玛斯", "纳克萨马斯", "納克薩瑪斯", "naxxramas", "naxramas", "纳克", "納克", "naxx", "nax", "nx" } },
    { code = "ZUG", name = "祖尔格拉布", aliases = { "祖尔格拉布", "祖爾格拉布", "祖格", "龙虎金", "龍虎金", "zul'gurub", "zul gurub", "zulgurub", "zug", "zg" } },
    { code = "AQ20", name = "安其拉废墟", aliases = { "安其拉废墟", "安其拉廢墟", "20人安其拉", "ruins of ahn'qiraj", "ahn'qiraj ruins", "aq20", "raq", "废墟", "廢墟", "fx" } },
    { code = "TH", name = "木喉要塞", aliases = { "木喉要塞", "timbermaw hold", "熊怪团", "熊怪團", "熊怪本", "木喉", "tmh" } },
    { code = "LKH", name = "卡拉赞下层", aliases = { "卡拉赞下层", "卡拉贊下層", "下层卡拉赞", "下層卡拉贊", "lower karazhan halls", "lower karazhan", "lower kara", "10人卡拉赞", "10人klz", "10人kara", "10klz", "10kara", "klz10", "kara10", "klz下层", "下层klz", "卡下", "下卡", "lkh", "k10" } },
    { code = "ES", name = "翡翠圣殿", aliases = { "翡翠圣殿", "翡翠聖殿", "翡翠圣域", "emerald sanctum", "翡翠", "es" } },
    { code = "TOK", name = "卡拉赞之塔", aliases = { "卡拉赞之塔", "卡拉贊之塔", "卡拉赞上层", "卡拉贊上層", "上层卡拉赞", "上層卡拉贊", "tower of karazhan", "upper karazhan halls", "upper karazhan", "upper kara", "40人卡拉赞", "40人klz", "40人kara", "40klz", "40kara", "klz40", "kara40", "klz上层", "上层klz", "卡上", "上卡", "ukh", "tok", "k40" } },
}
-- Eleven instanced raids: seven original and four Turtle additions, including Timbermaw.
-- World-boss names come from the existing Meeting menu; zones are not boss identities.
R.bossCatalog = {
    {code="Azuregos",name="艾索雷葛斯",category="BOSS",short="蓝龙",aliases={"艾索雷葛斯","azuregos","蓝龙","藍龍"}},
    {code="Emeriss",name="艾莫莉丝",category="BOSS",short="艾莫莉丝",aliases={"艾莫莉丝","艾莫莉絲","emeriss"}},
    {code="Lethon",name="雷索",category="BOSS",short="雷索",aliases={"雷索","lethon"}},
    {code="Taerar",name="泰拉尔",category="BOSS",short="泰拉尔",aliases={"泰拉尔","泰拉爾","taerar"}},
    {code="Ysondre",name="伊森德雷",category="BOSS",short="伊森德雷",aliases={"伊森德雷","ysondre"}},
    {code="Kazzak",name="卡扎克",category="BOSS",short="卡扎克",aliases={"卡扎克","kazzak"}},
    {code="Nerubian",name="蛛魔监工",category="BOSS",short="蛛魔监工",aliases={"蛛魔监工","蛛魔監工","nerubian overseer"}},
    {code="DarkReaver",name="卡拉赞黑暗掠夺者",category="BOSS",short="黑暗掠夺者",aliases={"卡拉赞黑暗掠夺者","黑暗掠夺者","黑暗掠奪者","dark reaver of karazhan","dark reaver"}},
    {code="Ostarius",name="奥兹塔里亚斯",category="BOSS",short="奥兹塔里亚斯",aliases={"奥兹塔里亚斯","奧茲塔里亞斯","ostarius"}},
    {code="Concavius",name="空卡维斯",category="BOSS",short="空卡维斯",aliases={"空卡维斯","空卡維斯","虚空之子","concavius"}},
    {code="Cow",name="奶牛王",category="BOSS",short="奶牛王",aliases={"奶牛王","cow king"}},
    {code="Cla'ckora",name="克拉科拉",category="BOSS",short="克拉科拉",aliases={"克拉科拉","cla'ckora","clackora"}},
}
local definitions = {}
for _, def in ipairs(R.catalog) do table.insert(definitions, def) end
for _, def in ipairs(R.bossCatalog) do table.insert(definitions, def) end
-- AQ and Karazhan without a wing are intentionally not assigned a specific raid.
local ambiguous = {
    { code = "?KARA", name = "卡拉赞·待确认", aliases = { "卡拉赞", "卡拉贊", "karazhan", "kara", "klz", "kz" } },
    { code = "?AQ", name = "安其拉·待确认", aliases = { "安其拉", "ahn'qiraj", "aq" } },
    { code = "?GREEN", name = "绿龙·待确认", category="BOSS", short="绿龙待定", aliases={"绿龙","綠龍"} },
    { code = "?WORLD", name = "世界首领·待确认", category="BOSS", short="首领待定", aliases={"世界boss","世界首领","世界首領","world boss"} },
}
local blockers = {
    "卡拉赞墓穴", "卡拉贊墓穴", "卡拉赞地穴", "卡拉贊地穴", "karazhan crypt", "klz墓穴", "klz地穴",
    "风暴废墟", "風暴廢墟", "风暴要塞", "風暴要塞", "黑龙鳞片", "黑龍鱗片", "黑龙皮", "黑龙宝宝", "黑龍寶寶",
    "翡翠梦境", "翡翠夢境", "翡翠矿", "翡翠礦", "翡翠宝石", "木喉声望", "木喉聲望", "木喉要塞声望", "木喉要塞聲望", "木喉隧道",
    "蓝龙鳞片", "藍龍鱗片", "蓝龙宝宝", "藍龍寶寶", "绿龙宝宝", "綠龍寶寶",
}

local entries = {}
local categories = {}
local greenBosses = {Emeriss=true,Lethon=true,Taerar=true,Ysondre=true}
local function AddEntries(def)
    categories[def.code] = def.category or "RAID"
    for _, alias in ipairs(def.aliases) do
        table.insert(entries, { alias = alias, code = def.code })
    end
end
for _, def in ipairs(definitions) do AddEntries(def) end
for _, def in ipairs(ambiguous) do AddEntries(def) end
for _, alias in ipairs(blockers) do table.insert(entries, { alias = alias, blocked = true }) end
table.sort(entries, function(a, b) return string.len(a.alias) > string.len(b.alias) end)

-- Keep aliases shared by recognition and the two supported menu categories.
for _, category in ipairs(Meeting.Categories) do
    if Meeting.IsSupportedCategory(category.key) then
        for _, info in ipairs(category.children) do
            for _, def in ipairs(definitions) do
                if info.key == def.code then info.match = def.aliases; info.nomatch = {} end
            end
        end
    end
end

local function Contains(text, word) return string.find(text, word, 1, true) ~= nil end
local function Any(text, words)
    for _, word in ipairs(words) do if Contains(text, word) then return true end end
    return false
end
function R.Normalize(message)
    local text = message
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    -- Remove the entire hyperlink (including the displayed name), not only its ID.
    text = string.gsub(text, "|H.-|h.-|h", " ")
    text = string.gsub(text, "|T.-|t", " ")
    text = string.gsub(text, "’", "'")
    text = string.gsub(text, "＝", "=")
    text = string.gsub(text, "＋", "+")
    return string.lower(text)
end
local function Boundary(text, first, last, alias)
    local before, after = string.sub(text, first - 1, first - 1), string.sub(text, last + 1, last + 1)
    if string.find(string.sub(alias, 1, 1), "[%a%d]") and string.find(before, "[%a%d_]") then return false end
    if string.find(string.sub(alias, -1), "[%a%d]") and string.find(after, "[%a_]") then
        local suffix = string.sub(text, last + 1)
        if not (string.sub(suffix, 1, 4) == "g团" or string.sub(suffix, 1, 6) == "dkp团"
            or string.sub(suffix, 1, 5) == "xy团" or string.sub(suffix, 1, 7) == "roll团") then return false end
    end
    if string.find(string.sub(alias, -1), "%d") and string.find(after, "%d") then return false end
    return true
end
local function FindMentions(text)
    local hits = {}
    for _, entry in ipairs(entries) do
        local offset = 1
        while offset <= string.len(text) do
            local first, last = string.find(text, entry.alias, offset, true)
            if not first then break end
            local overlap = false
            if Boundary(text, first, last, entry.alias) then
                for _, hit in ipairs(hits) do
                    if first <= hit.last and last >= hit.first then overlap = true; break end
                end
                if not overlap then table.insert(hits, { first = first, last = last, code = entry.code, blocked = entry.blocked }) end
            end
            offset = last + 1
        end
    end
    table.sort(hits, function(a, b) return a.first < b.first end)
    local result = {}
    for _, hit in ipairs(hits) do if not hit.blocked then table.insert(result, hit) end end
    return result
end

local seekers = { "求组", "求組", "求带", "求帶", "找团", "找團", "找个团", "蹲团", "有没有团", "有团吗", "有團嗎", "有没有人开", "有没有开", "有人开", "有人開", "looking for a group" }
local commerce = { "出售", "收购", "收購", "卖号", "賣號", "代练", "代練", "代打", "公会招人", "公會招人", "公会招募", "公會招募", "工会招人" }
local history = { "昨天", "昨日", "上周", "上週", "上次", "刚才", "剛才", "之前", "打完了", "已打完", "灭了", "滅了" }
local questions = { "怎么", "怎麼", "哪里", "哪裡", "在哪", "为什么", "為什麼", "几点开", "幾點開", "什么时候", "什麼時候", "规则是什么", "規則是什麼", "能打吗", "能打嗎" }
local closed = { "满了", "滿了", "满员", "滿員", "已满", "已滿", "停止招募", "取消开团", "取消開團", "不开了", "不開了", "不打了", "散团", "散團", "结束了", "結束了" }
local roles = { "奶", "治疗", "治療", "坦克", "输出", "輸出", "老板", "老闆", "消费", "消費", "打工", "躺尸", "躺屍", "法师", "法師", "猎人", "獵人", "牧师", "牧師", "骑士", "騎士", "圣骑", "聖騎", "战士", "戰士", "盗贼", "盜賊", "术士", "術士", "德鲁伊", "德魯伊", "萨满", "薩滿", "奶骑", "奶騎", "奶德", "奶萨", "奶薩", "防战", "防戰", "防骑", "防騎", "熊t", "狂暴战", "狂暴戰", "惩戒", "懲戒", "暗牧", "鸟德", "鳥德", "猫德", "貓德", "元素", "增强", "增強", "武器战", "武器戰", "dps", "healer", "healers", "tank", "tanks", "rdps", "mdps", "fs", "lr", "ms", "qs", "zs", "dz", "ss", "xd", "sm", "nq", "nd", "ns", "kbz", "fq", "fz", "t", "n", "人" }
table.sort(roles, function(a,b) return string.len(a) > string.len(b) end)
local strong = { "开组", "開組", "开团", "開團", "组起", "組起", "组人", "組人", "招募", "招人", "补人", "補人", "补位", "補位", "补坑", "補坑", "来人", "來人", "缺人", "looking for more" }
local function Word(text, word)
    local first, last = string.find(text, word, 1, true)
    while first do
        if Boundary(text, first, last, word) then return true end
        first, last = string.find(text, word, last + 1, true)
    end
    return false
end
local function StripNegative(text)
    for _, verb in ipairs({ "不缺", "不招", "不收", "不需要", "不要", "不用来", "不用來", "别来", "別來" }) do
        local offset = 1
        while true do
            local first, last = string.find(text, verb, offset, true)
            if not first then break end
            local tail = string.sub(text, last + 1)
            local prefix = string.find(tail, "%S") or 1
            local rest = string.sub(tail, prefix)
            rest = string.gsub(rest, "^%d*%s*", "")
            local removed = string.len(tail) - string.len(rest)
            local length = 0
            for _, role in ipairs(roles) do
                if string.sub(rest, 1, string.len(role)) == role and Boundary(rest, 1, string.len(role), role) then length = string.len(role); break end
            end
            if length > 0 then
                text = string.sub(text, 1, first - 1).." "..string.sub(text, last + removed + length + 1)
                offset = first + 1
            else offset = last + 1 end
        end
    end
    return text
end
local function Recruitment(text)
    if Any(text, seekers) or Word(text, "lfg") or Any(text, commerce) or Any(text, history) or Any(text, questions) then return false end
    if Any(text, closed) or Any(text, { "不开团", "不開團", "不开组", "不開組", "不招募" }) then return false end
    for _, verb in ipairs({ "缺", "招", "开团", "開團", "开组", "開組" }) do
        if string.find(text, verb..".-吗") or string.find(text, verb..".-嗎") or string.find(text, verb..".-么")
            or (Contains(text, verb) and string.find(text, "不%s*$")) then return false end
    end
    if string.find(text, "^%s*is%s") or string.find(text, "^%s*any%s") or Contains(text, "is there") then return false end
    text = StripNegative(text)
    if Word(text, "lfm") then return true end
    for token in string.gfind(text, "lf%d+m") do if Word(text, token) then return true end end
    if Any(text, strong) then return true end
    for _, verb in ipairs({ "来", "來", "缺", "招", "收", "补", "補", "等" }) do
        local start = 1
        while true do
            local first, last = string.find(text, verb, start, true)
            if not first then break end
            local tail = string.sub(text, last + 1)
            tail = string.gsub(tail, "^%s*%d*%s*", "")
            if string.sub(tail, 1, 3) == "个" or string.sub(tail, 1, 3) == "個" then tail = string.gsub(string.sub(tail, 4), "^%s*", "") end
            for _, role in ipairs(roles) do
                if string.sub(tail, 1, string.len(role)) == role and Boundary(tail, 1, string.len(role), role) then return true end
            end
            start = last + 1
        end
    end
    for have, need in string.gfind(text, "(%d+)%s*=%s*(%d+)") do
        have, need = tonumber(have), tonumber(need)
        if have > 0 and need > 0 and have + need <= 40 then return true end
    end
    if Word(text, "need") and (string.find(text, "need%s+%d*%s*healer") or string.find(text, "need%s+%d*%s*tank")
        or string.find(text, "need%s+%d*%s*dps")) then return true end
    local distribution = Any(text, { "许愿团", "許願團", "金团", "金團", "g团", "g團", "dkp团", "dkp團", "软保", "軟保", "roll团", "roll團" })
    return distribution and (Any(text, { "装备m", "裝備m", "私聊", "密我", "m我" }) or Word(text, "pst")) or false
end

local function Closure(text)
    if not Any(text, closed) or Any(text, history) or Any(text, questions) or Any(text, seekers) or Any(text, commerce) then return false end
    return not Any(text, { "吗", "嗎", "么", "麼", "如果", "要是", "可能", "听说", "聽說", "是不是" })
end

local function Connected(gap)
    gap = string.gsub(gap, "连打", "")
    gap = string.gsub(gap, "連打", "")
    gap = string.gsub(gap, "然后", "")
    gap = string.gsub(gap, "然後", "")
    gap = string.gsub(gap, "再", "")
    gap = string.gsub(gap, "和", "")
    gap = string.gsub(gap, "及", "")
    gap = string.gsub(gap, "、", "")
    return string.gsub(gap, "[%s%+/%-&>]", "") == ""
end
local function Bare(text, hits)
    for i = table.getn(hits), 1, -1 do text = string.sub(text, 1, hits[i].first - 1)..string.sub(text, hits[i].last + 1) end
    for _, tag in ipairs({ "许愿团", "許願團", "许愿", "許願", "金团", "金團", "g团", "g團", "全通", "速推" }) do text = string.gsub(text, tag, "") end
    return Connected(StripNegative(text))
end
function R.Parse(message)
    if type(message) ~= "string" or string.len(message) > 4096 then return nil end
    local text = R.Normalize(message)
    local parts = {}
    text = string.gsub(text, "[\r\n,;!?]", "\n")
    for _, mark in ipairs({ "，", "；", "。", "！", "？" }) do text = string.gsub(text, mark, "\n") end
    for part in string.gfind(text, "[^\n]+") do table.insert(parts, part) end
    local accepted, removed, seen = {}, {}, false
    for index, part in ipairs(parts) do
        local hits = FindMentions(part)
        if table.getn(hits) > 0 then
            seen = true
            local clusters = {}
            for _, hit in ipairs(hits) do
                local group = clusters[table.getn(clusters)]
                if group and Connected(string.sub(part, group.last + 1, hit.first - 1)) then
                    table.insert(group.hits, hit); group.last = hit.last
                else table.insert(clusters, { first = hit.first, last = hit.last, hits = { hit } }) end
            end
            for i, group in ipairs(clusters) do
                local finish = clusters[i + 1] and clusters[i + 1].first - 1 or string.len(part)
                local context = string.sub(part, i == 1 and 1 or group.first, finish)
                if table.getn(clusters) == 1 and Bare(part, hits) and parts[index + 1]
                    and table.getn(FindMentions(parts[index + 1])) == 0 then context = context.." "..parts[index + 1] end
                local recruiting = Recruitment(context)
                for _, hit in ipairs(group.hits) do
                    if recruiting then accepted[hit.code] = true
                    elseif Closure(context) then removed[hit.code] = true end
                end
            end
        end
    end
    if not seen then return nil end
    -- If both generic and explicit family names occur, the explicit wing takes priority.
    if accepted.LKH or accepted.TOK then accepted["?KARA"] = nil end
    if accepted.AQ20 or accepted.AQ40 then accepted["?AQ"] = nil end
    if accepted.Emeriss or accepted.Lethon or accepted.Taerar or accepted.Ysondre then accepted["?GREEN"] = nil end
    for code in pairs(accepted) do
        if categories[code] == "BOSS" and code ~= "?WORLD" then accepted["?WORLD"] = nil; break end
    end
    if next(accepted) then return { status = "recruit", codes = accepted } end
    if next(removed) then return { status = "closed", codes = removed } end
    return { status = "ignore", codes = {} }
end

function R.Label(result, compact)
    local labels = {}
    for _, def in ipairs(definitions) do if result.codes[def.code] then table.insert(labels, def.name) end end
    for _, def in ipairs(ambiguous) do if result.codes[def.code] then table.insert(labels, def.name) end end
    if compact and table.getn(labels) > 1 then
        local codes = {}
        for _, def in ipairs(definitions) do if result.codes[def.code] then table.insert(codes, def.short or def.code) end end
        for _, def in ipairs(ambiguous) do if result.codes[def.code] then table.insert(codes, def.short or (def.code == "?KARA" and "卡拉待定" or "AQ待定")) end end
        if table.getn(codes) > 2 then return codes[1].."/"..codes[2].."等"..table.getn(labels).."本" end
        return table.concat(codes, "/")
    end
    return table.concat(labels, "/")
end
function R.MatchesSearch(result, search, sourceCode)
    if next(search.codes) then
        if search.codes[sourceCode] then return true end
        for code in pairs(result.codes) do if search.codes[code] or search.codes[categories[code]] then return true end end
        return false
    end
    if search.code ~= "" then return search.code == sourceCode or result.codes[search.code] == true end
    if search.category == "" or search.category == "CHAT" then return true end
    for code in pairs(result.codes) do if categories[code] == search.category then return true end end
    return false
end
function R.Overlaps(a, b)
    for code in pairs(a.codes) do
        if b.codes[code] then return true end
        if code == "?KARA" and (b.codes.LKH or b.codes.TOK) then return true end
        if code == "?AQ" and (b.codes.AQ20 or b.codes.AQ40) then return true end
        if (code == "LKH" or code == "TOK") and b.codes["?KARA"] then return true end
        if (code == "AQ20" or code == "AQ40") and b.codes["?AQ"] then return true end
        for other in pairs(b.codes) do
            if (code == "?WORLD" and categories[other] == "BOSS") or (other == "?WORLD" and categories[code] == "BOSS") then return true end
            if (code == "?GREEN" and greenBosses[other]) or (other == "?GREEN" and greenBosses[code]) then return true end
        end
    end
    return false
end
