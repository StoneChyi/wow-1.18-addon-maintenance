-- ============================================================
-- 文件名: GoubayuHeal_Codec.lua
-- 功能: 配置文本编码器
--       导出流程：紧凑二进制序列化（通用嵌套表）→ LZ滑动窗口压缩
--       → Adler-32校验和 → URL安全Base64
--       前缀：GBYH:<版本>:
--       兼容 Lua 5.0.2：无位运算符（用 math.floor + 取余）
-- ============================================================

GoubayuHeal = GoubayuHeal or {}

local exportPrefix = "GBYH:1:"

-- ============================================================
-- 类型码定义
-- ============================================================

local TYPE_NUMBER = 1
local TYPE_BOOLEAN = 2
local TYPE_STRING = 3
local TYPE_TABLE = 4

local KEY_STRING = 1
local KEY_NUMBER = 2
local KEY_BOOLEAN = 3

local MAX_DEPTH = 16
local MAX_TABLE_ITEMS = 4096
local MAX_STRING_LEN = 65535

-- ============================================================
-- Base64 字母表（URL安全）
-- ============================================================

local base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local base64Lookup = nil

-- ============================================================
-- 取余运算（兼容Lua 5.0）
-- ============================================================

local function Remainder(value, divisor)
    return value - math.floor(value / divisor) * divisor
end

-- ============================================================
-- 打包/解包 16位/32位无符号整数
-- ============================================================

local function PackUnsigned16(value)
    if value < 0 or value > 65535 then
        return nil
    end
    local high = math.floor(value / 256)
    local low = value - high * 256
    return string.char(high, low)
end

local function PackUnsigned32(value)
    local byte1 = math.floor(value / 16777216)
    value = value - byte1 * 16777216
    local byte2 = math.floor(value / 65536)
    value = value - byte2 * 65536
    local byte3 = math.floor(value / 256)
    local byte4 = value - byte3 * 256
    return string.char(byte1, byte2, byte3, byte4)
end

local function UnpackUnsigned16(data, position)
    local high = string.byte(data, position)
    local low = string.byte(data, position + 1)
    if not high or not low then
        return nil
    end
    return high * 256 + low
end

local function UnpackUnsigned32(data, position)
    local byte1 = string.byte(data, position)
    local byte2 = string.byte(data, position + 1)
    local byte3 = string.byte(data, position + 2)
    local byte4 = string.byte(data, position + 3)
    if not byte1 or not byte2 or not byte3 or not byte4 then
        return nil
    end
    return byte1 * 16777216 + byte2 * 65536 + byte3 * 256 + byte4
end

-- ============================================================
-- Adler-32 校验和
-- ============================================================

local function CalculateChecksum(data)
    local first = 1
    local second = 0
    local index = 1
    local total = string.len(data)

    while index <= total do
        first = Remainder(first + string.byte(data, index), 65521)
        second = Remainder(second + first, 65521)
        index = index + 1
    end

    return second * 65536 + first
end

-- ============================================================
-- 序列化（通用嵌套表 → 二进制串）
-- ============================================================

local function EncodeValueKey(key, output)
    local ktype = type(key)

    if ktype == "string" then
        local len = string.len(key)
        local packedLen = PackUnsigned16(len)
        if not packedLen then
            -- 带错误码返回（此前裸 return nil，错误信息会一路传成空）
            return nil, GoubayuHeal.Codec.StrTooLong
        end
        table.insert(output, string.char(KEY_STRING))
        table.insert(output, packedLen)
        table.insert(output, key)

    elseif ktype == "number" then
        -- 与值路径一致：NaN/inf 数字键解码时无法还原（tonumber("nan")=nil），直接报错
        if key ~= key or key == math.huge or key == -math.huge then
            return nil, GoubayuHeal.Codec.NaN
        end
        local textValue = tostring(key)
        if string.len(textValue) > 255 then
            return nil, GoubayuHeal.Codec.StrTooLong
        end
        table.insert(output, string.char(KEY_NUMBER))
        table.insert(output, string.char(string.len(textValue)))
        table.insert(output, textValue)

    elseif ktype == "boolean" then
        table.insert(output, string.char(KEY_BOOLEAN))
        table.insert(output, string.char(key and 1 or 0))

    else
        return "skip"
    end

    return true
end

local function EncodeValue(data, output, depth)
    if data == nil then
        return "skip"
    end

    local vtype = type(data)

    if vtype == "number" then
        -- 与键路径一致：NaN/inf 解码端无法还原（tonumber("inf")=nil 会静默变0），直接报错
        if data ~= data or data == math.huge or data == -math.huge then
            return nil, GoubayuHeal.Codec.NaN
        end
        local textValue = tostring(data)
        if string.len(textValue) > 255 then
            return nil, GoubayuHeal.Codec.NumTooLong
        end
        table.insert(output, string.char(TYPE_NUMBER))
        table.insert(output, string.char(string.len(textValue)))
        table.insert(output, textValue)

    elseif vtype == "boolean" then
        table.insert(output, string.char(TYPE_BOOLEAN))
        table.insert(output, string.char(data and 1 or 0))

    elseif vtype == "string" then
        local len = string.len(data)
        if len > MAX_STRING_LEN then
            return nil, GoubayuHeal.Codec.StrTooLong
        end
        local packedLen = PackUnsigned16(len)
        if not packedLen then
            return nil, GoubayuHeal.Codec.StrTooLong
        end
        table.insert(output, string.char(TYPE_STRING))
        table.insert(output, packedLen)
        table.insert(output, data)

    elseif vtype == "table" then
        if depth > MAX_DEPTH then
            return nil, GoubayuHeal.Codec.NestTooDeep
        end

        local entries = {}
        local count = 0

        for key, value in data do
            local ktype = type(key)
            if ktype == "number" or ktype == "string" or ktype == "boolean" then
                local vtype = type(value)
                if vtype == "number" or vtype == "string" or vtype == "boolean"
                    or vtype == "table" then
                    count = count + 1
                    if count > MAX_TABLE_ITEMS then
                        return nil, GoubayuHeal.Codec.ElemTooLong
                    end
                    entries[count] = { key = key, value = value }
                end
            end
        end

        -- count 恒 <= MAX_TABLE_ITEMS(4096)，必在16位可表示范围内，无需额外上限检查

        local packedCount = PackUnsigned16(count)
        if not packedCount then
            return nil, GoubayuHeal.Codec.ElemTooLong
        end

        table.insert(output, string.char(TYPE_TABLE))
        table.insert(output, packedCount)

        for i = 1, count do
            local ok, err = EncodeValueKey(entries[i].key, output)
            if not ok then
                if err == "skip" then
                    -- 跳过
                else
                    return nil, err
                end
            end

            local valOk, valErr = EncodeValue(entries[i].value, output, depth + 1)
            if not valOk then
                return nil, valErr
            end
        end

    else
        return "skip"
    end

    return true
end

local function Serialize(data)
    local output = {}
    local ok, err = EncodeValue(data, output, 0)
    if not ok then
        return nil, err
    end
    return table.concat(output)
end

-- ============================================================
-- LZ 滑动窗口压缩/解压
-- ============================================================

local function FindBestMatch(data, position, total)
    local maximumOffset = position - 1
    if maximumOffset > 255 then
        maximumOffset = 255
    end

    local bestLength = 0
    local bestOffset = 0
    local offset = 1

    while offset <= maximumOffset do
        local length = 0
        while length < 130 and position + length <= total do
            local sourceByte = string.byte(data, position - offset + length)
            local currentByte = string.byte(data, position + length)
            if sourceByte ~= currentByte then
                break
            end
            length = length + 1
        end

        if length > bestLength and length >= 3 then
            bestLength = length
            bestOffset = offset
            if bestLength >= 130 then
                break
            end
        end

        offset = offset + 1
    end

    return bestLength, bestOffset
end

local function CompressBinary(data)
    local output = {}
    local total = string.len(data)
    local position = 1
    local literalStart = 1
    local literalLength = 0

    local function FlushLiteral()
        if literalLength <= 0 then
            return
        end
        table.insert(output, string.char(literalLength - 1))
        table.insert(output, string.sub(data, literalStart, literalStart + literalLength - 1))
        literalLength = 0
    end

    while position <= total do
        local matchLength, matchOffset = FindBestMatch(data, position, total)

        if matchLength >= 3 then
            FlushLiteral()
            table.insert(output, string.char(128 + matchLength - 3))
            table.insert(output, string.char(matchOffset))
            position = position + matchLength
            literalStart = position
        else
            if literalLength == 0 then
                literalStart = position
            end
            literalLength = literalLength + 1
            position = position + 1

            if literalLength >= 128 then
                FlushLiteral()
                literalStart = position
            end
        end
    end

    FlushLiteral()
    return table.concat(output)
end

local function DecompressBinary(data)
    local output = {}
    local position = 1
    local total = string.len(data)

    while position <= total do
        local header = string.byte(data, position)
        position = position + 1

        if header < 128 then
            local literalLength = header + 1
            if position + literalLength - 1 > total then
                return nil, GoubayuHeal.Codec.CompressedIncomplete
            end

            local literalIndex = 0
            while literalIndex < literalLength do
                table.insert(output, string.byte(data, position + literalIndex))
                literalIndex = literalIndex + 1
            end
            position = position + literalLength

        else
            local matchLength = header - 128 + 3
            local matchOffset = string.byte(data, position)

            if not matchOffset or matchOffset < 1 or matchOffset > table.getn(output) then
                return nil, GoubayuHeal.Codec.BadCompressedRef
            end

            position = position + 1
            local matchIndex = 1

            while matchIndex <= matchLength do
                local sourceIndex = table.getn(output) - matchOffset + 1
                table.insert(output, output[sourceIndex])
                matchIndex = matchIndex + 1
            end
        end

        -- 与压缩端对称放宽：超大配置不出现"导出成功、导入报TooLarge"的不对称
        if table.getn(output) > 1048576 then
            return nil, GoubayuHeal.Codec.TooLarge
        end
    end

    local result = {}
    local totalLen = table.getn(output)
    local i = 1

    while i <= totalLen do
        table.insert(result, string.char(output[i]))
        i = i + 1
    end

    return table.concat(result)
end

-- ============================================================
-- URL 安全 Base64 编解码
-- ============================================================

local function EncodeBase64(data)
    local output = {}
    local position = 1
    local total = string.len(data)

    while position <= total do
        local byte1 = string.byte(data, position) or 0
        local hasSecond = position + 1 <= total
        local hasThird = position + 2 <= total
        local byte2 = hasSecond and string.byte(data, position + 1) or 0
        local byte3 = hasThird and string.byte(data, position + 2) or 0

        local index1 = math.floor(byte1 / 4)
        local index2 = (byte1 - index1 * 4) * 16 + math.floor(byte2 / 16)
        local byte2High = math.floor(byte2 / 16)
        local index3 = (byte2 - byte2High * 16) * 4 + math.floor(byte3 / 64)
        local byte3High = math.floor(byte3 / 64)
        local index4 = byte3 - byte3High * 64

        table.insert(output, string.sub(base64Alphabet, index1 + 1, index1 + 1))
        table.insert(output, string.sub(base64Alphabet, index2 + 1, index2 + 1))

        if hasSecond then
            table.insert(output, string.sub(base64Alphabet, index3 + 1, index3 + 1))
        else
            table.insert(output, "=")
        end

        if hasThird then
            table.insert(output, string.sub(base64Alphabet, index4 + 1, index4 + 1))
        else
            table.insert(output, "=")
        end

        position = position + 3
    end

    return table.concat(output)
end

local function EnsureBase64Lookup()
    if base64Lookup then
        return
    end

    base64Lookup = {}
    local index = 1

    while index <= string.len(base64Alphabet) do
        base64Lookup[string.sub(base64Alphabet, index, index)] = index - 1
        index = index + 1
    end
end

local function RemoveCopyWhitespace(text)
    local output = {}
    local index = 1
    local total = string.len(text)

    while index <= total do
        local character = string.sub(text, index, index)
        if character ~= " " and character ~= "\t" and character ~= "\r" and character ~= "\n" then
            table.insert(output, character)
        end
        index = index + 1
    end

    return table.concat(output)
end

local function DecodeBase64(text)
    EnsureBase64Lookup()

    local total = string.len(text)
    if total == 0 or Remainder(total, 4) ~= 0 then
        return nil, GoubayuHeal.Codec.BadLength
    end

    local output = {}
    local position = 1

    while position <= total do
        local character1 = string.sub(text, position, position)
        local character2 = string.sub(text, position + 1, position + 1)
        local character3 = string.sub(text, position + 2, position + 2)
        local character4 = string.sub(text, position + 3, position + 3)

        local value1 = base64Lookup[character1]
        local value2 = base64Lookup[character2]
        local value3 = character3 == "=" and 0 or base64Lookup[character3]
        local value4 = character4 == "=" and 0 or base64Lookup[character4]

        if not value1 or not value2 or not value3 or not value4 then
            return nil, GoubayuHeal.Codec.BadChar
        end

        if character3 == "=" and character4 ~= "=" then
            return nil, GoubayuHeal.Codec.BadEnd
        end

        if (character3 == "=" or character4 == "=") and position + 3 ~= total then
            return nil, GoubayuHeal.Codec.BadPad
        end

        local byte1 = value1 * 4 + math.floor(value2 / 16)
        table.insert(output, string.char(byte1))

        if character3 ~= "=" then
            local value2Low = value2 - math.floor(value2 / 16) * 16
            local byte2 = value2Low * 16 + math.floor(value3 / 4)
            table.insert(output, string.char(byte2))
        end

        if character4 ~= "=" then
            local value3Low = value3 - math.floor(value3 / 4) * 4
            local byte3 = value3Low * 64 + value4
            table.insert(output, string.char(byte3))
        end

        position = position + 4
    end

    return table.concat(output)
end

-- ============================================================
-- 反序列化（二进制串 → 通用嵌套表）
-- ============================================================

local function DecodeKey(data, total, position)
    local ktype = string.byte(data, position)
    if not ktype then
        return nil, GoubayuHeal.Codec.Incomplete
    end
    position = position + 1

    if ktype == KEY_STRING then
        local len = UnpackUnsigned16(data, position)
        if not len then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        position = position + 2
        if position + len - 1 > total then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        local key = string.sub(data, position, position + len - 1)
        return key, position + len

    elseif ktype == KEY_NUMBER then
        local len = string.byte(data, position)
        if not len then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        position = position + 1
        if position + len - 1 > total then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        local textValue = string.sub(data, position, position + len - 1)
        local num = tonumber(textValue)
        return num, position + len

    elseif ktype == KEY_BOOLEAN then
        local b = string.byte(data, position)
        if not b then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        return (b == 1), position + 1
    end

    return nil, GoubayuHeal.Codec.Incomplete
end

local function DecodeValue(data, total, position, depth)
    local vtype = string.byte(data, position)
    if not vtype then
        return nil, GoubayuHeal.Codec.Incomplete
    end
    position = position + 1

    if vtype == TYPE_NUMBER then
        local len = string.byte(data, position)
        if not len then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        position = position + 1
        if position + len - 1 > total then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        local textValue = string.sub(data, position, position + len - 1)
        local num = tonumber(textValue)
        return (num and num or 0), position + len

    elseif vtype == TYPE_BOOLEAN then
        local b = string.byte(data, position)
        if not b then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        return (b == 1), position + 1

    elseif vtype == TYPE_STRING then
        local len = UnpackUnsigned16(data, position)
        if not len then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        position = position + 2
        if position + len - 1 > total then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        local value = string.sub(data, position, position + len - 1)
        return value, position + len

    elseif vtype == TYPE_TABLE then
        if depth > MAX_DEPTH then
            return nil, GoubayuHeal.Codec.NestTooDeep
        end

        local count = UnpackUnsigned16(data, position)
        if not count then
            return nil, GoubayuHeal.Codec.Incomplete
        end
        position = position + 2

        local result = {}
        local i = 1

        while i <= count do
            local key, afterKey = DecodeKey(data, total, position)
            if key == nil and type(afterKey) == "string" then
                return nil, afterKey
            end
            if key == nil then
                return nil, GoubayuHeal.Codec.Incomplete
            end
            position = afterKey

            local value, afterValue = DecodeValue(data, total, position, depth + 1)
            if value == nil and type(afterValue) == "string" then
                return nil, afterValue
            end
            if value == nil then
                return nil, GoubayuHeal.Codec.Incomplete
            end
            position = afterValue

            result[key] = value
            i = i + 1
        end

        return result, position
    end

    return nil, GoubayuHeal.Codec.BadType
end

local function Deserialize(data)
    local total = string.len(data)
    local value, position = DecodeValue(data, total, 1, 0)

    if value == nil and type(position) == "string" then
        return nil, position
    end
    if value == nil then
        return nil, GoubayuHeal.Codec.Incomplete
    end

    return value
end

-- ============================================================
-- 对外 API
-- ============================================================

-- 编码任意可序列化 Lua 数据
function GoubayuHeal.Codec_Encode(data)
    local serialized, err = Serialize(data)
    if not serialized then
        return nil, err
    end

    local compressed = CompressBinary(serialized)
    local envelope = PackUnsigned32(CalculateChecksum(serialized)) .. compressed

    return exportPrefix .. EncodeBase64(envelope)
end

-- 解码 GBYH:<版本>: 字符串
function GoubayuHeal.Codec_Decode(text)
    if not text or type(text) ~= "string" then
        return nil, GoubayuHeal.Codec.InvalidText
    end

    text = RemoveCopyWhitespace(text)
    local prefixLen = string.len(exportPrefix)

    if string.sub(text, 1, prefixLen) ~= exportPrefix then
        return nil, GoubayuHeal.Codec.BadPrefix
    end

    local payloadText = string.sub(text, prefixLen + 1)
    local payload, b64err = DecodeBase64(payloadText)
    if not payload then
        return nil, b64err
    end

    local envelopeLen = string.len(payload)
    if envelopeLen < 4 then
        return nil, GoubayuHeal.Codec.Incomplete
    end

    local expectedChecksum = UnpackUnsigned32(payload, 1)
    if not expectedChecksum then
        return nil, GoubayuHeal.Codec.Incomplete
    end

    local compressed = string.sub(payload, 5)
    local serialized, decompressErr = DecompressBinary(compressed)
    if not serialized then
        return nil, decompressErr
    end

    local actualChecksum = CalculateChecksum(serialized)
    if actualChecksum ~= expectedChecksum then
        return nil, GoubayuHeal.Codec.BadChecksum
    end

    local data, deserializeErr = Deserialize(serialized)
    if not data then
        return nil, deserializeErr
    end

    return data
end

-- 导出当前 Config
function GoubayuHeal.ExportConfigText()
    if not GoubayuHeal.Config then
        return nil, GoubayuHeal.Codec.NotInitialized
    end
    return GoubayuHeal.Codec_Encode(GoubayuHeal.Config)
end
