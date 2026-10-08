-- ============================================================
-- 文件名: SeaHooks.lua
-- 功能: SeaHooks 钩子库（用于函数和框架脚本元素的钩子）
--       支持 before / after / replace / hide 四种钩子类型
--       兼容 Lua 5.0.2，无位运算符依赖
-- ============================================================

local SEA_HOOKS_VERSION = 0.70
local loadThisEmbeddedInstance

local SeaHooks_hookInit, SeaHooks_getDynamicHookHandler
local SeaHooks_hookHandler, SeaHooks_hookHandlerQuick, SeaHooks_hookHandlerDebug
local SeaHooks_assignReturnArgs, SeaHooks_debugErrorPrint

SEA_HOOKS_DEBUG = nil
SEA_HOOKS_DEBUG_VERBOSE = nil

-- ============================================================
-- 嵌入式子库加载算法
-- ============================================================

if not Sea then
    Sea = {}
    Sea.versions = {}
    Sea.versions.SeaHooks = SEA_HOOKS_VERSION
    loadThisEmbeddedInstance = true
    Sea.util = {}
    Sea.util.Hooks = {}
    Sea.util.valueTable = {}
    Sea.util.returnArgs = {}
else
    if not Sea.versions then
        Sea.versions = {}
    end
    if (not Sea.versions.SeaHooks) or (Sea.versions.SeaHooks < SEA_HOOKS_VERSION) then
        Sea.versions.SeaHooks = SEA_HOOKS_VERSION
        loadThisEmbeddedInstance = true
    end
    if not Sea.util then
        Sea.util = {}
    end
    if not Sea.util.Hooks then
        Sea.util.Hooks = {}
    end
    if not Sea.util.valueTable then
        Sea.util.valueTable = {}
    end
    if not Sea.util.returnArgs then
        Sea.util.returnArgs = {}
    end
end

if loadThisEmbeddedInstance then
    loadThisEmbeddedInstance = nil

    -- ============================================================
    -- 钩子注册与注销（用户函数）
    -- ============================================================

    -- Sea.util.hook(orig, new, hooktype, scriptElementName)
    -- hooktype: "hide" | "before" | "replace" | "after"
    function Sea.util.hook(orig, new, hooktype, scriptElementName)
        if not hooktype then
            hooktype = "before"
        end

        local compoundOrig = orig
        if scriptElementName then
            compoundOrig = orig .. "." .. scriptElementName
        end

        SeaHooks_debugErrorPrint(
            (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
            nil, NORMAL_FONT_COLOR,
            "SeaHooks Progress: Hooking ", orig, " to ", new,
            ", hooktype ", hooktype, ", scriptElementName ", scriptElementName
        )

        local newFunc = new
        if type(new) ~= "function" then
            newFunc = Sea.util.getValue(new)
        end

        local hookObj = Sea.util.Hooks[compoundOrig]
        if not hookObj then
            hookObj = SeaHooks_hookInit(orig, compoundOrig, scriptElementName)
        else
            for key, value in hookObj[hooktype] do
                if value == newFunc then
                    SeaHooks_debugErrorPrint(
                        (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
                        nil, NORMAL_FONT_COLOR,
                        "SeaHooks Progress: Already hooked '", compoundOrig,
                        "' with '", new, "' skipping."
                    )
                    return
                end
            end
        end

        local currKey = table.getn(hookObj[hooktype]) + 1
        table.insert(hookObj[hooktype], currKey, newFunc)
        hookObj.count = hookObj.count + 1

        local infoKey = currKey .. "Info"
        local embeddedTable = hookObj[hooktype][infoKey]
        if type(embeddedTable) ~= "table" then
            embeddedTable = {}
        end

        if this and this:GetName() then
            embeddedTable.parent = this:GetName()
        else
            embeddedTable.parent = "unknown"
        end
        embeddedTable.name = new

        hookObj[hooktype][infoKey] = embeddedTable
        Sea.util.Hooks[compoundOrig] = hookObj
    end

    -- Sea.util.unhook(orig, new, hooktype, scriptElementName)
    function Sea.util.unhook(orig, new, hooktype, scriptElementName)
        if not hooktype then
            hooktype = "before"
        end

        local compoundOrig = orig
        if scriptElementName then
            compoundOrig = orig .. "." .. scriptElementName
        end

        SeaHooks_debugErrorPrint(
            (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
            nil, NORMAL_FONT_COLOR,
            "SeaHooks Progress: Unhooking ", orig, " to ", new,
            ", hooktype ", hooktype, ", scriptElementName ", scriptElementName
        )

        local newFunc = new
        if type(new) ~= "function" then
            newFunc = Sea.util.getValue(new)
        end

        local hookObj = Sea.util.Hooks[compoundOrig]
        if not hookObj then
            hookObj = SeaHooks_hookInit(orig, compoundOrig, scriptElementName)
        else
            local foundIt
            for key, value in hookObj[hooktype] do
                if value == newFunc then
                    foundIt = true
                    break
                end
            end

            if not foundIt then
                SeaHooks_debugErrorPrint(
                    (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
                    nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: '", compoundOrig,
                    "' not hooked with '", new, "' skipping."
                )
                return
            end
        end

        local info = hookObj[hooktype]
        for key, value in info do
            if type(value) == "function" and value == newFunc then
                info[key] = nil
                local embeddedTable = info[key .. "Info"]
                if type(embeddedTable) == "table" then
                    embeddedTable.parent = nil
                    embeddedTable.name = nil
                end
                info[key .. "Info"] = embeddedTable
                hookObj[hooktype] = info
                hookObj.count = hookObj.count - 1
                Sea.util.Hooks[compoundOrig] = hookObj

                SeaHooks_debugErrorPrint(
                    (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
                    nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: Found and unhooked '", new,
                    "' from '", compoundOrig, "'."
                )
                return
            end
        end

        Sea.util.Hooks[compoundOrig] = hookObj
    end

    -- ============================================================
    -- 获取当前钩子函数的返回值（用于 after 钩子）
    -- ============================================================

    function Sea.util.getReturnArgs()
        return unpack(Sea.util.returnArgs)
    end

    -- ============================================================
    -- 调试开关
    -- ============================================================

    function Sea.util.debugHooks(enable, verboseFunctionName)
        if enable then
            SEA_HOOKS_DEBUG = true
            if verboseFunctionName then
                SEA_HOOKS_DEBUG_VERBOSE = verboseFunctionName
            else
                SEA_HOOKS_DEBUG_VERBOSE = nil
            end
        else
            SEA_HOOKS_DEBUG = nil
            SEA_HOOKS_DEBUG_VERBOSE = nil
        end
    end

    -- ============================================================
    -- 字符串工具：split（按分隔符拆分）
    -- ============================================================

    function Sea.util.split(text, separator, t, noPurge, inclusive)
        local value
        local mstart, mend = 1
        local oldn, numMatches = 0, 0
        local regexKey

        if inclusive then
            regexKey = "([^" .. separator .. "]*)"
        else
            regexKey = "([^" .. separator .. "]+)"
        end

        local sfind = strfind

        if not t then
            t = {}
        else
            oldn = table.getn(t)
        end

        mstart, mend, value = sfind(text, regexKey, mstart)
        while value do
            numMatches = numMatches + 1
            t[numMatches] = value
            mstart = mend + 1
            mstart, mend, value = sfind(text, regexKey, mstart)
        end

        if not noPurge then
            for i = numMatches + 1, oldn do
                t[i] = nil
            end
        end

        table.setn(t, numMatches)
        return t
    end

    if not Sea.string then
        Sea.string = {}
    end
    Sea.string.split = Sea.util.split
    Sea.string.explode = Sea.util.split

    -- ============================================================
    -- 变量工具：getValue / setValue（支持点号分隔的路径）
    -- ============================================================

    function Sea.util.getValue(variableName)
        if type(variableName) ~= "string" then
            return
        end

        local sfind = strfind
        local strsub = strsub

        local sstart = 2
        local value

        local match = sfind(variableName, ".", sstart, true)
        if match then
            value = getglobal(strsub(variableName, 0, match - 1))
        else
            return getglobal(variableName)
        end

        while true do
            if type(value) ~= "table" then
                return
            end

            sstart = match + 1
            match = sfind(variableName, ".", sstart, true)

            if match then
                value = value[strsub(variableName, sstart, match - 1)]
            else
                return value[strsub(variableName, sstart)]
            end
        end
    end

    function Sea.util.setValue(variableName, newValue)
        if type(variableName) ~= "string" then
            return
        end

        local sfind = strfind
        local strsub = strsub

        local sstart = 2
        local value

        local match = sfind(variableName, ".", sstart, true)
        if match then
            value = getglobal(strsub(variableName, 0, match - 1))
        else
            setglobal(variableName, newValue)
            return true
        end

        while true do
            if type(value) ~= "table" then
                return false
            end

            sstart = match + 1
            match = sfind(variableName, ".", sstart, true)

            if match then
                value = value[strsub(variableName, sstart, match - 1)]
            else
                value[strsub(variableName, sstart)] = newValue
                return true
            end
        end

        return false
    end

    -- ============================================================
    -- 钩子内部函数：初始化 / 处理器
    -- ============================================================

    function SeaHooks_hookInit(orig, compoundOrig, scriptElementName)
        SeaHooks_debugErrorPrint(
            (SEA_HOOKS_DEBUG and (SEA_HOOKS_DEBUG_VERBOSE == compoundOrig)),
            nil, NORMAL_FONT_COLOR,
            "SeaHooks Progress: Hook Init - storing '", compoundOrig,
            "' orig and replacing with hookHandler."
        )

        local hookObj = {
            name = compoundOrig,
            count = 0,
            before = {},
            after = {},
            hide = {},
            replace = {},
        }

        if scriptElementName then
            local origFrame = Sea.util.getValue(orig)
            hookObj.orig = origFrame:GetScript(scriptElementName)
            hookObj.hookFunction = SeaHooks_getDynamicHookHandler(compoundOrig)
            origFrame:SetScript(scriptElementName, hookObj.hookFunction)
            Sea.util.setValue(orig, origFrame)
        else
            hookObj.orig = Sea.util.getValue(orig)
            hookObj.hookFunction = SeaHooks_getDynamicHookHandler(compoundOrig)
            Sea.util.setValue(orig, hookObj.hookFunction)
        end

        return hookObj
    end

    function SeaHooks_getDynamicHookHandler(databaseID)
        return function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
            return SeaHooks_hookHandler(databaseID, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        end
    end

    -- 快速（非调试）钩子处理器
    function SeaHooks_hookHandlerQuick(hookObj, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
            a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        if type(hookObj) ~= "table" then
            hookObj = Sea.util.Hooks[hookObj]
            if not hookObj then
                return
            end
        end

        if hookObj.count == 0 then
            if hookObj.orig then
                return hookObj.orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
            end
            return
        end

        local ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10
        local ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
        local toggle

        -- hide 钩子
        for key, value in hookObj.hide do
            if type(value) == "function" then
                toggle, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
                if not toggle then
                    return ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                        ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
                end
            end
        end

        local ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10
        local ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20

        -- before 钩子
        for key, value in hookObj.before do
            if type(value) == "function" then
                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
                if toggle then
                    a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20
                end
            end
        end

        toggle = true

        -- replace 钩子
        for key, value in hookObj.replace do
            if type(value) == "function" then
                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
                if not toggle then
                    ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20
                    break
                end
            end
        end

        -- 调用原始函数
        if toggle and hookObj.orig then
            ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
            ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                hookObj.orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        end

        -- after 钩子
        for key, value in hookObj.after do
            if type(value) == "function" then
                SeaHooks_assignReturnArgs(true, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20)
                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
                SeaHooks_assignReturnArgs()
                if toggle then
                    ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20
                end
            end
        end

        if (type(ra1) == "table") and ((ra2 and ra3 and ra4 and ra5 and ra6 and ra7 and ra8
            and ra9 and ra10 and ra11 and ra12 and ra13 and ra14 and ra15 and ra16
            and ra17 and ra18 and ra19 and ra20) == nil) then
            return unpack(ra1)
        end

        return ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
            ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
    end

    -- 调试钩子处理器
    function SeaHooks_hookHandlerDebug(hookObj, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
            a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        local name, parent, hookFuncName

        if type(hookObj) ~= "table" then
            name = hookObj
            hookObj = Sea.util.Hooks[hookObj]
            if not hookObj then
                SeaHooks_debugErrorPrint(true, nil, RED_FONT_COLOR,
                    "SeaHooks Error: SeaHooks_hookHandler called with no defined hook parameters for '",
                    name, "'.")
                return
            end
        else
            name = hookObj.name or "unknown"
        end

        local debugVerbose = (SEA_HOOKS_DEBUG_VERBOSE) and (SEA_HOOKS_DEBUG_VERBOSE == name)

        if hookObj.count == 0 then
            if hookObj.orig then
                SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: No known hooks for '", name, "'. Calling orig.")
                return hookObj.orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
            end
            SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                "SeaHooks Progress: No known hooks or orig for '", name, "'. Exiting.")
            return
        end

        local ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10
        local ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
        local toggle

        -- hide 钩子
        for key, value in hookObj.hide do
            if type(value) == "function" then
                if type(hookObj.hide[key .. "Info"]) == "function" then
                    parent = hookObj.hide[key .. "Info"].parent
                    hookFuncName = hookObj.hide[key .. "Info"].name
                end
                SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: calling 'hide' hook #", key, ": '",
                    hookFuncName, "' for '", name, "', registered by '", parent, "'.")

                toggle, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

                if not toggle then
                    if SEA_HOOKS_DEBUG then
                        SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                            "SeaHooks Progress: 'hide' hook #", key,
                            " for '", name, "' has hidden all subsequent hook and original function calls.")
                        local numHideHooks = table.getn(hookObj.hide)
                        SeaHooks_debugErrorPrint((numHideHooks > key), nil, RED_FONT_COLOR,
                            "SeaHooks Error: detected ", numHideHooks,
                            " 'hide' hooks for '", name, "', one of which has hidden another. This will most likely cause addon conflicts.")
                    end
                    return ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                        ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
                end
            end
        end

        local ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10
        local ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20

        -- before 钩子
        for key, value in hookObj.before do
            if type(value) == "function" then
                SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: calling a 'before' hook for '", name, "'.")

                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

                if toggle then
                    a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20
                    SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                        "SeaHooks Progress: 'before' hook #", key,
                        " for '", name, "' has returned argument(s) to be passed to subsequent hook and original function calls.")
                end
            end
        end

        toggle = true

        -- replace 钩子
        for key, value in hookObj.replace do
            if type(value) == "function" then
                SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: calling a 'replace' hook for '", name, "'.")

                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

                if not toggle then
                    ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20
                    break
                end
            end
        end

        -- 调用原始函数
        if toggle and hookObj.orig then
            SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                "SeaHooks Progress: calling the 'orig' function for '", name, "'.")

            ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
            ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                hookObj.orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                    a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        end

        -- after 钩子
        for key, value in hookObj.after do
            if type(value) == "function" then
                SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                    "SeaHooks Progress: calling an 'after' hook for '", name, "'.")

                SeaHooks_assignReturnArgs(true, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20)

                toggle, ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20 =
                    value(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

                SeaHooks_assignReturnArgs()

                if toggle then
                    ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
                    ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20 =
                        ta1, ta2, ta3, ta4, ta5, ta6, ta7, ta8, ta9, ta10,
                        ta11, ta12, ta13, ta14, ta15, ta16, ta17, ta18, ta19, ta20

                    SeaHooks_debugErrorPrint(debugVerbose, nil, NORMAL_FONT_COLOR,
                        "SeaHooks Progress: 'after' hook for '", name,
                        "' has returned argument(s) to be passed to subsequent hook and original function calls.")
                end
            end
        end

        if (type(ra1) == "table") and ((ra2 and ra3 and ra4 and ra5 and ra6 and ra7 and ra8
            and ra9 and ra10 and ra11 and ra12 and ra13 and ra14 and ra15 and ra16
            and ra17 and ra18 and ra19 and ra20) == nil) then
            SeaHooks_debugErrorPrint(SEA_HOOKS_DEBUG, nil, RED_FONT_COLOR,
                "SeaHooks Error: Return argument #1 is a table for '", name,
                "'. This can be used to pass return arguments from a replace/after hook. If that is not the intention of your hook then pass an additional non-nil argument to avoid unpacking.")
            return unpack(ra1)
        end

        return ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8, ra9, ra10,
            ra11, ra12, ra13, ra14, ra15, ra16, ra17, ra18, ra19, ra20
    end

    -- 钩子分发器
    function SeaHooks_hookHandler(hookInfo, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
            a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        hookInfo = Sea.util.Hooks[hookInfo]

        if SEA_HOOKS_DEBUG then
            return SeaHooks_hookHandlerDebug(hookInfo, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        end
        return SeaHooks_hookHandlerQuick(hookInfo, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
            a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
    end

    -- ============================================================
    -- 返回值分配（用于 after 钩子传递原始返回值）
    -- ============================================================

    function SeaHooks_assignReturnArgs(toggle, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
            a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        local temp = Sea.util.returnArgs

        if toggle then
            temp[1] = a1
            temp[2] = a2
            temp[3] = a3
            temp[4] = a4
            temp[5] = a5
            temp[6] = a6
            temp[7] = a7
            temp[8] = a8
            temp[9] = a9
            temp[10] = a10
            temp[11] = a11
            temp[12] = a12
            temp[13] = a13
            temp[14] = a14
            temp[15] = a15
            temp[16] = a16
            temp[17] = a17
            temp[18] = a18
            temp[19] = a19
            temp[20] = a20

            local n = 0
            for i = 1, 20 do
                if temp[i] then
                    n = i
                end
            end
            table.setn(temp, n)
        else
            for i = 1, 20 do
                temp[i] = nil
            end
            table.setn(temp, 0)
        end

        Sea.util.returnArgs = temp
    end

    -- ============================================================
    -- 调试输出（避免频繁创建表）
    -- ============================================================

    function SeaHooks_debugErrorPrint(toggle, frameUnused, color, ...)
        if toggle then
            local msg = ""
            for key, value in arg do
                if type(key) == "number" then
                    if value == nil then
                        msg = msg .. "(nil)"
                    else
                        local currType = type(value)
                        if currType == "boolean" then
                            msg = msg .. "("
                            if value then
                                msg = msg .. "true"
                            else
                                msg = msg .. "false"
                            end
                            msg = msg .. ")"
                        elseif currType ~= "string" and currType ~= "number" then
                            msg = msg .. "(" .. currType .. ")"
                        else
                            msg = msg .. value
                        end
                    end
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(msg, color.r, color.g, color.b)
        end
    end

    -- ============================================================
    -- 更新旧版钩子数据库（即时执行）
    -- ============================================================

    for origName, info in Sea.util.Hooks do
        if type(info) == "table" then
            Sea.util.Hooks[origName].count = 0

            for hookType, hookTable in info do
                if type(hookTable) == "table" then
                    if type(hookTable.n) == "number" then
                        table.setn(Sea.util.Hooks[origName][hookType], hookTable.n)
                        SeaHooks_debugErrorPrint(
                            (SEA_HOOKS_DEBUG and SEA_HOOKS_DEBUG_VERBOSE),
                            nil, NORMAL_FONT_COLOR,
                            "SeaHooks Progress: Updating Hook Registry for '",
                            origName, "' - '", hookType, "' hooks, ",
                            hookTable.n, " found. If possible, these hooks might benifit if their addons optionally required SeaHooks."
                        )
                        Sea.util.Hooks[origName][hookType].n = nil
                    end

                    local i = 1
                    while type(hookTable[i]) == "function" do
                        Sea.util.Hooks[origName].count = Sea.util.Hooks[origName].count + 1
                        i = i + 1
                    end
                end
            end
        end
    end
end