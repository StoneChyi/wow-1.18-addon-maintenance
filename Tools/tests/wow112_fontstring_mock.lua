-- Shared 1.12 UI test contract. Pass the mock method table and object factory.
-- Font file availability is injected by tests, not inferred from local files.
return function(methods, newObject)
    local templates = {}
    for _, name in ipairs({'GameFontNormal', 'GameFontNormalLarge', 'GameFontHighlightSmall'}) do
        local font = {font = {'Fonts\\FZXHLJW.TTF', name == 'GameFontNormalLarge' and 16 or 10}}
        templates[name] = font
        _G[name] = font
    end
    failedFontPaths = {}

    function methods:SetFont(path, size, flags)
        if type(path) ~= 'string' or path == '' or failedFontPaths[path]
            or type(size) ~= 'number' or size ~= size or size <= 0 or size == math.huge then
            return nil
        end
        self.font = {path, size, flags}
        return 1
    end

    function methods:SetFontObject(font)
        if type(font) == 'string' then font = templates[font] end
        assert(type(font) == 'table' and font.font, 'unknown font object in UI mock')
        self.font = {unpack(font.font)}
    end

    function methods:SetText(value)
        assert(self.kind ~= 'FontString' or self.font, 'SetText(): Font not set')
        self.text = tostring(value)
    end

    function methods:CreateFontString(name, layer, template)
        local text = newObject('FontString', name, self)
        if template then
            assert(templates[template], 'unknown font template in UI mock: ' .. template)
            text:SetFontObject(templates[template])
        end
        return text
    end
end
