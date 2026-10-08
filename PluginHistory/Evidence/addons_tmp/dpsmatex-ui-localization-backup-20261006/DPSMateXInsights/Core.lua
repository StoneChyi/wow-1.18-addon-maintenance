local D = DPSMateX
local E = { VERSION = 1, ready = false, shields = {}, pending = {}, identities = {}, seen = {} }
D.Insights = E

E.ids = { healing = "healingabsorbsactual", casts = "spellcastsactual", playback = "actionreplay" }
E.names = { healing = "治疗与实际吸收", casts = "成功施放", playback = "动作回放" }
E.UNKNOWN = "来源未知"
E.limits = { perUser = 500, perFight = 8000, audit = 300, debug = 200 }

local function segment()
    return { healing = {}, casts = {}, playback = {}, duration = 0, seq = 0,
        stored = 0, dropped = 0, absorbed = 0, unknown = 0, excluded = 0, audit = {}, collected = {} }
end
E.NewSegment = segment

function E:Copy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k,v in pairs(t) do n[k] = self:Copy(v) end
    return n
end

-- Bounded ring, persisted without shared references between fights.
function E:Push(ring, value, limit)
    ring.data = ring.data or {}; ring.head = ring.head or 1; ring.count = ring.count or 0
    if ring.count < limit then
        local slot = math.mod(ring.head + ring.count - 1, limit) + 1
        ring.data[slot] = value; ring.count = ring.count + 1
    else
        ring.data[ring.head] = value; ring.head = math.mod(ring.head, limit) + 1
        ring.dropped = (ring.dropped or 0) + 1
    end
end

function E:RingValues(ring, limit)
    local result = {}
    if not ring or not ring.data then return result end
    for i=0,(ring.count or 0)-1 do
        result[table.getn(result)+1] = ring.data[math.mod((ring.head or 1)+i-1, limit)+1]
    end
    return result
end

function E:MigrateReplayBounds()
    local db=self.db
    if db.replayLimit==self.limits.perUser and db.replayFightLimit==self.limits.perFight then return end
    local oldLimit=db.replayLimit or 2000
    local segments={db.current,db.total}
    for _,s in ipairs(db.history or {}) do table.insert(segments,s) end
    for _,s in ipairs(segments) do
        local candidates,byUser={},{}
        local previous=0
        for name,u in pairs(s.playback or {}) do
            local all=self:RingValues(u.events,oldLimit)
            previous=previous+table.getn(all)
            local kept={}
            for i=math.max(1,table.getn(all)-self.limits.perUser+1),table.getn(all) do
                table.insert(kept,all[i]);table.insert(candidates,all[i])
            end
            byUser[name]={user=u,events=kept,previous=table.getn(all),dropped=u.events.dropped or 0}
        end
        table.sort(candidates,function(a,b) return a.seq>b.seq end)
        local threshold=table.getn(candidates)>self.limits.perFight and candidates[self.limits.perFight].seq or 0
        local stored=0
        for _,entry in pairs(byUser) do
            local ring={}
            for _,ev in ipairs(entry.events) do
                if ev.seq>=threshold then self:Push(ring,ev,self.limits.perUser);stored=stored+1 end
            end
            ring.dropped=entry.dropped+entry.previous-(ring.count or 0)
            entry.user.events=ring
        end
        s.stored=stored;s.dropped=(s.dropped or 0)+math.max(0,previous-stored)
    end
    db.replayLimit=self.limits.perUser;db.replayFightLimit=self.limits.perFight
    self.replayIndexes=nil
end

function E:Initialize()
    if not D.Settings or not D.DPSMateXHistory then return end
    local db = DPSMateXInsightsDB
    if type(db) ~= "table" or db.version ~= self.VERSION then
        db = { version = self.VERSION, total = segment(), current = segment(), history = {},
            config = { rawHealing = false, debug = false }, debugLog = {} }
        DPSMateXInsightsDB = db
    end
    self.db = db; self.ready = true
    self:MigrateReplayBounds()
    self:ReleaseHealingBins()
    if not self.initialized then
        self.initialized = true
        -- A reload/reconnect cannot reconstruct all still-active shield owners reliably.
        if db.current.active then
            db.total.duration=(db.total.duration or 0)+math.max(0,(db.current.duration or 0)-(db.current.offset or 0))
        end
        db.current.active = false; db.current.started = nil
        self.shields = {}; self.seen = {}; self.pending = {}; self.identities = {}
        if not db.installed then
            for _,id in pairs(self.ids) do D.Settings.enabledmodes[id] = true end
            db.installed = true
        end
    end
    self:AlignHistory()
    for _,users in pairs({db.total.healing,db.total.casts,db.total.playback,db.current.healing,db.current.casts,db.current.playback}) do
        for name,u in pairs(users) do
            D.DB:BuildUser(name, u.class)
        end
    end
    if self.RegisterModes then self:RegisterModes() end
    for _,id in pairs(self.ids) do
        if D:TContains(D.Settings.enabledmodes, id) then D:EnableModule(id) end
    end
    local major,minor,patch
    if GetNampowerVersion then major,minor,patch = GetNampowerVersion() end
    self.versionText = string.format("%s.%s.%s", tostring(major or 0), tostring(minor or 0), tostring(patch or 0))
    self.available = major and (major > 4 or (major == 4 and minor >= 5)) and
        GetSpellNameAndRankForId and GetUnitGUID and bit and bit.band and true or false
    if not self.available and not self.warned then
        self.warned = true
        D:SendMessage("精确统计扩展需要 Nampower 4.5 或以上；当前无法采集新模块。")
    end
end

function E:AlignHistory()
    local names = D.DPSMateXHistory.names or {}
    local aligned = {}
    for i,label in ipairs(names) do
        local saved = self.db.history[i]
        if saved and saved.label == label then aligned[i] = saved
        else aligned[i] = { label = label, missing = true } end
    end
    self.db.history = aligned
end

function E:Reset()
    if not self.ready then
        if type(DPSMateXInsightsDB)=="table" then
            DPSMateXInsightsDB.total=segment();DPSMateXInsightsDB.current=segment();DPSMateXInsightsDB.history={}
            DPSMateXInsightsDB.debugLog={}
        end
        return
    end
    self.db.total = segment(); self.db.current = segment(); self.db.history = {}
    self.db.debugLog = {}; self.shields = {}; self.pending = {}; self.identities = {}; self.seen = {}
    if self.HideDetails then self:HideDetails() end
end

function E:ResetCurrent()
    if not self.ready then return end
    local continuing = D.DB:IsCombatActive()
    self:EndCombat()
    self.db.current = segment(); self.seen = {}; self.pending = {}
    if continuing then self:StartCombat() end
    -- Preserve pre-pull shields. Their lifetime is independent of statistical segments.
end

function E:StartCombat()
    if not self.ready then return end
    local s = self.db.current
    if not s.active then s.active = true; s.started = GetTime(); s.offset = s.duration or 0 end
end

function E:Duration(s)
    if s.active and s.started then return (s.offset or 0) + math.max(0, GetTime()-s.started) end
    return s.duration or 0
end

function E:EndCombat()
    if not self.ready then return end
    local s = self.db.current
    if s.active then
        s.duration = self:Duration(s); s.active = false; s.started = nil
        self.db.total.duration = (self.db.total.duration or 0) + math.max(0, s.duration-(s.offset or 0))
    end
end

function E:SaveSegment(label)
    if not self.ready then return end
    local s = self:Copy(self.db.current)
    s.duration = self:Duration(self.db.current); s.active = false; s.started = nil; s.label = label
    table.insert(self.db.history, 1, s)
    local limit = math.max(1, math.min(100, tonumber(D.Settings.datasegments) or 10))
    while table.getn(self.db.history) > limit do table.remove(self.db.history) end
end

function E:RemoveSegment(i)
    if self.ready then table.remove(self.db.history, i) end
end

function E:GetMode(key, kind)
    if not self.ready then return {missing=true}, 0, {} end
    if D.Encounters and D.Encounters.ready and D.Encounters:Normalize(key) then return D.Encounters:GetInsights(key,kind) end
    local s = self.db.current
    local options = D.Settings.windows[key].options[2]
    for mode,checked in pairs(options) do
        if checked then
            if mode == "total" then
                if kind == "playback" then return {unsupported=true}, 0, {} end
                s = self.db.total
            elseif string.find(mode, "^segment%d+$") then
                local index = tonumber(string.sub(mode,8))
                s = self.db.history[index]
                if not s or s.label ~= D.DPSMateXHistory.names[index] then return {missing=true}, 0, {} end
            end
            break
        end
    end
    local duration = self:Duration(s)
    if s == self.db.total and self.db.current.active then
        duration = duration + self:Duration(self.db.current)-(self.db.current.offset or 0)
    end
    return s, math.max(1, duration), {}
end

function E:Enabled(kind)
    return self.ready and self.available and D.Registered and D.EnabledModules[self.ids[kind]]
end

function E:User(s, kind, person)
    local users = s[kind]
    local u = users[person.name]
    if not u then
        D.DB:BuildUser(person.name,person.class)
        u = { name=person.name, class=person.class, owner=person.owner, guid=person.guid, total=0, effective=0,
            absorb=0, count=0, skills={}, targets={}, events={} }
        users[person.name] = u
    end
    return u
end

function E:Skill(u, key, spell, spellId, source)
    local row = u.skills[key]
    if not row then
        row = {name=spell, spellId=spellId, source=source, total=0,effective=0,absorb=0,count=0,targets={}}
        u.skills[key] = row
    end
    return row
end

function E:Target(rows, name)
    name = name or "无目标"
    local row = rows[name]
    if not row then row={name=name,total=0,effective=0,absorb=0,count=0}; rows[name]=row end
    return row
end

function E:Value(row, kind)
    if kind == "healing" then return (self.db.config.rawHealing and row.total or row.effective) + row.absorb end
    return row.count or 0
end

function E:Name(u)
    if D.Settings.mergepets and u.owner then return u.owner end
    return u.name
end

function E:SelectedUsers(s, kind, name, key)
    local users = {}
    for _,u in pairs(s[kind] or {}) do
        local display=self:Name(u)
        if (not name or display == name) and (name or not key or display==self.UNKNOWN or D:ApplyFilter(key,display)) then table.insert(users,u) end
    end
    return users
end

function E:Sorted(s, kind, key)
    local merged = {}
    for _,u in pairs(s[kind] or {}) do
        local name = self:Name(u)
        if name == self.UNKNOWN or D:ApplyFilter(key,name) then
            merged[name] = (merged[name] or 0) + self:Value(u,kind)
        end
    end
    local result,total = {},0
    for name,value in pairs(merged) do
        if value > 0 then table.insert(result,{name=name,value=value}); total=total+value end
    end
    table.sort(result,function(a,b) if a.value == b.value then return a.name < b.name end return a.value > b.value end)
    return result,total
end

function E:RelativeTime()
    return self.eventTime or self:Duration(self.db.current)
end



function E:Audit(record)
    self:Push(self.db.current.audit, record, self.limits.audit)
    if self.db.config.debug then self:Push(self.db.debugLog,self:Copy(record),self.limits.debug) end
end

function E:Touch(kind)
    self.db.current.collected[kind] = true; self.db.total.collected[kind] = true
    D.DB.NeedUpdate = true
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("PLAYER_LOGOUT")
lifecycle:RegisterEvent("PLAYER_ENTERING_WORLD")
lifecycle:SetScript("OnEvent",function()
    if event == "PLAYER_LOGOUT" and E.ready then E:EndCombat()
    elseif event == "PLAYER_ENTERING_WORLD" then
        E.shields = {}; E.identities = {}; E.pending = {}; E.seen = {}
    end
end)
local elapsed = 0
lifecycle:SetScript("OnUpdate",function()
    if not E.ready or (not E.db.current.active and table.getn(E.pending)==0) then return end
    elapsed = elapsed + arg1
    if elapsed < 0.25 then return end
    elapsed = 0
    if E.db.current.active then E.db.current.duration = E:Duration(E.db.current) end
    if table.getn(E.pending)>0 and E.FlushPending then E:FlushPending() end
end)

SLASH_DPSMATEXINSIGHTS1 = "/dpsx"
SlashCmdList.DPSMATEXINSIGHTS = function(message)
    if not E.ready then return end
    local cmd = string.lower(message or "")
    if cmd == "debug" then
        E.db.config.debug = not E.db.config.debug
        D:SendMessage("扩展调试记录："..(E.db.config.debug and "开启（最多200条）" or "关闭"))
    elseif cmd == "status" then
        local s = E.db.current
        D:SendMessage("Nampower "..(E.versionText or "未知").."；吸收 "..s.absorbed.." / 未知 "..s.unknown..
            " / 排除 "..s.excluded.."；回放保留 "..s.stored.." / 丢弃 "..s.dropped)
    elseif cmd == "raw" then
        E.db.config.rawHealing = not E.db.config.rawHealing
        D.DB.NeedUpdate = true
        D:SendMessage(E.db.config.rawHealing and "合计口径：总治疗＋实际吸收" or "合计口径：有效治疗＋实际吸收")
    else
        E:OpenDetails("healing",nil,1)
        D:SendMessage("/dpsx：详情；/dpsx raw：合计口径；/dpsx debug：调试；/dpsx status：核对")
    end
end

function E:ReleaseHealingBins()
    if self.db.compactDetailsVersion == 1 then return end
    local function clear(s)
        for _,u in pairs(s.healing or {}) do
            u.bins=nil;u.binCount=nil;u.binsTruncated=nil
        end
    end
    clear(self.db.total);clear(self.db.current)
    for _,s in pairs(self.db.history or {}) do clear(s) end
    self.db.compactDetailsVersion=1
end
