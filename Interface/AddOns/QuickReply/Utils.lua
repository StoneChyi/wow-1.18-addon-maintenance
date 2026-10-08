-- 工具函数

-- 深拷贝
function DeepCopy(orig)
    if type(orig) ~= 'table' then
        return orig
    end
    
    local copy = {}
    for key, value in pairs(orig) do
        copy[DeepCopy(key)] = DeepCopy(value)
    end
    return copy
end

-- 去掉字符串首尾空格
function strtrim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end