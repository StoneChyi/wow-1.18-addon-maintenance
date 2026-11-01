-- Offline Lua 5.0 mock; maintained by StoneChyi & Codex.

local lib={new=function() return {} end,getHeal=function() return 0 end}
function AceLibrary() return lib end
function UnitClass() return 'Priest','PRIEST' end
units={player={hp=50,max=1000},target={hp=20,max=1000},raid1={hp=300,max=1000},raid2={hp=250,max=1000},raid3={hp=1,max=1000}}
function UnitExists(u) return units[u]~=nil,'guid-'..tostring(u) end
function UnitName(u) return units[u] and u end
function UnitHealth(u) return units[u].hp end
function UnitHealthMax(u) return units[u].max end
function UnitIsUnit(a,b) return a==b end
function GetTime() return 100 end
function GetNumRaidMembers() return 3 end
function GetNumPartyMembers() return 0 end
function PlaySound() end
function GetCVar() cvarReads=cvarReads+1;return 1 end
function SetCVar() cvarWrites=cvarWrites+1 end
function CreateFrame() return {SetScript=function()end} end
function UnitBuff() end
function SpellStopCasting() stops=stops+1 end
function CastSpell() casts=casts+1 end
function UnitIsConnected() return true end
SUPERWOW_VERSION=1
function UnitXP() return 10 end
DEFAULT_CHAT_FRAME={AddMessage=function() notices=notices+1 end}
BOOKTYPE_SPELL='spell';casts=0;stops=0;cvarReads=0;cvarWrites=0;notices=0

