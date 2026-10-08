function string.startswith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

function string.isempty(s)
    return s == nil or s == ''
end

function string.meetingsplit(str, delimiter)
    if not str then
        return nil
    end
    local delimiter, fields = delimiter or ":", {}
    local pattern = string.format("([^%s]+)", delimiter)
    string.gsub(str, pattern, function(c)
        fields[table.getn(fields) + 1] = c
    end)
    return unpack(fields)
end

-- 添加字符串trim函数 by 武藤纯子酱 2025.12.30
function string.trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

-- 转义 FontString 标记字符，防止评论中的 |c/|T 等序列污染整行渲染；
-- 但完整保留超链接（|c色彩包装|H...|h[名]|h|r 结构），使物品/任务链接正常显示
function string.escapemarkup(s)
    if not s then
        return ""
    end
    local links = {}
    local index = 0
    local function mask(m)
        index = index + 1
        links[index] = m
        return "\1" .. index .. "\1"
    end
    -- 1. 先屏蔽"彩色链接"整体（|cAARRGGBB|H...|h[名]|h|r）
    s = string.gsub(s, "|[cC]%x%x%x%x%x%x%x%x|H[^|]+|h.-|h|[rR]", mask)
    -- 2. 再屏蔽无色链接（|H...|h[名]|h）
    s = string.gsub(s, "|H[^|]+|h.-|h", mask)
    -- 3. 剩余的裸颜色标记直接移除（不产生可见垃圾码，阻断颜色注入）
    s = string.gsub(s, "|[cC]%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|[rR]", "")
    -- 4. 其余 | 一律转义（|T 贴图、残缺链接片段等），避免被客户端解析
    s = string.gsub(s, "|", "||")
    -- 5. 还原链接（逐段拼接，避免替换串中的 % 被再次解释）
    local out = {}
    local pos = 1
    while true do
        local a, b, n = string.find(s, "\1(%d+)\1", pos)
        if not a then
            table.insert(out, string.sub(s, pos))
            break
        end
        table.insert(out, string.sub(s, pos, a - 1))
        table.insert(out, links[tonumber(n)] or "")
        pos = b + 1
    end
    return table.concat(out)
end
