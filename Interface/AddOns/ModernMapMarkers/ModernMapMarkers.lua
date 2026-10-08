local MMM = CreateFrame("Frame", "ModernMapMarkersCore", UIParent)
MMM.markers = {}
MMM.Data = {}
MMM.ZoneMarkers = {}
MMM.FlatDropdownData = nil

local L = ModernMapMarkers_Locale

local ALL_TYPES = { "DUNGEON", "RAID", "WORLDBOSS", "BOAT", "ZEPPELIN", "TRAM" }

MMM.filters = {
    DUNGEON   = true,
    RAID      = true,
    BOAT      = true,
    ZEPPELIN  = true,
    TRAM      = true,
    WORLDBOSS = true,
    FACTION   = "ALL"
}

local lastContinent = nil
local lastZone      = nil
local forceRefresh  = false

local TEX_BASE = "Interface\\AddOns\\ModernMapMarkers\\Textures\\"
local TEXTURE_MAP = {
    DUNGEON   = TEX_BASE .. "dungeon.tga",
    RAID      = TEX_BASE .. "raid.tga",
    BOAT      = TEX_BASE .. "boat.tga",
    ZEPPELIN  = TEX_BASE .. "zepp.tga",
    TRAM      = TEX_BASE .. "tram.tga",
    WORLDBOSS = TEX_BASE .. "worldboss.tga",
}

local ZONE_CACHE = {}
function MMM:CacheZones()
    ZONE_CACHE[1] = { GetMapZones(1) }
    ZONE_CACHE[2] = { GetMapZones(2) }
end

local CANONICAL_ZONE = {
    ["Blackrock Depths"]      = "Burning Steppes",
    ["Lower Blackrock Spire"] = "Burning Steppes",
    ["Upper Blackrock Spire"] = "Burning Steppes",
    ["Blackwing Lair"]        = "Burning Steppes",
    ["Molten Core"]           = "Burning Steppes",
    ["Stormwind Vault"]       = "Stormwind City",
}

function MMM:BuildData()
    if self.dataBuilt then return end
    if not ModernMapMarkers_Points then return end

    MMM.Data = {}
    MMM.ZoneMarkers = {}

    local index = 1

    for contID, zones in pairs(ModernMapMarkers_Points) do
        MMM.ZoneMarkers[contID] = MMM.ZoneMarkers[contID] or {}

        for zoneName, markers in pairs(zones) do
            MMM.ZoneMarkers[contID][zoneName] = {}

            for _, m in ipairs(markers) do
                local typeUpper = string.upper(m.type or "UNKNOWN")
                if typeUpper == "ZEPP" then typeUpper = "ZEPPELIN" end

                local markerData = {
                    continent   = contID,
                    zoneName    = zoneName,
                    x           = m.x,
                    y           = m.y,
                    name        = m.name,
                    type        = typeUpper,
                    description = m.info,
                    atlasID     = m.atlas,
                    id          = index
                }

                table.insert(MMM.Data, markerData)
                table.insert(MMM.ZoneMarkers[contID][zoneName], markerData)

                index = index + 1
            end
        end
    end
    self.dataBuilt = true
end

function ModernMapMarkers_GetFlatData()
    MMM:BuildData()

    if MMM.FlatDropdownData then return MMM.FlatDropdownData end

    local filteredData = {}
    local seenNames = {}

    for _, data in ipairs(MMM.Data) do
        if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
            local baseName = data.name or ""

            local dashIndex = string.find(baseName, " %- ")
            if dashIndex then
                baseName = string.sub(baseName, 1, dashIndex - 1)
            end

            local existingIndex = seenNames[baseName]
            if not existingIndex then
                local dropData = {}
                for k, v in pairs(data) do dropData[k] = v end
                dropData.name = baseName
                table.insert(filteredData, dropData)
                seenNames[baseName] = table.getn(filteredData)
            else
                local canon = CANONICAL_ZONE[baseName]
                if canon and data.zoneName == canon then
                    local dropData = {}
                    for k, v in pairs(data) do dropData[k] = v end
                    dropData.name = baseName
                    filteredData[existingIndex] = dropData
                end
            end
        end
    end

    MMM.FlatDropdownData = filteredData
    return filteredData
end

function MMM:RefreshMarkers()
    if not WorldMapFrame:IsVisible() then return end

    self:BuildData()

    local currentContinent = GetCurrentMapContinent()
    local currentZone      = GetCurrentMapZone()

    if not forceRefresh
       and currentContinent == lastContinent
       and currentZone == lastZone then
        return
    end

    lastContinent = currentContinent
    lastZone      = currentZone
    forceRefresh  = false

    if currentContinent == 0 or currentZone == 0 then
        self:HideAllMarkers()
        return
    end

    local zoneNames      = ZONE_CACHE[currentContinent]
    local currentZoneName = zoneNames and zoneNames[currentZone]
    if not currentZoneName then
        self:HideAllMarkers()
        return
    end

    local englishZoneName = L:GetEnglishZoneName(currentZoneName)

    local zoneMarkers = MMM.ZoneMarkers[currentContinent] and MMM.ZoneMarkers[currentContinent][englishZoneName]

    local markerIndex = 0

    if zoneMarkers then
        for _, data in ipairs(zoneMarkers) do
            
            local showMarker = (MMM.filters[data.type] == true)

            if showMarker and (data.type == "BOAT" or data.type == "ZEPPELIN" or data.type == "TRAM") then
                if MMM.filters.FACTION ~= "ALL"
                   and data.description ~= "Neutral"
                   and data.description ~= MMM.filters.FACTION then
                    showMarker = false
                end
            end

            if showMarker then
                markerIndex = markerIndex + 1
                local marker = self:GetOrCreateMarker(markerIndex)

                if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
                    marker:SetWidth(32)
                    marker:SetHeight(32)
                else
                    marker:SetWidth(24)
                    marker:SetHeight(24)
                end

                local width  = WorldMapDetailFrame:GetWidth()
                local height = WorldMapDetailFrame:GetHeight()
                marker:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", data.x * width, -data.y * height)

                local tex = TEXTURE_MAP[data.type] or "Interface\\Minimap\\POIIcons"
                if marker.lastTexture ~= tex then
                    marker.texture:SetTexture(tex)
                    marker.lastTexture = tex
                end

                marker.name        = L:GetLocalizedMarkerName(data.name)
                marker.description = data.description
                marker.markerType  = data.type
                marker.atlasID     = data.atlasID
                marker.continent   = data.continent
                marker.zoneName    = data.zoneName

                marker:Show()
            end
        end
    end

    self:HideMarkersFrom(markerIndex + 1)
end

function MMM:HideAllMarkers()
    self:HideMarkersFrom(1)
end

function MMM:HideMarkersFrom(startIndex)
    for i = startIndex, table.getn(self.markers) do
        if self.markers[i] then
            self.markers[i]:Hide()
        end
    end
end

function MMM:InvalidateCache()
    forceRefresh = true
end

function MMM:OnMarkerClick(marker)
    if marker.atlasID then
        if Atlas_Refresh and AtlasOptions then
            local foundType, foundIndex = nil, nil

            for catIndex, catMaps in ipairs(ATLAS_DROPDOWNS) do
                for mapIndex, mapID in ipairs(catMaps) do
                    if mapID == marker.atlasID then
                        foundType = catIndex
                        foundIndex = mapIndex
                        break
                    end
                end
                if foundType then break end
            end

            if not foundType then
                local englishZone = marker.zoneName
                local localizedZone = L:GetLocalizedZoneName(englishZone) or englishZone

                for mapID, mapInfo in pairs(AtlasMaps) do
                    if mapInfo.ZoneName and mapInfo.ZoneName[1] == localizedZone then
                        for catIndex, catMaps in ipairs(ATLAS_DROPDOWNS) do
                            for mapIndex, id in ipairs(catMaps) do
                                if id == mapID then
                                    foundType = catIndex
                                    foundIndex = mapIndex
                                    break
                                end
                            end
                            if foundType then break end
                        end
                        if foundType then break end
                    end
                end
            end

            if not foundType then
                local baseName = marker.name
                local dashIndex = string.find(baseName, " %- ")
                if dashIndex then
                    baseName = string.sub(baseName, 1, dashIndex - 1)
                end
                local localizedName = L:GetLocalizedMarkerName(baseName) or baseName
                for mapID, mapInfo in pairs(AtlasMaps) do
                    if mapInfo.ZoneName and mapInfo.ZoneName[1] == localizedName then
                        for catIndex, catMaps in ipairs(ATLAS_DROPDOWNS) do
                            for mapIndex, id in ipairs(catMaps) do
                                if id == mapID then
                                    foundType = catIndex
                                    foundIndex = mapIndex
                                    break
                                end
                            end
                            if foundType then break end
                        end
                        if foundType then break end
                    end
                end
            end

            if foundType then
                AtlasOptions.AtlasType = foundType
                AtlasOptions.AtlasZone = foundIndex

                if AtlasFrame and not AtlasFrame:IsVisible() then
                    AtlasFrame:Show()
                else
                    Atlas_Refresh()
                end

                -- 大地图层级高于 Atlas，打开 Atlas 后隐藏世界地图，避免遮挡
                if WorldMapFrame and WorldMapFrame:IsVisible() then
                    WorldMapFrame:Hide()
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModernMapMarkers:|r 未找到对应的 Atlas 地图。请检查数据或报告作者。 (ID: " .. tostring(marker.atlasID) .. ")")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModernMapMarkers:|r " .. (L:GetLocalizedMarkerName("Atlas is not installed or enabled.") or "Atlas 未安装或未启用。"))
        end
    end
end

function MMM:GetOrCreateMarker(index)
    if not self.markers[index] then
        local marker = CreateFrame("Button", "ModernMapMarkerIcon"..index, WorldMapButton)
        marker:SetWidth(24)
        marker:SetHeight(24)
        marker:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)

        local tex = marker:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(marker)
        marker.texture = tex

        marker:SetScript("OnClick", function() MMM:OnMarkerClick(this) end)

        marker:SetScript("OnEnter", function()
            WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
            WorldMapTooltip:AddLine(this.name, 1, 0.82, 0)

            if this.description then
                if this.markerType == "DUNGEON" or this.markerType == "RAID" or this.markerType == "WORLDBOSS" then
                    local lvlLabel = L:GetLocalizedMarkerName("Level") or "Level"
                    WorldMapTooltip:AddLine(lvlLabel .. ": " .. this.description, 1, 1, 1, 1)
                elseif this.description == "Alliance" then
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Alliance"), 0.0, 0.47, 1.0, 1)
                elseif this.description == "Horde" then
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Horde"), 1.0, 0.0, 0.0, 1)
                else
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName(this.description), 1, 1, 1, 1)
                end
            end
            WorldMapTooltip:Show()
        end)

        marker:SetScript("OnLeave", function() WorldMapTooltip:Hide() end)

        self.markers[index] = marker
    end
    return self.markers[index]
end

function ModernMapMarkers_SetFilter(key, state)
    if key == "ALL" then
        for _, t in ipairs(ALL_TYPES) do
            MMM.filters[t] = state
        end
    else
        MMM.filters[key] = state
    end
    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

function ModernMapMarkers_SetFactionFilter(factionStr)
    MMM.filters.FACTION = factionStr
    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

function MMM:GetZoneIndex(continentID, zoneName)
    local zones = ZONE_CACHE[continentID] or {}
    local localizedName = L:GetLocalizedZoneName(zoneName)
    for i, name in ipairs(zones) do
        if name == localizedName then return i end
    end
    for i, name in ipairs(zones) do
        if name == zoneName then return i end
    end
    return 0
end

function ModernMapMarkers_FindMarker(dataIndex)
    MMM:BuildData()
    local data = MMM.Data[dataIndex]
    if not data then return end

    local zoneIndex = MMM:GetZoneIndex(data.continent, data.zoneName)
    if zoneIndex > 0 then
        SetMapZoom(data.continent, zoneIndex)
    end

    if not MMM.filters[data.type] then
        MMM.filters[data.type] = true
        if ModernMapMarkers_SyncFilterUI then
            ModernMapMarkers_SyncFilterUI(data.type, true)
        end
    end

    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

local original_WorldMapFrame_Update = WorldMapFrame_Update
function WorldMapFrame_Update()
    if original_WorldMapFrame_Update then
        original_WorldMapFrame_Update()
    end
    MMM:RefreshMarkers()
end

MMM:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if ModernMapMarkersDB and ModernMapMarkersDB.filters then
            for k, v in pairs(ModernMapMarkersDB.filters) do
                MMM.filters[k] = v
            end
        else
            local faction = UnitFactionGroup("player")
            if faction == "Alliance" or faction == "Horde" then
                MMM.filters.FACTION = faction
            end
        end

        L:Initialize()
        MMM:CacheZones()
        MMM:BuildData()
        MMM:InvalidateCache()
        MMM:RefreshMarkers()

    elseif event == "PLAYER_LOGOUT" then
        if not ModernMapMarkersDB then ModernMapMarkersDB = {} end
        ModernMapMarkersDB.filters = {}
        for k, v in pairs(MMM.filters) do
            ModernMapMarkersDB.filters[k] = v
        end
    end
end)
MMM:RegisterEvent("VARIABLES_LOADED")
MMM:RegisterEvent("PLAYER_LOGOUT")