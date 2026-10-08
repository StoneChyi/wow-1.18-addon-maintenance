--[[
	Macro Syntax Error Checker
	Author: Mewtiny
	License: MIT License

	Validates macro syntax and reports errors to help users debug their macros
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

-- Known valid conditionals
-- Minimal static entries for special cases not in CleveRoids.Keywords
-- The bulk of valid conditionals are auto-populated from Keywords below
local VALID_CONDITIONALS = {
    -- multiscan is processed in Core.lua before Keywords loop (target resolution)
    -- It's in ignoreKeywords, not Keywords, but users write it in macros
    multiscan = true,
    -- [button:N]/[btn:N]/[nobutton:N]/[nobtn:N] 冒号写法在 Core.lua 解析时映射为 buttonN/btnN（无冒号，由 Keywords 提供），
    -- 此处登记源关键字，避免检查器误报 Unknown conditional by 武藤纯子酱 2026.9.23
    button = true, btn = true, nobutton = true, nobtn = true,
}

-- Auto-populate from CleveRoids.Keywords (all registered conditionals)
-- MacroErrorChecker.lua loads after Conditionals.lua so Keywords is populated
if CleveRoids.Keywords then
    for keyword, _ in pairs(CleveRoids.Keywords) do
        VALID_CONDITIONALS[keyword] = true
    end
end

-- Also add user-facing entries from ignoreKeywords (multiscan already added above)
if CleveRoids.ignoreKeywords then
    for keyword, _ in pairs(CleveRoids.ignoreKeywords) do
        -- Skip internal metadata keys that users never type in macros
        if keyword ~= "_operators" and keyword ~= "_groups" and keyword ~= "action" then
            VALID_CONDITIONALS[keyword] = true
        end
    end
end

-- Known valid commands
-- 这些命令的正文里出现多个 [...] 属正常文本/脚本，不做 "Missing ';'" 检查 by 武藤纯子酱 2026.8.31
local NO_SEMICOLON_CHECK_COMMANDS = {
    ["/p"] = true, ["/party"] = true,
    ["/s"] = true, ["/say"] = true,
    ["/y"] = true, ["/yell"] = true,
    ["/e"] = true, ["/em"] = true, ["/emote"] = true,
    ["/ra"] = true, ["/raid"] = true,
    ["/rw"] = true,
    ["/w"] = true, ["/tell"] = true, ["/whisper"] = true,
    ["/1"] = true, ["/2"] = true, ["/3"] = true, ["/4"] = true,
    ["/bg"] = true,
    ["/run"] = true, ["/script"] = true, ["/crmrun"] = true,
    ["/sendmessage"] = true, ["/print"] = true,
}

local VALID_COMMANDS = {
    -- Core addon commands
    ["/cast"] = true,
    ["/castpet"] = true,
    ["/cancelaura"] = true,
    ["/castsequence"] = true,
    ["/equip"] = true,
    ["/equipmh"] = true,
    ["/equipoh"] = true,
    ["/equip11"] = true,
    ["/equip12"] = true,
    ["/equip13"] = true,
    ["/equip14"] = true,
    ["/focus"] = true,
    ["/petattack"] = true,
    ["/petfollow"] = true,
    ["/petwait"] = true,
    ["/petpassive"] = true,
    ["/petaggressive"] = true,
    ["/petdefensive"] = true,
    ["/print"] = true,
    ["/run"] = true,
    ["/runmacro"] = true,
    ["/script"] = true,
    ["/startattack"] = true,
    ["/stopattack"] = true,
    ["/stopcasting"] = true,
    ["/stopmacro"] = true,
    ["/skipmacro"] = true,
    ["/target"] = true,
    ["/cleartarget"] = true,
    ["/unqueue"] = true,
    ["/use"] = true,
    ["/unbuff"] = true,
    ["/unshift"] = true,
    ["/retarget"] = true,
    ["/firstaction"] = true,
    ["/nofirstaction"] = true,
    ["/applymain"] = true,
    ["/applyoff"] = true,
    ["/clearequipqueue"] = true,
    ["/equipqueuestatus"] = true,
    ["/quickheal"] = true,
    ["/qh"] = true,
    ["/rl"] = true,
    ["/combotrack"] = true,
    ["/cleveroid"] = true,
    ["/cleveroidmacros"] = true,
    ["/macrocheck"] = true,
    -- Turtle WoW / third-party addon commands
    ["/db"] = true,
    ["/rinse"] = true,
    ["/am"] = true,
    ["/aux"] = true,
    ["/instancetimers"] = true,
    ["/umacro"] = true,
    ["/cursive"] = true,
    -- 修复：以下命令由本插件注册（Console.lua）但原先未列入白名单，导致合法宏被误报 "Unknown command" by 武藤纯子酱 2026.8.31
    ["/switch"] = true,
    ["/lasttarget"] = true,
    ["/crmrun"] = true,
    ["/sendmessage"] = true,

    --------------------------------------------------------------------------
    -- Standard WoW 1.12.1 Commands
    --------------------------------------------------------------------------

    -- Chat
    ["/say"] = true,
    ["/s"] = true,
    ["/yell"] = true,
    ["/y"] = true,
    ["/shout"] = true,
    ["/whisper"] = true,
    ["/w"] = true,
    ["/tell"] = true,
    ["/reply"] = true,
    ["/r"] = true,
    ["/party"] = true,
    ["/p"] = true,
    ["/guild"] = true,
    ["/g"] = true,
    ["/officer"] = true,
    ["/o"] = true,
    ["/raid"] = true,
    ["/ra"] = true,
    ["/battleground"] = true,
    ["/bg"] = true,
    ["/emote"] = true,
    ["/e"] = true,
    ["/em"] = true,
    ["/me"] = true,
    ["/rw"] = true,
    ["/announce"] = true,

    -- Channel
    ["/join"] = true,
    ["/leave"] = true,
    ["/channel"] = true,
    ["/chatlist"] = true,
    ["/chatwho"] = true,
    ["/chatinvite"] = true,
    ["/ckick"] = true,

    -- Targeting
    ["/tar"] = true,
    ["/assist"] = true,
    ["/a"] = true,
    ["/targetenemy"] = true,
    ["/targetfriend"] = true,
    ["/targetnearestenemy"] = true,
    ["/targetnearestfriend"] = true,
    ["/targetlasttarget"] = true,
    ["/targetlastenemy"] = true,
    ["/targetlastfriend"] = true,

    -- Group / Raid
    ["/invite"] = true,
    ["/inv"] = true,
    ["/uninvite"] = true,
    ["/kick"] = true,
    ["/promote"] = true,
    ["/leader"] = true,
    ["/disband"] = true,
    ["/trade"] = true,
    ["/roll"] = true,
    ["/random"] = true,
    ["/raidinfo"] = true,
    ["/readycheck"] = true,
    ["/lfg"] = true,
    ["/lfm"] = true,

    -- Loot
    ["/masterloot"] = true,
    ["/ffa"] = true,
    ["/roundrobin"] = true,
    ["/needbeforegreed"] = true,
    ["/grouploot"] = true,

    -- Guild
    ["/ginvite"] = true,
    ["/guildinvite"] = true,
    ["/gremove"] = true,
    ["/guildremove"] = true,
    ["/gpromote"] = true,
    ["/guildpromote"] = true,
    ["/gdemote"] = true,
    ["/guilddemote"] = true,
    ["/gquit"] = true,
    ["/guildquit"] = true,
    ["/gdisband"] = true,
    ["/guilddisband"] = true,
    ["/gmotd"] = true,
    ["/guildmotd"] = true,
    ["/ginfo"] = true,
    ["/guildinfo"] = true,
    ["/groster"] = true,
    ["/guildroster"] = true,
    ["/guildleader"] = true,

    -- System
    ["/logout"] = true,
    ["/camp"] = true,
    ["/quit"] = true,
    ["/exit"] = true,
    ["/reload"] = true,
    ["/reloadui"] = true,
    ["/console"] = true,
    ["/macro"] = true,
    ["/played"] = true,
    ["/time"] = true,
    ["/who"] = true,
    ["/afk"] = true,
    ["/away"] = true,
    ["/dnd"] = true,
    ["/busy"] = true,
    ["/help"] = true,
    ["/pvp"] = true,
    ["/combatlog"] = true,
    ["/chatlog"] = true,
    ["/clear"] = true,
    ["/ignore"] = true,
    ["/unignore"] = true,
    ["/friend"] = true,
    ["/friends"] = true,
    ["/removefriend"] = true,
    ["/gm"] = true,
    ["/bug"] = true,
    ["/suggest"] = true,

    -- Movement / Stance
    ["/follow"] = true,
    ["/f"] = true,
    ["/dismount"] = true,
    ["/cancelform"] = true,

    -- Pet (standard WoW extras)
    ["/petabandon"] = true,
    ["/petstay"] = true,

    -- Emotes
    ["/agree"] = true,
    ["/amaze"] = true,
    ["/angry"] = true,
    ["/apologize"] = true,
    ["/applaud"] = true,
    ["/attacktarget"] = true,
    ["/bark"] = true,
    ["/bashful"] = true,
    ["/beckon"] = true,
    ["/beg"] = true,
    ["/bite"] = true,
    ["/bleed"] = true,
    ["/blink"] = true,
    ["/blush"] = true,
    ["/boggle"] = true,
    ["/bonk"] = true,
    ["/bored"] = true,
    ["/bounce"] = true,
    ["/bow"] = true,
    ["/bravo"] = true,
    ["/burp"] = true,
    ["/bye"] = true,
    ["/cackle"] = true,
    ["/calm"] = true,
    ["/cat"] = true,
    ["/charge"] = true,
    ["/cheer"] = true,
    ["/chicken"] = true,
    ["/chuckle"] = true,
    ["/clap"] = true,
    ["/cold"] = true,
    ["/comfort"] = true,
    ["/commend"] = true,
    ["/confused"] = true,
    ["/congratulate"] = true,
    ["/congrats"] = true,
    ["/cough"] = true,
    ["/cower"] = true,
    ["/crack"] = true,
    ["/cringe"] = true,
    ["/cry"] = true,
    ["/cuddle"] = true,
    ["/curious"] = true,
    ["/curtsey"] = true,
    ["/dance"] = true,
    ["/disappointed"] = true,
    ["/doom"] = true,
    ["/drink"] = true,
    ["/drool"] = true,
    ["/duck"] = true,
    ["/eat"] = true,
    ["/embarrass"] = true,
    ["/encourage"] = true,
    ["/enemy"] = true,
    ["/eye"] = true,
    ["/fart"] = true,
    ["/feast"] = true,
    ["/fidget"] = true,
    ["/flap"] = true,
    ["/flee"] = true,
    ["/flex"] = true,
    ["/flirt"] = true,
    ["/flop"] = true,
    ["/gasp"] = true,
    ["/gaze"] = true,
    ["/giggle"] = true,
    ["/glad"] = true,
    ["/gloat"] = true,
    ["/glare"] = true,
    ["/golfclap"] = true,
    ["/goodbye"] = true,
    ["/greet"] = true,
    ["/grin"] = true,
    ["/groan"] = true,
    ["/grovel"] = true,
    ["/growl"] = true,
    ["/guffaw"] = true,
    ["/hail"] = true,
    ["/happy"] = true,
    ["/healme"] = true,
    ["/hello"] = true,
    ["/helpme"] = true,
    ["/hug"] = true,
    ["/hungry"] = true,
    ["/impatient"] = true,
    ["/incoming"] = true,
    ["/insult"] = true,
    ["/introduce"] = true,
    ["/jk"] = true,
    ["/kiss"] = true,
    ["/kneel"] = true,
    ["/laugh"] = true,
    ["/laydown"] = true,
    ["/lick"] = true,
    ["/listen"] = true,
    ["/lost"] = true,
    ["/love"] = true,
    ["/massage"] = true,
    ["/moan"] = true,
    ["/mock"] = true,
    ["/moo"] = true,
    ["/moon"] = true,
    ["/mourn"] = true,
    ["/no"] = true,
    ["/nod"] = true,
    ["/nosepick"] = true,
    ["/oom"] = true,
    ["/openfire"] = true,
    ["/panic"] = true,
    ["/pat"] = true,
    ["/peek"] = true,
    ["/peer"] = true,
    ["/peon"] = true,
    ["/pest"] = true,
    ["/pick"] = true,
    ["/pinch"] = true,
    ["/pity"] = true,
    ["/plead"] = true,
    ["/point"] = true,
    ["/poke"] = true,
    ["/ponder"] = true,
    ["/pounce"] = true,
    ["/praise"] = true,
    ["/pray"] = true,
    ["/purr"] = true,
    ["/puzzle"] = true,
    ["/question"] = true,
    ["/raise"] = true,
    ["/rasp"] = true,
    ["/ready"] = true,
    ["/regret"] = true,
    ["/roar"] = true,
    ["/rofl"] = true,
    ["/rude"] = true,
    ["/ruffle"] = true,
    ["/sad"] = true,
    ["/salute"] = true,
    ["/scared"] = true,
    ["/scratch"] = true,
    ["/sexy"] = true,
    ["/shake"] = true,
    ["/shimmy"] = true,
    ["/shiver"] = true,
    ["/shoo"] = true,
    ["/shrug"] = true,
    ["/shy"] = true,
    ["/sigh"] = true,
    ["/silly"] = true,
    ["/sit"] = true,
    ["/slap"] = true,
    ["/sleep"] = true,
    ["/smile"] = true,
    ["/smirk"] = true,
    ["/snarl"] = true,
    ["/snicker"] = true,
    ["/sniff"] = true,
    ["/sob"] = true,
    ["/soothe"] = true,
    ["/sorry"] = true,
    ["/spit"] = true,
    ["/stand"] = true,
    ["/stare"] = true,
    ["/stink"] = true,
    ["/strong"] = true,
    ["/surprised"] = true,
    ["/surrender"] = true,
    ["/tap"] = true,
    ["/tease"] = true,
    ["/thank"] = true,
    ["/thirsty"] = true,
    ["/threaten"] = true,
    ["/tickle"] = true,
    ["/tired"] = true,
    ["/train"] = true,
    ["/truce"] = true,
    ["/twiddle"] = true,
    ["/veto"] = true,
    ["/victory"] = true,
    ["/violin"] = true,
    ["/volunteer"] = true,
    ["/wait"] = true,
    ["/wave"] = true,
    ["/welcome"] = true,
    ["/whine"] = true,
    ["/whistle"] = true,
    ["/wink"] = true,
    ["/work"] = true,
    ["/yawn"] = true,
    ["/yes"] = true,

	-- 新增 by 武藤纯子酱 2026.2.10
	["/castrandom"] = true,
	["/equipslot"] = true,
	["/targetenemyplayer"] = true,
	["/targetfriendplayer"] = true,
	["/targetparty"] = true,
	["/targetraid"] = true,
	["/targetexact"] = true,
	["/petautocastoff"] = true,
	["/petautocaston"] = true,
	["/petautocasttoggle"] = true,
	["/mount"] = true,
	["/changeactionbar"] = true,
	["/swapactionbar"] = true,
	["/userandom"] = true,
	["/feed"] = true,
	["/runsupermacro"] = true,
	["/rh"] = true,
	["/settag"] = true,
	-- 新增（行屏蔽/射击开关/拾取卸装/别名）by 武藤纯子酱 2026.9.16
	["/--cast"] = true,
	["/--use"] = true,
	["/--castsequence"] = true,
	["/--follow"] = true,
	["/attack"] = true,
	["/lastenemy"] = true,
	["/autoshoot"] = true,
	["/shootattack"] = true,
	["/stopshoot"] = true,
	["/pickup"] = true,
	["/unequip"] = true,
	-- 原版命令补充（1.12 客户端确有：/click 由本插件模拟实现，/duel /forfeit /macrohelp 为原生）by 武藤纯子酱 2026.9.23
	["/click"] = true,
	["/duel"] = true,
	["/forfeit"] = true,
	["/macrohelp"] = true,
	["/threshold"] = true,
	-- 新增（正式服宏命令对齐）by 武藤纯子酱 2026.9.3
	["/stopspelltarget"] = true,
	["/petdismiss"] = true,
}

-- ============================================================================
-- Command Whitelist API (for third-party addon commands)
-- ============================================================================

local function GetWhitelistedCommands()
    if not CleveRoidMacros then CleveRoidMacros = {} end
    if not CleveRoidMacros.whitelistedCommands then
        CleveRoidMacros.whitelistedCommands = {}
    end
    return CleveRoidMacros.whitelistedCommands
end

function CleveRoids.AddWhitelistedCommand(cmd)
    if not cmd or cmd == "" then return end
    cmd = string.lower(cmd)
    -- Auto-prepend "/" if missing
    if string.sub(cmd, 1, 1) ~= "/" then
        cmd = "/" .. cmd
    end
    local whitelist = GetWhitelistedCommands()
    whitelist[cmd] = true
end

function CleveRoids.RemoveWhitelistedCommand(cmd)
    if not cmd or cmd == "" then return end
    cmd = string.lower(cmd)
    if string.sub(cmd, 1, 1) ~= "/" then
        cmd = "/" .. cmd
    end
    local whitelist = GetWhitelistedCommands()
    whitelist[cmd] = nil
end

function CleveRoids.IsWhitelistedCommand(cmd)
    if not cmd or cmd == "" then return false end
    cmd = string.lower(cmd)
    if string.sub(cmd, 1, 1) ~= "/" then
        cmd = "/" .. cmd
    end
    local whitelist = GetWhitelistedCommands()
    return whitelist[cmd] == true
end

function CleveRoids.GetWhitelistedCommandsList()
    local whitelist = GetWhitelistedCommands()
    local list = {}
    for cmd, _ in pairs(whitelist) do
        table.insert(list, cmd)
    end
    table.sort(list)
    return list
end

-- Commands that can have conditionals without actions
-- e.g., /petattack [harm] or /target [exists,hp:<=20]
local COMMANDS_NO_ACTION_NEEDED = {
    ["/petattack"] = true,
    ["/petfollow"] = true,
    ["/petwait"] = true,
    ["/petpassive"] = true,
    ["/petaggressive"] = true,
    ["/petdefensive"] = true,
    ["/target"] = true,
    ["/cleartarget"] = true,
    ["/focus"] = true,
    ["/follow"] = true,
    ["/f"] = true,
    ["/dismount"] = true,
    ["/cancelform"] = true,
    ["/startattack"] = true,
    ["/stopattack"] = true,
    ["/stopcasting"] = true,
    ["/unqueue"] = true,
    ["/retarget"] = true,
    ["/stopmacro"] = true,
    ["/skipmacro"] = true,
    ["/unshift"] = true,
    ["/firstaction"] = true,
    ["/nofirstaction"] = true,
    ["/clearequipqueue"] = true,
    ["/equipqueuestatus"] = true,
    ["/quickheal"] = true,
    ["/qh"] = true,
    ["/rl"] = true,
    ["/combotrack"] = true,
    ["/cleveroid"] = true,
    ["/cleveroidmacros"] = true,
    ["/print"] = true,
    ["/run"] = true,
    ["/script"] = true,

	-- 新增 by 武藤纯子酱 2026.2.10
	["/switch"] = true,
	["/lasttarget"] = true,
	-- 新增（可只带条件、无后续动作）by 武藤纯子酱 2026.9.16
	["/attack"] = true,
	["/lastenemy"] = true,
	["/autoshoot"] = true,
	["/shootattack"] = true,
	["/stopshoot"] = true,
}

-- Safe string operations to prevent addon errors from malformed macros
local function safeStringSub(str, startPos, endPos)
    if not str or type(str) ~= "string" then return "" end
    local len = string.len(str)
    if startPos < 1 then startPos = 1 end
    if endPos and endPos > len then endPos = len end
    return string.sub(str, startPos, endPos)
end

local function safeStringFind(str, pattern, init)
    if not str or type(str) ~= "string" then return nil end
    -- 修复：原先最多返回 3 个值，双捕获组模式（如 ^([a-z]+)([<>=~%d].+)$）的第 4 个
    -- 捕获值被丢弃，"缺少冒号"检查永远不触发 by 武藤纯子酱 2026.8.31
    local success, result1, result2, result3, result4, result5 = pcall(string.find, str, pattern, init)
    if success then
        return result1, result2, result3, result4, result5
    end
    return nil
end

local function safeStringLen(str)
    if not str or type(str) ~= "string" then return 0 end
    return string.len(str)
end

local function safeTrim(str)
    if not str or type(str) ~= "string" then return "" end
    local success, result = pcall(CleveRoids.Trim, str)
    if success then return result end
    return str
end

-- Error types
local ERROR_TYPES = {
    INVALID_CONDITIONAL = "Invalid conditional",
    MISMATCHED_BRACKETS = "Mismatched brackets",
    EMPTY_CONDITIONAL = "Empty conditional block",
    INVALID_OPERATOR = "Invalid operator",
    MISSING_ARGUMENT = "Missing argument",
    INVALID_COMMAND = "Unknown command",
    INVALID_TARGET = "Invalid target format",
    MALFORMED_QUOTES = "Malformed quotes",
    EMPTY_ACTION = "Empty action",
    INVALID_SYNTAX = "Invalid syntax",
}

CleveRoids.MacroErrors = {}

-- Check if a string has balanced brackets
local function checkBrackets(text)
    if not text or type(text) ~= "string" then return true end

    local openCount = 0
    local inQuotes = false
    local len = safeStringLen(text)

    for i = 1, len do
        local char = safeStringSub(text, i, i)
        if not char or char == "" then break end

        if char == '"' then
            inQuotes = not inQuotes
        elseif not inQuotes then
            if char == "[" then
                openCount = openCount + 1
            elseif char == "]" then
                openCount = openCount - 1
                if openCount < 0 then
                    return false, "Extra closing bracket"
                end
            end
        end
    end

    if openCount > 0 then
        return false, "Missing closing bracket"
    elseif openCount < 0 then
        return false, "Extra closing bracket"
    end

    return true
end

-- Check if quotes are balanced
local function checkQuotes(text)
    if not text or type(text) ~= "string" then return true end

    local quoteCount = 0
    local escaped = false
    local len = safeStringLen(text)

    for i = 1, len do
        local char = safeStringSub(text, i, i)
        if not char or char == "" then break end

        if escaped then
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif char == '"' then
            quoteCount = quoteCount + 1
        end
    end

    local quotient = math.floor(quoteCount / 2)
    if (quoteCount - (quotient * 2)) ~= 0 then
        return false, "Unmatched quotes"
    end

    return true
end

-- Validate conditional syntax
local function validateConditional(conditional, args, action)
    local errors = {}

    if not conditional or conditional == "" then
        return errors
    end

    -- Check if conditional is valid
    local baseCond = string.lower(safeTrim(conditional))
    if not VALID_CONDITIONALS[baseCond] then
        table.insert(errors, {
            type = ERROR_TYPES.INVALID_CONDITIONAL,
            conditional = conditional,
            message = "Unknown conditional: " .. conditional
        })
    end

    -- Check for required arguments
    local needsArgs = {
        combo = true,
        hp = true, myhp = true, rawhp = true, myrawhp = true,
        power = true, mypower = true, rawpower = true, myrawpower = true,
        hplost = true, myhplost = true,
        powerlost = true, mypowerlost = true,
        stat = true,
        talent = true,
        actionbar = true,
        form = true, stance = true,
        level = true, mylevel = true,
        distance = true, nodistance = true,
        swingtimer = true, stimer = true,
        rangedtimer = true, rtimer = true,
        threat = true,
        ttk = true, tte = true,
        spellcasttime = true, nospellcasttime = true,
    }

    if needsArgs[baseCond] and (not args or args == "") and (not action or action == "") then
        table.insert(errors, {
            type = ERROR_TYPES.MISSING_ARGUMENT,
            conditional = conditional,
            message = conditional .. " requires an argument"
        })
    end

    -- Check operator syntax for numeric comparisons
    if args and type(args) == "string" then
        local hasHpOrPower = safeStringFind(baseCond, "hp") or safeStringFind(baseCond, "power") or
                            safeStringFind(baseCond, "combo") or baseCond == "stat"
        if hasHpOrPower then
            local hasOperator = safeStringFind(args, "[<>=~]+")
            if args ~= "" and not hasOperator and not safeStringFind(args, "^%d+$") then
                -- Might be missing operator
                if not safeStringFind(args, "[a-zA-Z]") then
                    table.insert(errors, {
                        type = ERROR_TYPES.INVALID_OPERATOR,
                        conditional = conditional,
                        message = conditional .. " may need an operator (>, <, =, >=, <=)"
                    })
                end
            end
        end
    end

    return errors
end

-- 运行时探测：命令若有处理器（本插件或第三方插件经 SLASH_<KEY><N> 注册）即视为合法，
-- 避免对"由其它插件提供"的命令误报（如 /equipset /targetfocus /clearfocus） by 武藤纯子酱 2026.9.23
local function CommandHasHandler(cmdWithSlash)
    if not cmdWithSlash then return false end
    local key = string.upper(string.sub(cmdWithSlash, 2))
    if SlashCmdList and SlashCmdList[key] then return true end
    local G = _G or getfenv(0)
    for k, v in pairs(G) do
        if type(k) == "string" and string.sub(k, 1, 6) == "SLASH_" and v == cmdWithSlash then
            return true
        end
    end
    return false
end

-- Parse and validate a single line
local function validateLine(line, lineNum)    local errors = {}

    -- Skip comments and empty lines
    if not line or type(line) ~= "string" then
        return errors
    end

    line = safeTrim(line)
    if line == "" or safeStringSub(line, 1, 2) == "--" then
        return errors
    end

    -- Check for # directives - only #show/#showtooltip/#showtooltips are valid by 武藤纯子酱 2026.9.3
    if safeStringSub(line, 1, 1) == "#" then
        local _, _, directive = safeStringFind(line, "^(#[a-zA-Z]+)") -- 修复：支持混合大小写（#ShowTooltip）by 武藤纯子酱 2026.9.11
        if directive then
            local lowerDirective = string.lower(directive)
            if lowerDirective ~= "#showtooltip" and lowerDirective ~= "#showtooltips" and lowerDirective ~= "#show" then
                table.insert(errors, {
                    type = ERROR_TYPES.INVALID_COMMAND,
                    line = lineNum,
                    command = directive,
                    message = "Unknown directive: " .. directive .. " (did you mean #showtooltip?)"
                })
            end
        end
        -- Valid #showtooltip or other # lines are skipped from further validation
        return errors
    end

    -- Wrap the entire validation in pcall to catch any unexpected errors
    local success, result = pcall(function()
        local localErrors = {}

        -- Check for valid command
        local _, _, cmd = safeStringFind(line, "^(/[a-z]+%d*)")
        if cmd then
            local lowerCmd = string.lower(cmd)
            if not VALID_COMMANDS[lowerCmd] and not CleveRoids.IsWhitelistedCommand(lowerCmd)
               and not CommandHasHandler(lowerCmd) then
                table.insert(localErrors, {
                    type = ERROR_TYPES.INVALID_COMMAND,
                    line = lineNum,
                    command = cmd,
                    message = "Unknown command: " .. cmd
                })
            end
        end
        -- Check brackets
        local bracketsOk, bracketError = checkBrackets(line)
        if not bracketsOk then
            table.insert(localErrors, {
                type = ERROR_TYPES.MISMATCHED_BRACKETS,
                line = lineNum,
                message = bracketError or "Bracket mismatch"
            })
        end

        -- Check quotes
        local quotesOk, quoteError = checkQuotes(line)
        if not quotesOk then
            table.insert(localErrors, {
                type = ERROR_TYPES.MALFORMED_QUOTES,
                line = lineNum,
                message = quoteError or "Quote mismatch"
            })
        end

        -- Check for semicolons inside brackets (must check full line before semicolon split)
        -- e.g., [nomybuff;battleshout] is wrong - semicolons separate actions, not conditionals
        if bracketsOk then
            local depth = 0
            local inQuotes = false
            local lineLen = safeStringLen(line)
            for i = 1, lineLen do
                local ch = safeStringSub(line, i, i)
                if ch == '"' then
                    inQuotes = not inQuotes
                elseif not inQuotes then
                    if ch == "[" then
                        depth = depth + 1
                    elseif ch == "]" then
                        depth = depth - 1
                    elseif ch == ";" and depth > 0 then
                        table.insert(localErrors, {
                            type = ERROR_TYPES.INVALID_SYNTAX,
                            line = lineNum,
                            message = "';' inside brackets is invalid - use spaces to separate conditionals, ':' for arguments"
                        })
                        break
                    end
                end
            end
        end

        -- Check for missing semicolons between bracket groups
        -- e.g., /cast [cond]Backstab[cond2]Garrote should use ; between actions
        -- 修复：聊天/脚本类命令的正文出现多个 [...] 属正常文本（如 "/p 集火 [骷髅] 然后 [十字]"），
        -- 不应报 "Missing ';'"；引号数为奇数时也无法可靠判断 by 武藤纯子酱 2026.8.31
        local skipMissingSemicolonCheck = false
        if cmd then
            local lowerCmd = string.lower(cmd)
            if NO_SEMICOLON_CHECK_COMMANDS[lowerCmd] then
                skipMissingSemicolonCheck = true
            end
        end
        if not skipMissingSemicolonCheck then
            local quoteCount = 0
            for i = 1, safeStringLen(line) do
                if safeStringSub(line, i, i) == '"' then quoteCount = quoteCount + 1 end
            end
            if math.mod(quoteCount, 2) == 1 then skipMissingSemicolonCheck = true end
        end
        if bracketsOk and not skipMissingSemicolonCheck then
            local pos = 1
            while true do
                local closePos = safeStringFind(line, "%]", pos)
                if not closePos then break end

                local nextOpenPos = safeStringFind(line, "%[", closePos + 1)
                if not nextOpenPos then break end

                local between = safeStringSub(line, closePos + 1, nextOpenPos - 1)
                if not safeStringFind(between, ";") then
                    local trimmed = safeTrim(between)
                    if trimmed ~= "" then
                        table.insert(localErrors, {
                            type = ERROR_TYPES.INVALID_SYNTAX,
                            line = lineNum,
                            message = "Missing ';' before '[' - use '" .. trimmed .. ";' to separate actions"
                        })
                    end
                end

                pos = nextOpenPos + 1
            end
        end

        -- Split by semicolons to handle multiple actions per line
        local actions = CleveRoids.splitStringIgnoringQuotes(line, ";")
        if not actions then
            return localErrors
        end

        for _, actionPart in ipairs(actions) do
            actionPart = safeTrim(actionPart)
            if actionPart ~= "" and safeStringSub(actionPart, 1, 1) ~= "/" then
                actionPart = "/" .. actionPart  -- Add leading slash if missing after split
            end

            -- Parse conditionals if present - use non-greedy match
            local condStart = safeStringFind(actionPart, "%[")
            local condEnd = nil
            local conditionBlock = nil

            if condStart then
                -- Find matching closing bracket
                local depth = 0
                local inQuotes = false
                local len = safeStringLen(actionPart)

                for i = condStart, len do
                    local char = safeStringSub(actionPart, i, i)
                    if not char or char == "" then break end

                    if char == '"' then
                        inQuotes = not inQuotes
                    elseif not inQuotes then
                        if char == "[" then
                            depth = depth + 1
                        elseif char == "]" then
                            depth = depth - 1
                            if depth == 0 then
                                condEnd = i
                                conditionBlock = safeStringSub(actionPart, condStart + 1, i - 1)
                                break
                            end
                        end
                    end
                end
            end

            if conditionBlock then
                if safeTrim(conditionBlock) == "" then
                    table.insert(localErrors, {
                        type = ERROR_TYPES.EMPTY_CONDITIONAL,
                        line = lineNum,
                        message = "Empty conditional block []"
                    })
                else
                    -- Check for invalid @ target syntax
                    local _, _, target = safeStringFind(conditionBlock, "(@[^%s,]+)")
                    if target and not safeStringFind(target, "^@[a-z]+%d*") then
                        table.insert(localErrors, {
                            type = ERROR_TYPES.INVALID_TARGET,
                            line = lineNum,
                            message = "Invalid target: " .. target
                        })
                    end

                    -- Parse individual conditionals
                    local condGroups = CleveRoids.splitStringIgnoringQuotes(conditionBlock, {",", " "})
                    if condGroups then
                        for _, condGroup in condGroups do
                            if condGroup ~= "" and condGroup ~= target then
                                local parts = CleveRoids.splitStringIgnoringQuotes(condGroup, ":")
                                if parts then
                                    local cond = string.lower(safeTrim(parts[1] or ""))
                                    local args = safeTrim(parts[2] or "")

                                    -- Check for missing ':' between conditional and its argument
                                    -- e.g., "combo>0" should be "combo:>0", "hp50" should be "hp:50"
                                    if cond ~= "" and (not parts[2] or args == "") and not safeStringFind(cond, "^@") then
                                        local _, _, condPrefix, valueSuffix = safeStringFind(cond, "^([a-z]+)([<>=~%d].+)$")
                                        if condPrefix and valueSuffix and VALID_CONDITIONALS[condPrefix] then
                                            table.insert(localErrors, {
                                                type = ERROR_TYPES.INVALID_SYNTAX,
                                                line = lineNum,
                                                message = "Missing ':' after " .. condPrefix .. " (use " .. condPrefix .. ":" .. valueSuffix .. ")"
                                            })
                                            cond = nil -- Skip further validation, we identified the issue
                                        end
                                    end

                                    if cond and cond ~= "" then
                                        -- Validate the conditional
                                        local condErrors = validateConditional(cond, args, nil)
                                        for _, err in condErrors do
                                            err.line = lineNum
                                            table.insert(localErrors, err)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Check for action after conditionals
                -- Extract the command from this action part
                local _, _, cmdFromAction = safeStringFind(actionPart, "^(/[a-z]+%d*)")
                local needsAction = true

                if cmdFromAction then
                    local lowerCmdFromAction = string.lower(cmdFromAction)
                    if COMMANDS_NO_ACTION_NEEDED[lowerCmdFromAction] then
                        needsAction = false
                    end
                end

                if needsAction then
                    local afterCond = safeStringSub(actionPart, (condEnd or 0) + 1)
                    local _, _, action = safeStringFind(afterCond, "^%s*[!~?]?(.+)")
                    if not action or safeTrim(action) == "" then
                        table.insert(localErrors, {
                            type = ERROR_TYPES.EMPTY_ACTION,
                            line = lineNum,
                            message = "Conditional has no action"
                        })
                    end
                end
            end
        end

        return localErrors
    end)

    if success and result then
        return result
    elseif not success then
        -- An error occurred during validation
        return {{
            type = "VALIDATION_ERROR",
            line = lineNum,
            message = "Internal error validating line: " .. tostring(result)
        }}
    end

    return errors
end

-- Validate an entire macro
function CleveRoids.ValidateMacro(macroName)
    -- Wrap entire function in pcall for safety
    local success, result = pcall(function()
        local errors = {}

        if not macroName or macroName == "" then
            return {{
                type = "ERROR",
                message = "No macro name provided"
            }}
        end

        local macroID = GetMacroIndexByName(macroName)

        if not macroID or macroID == 0 then
            return {{
                type = "ERROR",
                message = "Macro not found: " .. tostring(macroName)
            }}
        end

        local name, texture, body = GetMacroInfo(macroID)
        if not body or body == "" then
            return {{
                type = "ERROR",
                message = "Macro is empty"
            }}
        end

        -- Split into lines
        local lines = CleveRoids.splitString(body, "\n")
        if not lines then
            return {{
                type = "ERROR",
                message = "Failed to parse macro body"
            }}
        end

        for lineNum, line in ipairs(lines) do
            local lineErrors = validateLine(line, lineNum)
            if lineErrors then
                for _, err in lineErrors do
                    table.insert(errors, err)
                end
            end
        end

        return errors
    end)

    if success then
        return result
    else
        -- Return a safe error message if validation itself fails
        return {{
            type = "CRITICAL_ERROR",
            message = "Critical error validating macro: " .. tostring(result)
        }}
    end
end

-- Validate raw macro body text (for live editing in the macro frame)
-- bodyText: The raw text from the EditBox (not yet saved)
-- Returns: Array of error tables with .type, .line, .message fields
function CleveRoids.ValidateMacroBody(bodyText)
    local success, result = pcall(function()
        local errors = {}

        if not bodyText or bodyText == "" then
            return errors
        end

        local lines = CleveRoids.splitString(bodyText, "\n")
        if not lines then
            return errors
        end

        for lineNum, line in ipairs(lines) do
            local lineErrors = validateLine(line, lineNum)
            if lineErrors then
                for _, err in lineErrors do
                    table.insert(errors, err)
                end
            end
        end

        return errors
    end)

    if success then
        return result
    else
        return {{
            type = "CRITICAL_ERROR",
            message = "Critical error validating macro body: " .. tostring(result)
        }}
    end
end

-- Validate all macros
function CleveRoids.ValidateAllMacros()
    local results = {}
    local totalErrors = 0

    -- Account-wide macros are indexed from 1 up to GetNumMacros().
    -- Character-specific macros occupy the slots immediately following the account-wide ones.
    -- In Classic clients, the macro UI has 18 General (Account) slots and 18 Character-Specific slots.
    local numAccountMacros = GetNumMacros()

    -- The WoW API GetMacroInfo(index) supports indexing up to 36 (1-18 for General, 19-36 for Character)
    -- in Classic clients, even though the total is GetNumMacros() + GetNumCharacterMacros() in Retail.
    -- To ensure we check all 36 possible slots:
    local totalSlots = 36

    for i = 1, totalSlots do
        local nameSuccess, name = pcall(GetMacroInfo, i)

        -- Check if GetMacroInfo returned a name (i.e., the slot is used)
        if nameSuccess and name and name ~= "" then
            -- Wrap each macro validation in pcall so one bad macro doesn't stop all validation
            local errorsSuccess, errors = pcall(CleveRoids.ValidateMacro, name)

            if errorsSuccess and errors and table.getn(errors) > 0 then
                -- 修复：通用宏与角色宏允许同名（1.12 合法），按名字做键会互相覆盖，
                -- 改用 槽位序号 做键并记录名字 by 武藤纯子酱 2026.8.31
                results[i] = { name = name, errors = errors }
                totalErrors = totalErrors + table.getn(errors)
            end
        end
    end

    return results, totalErrors
end

-- Print errors for a macro
function CleveRoids.PrintMacroErrors(macroName)
    local success, errors = pcall(CleveRoids.ValidateMacro, macroName)

    if not success then
        CleveRoids.Print("|cffff0000Error|r: Failed to validate macro '" .. tostring(macroName) .. "': " .. tostring(errors))
        return
    end

    if not errors or table.getn(errors) == 0 then
        CleveRoids.Print("|cff00ff00[OK]|r Macro '" .. macroName .. "' has no syntax errors")
        return
    end

    CleveRoids.Print("|cffff0000[ERRORS]|r Macro '" .. macroName .. "' has " .. table.getn(errors) .. " error(s):")

    for _, err in errors do
        if err and err.message then
            local line = err.line and ("Line " .. err.line .. ": ") or ""
            local msg = "|cffffaa00" .. line .. "|r" .. err.message
            pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, "  " .. msg)
        end
    end
end

-- Print all macro errors
function CleveRoids.PrintAllMacroErrors()
    local success, results, totalErrors = pcall(CleveRoids.ValidateAllMacros)

    if not success then
        CleveRoids.Print("|cffff0000Error|r: Failed to validate macros: " .. tostring(results))
        return
    end

    if totalErrors == 0 then
        CleveRoids.Print("|cff00ff00[OK]|r All macros are error-free!")
        return
    end

    local macroCount = 0
    for _ in pairs(results) do macroCount = macroCount + 1 end

    CleveRoids.Print("|cffff0000Found " .. totalErrors .. " error(s) in " .. macroCount .. " macro(s):|r")

    for _, entry in pairs(results) do
        if entry and entry.name and entry.errors then
            local macroName = entry.name
            local errors = entry.errors
            pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, " ")
            pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, "|cffff8800" .. macroName .. "|r (" .. table.getn(errors) .. " error(s)):")

            for _, err in errors do
                if err and err.message then
                    local line = err.line and ("Line " .. err.line .. ": ") or ""
                    local msg = "  |cffffaa00" .. line .. "|r" .. err.message
                    pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, msg)
                end
            end
        end
    end
end

-- Slash command
SLASH_MACROCHECK1 = "/macrocheck"
SlashCmdList.MACROCHECK = function(msg)
    if CleveRoidMacros and CleveRoidMacros.macrocheck == 0 then
        CleveRoids.Print("Macro syntax checker is disabled. Enable with /cleveroid macrocheck 1")
        return
    end

    local success, result = pcall(function()
        msg = safeTrim(msg or "")

        if msg == "" or msg == "all" then
            CleveRoids.PrintAllMacroErrors()
        else
            CleveRoids.PrintMacroErrors(msg)
        end
    end)

    if not success then
        CleveRoids.Print("|cffff0000Error|r: Macro check failed: " .. tostring(result))
    end
end

if not CleveRoidMacros or CleveRoidMacros.macrocheck ~= 0 then
    CleveRoids.Print("Macro syntax checker loaded. Use /macrocheck [macroname] or /macrocheck all")
end
