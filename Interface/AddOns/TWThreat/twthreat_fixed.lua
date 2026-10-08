-- 修复后的TWT.setColumnLabels函数
function TWT.setColumnLabels()
    _G['TWTMain']:SetWidth(TWT.windowStartWidth - 70 - 70 - 70)

    TWT.nameLimit = 5
    
    -- 动态计算标签Y偏移量，永远在标题栏色块下方4px处
    local labelYOffset = -TWT_CONFIG.titleHeight - 4
    
    -- 计算标签字体大小，与姓名标签保持一致
    local titleFontSize = math.floor(TWT_CONFIG.titleHeight * 0.6)
    local labelFontSize = math.floor(titleFontSize * 0.8)
    
    -- 设置所有标签的字体大小，确保高度统一
    local fontPath = "Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf"
    
    -- 重置所有标签的字体和位置，确保高度统一
    if _G['TWTMainNameLabel'] then
        _G['TWTMainNameLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        _G['TWTMainNameLabel']:SetPoint('TOPLEFT', 5, labelYOffset)
        _G['TWTMainNameLabel']:Show()
    end

    if TWT_CONFIG.colPerc then
        _G['TWTMainPercLabel']:Show()
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8
        
        _G['TWTMainPercLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        _G['TWTMainPercLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10, labelYOffset)
    else
        _G['TWTMainPercLabel']:Hide()
    end

    if TWT_CONFIG.colThreat then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8

        -- 确保威胁值标签与姓名标签高度一致
        _G['TWTMainThreatLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        if TWT_CONFIG.colPerc then
            _G['TWTMainThreatLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -80, labelYOffset)
        else
            _G['TWTMainThreatLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10, labelYOffset)
        end
        _G['TWTMainThreatLabel']:Show()
    else
        _G['TWTMainThreatLabel']:Hide()
    end

    if TWT_CONFIG.colTPS then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8

        -- 确保TPS标签与姓名标签高度一致
        _G['TWTMainTPSLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        local rightOffset = -10
        if TWT_CONFIG.colPerc then
            rightOffset = rightOffset - 70
        end
        if TWT_CONFIG.colThreat then
            rightOffset = rightOffset - 70
        end
        _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], rightOffset, labelYOffset)
        _G['TWTMainTPSLabel']:Show()
    else
        _G['TWTMainTPSLabel']:Hide()
    end

    if TWT.nameLimit < 14 then
        TWT.nameLimit = 14
    end

    if _G['TWTMain']:GetWidth() < 190 then
        _G['TWTMain']:SetWidth(190)
    end

    TWT.windowWidth = _G['TWTMain']:GetWidth()

    TWT.setMinMaxResize()
end
