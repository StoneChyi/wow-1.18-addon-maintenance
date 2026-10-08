from refactor_compact_details import ROOT,BACKUP,save,methods,block_end
import re

for old in BACKUP.rglob('*Details*.lua'):
    p=ROOT/old.relative_to(BACKUP)
    s=p.read_text(encoding='utf-8-sig')
    for m in reversed(list(re.finditer(r'\bif \(PieChart\) then',s))):
        end=block_end(s,m.start());s=s[:m.start()]+s[end:]
    s=re.sub(r'^\s*[\w.]+\.proc = "None"\s*\n','\n',s,flags=re.M)
    while True:
        cleaned=re.sub(r'\bif [^\n]+ then\s*(?:else\s*)?end\s*\n','',s)
        if cleaned==s:break
        s=cleaned
    s=re.sub(r'\n(?:[ \t]*\n){3,}','\n\n',s)
    save(p,s)

p=ROOT/'DPSMateXInsights/Details.lua';s=p.read_text(encoding='utf-8-sig')
for a,b,n in reversed(methods(s)):
    if n=='DrawGraph':s=s[:a]+s[b:]
s=s.replace('(w.view=="graph" or w.view=="audit")','w.view=="audit"')
s=re.sub(r'^.*if w.graph then w.graph:Hide\(\) end\s*\n','',s,flags=re.M)
s=re.sub(r'^.*local graph=w.view=="graph".*\n','',s,flags=re.M)
s=s.replace('if line and not graph then','if line then')
s=re.sub(r'^.*if graph then self:DrawGraph.*\n','',s,flags=re.M)
s=re.sub(r'^.*elseif w.view=="graph".*\n','',s,flags=re.M)
s=s.replace(' or (view=="graph" and w.kind=="healing" and not s.aggregate)','')
save(p,s)

p=ROOT/'DPSMateXInsights/Core.lua';s=p.read_text(encoding='utf-8-sig')
for a,b,n in reversed(methods(s)):
    if n=='AddBin':s=s[:a]+s[b:]
s=s.replace(', bins = 600','').replace('targets={}, bins={}, events={}','targets={}, events={}')
# No new timeline samples; old saved graphs are released once, outside combat.
s=s.replace('self:MigrateReplayBounds()','self:MigrateReplayBounds()\n    self:ReleaseHealingBins()')
s+='''
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
'''
save(p,s)
p=ROOT/'DPSMateXInsights/Parser.lua';s=p.read_text(encoding='utf-8-sig')
s=re.sub(r'^.*self:AddBin\(.*\n','',s,flags=re.M);save(p,s)

p=ROOT/'DPSMateXEncounters/Views.lua';s=p.read_text(encoding='utf-8-sig')
for a,b,n in reversed(methods(s)):
    if n=='GraphNote':s=s[:a]+s[b:]
start=s.index('local totals={');end=s.index('function C:InstallDetailHooks()',start)
s=s[:start]+s[end:]
start=s.index('            for _,method in ipairs({"UpdateLineGraph"');end=s.index('            local aura=',start)
s=s[:start]+s[end:]
start=s.index('            local aura=');end=s.index('\n        end\n    end\nend',start)
s=s[:start]+s[end:];save(p,s)

# Keep protocol entry points for old peers, but stop outgoing timeline sorting and storage.
# Incoming packets still update the battle duration, used by DPS/HPS calculations.
p=ROOT/'DPSMateX/DPSMateX_Sync.lua';s=p.read_text(encoding='utf-8-sig')
amount={'DMGDone','DMGTaken','ED','Healing','HealingTaken'}
for a,b,n in reversed(methods(s)):
    if n.endswith('StatOut') and n[:-7] in amount:
        header=s[a:s.index('\n',a)]
        s=s[:a]+header+'\n\t-- Amount/time plots are disabled; cumulative ability packets remain.\nend'+s[b:]
    elif n.endswith('StatIn') and n[:-6] in amount:
        body=s[a:b];body=re.sub(r'^.*Arrays\[.*\["i"\]\[.*\] *= *tnbr\(.*\n','',body,flags=re.M)
        s=s[:a]+body+s[b:]
save(p,s)
print('Removed residual graph controls, Insights bins and aggregate graph hooks; disabled amount timeline sync')
