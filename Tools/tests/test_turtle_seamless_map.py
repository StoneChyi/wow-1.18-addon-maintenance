"""Geometry, extracted-resource coverage, actual addon UI and adapter regressions.

Uses the existing local Lua 5.1 interpreter and the strict 1.12 font contract.
These tests do not claim an in-game acceptance test.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
sys.path.insert(0, str(ROOT / 'Tools'))
from lupa.lua51 import LuaRuntime
from build_turtle_seamless_map import decode_blp
from PIL import Image, ImageChops, ImageStat

ADDON = ROOT / 'Interface/AddOns/TurtleSeamlessMap'
STAGE = ROOT / 'PluginHistory/staging/turtle-seamless-map'

MOCK = r'''
objects={};failedTextures={};now=10;mouseX=600;mouseY=400;ctrl=false;shift=false;mapFile='Elwynn'
mapSets=0;nativeUpdates=0;trackerResets=0;questClicks=0;atlasClicks=0;messages={}
UISpecialFrames={};SlashCmdList={};STANDARD_TEXT_FONT='missing-user-font.ttf'
local methods={}
function newObject(kind,name,parent,template)
 local o=setmetatable({kind=kind,name=name,parent=parent,template=template,width=0,height=0,shown=true,scale=1,alpha=1,level=parent and parent.level+1 or 1,scripts={},points={}}, {__index=methods})
 table.insert(objects,o);if name then _G[name]=o end;return o
end
function methods:SetWidth(v) assert(v>0 and v==v);self.width=v end
function methods:SetHeight(v) assert(v>0 and v==v);self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...};table.insert(self.points,self.point);self.pointSets=(self.pointSets or 0)+1 end
function methods:ClearAllPoints() self.point=nil;self.points={} end
function methods:SetAllPoints(p) self.allpoints=p end
function methods:GetParent() return self.parent end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetLeft()
 if self==UIParent then return 0 end
 local p=self.point
 if self.allpoints then return self.allpoints:GetLeft() end
 if not p then return 0 end
 local parent=p[2];local rel=p[3];local x=p[4] or 0
 local left=parent:GetLeft()
 if string.find(rel,'RIGHT') then left=left+parent:GetWidth() elseif not string.find(rel,'LEFT') then left=left+parent:GetWidth()/2 end
 if string.find(p[1],'RIGHT') then left=left-self.width elseif not string.find(p[1],'LEFT') then left=left-self.width/2 end
 return left+x
end
function methods:GetTop()
 if self==UIParent then return self.height end
 if self.allpoints then return self.allpoints:GetTop() end
 local p=self.point;if not p then return self.height end
 local parent=p[2];local rel=p[3];local y=p[5] or 0
 local top=parent:GetTop()
 if string.find(rel,'BOTTOM') then top=top-parent:GetHeight() elseif not string.find(rel,'TOP') then top=top-parent:GetHeight()/2 end
 if string.find(p[1],'BOTTOM') then top=top+self.height elseif not string.find(p[1],'TOP') then top=top+self.height/2 end
 return top+y
end
function methods:SetFrameLevel(n) assert(n>=0);self.level=n end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:EnableMouse(v) self.mouse=v end
function methods:EnableMouseWheel(v) self.wheel=v end
function methods:SetMovable(v) self.movable=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:RegisterForDrag(...) self.dragButtons={...} end
function methods:RegisterForClicks(...) self.clickButtons={...} end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:RegisterEvent(event) self.events=self.events or {};self.events[event]=true end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function invoke(o,event,...)
 local oldThis,oldArg1=this,arg1;this=o;arg1=(...)
 if o.scripts[event] then o.scripts[event](...) end
 this,arg1=oldThis,oldArg1
end
function methods:Show() local was=self.shown;self.shown=true;if not was then invoke(self,'OnShow') end end
function methods:Hide() local was=self.shown;self.shown=false;if was then invoke(self,'OnHide') end end
function methods:SetAlpha(v) assert(v>=0 and v<=1);self.alpha=v end
function methods:CreateTexture(name,layer) local t=newObject('Texture',name,self);t.layer=layer;return t end
function methods:SetTexture(...) local path=(...);self.textureSets=(self.textureSets or 0)+1;if path and failedTextures[path] then self.texture=nil;return nil end;self.texture=path;return 1 end
function methods:SetTexCoord(l,r,t,b) assert(l>=-1e-8 and r<=1+1e-8 and t>=-1e-8 and b<=1+1e-8 and l<r and t<b);self.uv={l,r,t,b} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAutoFocus(v) self.autofocus=v end
function methods:ClearFocus() self.focused=false end
function methods:GetText() return self.text end
function methods:SetOwner(o,anchor) self.owner=o end
function methods:AddLine(text,...) assert(text);self.lastLine=text end
function methods:AddDoubleLine(a,b,...) assert(a and b) end
function CreateFrame(kind,name,parent,template) return newObject(kind,name,parent,template) end
local font=assert(loadstring(FONT_CONTRACT))();font(methods,newObject)
failedFontPaths[STANDARD_TEXT_FONT]=true
UIParent=newObject('Frame','UIParent');UIParent.width=1440;UIParent.height=1000
WorldMapFrame=newObject('Frame','WorldMapFrame',UIParent);WorldMapFrame:Hide()
WorldMapFrame:SetScript('OnShow',function() nativeUpdates=nativeUpdates+1 end)
GameTooltip=newObject('Tooltip','GameTooltip',UIParent);GameTooltip:Hide()
DEFAULT_CHAT_FRAME={AddMessage=function(self,text)table.insert(messages,text)end}
function GetCursorPosition() return mouseX,mouseY end
function GetTime() return now end
function IsControlKeyDown() return ctrl end
function IsShiftKeyDown() return shift end
function IsMouseButtonDown(button) return true end
function GetMapInfo() return mapFile end
function GetRealZoneText() return '艾尔文森林' end
function GetPlayerMapPosition(unit) return .5,.5 end
function SetMapZoom(continent,zone) mapSets=mapSets+1;mapFile=zone==1 and 'Westfall' or 'Elwynn' end
function SetMapToCurrentZone() mapSets=mapSets+1;mapFile=currentFile or 'Elwynn' end
function UpdateMicroButtons() end
function ToggleWorldMap() WorldMapFrame:Show() end
ModernMapMarkersCore={Data={},filters={DUNGEON=true,RAID=true,WORLDBOSS=true,BOAT=true,ZEPPELIN=true,TRAM=true,FACTION='ALL'}}
function ModernMapMarkersCore:BuildData() end
function ModernMapMarkersCore:OnMarkerClick(p) atlasClicks=atlasClicks+1;AtlasFrame:Show() end
ModernMapMarkers_Locale={GetLocalizedZoneName=function(self,name) return name=='Elwynn Forest' and '艾尔文森林' or name end,GetLocalizedMarkerName=function(self,name)return name end}
function ModernMapMarkers_SetFilter(key,value) ModernMapMarkersCore.filters[key]=value end
function ModernMapMarkers_SetFactionFilter(value) ModernMapMarkersCore.filters.FACTION=value end
function ModernMapMarkers_FindMarker(id) SetMapZoom(2,1) end
AtlasFrame=newObject('Frame','AtlasFrame',UIParent);AtlasFrame:Hide()
pfQuest_config={showcluster='1',showspawn='1'};pfQuest={icons={}}
pfMap={nodes={},ShowMapID=function(self,id)ToggleWorldMap()end,
 ShowTooltip=function(self,meta,tip,alias) tip:AddLine(meta.title) end,
 NodeClick=function(self) questClicks=questClicks+1 end,
 UpdateNodes=function() error('A view change must not rebuild pfQuest nodes') end}
'''


def runtime(with_plugins=True, saved=None, screen=None, defaults=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().FONT_CONTRACT = (ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8')
    lua.execute(MOCK)
    if screen:
        lua.execute(f'UIParent.width={screen[0]};UIParent.height={screen[1]}')
    entries=(ADDON/'TurtleSeamlessMap.toc').read_text(encoding='utf-8').splitlines()
    for name in [line.strip() for line in entries if line.strip().endswith('.lua')]:
        lua.execute((ADDON/name).read_text(encoding='utf-8'), name=name)
    if not with_plugins:
        lua.execute('ModernMapMarkersCore=nil;pfMap=nil;pfQuest=nil')
    if saved:
        lua.execute('TurtleSeamlessMapDB='+saved)
    if not defaults:
        # Run the original compatibility regressions in the retained paper /
        # continuous mode. New tests below exercise the new shipped defaults.
        lua.execute('TurtleSeamlessMapDB=TurtleSeamlessMapDB or {};TurtleSeamlessMapDB.detailStyle="paper";TurtleSeamlessMapDB.overviewStyle="continuous"')
    lua.execute('TurtleSeamlessMap:Install();M=TurtleSeamlessMap;G=M.Geometry')
    return lua


class SeamlessMapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lua=runtime()
        cls.report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-地图提取-20261024.json').read_text(encoding='utf-8'))

    def test_all_declared_maps_complete(self):
        self.assertEqual(self.report['map_count'],173)
        self.assertEqual(self.report['complete_maps'],self.report['map_count'])
        self.assertEqual(self.report['missing_listed_files'],[])
        self.assertEqual(self.report['incomplete_maps'],[])
        self.assertEqual(self.lua.eval('#M.maps'),63)
        self.assertEqual(self.report['kinds']['surface'],74)

    def test_extracted_bytes_and_previews(self):
        inventory=json.loads((STAGE/'inventory.json').read_text(encoding='utf-8'))
        self.assertEqual(len(inventory),3551)
        for entry in inventory:
            data=(STAGE/'raw'/entry['path'].replace('\\','/')).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(),entry['sha256'],entry['path'])
        for entry in self.report['maps']:
            im=Image.open(STAGE/'previews'/(entry['file']+'.png'))
            self.assertEqual(im.size,(1002,668))

    def test_dbc_projection_round_trips_and_neighbours(self):
        rng=random.Random(118)
        for _,m in self.lua.globals().M.maps.items():
            if m.rect:
                for _ in range(12):
                    x,y=rng.random(),rng.random()
                    wx,wy=self.lua.globals().G.Project(m.rect,x,y)
                    px,py=self.lua.globals().G.Inverse(m.rect,wx,wy)
                    self.assertAlmostEqual(px,x,places=10)
                    self.assertAlmostEqual(py,y,places=10)
        # A shared game-world coordinate must meet exactly across zone images.
        self.lua.execute('''
          local e,w=M.byID[30],M.byID[39]
          local a,b=G.Inverse(e.rect,42000,10000)
          local c,d=G.Inverse(w.rect,42000,10000)
          local x1,y1=G.Project(e.rect,a,b);local x2,y2=G.Project(w.rect,c,d)
          assert(math.abs(x1-x2)<1e-8 and math.abs(y1-y2)<1e-8)
        ''')

    def test_cursor_pivot_zoom_and_limits(self):
        lua=runtime()
        lua.execute('''
          M:FocusMap(30);local beforeX,beforeY=G.World(M.view,1152,678,234,456)
          for i=1,250 do
            G.Zoom(M.view,1152,678,234,456,1.18,.001,3)
            local x,y=G.World(M.view,1152,678,234,456)
            assert(math.abs(x-beforeX)<1e-7 and math.abs(y-beforeY)<1e-7)
          end
          assert(M.view.scale==3)
          for i=1,500 do G.Zoom(M.view,1152,678,234,456,1/1.18,.001,3) end
          assert(M.view.scale==.001)
        ''')

    def test_texture_culling_clipping_and_scene_coverage(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:FocusMap(30);M:Render();assert(M.tileUsed>0)
          for i=1,M.tileUsed do
            local t=M.tiles[i];assert(t.point[4]>=0 and -t.point[5]>=0)
            assert(t.point[4]+t.width<=M.canvas.width+.001)
            assert(-t.point[5]+t.height<=M.canvas.height+.001)
          end
          M.Cursor=function() return -10,-10 end
          for _,map in ipairs(M.maps) do
            M:FocusMap(map.id,true);M:Render();assert(M.tileUsed>0,map.file)
            assert(M.scene==nil)
            assert(not next(M.providerErrors))
          end
          M.view.x=1e9;M.view.y=1e9;M:Render();assert(M.tileUsed==0)
        ''')

    def test_font_fallback_and_ui_paths(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:ToggleMarkerMenu();M:UpdateMarkerMenu();M:UpdateList()
          M.search:SetText('海加尔');M:UpdateList();assert(#M.listMaps>0)
          M.search:SetText('not-a-region');M:UpdateList();assert(#M.listMaps==0)
          M.frame:Hide();M.frame:Show();M:Render()
          for _,obj in ipairs(objects) do
            if obj.kind=='FontString' and obj.text then assert(obj.font) end
          end
          local bad=M.frame:CreateFontString(nil,'OVERLAY')
          assert(not pcall(function() bad:SetText('') end))
        ''')

    def test_pan_zoom_never_changes_global_map(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:FocusMap(30);local count=mapSets
          for i=1,200 do
            M:Zoom(i%2==0 and 1.18 or 1/1.18)
            M.view.x=M.view.x+i;M:Render()
          end
          assert(count==mapSets)
          assert(trackerResets==0)
        ''')

    def test_modern_markers_filters_and_atlas(self):
        lua=runtime()
        lua.execute('''
          ModernMapMarkersCore.Data={{id=1,zoneName='Elwynn Forest',x=.5,y=.5,name='Test dungeon',type='DUNGEON',atlasID='Test'},
            {id=2,zoneName='Elwynn Forest',x=.6,y=.5,name='Horde boat',type='BOAT',description='Horde'}}
          M.frame:Show();M:FocusMap(30);M:Render();assert(not next(M.providerErrors))
          local pin;for i=1,M.pinUsed do if M.pins[i].key=='mmm1' then pin=M.pins[i] end end
          assert(pin);invoke(pin,'OnEnter');invoke(pin,'OnClick','LeftButton');assert(atlasClicks==1 and not M.frame:IsShown())
          ModernMapMarkersCore.filters.DUNGEON=false;ModernMapMarkersCore.filters.FACTION='Alliance'
          M.frame:Show();M:Render()
          for i=1,M.pinUsed do assert(M.pins[i].key~='mmm1' and M.pins[i].key~='mmm2') end
          M:FocusMap(30,true);M:Render()
        ''')

    def test_pfquest_nodes_actions_and_table_integrity(self):
        lua=runtime()
        lua.execute('''
          local node={Quest={title='Quest',zone=12,x=50,y=50,spawn='Wolf',spawnid=1,texture='Interface\\\\Icons\\\\INV_Misc_QuestionMark',addon='PFQUEST'}}
          pfMap.nodes={PFQUEST={[12]={['50|50']=node}}}
          local original=pfMap.nodes
          M.frame:Show();M:FocusMap(30);M:Render();assert(not next(M.providerErrors))
          local pin;for i=1,M.pinUsed do if string.find(M.pins[i].key,'pf:',1,true) then pin=M.pins[i] end end
          assert(pin);invoke(pin,'OnEnter');invoke(pin,'OnClick','LeftButton')
          assert(questClicks==1 and pfMap.nodes==original and node.Quest.spawn=='Wolf')
          M.settings.quests=false;M:Render()
          for i=1,M.pinUsed do assert(not string.find(M.pins[i].key,'pf:',1,true)) end
        ''')

    def test_default_toggle_native_fallback_and_saved_view(self):
        lua=runtime()
        lua.execute('''
          ToggleWorldMap();assert(M.frame:IsShown() and not WorldMapFrame:IsShown())
          ToggleWorldMap();assert(not M.frame:IsShown())
          WorldMapFrame:Show();assert(M.frame:IsShown() and not WorldMapFrame:IsShown())
          M:ShowNative();assert(WorldMapFrame:IsShown() and not M.frame:IsShown() and nativeUpdates==1)
          ToggleWorldMap();assert(not WorldMapFrame:IsShown())
          M.frame:Show();M:FocusMap(30);M.frame:Hide();assert(TurtleSeamlessMapDB.view.selected==30)
          local calls=mapSets;pfMap:ShowMapID(40);assert(M.selected==39 and M.frame:IsShown() and mapSets==calls)
        ''')

    def test_all_runtime_art_present_valid_and_bounded(self):
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json').read_text(encoding='utf-8'))
        terrain=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.4.0地形资源-20261024.json').read_text(encoding='utf-8'))
        classic=[r for r in terrain['files'] if r['file'].startswith('v5_classic_')]
        refined=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.6.0*.json')).read_text(encoding='utf8'))
        previous=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.5.0*.json')).read_text(encoding='utf8'))
        ocean=[r for r in previous['files'] if r['file'].startswith('v6_sea_')]
        report['files']+=classic+ocean+refined['files'];report['total_files']+=len(classic)+len(ocean)+refined['total_files']
        expected={r['file'] for r in report['files']}
        for _,m in self.lua.globals().M.maps.items():
            if m.rect:
                for _,tile in m.tiles.items():
                    self.assertIn(tile[1]+'.blp',expected)
        actual={p.name for p in (ADDON/'Art').glob('*.blp')}
        self.assertEqual(expected,actual)
        self.assertEqual(len(actual),report['total_files'])
        for entry in report['files']:
            self.assertEqual(hashlib.sha256((ADDON/'Art'/entry['file']).read_bytes()).hexdigest(),entry['sha256'])
        for name in actual:
            im=decode_blp((ADDON/'Art'/name).read_bytes())
            self.assertEqual(im.size,(256,256))

    def test_independent_without_other_map_addons(self):
        lua=runtime(False)
        lua.execute('''
          M.frame:Show();M:WorldView();M:Render();M:ToggleMarkerMenu();M:UpdateList()
          assert(not next(M.providerErrors) and M.tileUsed>0)
          M:FocusMap(30);M:Zoom(1.18);M:Render()
        ''')

    def test_real_modernmap_data_zone_resolution(self):
        lua=runtime()
        lua.execute('function GetLocale() return "zhCN" end')
        for name in ['Localization.lua','Locales/Locale_zhCN.lua','MarkerData.lua']:
            lua.execute((ROOT/'Interface/AddOns/ModernMapMarkers'/name).read_text(encoding='utf-8-sig'))
        lua.execute('ModernMapMarkers_Locale:Initialize()')
        lua.execute('''
          local count=0
          for continent,zones in pairs(ModernMapMarkers_Points) do
            for zone,points in pairs(zones) do
              local localized=ModernMapMarkers_Locale:GetLocalizedZoneName(zone)
              assert(M.byName[localized] or M.byName[zone],zone..' / '..localized)
              count=count+#points
            end
          end
          assert(count>60)
        ''')

    def test_real_pfquest_click_route_metadata(self):
        lua=runtime()
        code=(ROOT/'Interface/AddOns/pfQuest/map.lua').read_text(encoding='utf-8-sig')
        function='function pfMap:NodeClick()'+code.split('function pfMap:NodeClick()',1)[1].split('function pfMap:NodeEnter()',1)[0]
        lua.execute(function)
        lua.execute('''
          pfQuest_config.routestarter='1'
          pfQuest.route={IsTarget=function()return false end,SetTarget=function(pin) selectedQuestTitle=pin.title end}
          pfMap.nodes={PFQUEST={[12]={['50|50']={Quest={title='Quest',zone=12,x=50,y=50,spawn='Wolf',texture='test',layer=1}}}}}
          M.frame:Show();M:FocusMap(30);M:Render()
          for i=1,M.pinUsed do
            if string.find(M.pins[i].key,'pf:',1,true) then invoke(M.pins[i],'OnClick','LeftButton') end
          end
          assert(selectedQuestTitle=='Quest' and pfMap.queue_update==now)
        ''')

    def test_outdoor_scope_and_one_world_canvas(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:UpdateList();assert(#M.listMaps==60)
          local count,city=0,0
          for _,map in ipairs(M.maps) do
            assert(map.kind=='world' or map.kind=='continent' or map.kind=='surface')
            if map.kind=='surface' then count=count+1;if map.city then city=city+1 end end
          end
          assert(count==60 and city==7)
          for _,id in ipairs({500,514,516,517,518,519,520,521,522,523,689,700,701,705}) do
            assert(not M.byID[id]);local selected=M.selected;M:FocusMap(id);assert(M.selected==selected)
          end
          M:WorldView();M:Render()
          local seen={}
          for i=1,M.tileUsed do seen[M.tiles[i].path]=true end
          local paper=false;local land=false
          for path in pairs(seen) do
            if string.find(path,'v4_paper',1,true) then paper=true end
            if string.find(path,'v4_c',1,true) then land=true end
          end
          assert(paper and land)
          local dx,dy=M:MapToWorld(4,.5,.5);local ex,ey=M:MapToWorld(30,.5,.5)
          assert(dx<ex and dx>0 and ex<1002 and dy>0 and ey<668)
          M:FocusMap(13);local canvas=M.canvas;M:FocusMap(14)
          assert(M.canvas==canvas and M.scene==nil)
        ''')

    def test_hidden_zone_nodes_are_never_enumerated(self):
        lua=runtime()
        lua.execute('''
          local hidden={['50|50']={Quest={title='Quest',texture='test'}}}
          local offscreen={['50|50']={Quest={title='Other',texture='test'}}}
          local originalPairs=pairs
          local forbidden=true
          pairs=function(t)
            assert(t~=offscreen and (t~=hidden or not forbidden),'Hidden nodes were enumerated')
            return originalPairs(t)
          end
          pfMap.nodes={PFQUEST={[12]=hidden,[14]=offscreen}}
          ModernMapMarkersCore.Data={{id=1,zoneName='Elwynn Forest',x=.5,y=.5,name='Dungeon',type='DUNGEON'}}
          M.frame:Show();M:WorldView();M:Render()
          assert(not next(M.providerErrors) and M.questNodesVisited==0 and not next(M.detailAreas))
          for i=1,M.pinUsed do assert(M.pins[i].key=='player' or string.find(M.pins[i].key,'note',1,true)) end
          M:FocusMap(30);forbidden=false;M:Render()
          assert(not next(M.providerErrors) and M.questNodesVisited==1 and M.detailAreas[12])
          M:WorldView();forbidden=true;M:Render()
          assert(not next(M.providerErrors) and M.questNodesVisited==0)
          pairs=originalPairs
        ''')

    def test_all_city_layers_require_zoom_and_focus(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show()
          for _,map in ipairs(M.maps) do
            if map.city then
              M:FocusMap(map.parent);M:Render()
              assert(map.alpha==0 and not M.detailAreas[map.area],map.file..' visible at parent zoom')
              M:FocusMap(map.id);M:Render()
              assert(map.cityActive and map.alpha>.95 and M.detailAreas[map.area],map.file)
              -- Keep zoom but move away from the city: no detached city layer.
              M.view.x=map.rect[1]+map.rect[3]*2;M:Render()
              assert(not map.cityActive and map.alpha==0 and not M.detailAreas[map.area])
            end
          end
          M:FocusMap(301);M:Render();local c=M.byID[301]
          M.view.scale=.68*M.canvas:GetWidth()/c.rect[3];M:Render();assert(c.cityActive)
          M.view.scale=.57*M.canvas:GetWidth()/c.rect[3];M:Render();assert(not c.cityActive)
          M.view.scale=.68*M.canvas:GetWidth()/c.rect[3];M:Render();assert(not c.cityActive)
          -- A user can zoom at a city near the canvas edge without first
          -- centering the camera. The visible cursor anchor also counts.
          M.view.scale=.8*M.canvas:GetWidth()/c.rect[3]
          M.Cursor=function() return M.canvas.width/2,M.canvas.height/2 end
          M.view.x=c.rect[1]+c.rect[3]*1.1;M:Render();assert(not c.cityActive)
          local x,y=G.Screen(M.view,M.canvas.width,M.canvas.height,c.rect[1]+c.rect[3]/2,c.rect[2]+c.rect[4]/2)
          M.Cursor=function() return x,y end
          M:Zoom(1.01);M:Render();assert(c.cityActive)
          invoke(M.canvas,'OnMouseDown','LeftButton');assert(M.zoomFocus==nil)
        ''')

    def test_world_fills_canvas_and_camera_stays_inside(self):
        for screen in [(1440,1000),(1024,768),(2560,1440),(800,600)]:
            lua=runtime(screen=screen)
            lua.execute('''
              M.frame:Show();M:WorldView();M:Render()
              assert(M.frame.width<=UIParent.width-50+.001 and M.frame.height<=UIParent.height-60+.001)
              local w,h=M.canvas.width,M.canvas.height
              assert(math.abs(w/h-1.5)<1e-9 and M:IsWorldView())
              local x,y=G.Screen(M.view,w,h,0,0);local r,b=G.Screen(M.view,w,h,1002,668)
              assert(math.abs(x)<1e-7 and math.abs(y)<1e-7 and math.abs(r-w)<1e-7 and math.abs(b-h)<1e-7)
              invoke(M.canvas,'OnMouseDown','LeftButton');assert(not M.drag)
              for i=1,12 do M:Zoom(.5) end
              assert(M.view.x==501 and M.view.y==334 and M.view.scale==M:WorldScale())
              assert(not next(M.detailAreas))
              M:Zoom(3);invoke(M.canvas,'OnMouseDown','LeftButton');assert(M.drag)
              M.view.x=-1e6;M.view.y=1e6;M:ConstrainView()
              local left,top=G.World(M.view,w,h,0,0);local right,bottom=G.World(M.view,w,h,w,h)
              assert(left>=-1e-7 and top>=-1e-7 and right<=1002+1e-7 and bottom<=668+1e-7)
              M:Zoom(.001);assert(not M.drag and M:IsWorldView())
              local renders=M.artRenders;M:Zoom(.5);assert(M.artRenders==renders)
            ''')

    def test_m_opens_current_location_every_time(self):
        lua=runtime()
        lua.execute('''
          M:WorldView();mapFile='Westfall';local before=mapSets
          ToggleWorldMap();assert(M.selected==30 and mapSets==before+1)
          local x,y=M:MapToWorld(30,.5,.5)
          assert(math.abs(M.view.x-x)<1e-8 and math.abs(M.view.y-y)<1e-8)
          M:FocusMap(4);ToggleWorldMap();ToggleWorldMap();assert(M.selected==30)
          ToggleWorldMap();currentFile='Durotar'
          GetRealZoneText=function() return '杜隆塔尔' end
          GetPlayerMapPosition=function() return .25,.75 end
          ToggleWorldMap();assert(M.selected==4)
          x,y=M:MapToWorld(4,.25,.75)
          assert(math.abs(M.view.x-x)<1e-8 and math.abs(M.view.y-y)<1e-8)
          ToggleWorldMap();currentFile='NoOutdoorPosition';GetRealZoneText=function() return 'UnknownDungeon' end
          ToggleWorldMap();assert(M:IsWorldView())
          ToggleWorldMap();SlashCmdList.TURTLESEAMLESSMAP('world');assert(M:IsWorldView())
          ToggleWorldMap();currentFile='Elwynn';GetRealZoneText=function() return '艾尔文森林' end
          GetPlayerMapPosition=function() return 0,0 end
          ToggleWorldMap();assert(M.selected==30)
          for i=1,M.pinUsed do assert(M.pins[i].key~='player') end
        ''')

    def test_map_frames_have_stable_depth_and_asset_ownership(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show()
          for _,id in ipairs({30,301,39,4,13,14,301,30}) do M:FocusMap(id);M:Render() end
          local last=0
          for _,map in ipairs(M.drawOrder) do
            assert(map.drawLevel>last);last=map.drawLevel
            if map.artFrame then
              assert(map.artFrame.level==map.drawLevel and map.artFrame.level<M.pinLayer.level)
              for path,texture in pairs(map.texturePool) do
                assert(texture.parent==map.artFrame and texture.path==path and texture.textureSets==1)
                assert(texture.layer=='ARTWORK')
                assert(texture.paintPass==M.paintPass or not texture:IsShown())
              end
              if map.atlas then
                assert(#map.atlasPool<=256)
                for _,texture in ipairs(map.atlasPool) do
                  assert(texture.parent==map.artFrame and texture.layer=='ARTWORK')
                  assert(texture.paintPass==M.paintPass or not texture:IsShown())
                end
              end
            end
          end
          local frames=#objects
          for i=1,50 do M:RenderArt() end
          assert(#objects==frames)
          for _,map in ipairs(M.maps) do
            if not map.atlas then for _,texture in ipairs(map.textures or {}) do assert(texture.textureSets==1) end end
          end
        ''')

    def test_zoom_updates_art_immediately_without_scanning_nodes(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:FocusMap(30);M:Render()
          local calls=0
          M:RegisterProvider('slowNodes',function() calls=calls+1 end)
          local art=M.artRenders;local before=mapSets
          for i=1,40 do
            invoke(M.canvas,'OnMouseWheel',i%2==0 and 1 or -1)
            assert(M.paintedView.scale==M.view.scale and M.artRenders==art+i)
            invoke(M.frame,'OnUpdate')
          end
          assert(calls==0 and mapSets==before)
          now=now+.09;invoke(M.frame,'OnUpdate');assert(calls==1)
          art=M.artRenders
          for i=1,10 do now=now+.36;invoke(M.frame,'OnUpdate') end
          assert(calls==11 and M.artRenders==art)
          M:WorldView()
          for i=1,M.pinUsed do
            local p=M.pins[i];if p.mapID then assert(not p:IsShown()) end
          end
        ''')

    def test_only_cursor_zone_visits_nodes_while_atlas_stays_continuous(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:FocusMap(30)
          local focusX,focusY
          M.Cursor=function() return focusX,focusY end
          local function point(map,u,v)
            local x,y=M:MapToWorld(map,u,v)
            focusX,focusY=G.Screen(M.view,M.canvas.width,M.canvas.height,x,y)
          end
          -- Wide view contains both Elwynn and Westfall; artwork stays complete
          -- but only the pointed region may enumerate its nodes.
          M.view.scale=6.5;M.view.x=700;M.view.y=435
          local nodesA={['50|50']={A={title='A',texture='test'}}}
          local nodesB={['50|50']={B={title='B',texture='test'}}}
          pfMap.nodes={PFQUEST={[12]=nodesA,[40]=nodesB}}
          local origPairs=pairs;local forbidden=nodesB
          pairs=function(t) assert(t~=forbidden,'nonfocused zone enumerated');return origPairs(t) end
          point(30,.5,.5);M:Render();assert(M.detailTarget.id==30 and M.detailAreas[12] and M.questNodesVisited==1 and not next(M.providerErrors))
          local backdrop={}
          for _,map in ipairs(M.maps) do
            if map.kind~='surface' then for _,texture in ipairs(map.textures or {}) do backdrop[texture]=texture.pointSets end end
          end
          for _,map in ipairs(M.maps) do if map.kind=='surface' and map.id~=30 then assert(map.alpha==0) end end
          forbidden=nodesA;point(39,.5,.5);M:Render()
          assert(M.detailTarget.id==39 and M.detailAreas[40] and M.questNodesVisited==1 and not next(M.providerErrors))
          for texture,count in pairs(backdrop) do assert(texture.pointSets==count) end
          for _,map in ipairs(M.maps) do if map.kind=='surface' and map.id~=39 then assert(map.alpha==0) end end
          -- Pointer crossing alone updates art next frame; no zoom is needed.
          forbidden=nil;point(30,.5,.5);invoke(M.frame,'OnUpdate')
          assert(M.paintedView.focus==30 and M.byID[39].alpha==0)
          local cached=M.artRenders;focusX=focusX+1;invoke(M.frame,'OnUpdate');assert(M.artRenders==cached)
          local map=M.byID[30];local x,y=G.Project(map.rect,.001,.001)
          assert(not G.Hit(map,x,y))
          pairs=origPairs
        ''')

    def test_all_sixty_regions_have_selectable_painted_territory(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();local px,py=0,0;M.Cursor=function() return px,py end
          local total=0
          for _,map in ipairs(M.maps) do
            if map.kind=='surface' then
              local mask=TurtleSeamlessMap_Focus[map.id]
              assert(mask and #mask[3]==mask[1]*mask[2]/4)
              M:FocusMap(map.id);local found=false
              for row=1,31 do
                for col=1,47 do
                  if not found then
                    local x,y=G.Project(map.rect,col/48,row/32)
                    local sx,sy=G.Screen(M.view,M.canvas.width,M.canvas.height,x,y)
                    if sx>=0 and sx<M.canvas.width and sy>=0 and sy<M.canvas.height then
                      px,py=sx,sy;if M:ChooseDetailMap()==map then found=true end
                    end
                  end
                end
              end
              assert(found,map.file..' has no selectable territory');total=total+1
            end
          end
          assert(total==60)
        ''')

    def test_composite_ignores_same_layer_texture_order(self):
        lua=runtime()
        lua.execute('M:FocusMap(301);M.frame:Show();M:FocusMap(30);M:Render()')
        normal=compose_preview(lua)
        reversed_order=compose_preview(lua,reverse=True)
        self.assertEqual(normal.tobytes(),reversed_order.tobytes())

    def test_native_first_open_rejects_stale_tanaris_and_retries_bounded(self):
        lua=runtime(saved='{layoutVersion=2,notes={},view={x=300,y=530,scale=5,selected=161}}')
        lua.execute('''
          local ready=false;local reads=0
          SetMapToCurrentZone=function() mapSets=mapSets+1;mapFile=ready and 'Elwynn' or 'Tanaris' end
          GetPlayerMapPosition=function() reads=reads+1;return .33,.66 end
          mapFile='Tanaris';WorldMapFrame:Show()
          assert(M.frame:IsShown() and M.selected==30 and M.pendingLocation)
          assert(reads==0,'Coordinates from a stale selected page must not be used')
          local x,y=M:MapToWorld(30,.5,.5)
          assert(math.abs(M.view.x-x)<1e-7 and math.abs(M.view.y-y)<1e-7)
          ready=true;now=now+.11;invoke(M.frame,'OnUpdate')
          x,y=M:MapToWorld(30,.33,.66)
          assert(M.selected==30 and not M.pendingLocation and mapSets==2)
          assert(math.abs(M.view.x-x)<1e-7 and math.abs(M.view.y-y)<1e-7)
          local calls=mapSets;for i=1,20 do now=now+.1;invoke(M.frame,'OnUpdate') end
          assert(mapSets==calls)
          M.frame:Hide();ready=false;M:Toggle();assert(M.pendingLocation)
          now=now+.11;invoke(M.frame,'OnUpdate');assert(M.pendingLocation)
          for i=1,10 do now=now+.3;invoke(M.frame,'OnUpdate') end
          assert(not M.pendingLocation)
          calls=mapSets;now=now+1;invoke(M.frame,'OnUpdate');assert(mapSets==calls)
          M.frame:Hide();M:Toggle();assert(M.pendingLocation)
          M:Zoom(1.1);assert(not M.pendingLocation)
          calls=mapSets;now=now+1;invoke(M.frame,'OnUpdate');assert(mapSets==calls)
          M.ignoreMapEvent=true;mapFile='Tanaris';WorldMapFrame:Show();M.ignoreMapEvent=false
          assert(M.selected==161,'Explicit third-party navigation must keep its destination')
        ''')

    def test_city_cutouts_preserve_coordinates_and_remove_page_corners(self):
        lua=runtime()
        lua.execute('''
          for _,map in ipairs(M.maps) do
            if map.city then
              assert(#map.tiles==12 and map.artWidth==1002 and map.artHeight==668)
              local x,y=M:MapToWorld(map.id,0,0)
              local ax,ay=G.Project(map.artRect,0,0)
              assert(math.abs(ax-x)<1e-7 and math.abs(ay-y)<1e-7)
              x,y=M:MapToWorld(map.id,1,1)
              ax,ay=G.Project(map.artRect,1,1)
              assert(math.abs(ax-x)<1e-7 and math.abs(ay-y)<1e-7)
            end
          end
          local map=M.byID[301]
          local x,y=M:MapToWorld(301,.15,.35);assert(G.Hit(map,x,y),'Port label remains part of the city')
          x,y=M:MapToWorld(301,.94,.90);assert(not G.Hit(map,x,y),'Corner compass is not city territory')
          x,y=M:MapToWorld(301,.50,.075);assert(not G.Hit(map,x,y),'Title ribbon is not city territory')
        ''')
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json').read_text(encoding='utf-8'))
        self.assertEqual(sum(r['file'].startswith('v4_city') for r in report['files']),84)

    def test_ocean_retains_original_world_composition_across_zoom(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M.view.x=501;M.view.y=334;M.view.scale=8;M:Render()
          assert(not M.canvas.backdrop)
          assert(M.byID[694].atlas and M.byID[694].atlasLevel==2)
          for i=1,M.tileUsed do assert(not string.find(M.tiles[i].path,'SeaPaper',1,true)) end
        ''')
        first=compose_preview(lua)
        lua.execute('M.view.scale=32;M:Render()')
        closer=compose_preview(lua)
        # The whirlpool is geographically anchored original art, not a
        # screen-fixed repeating texture: it must change apparent size on zoom.
        self.assertNotEqual(first.tobytes(),closer.tobytes())
        extrema=first.convert('RGB').getextrema()
        self.assertGreater(max(high-low for low,high in extrema),10)

    def test_old_notes_views_and_unmapped_records_migrate_once(self):
        lua=runtime(saved='''{notes={{x=42000,y=10000},{x=501,y=334,scene=301},
          {x=501,y=334,scene=514},{x=1e8,y=1e8}},view={x=42000,y=10000,scale=.2,selected=30}}''')
        lua.execute('''
          local s=M.settings
          assert(s.layoutVersion==2 and #s.notes==2 and #s.unplacedNotes==2 and #s.layoutV1Backup.notes==4)
          local t=TurtleSeamlessMap_Layout[0]
          assert(math.abs(s.notes[1].x-t.x)<1e-6 and math.abs(s.notes[1].y-(t.y+10000*t.scale))<1e-6)
          local x,y=M:MapToWorld(301,.5,.5)
          assert(math.abs(s.notes[2].x-x)<1e-6 and math.abs(s.notes[2].y-y)<1e-6)
          assert(math.abs(M.view.scale-.2/t.scale)<1e-5 and #messages==1)
          local notes=s.notes;M:MigrateSettings();assert(s.notes==notes and #s.unplacedNotes==2 and #messages==1)
          M.frame:Show();M:Render();M.frame:Hide();assert(not s.view.scene)
        ''')
        lua=runtime(saved='''{layoutVersion=2,notes={{x=750,y=440}},view={x=700,y=450,scale=12,selected=30}}''')
        lua.execute('assert(M.view.x==700 and M.view.scale==12 and M.settings.notes[1].x==750 and not M.settings.layoutV1Backup)')

    def test_atlas_viewport_pools_are_bounded_and_release_inactive_assets(self):
        lua=runtime(screen=(3840,2160))
        lua.execute('''
          M.frame:Show();M.Cursor=function() return -1,-1 end
          for _,scale in ipairs({2,4,8,16,32,64,3,7,12}) do
            for _,id in ipairs({30,39,201,261,161,40,502,4,699,507}) do
              local r=M.byID[id].rect
              M.view.x=r[1]+r[3]/2;M.view.y=r[2]+r[4]/2;M.view.scale=scale
              M:RenderArt()
              for _,map in ipairs(M.maps) do
                if map.atlasPool then
                  assert(#map.atlasPool<=256 and map.atlasVisits<=256)
                  for _,t in ipairs(map.atlasPool) do
                    if t.active then assert(t.path and t.texture==t.path)
                    else assert(not t.texture and not t.path) end
                  end
                end
              end
            end
          end
        ''')

    def test_atlas_failed_texture_uses_complete_lower_resolution(self):
        lua=runtime()
        lua.execute('''
          local atlas=M.byID[14];local level=atlas.atlas.levels[5]
          for key in pairs(level.tiles) do
            local row=math.floor((key-1)/level.cols);local col=math.mod(key-1,level.cols)
            failedTextures['Interface\\\\AddOns\\\\TurtleSeamlessMap\\\\Art\\\\v4_c0_16_'..col..'_'..row]=true
          end
          M.frame:Show();M:FocusMap(30);M.view.scale=12
          M.paintedView=nil;M:RenderArt()
          assert(atlas.atlasLevel==8 and M.tileUsed>0)
          for _,t in ipairs(atlas.atlasPool) do
            if t.active then assert(string.find(t.path,'v4_c0_8_',1,true)) end
          end
          failedTextures={};M.paintedView=nil;M:RenderArt();assert(atlas.atlasLevel==16)
        ''')

    def test_atlas_preserves_all_region_centres_and_native_coordinates(self):
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json').read_text(encoding='utf-8'))
        self.assertEqual(len(report['regions']),53)
        self.assertEqual(report['density_levels'],[1,2,4,8,16])
        continents={c['id']:c for c in report['continents']}
        for r in report['regions']:
            m=self.lua.globals().M.byID[r['id']]
            # Historical Lua data uses 10 significant digits; offline DBC JSON
            # retains full doubles. This bound is < .000016 atlas pixels.
            for i,value in enumerate(r['rect'],1):self.assertAlmostEqual(m.rect[i],value,delta=1e-6)
            c=continents[m.map];x=r['rect'][0]+r['rect'][2]/2;y=r['rect'][1]+r['rect'][3]/2
            for density in (2,8,16):
                px=(x-c['rect'][0])*density;py=(y-c['rect'][1])*density
                col,row=int(px//254),int(py//254)
                path=ADDON/'Art'/f'v4_c{m.map}_{density}_{col}_{row}.blp'
                self.assertTrue(path.is_file(),r['file'])
                im=decode_blp(path.read_bytes()).convert('RGBA')
                self.assertGreater(im.getpixel((int(px%254)+1,int(py%254)+1))[3],200,r['file'])
        audit=report['minimap_audit']
        self.assertEqual(sum(c['decoded'] for c in audit.values()),1755)
        self.assertTrue(all(not c['failures'] for c in audit.values()))

    def test_atlas_gutters_match_neighbours(self):
        for prefix in ('v4_c1_16','v7_t1_32','v7_city301_64','v7_city341_96'):
            paths=sorted((ADDON/'Art').glob(prefix+'_*.blp'));count=0
            for path in paths:
                col,row=map(int,path.stem.split('_')[-2:])
                for dc,dr in ((1,0),(0,1)):
                    other=path.with_name(f'{prefix}_{col+dc}_{row+dr}.blp')
                    if not other.is_file():continue
                    a=(255,0,256,256) if dc else (0,255,256,256)
                    b=(1,0,2,256) if dc else (0,1,256,2)
                    left=decode_blp(path.read_bytes()).convert('RGBA').crop(a)
                    right=decode_blp(other.read_bytes()).convert('RGBA').crop(b)
                    self.assertEqual(ImageChops.difference(left.getchannel('A'),right.getchannel('A')).getextrema()[1],0,prefix)
                    self.assertLess(max(ImageStat.Stat(ImageChops.difference(left.convert('RGB'),right.convert('RGB'))).mean),18,prefix)
                    count+=1
                    if count>=30:break
                if count>=30:break
            self.assertEqual(count,30,prefix)

    def test_same_source_lod_keeps_land_silhouette(self):
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json').read_text(encoding='utf-8'))
        for c in report['continents']:
            def reconstruct(density):
                size=(c['rect'][2]*density,c['rect'][3]*density)
                image=Image.new('RGBA',size)
                for path in (ADDON/'Art').glob(f'v4_c{c["id"]}_{density}_*.blp'):
                    col,row=map(int,path.stem.split('_')[-2:])
                    image.paste(decode_blp(path.read_bytes()).convert('RGBA').crop((1,1,255,255)),(col*254,row*254))
                return image
            high=reconstruct(8).getchannel('A').resize((c['rect'][2],c['rect'][3]),Image.Resampling.LANCZOS)
            low=reconstruct(1).getchannel('A')
            self.assertLess(ImageStat.Stat(ImageChops.difference(high,low)).mean[0],3)

    def test_new_defaults_classic_overview_and_terrain_detail(self):
        lua=runtime(defaults=True)
        lua.execute('''
          assert(M.settings.detailStyle=='terrain' and M.settings.overviewStyle=='classic')
          M.frame:Show();M:WorldView();M:Render()
          for i=1,M.tileUsed do assert(string.find(M.tiles[i].path,'v5_classic_',1,true)) end
          assert(not next(M.detailAreas))
          M:FocusMap(11);M:Render()
          local terrain=false
          for i=1,M.tileUsed do if string.find(M.tiles[i].path,'v7_t1_',1,true) then terrain=true end end
          assert(terrain)
          M:UpdateStyleMenu();M.styleMenu:Show()
          invoke(M.styleButtons[1],'OnClick');assert(M.settings.detailStyle=='paper')
          invoke(M.styleButtons[2],'OnClick');assert(M.settings.overviewStyle=='continuous')
          invoke(M.styleButtons[3],'OnClick');assert(not M.settings.cityMaps)
          M.frame:Hide();assert(not M.styleMenu:IsShown())
        ''')

    def test_empty_current_zone_never_accepts_stale_tanaris(self):
        for real in ('nil','""'):
            lua=runtime(defaults=True,saved='{layoutVersion=2,notes={},view={x=300,y=500,scale=10,selected=161}}')
            lua.execute('''
              local reads=0
              GetRealZoneText=function() return '''+real+''' end
              SetMapToCurrentZone=function() mapSets=mapSets+1 end
              mapFile='Tanaris';GetPlayerMapPosition=function() reads=reads+1;return .33,.66 end
              WorldMapFrame:Show()
              assert(M:IsWorldView() and M.selected==nil and M.pendingLocation and reads==0)
              GetRealZoneText=function() return '艾尔文森林' end
              SetMapToCurrentZone=function() mapSets=mapSets+1;mapFile='Elwynn' end
              now=now+.11;invoke(M.frame,'OnUpdate')
              assert(M.selected==30 and not M.pendingLocation and reads>0)
              GetRealZoneText=function() return nil end
              M.frame:Hide();M:Toggle();assert(M.pendingLocation)
              for i=1,20 do now=now+.3;invoke(M.frame,'OnUpdate') end
              assert(not M.pendingLocation and M.selected==nil)
            ''')

    def test_background_map_selection_does_not_navigate(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();M:FocusMap(30);local x,y=M.view.x,M.view.y
          SetMapZoom(2,1)
          assert(M.selected==30 and M.view.x==x and M.view.y==y)
          pfMap:ShowMapID(40);assert(M.selected==39)
          M.ignoreMapEvent=true;pfMap:ShowMapID(12);assert(M.ignoreMapEvent==true)
          M.ignoreMapEvent=false
        ''')

    def test_scoped_navigation_restores_state_after_error(self):
        # The wrapped original can fail after a nested call. Its caller's
        # guard must be restored even when the error escapes to that caller.
        lua=runtime(defaults=True)
        lua.execute('''
          local original=pfMap.ShowMapID
          M.ignoreMapEvent=true;original(pfMap,12);assert(M.ignoreMapEvent)
          M.ignoreMapEvent=false
          mapSets=nil
          local ok=pcall(ModernMapMarkers_FindMarker,1)
          assert(not ok and not M.ignoreMapEvent)
          mapSets=0
          SetMapToCurrentZone=function() error('temporary map API failure') end
          M:FindPlayer();assert(not M.ignoreMapEvent and not M.locating and M.pendingLocation and M.locationError)
          M:Zoom(1.1);assert(not M.pendingLocation)
        ''')

    def test_terrain_area_lookup_agrees_with_adt_at_problem_regions(self):
        from build_turtle_map_terrain import parse_adt
        from turtle_map_archive import Client,dbc
        client=Client(ROOT,include_terrain=True)
        rows,_,_=dbc(client.read('DBFilesClient\\AreaTable.dbc')[0]);parents={r[0]:r[2] for r in rows}
        lua=runtime(defaults=True);m=lua.globals().M;checked={11:0,182:0}
        try:
            for tx,ty in ((36,34),(34,21)):
                cells,_=parse_adt(client.read(f'World\\Maps\\Kalimdor\\Kalimdor_{tx}_{ty}.adt')[0])
                grid=lua.globals().TurtleSeamlessMap_Terrain.territory[1]
                for (cx,cy),cell in cells.items():
                    area=cell['area'];seen=set();expected=None
                    while area and area not in seen:
                        seen.add(area)
                        if m.byArea[area] is not None:expected=m.byArea[area].id;break
                        area=parents.get(area,0)
                    x=grid.x+(tx-32+(cx+.5)/16)*grid.step;y=grid.y+(ty-32+(cy+.5)/16)*grid.step
                    actual=m.TerrainMapAt(m,x,y)
                    self.assertEqual(actual.id if actual else None,expected)
                    if expected in checked:checked[expected]+=1
            self.assertTrue(all(n>100 for n in checked.values()))
        finally:
            for archive in client.archives:archive.close()

    def test_terrain_single_zone_nodes_and_label_fonts(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();local px,py=0,0;M.Cursor=function() return px,py end
          local grid=TurtleSeamlessMap_Terrain.territory[1]
          local barrens={['50|50']={A={title='A',texture='test'}}}
          local felwood={['50|50']={B={title='B',texture='test'}}}
          pfMap.nodes={PFQUEST={[17]=barrens,[361]=felwood}}
          local originalPairs=pairs;local forbidden
          pairs=function(t) assert(t~=forbidden,'Nonfocused terrain nodes enumerated');return originalPairs(t) end
          for _,tile in ipairs({{36,34,11},{34,21,182}}) do
            forbidden=tile[3]==11 and felwood or barrens
            local found=false
            for cy=0,15 do for cx=0,15 do
              if not found then
                local x=grid.x+(tile[1]-32+(cx+.5)/16)*grid.step
                local y=grid.y+(tile[2]-32+(cy+.5)/16)*grid.step
                local map=M:TerrainMapAt(x,y)
                if map and map.id==tile[3] then
                  M.view.x=x;M.view.y=y;M.view.scale=8;px=M.canvas.width/2;py=M.canvas.height/2
                  M:Render();assert(M.detailTarget.id==tile[3] and M.questNodesVisited==1 and not next(M.providerErrors));found=true
                  local count=0;for _ in pairs(M.detailAreas) do count=count+1 end;assert(count==1)
                end
              end
            end end
            assert(found)
          end
          for _,label in ipairs(M.regionLabels) do assert(label.font) end
          M:WorldView();for _,label in ipairs(M.regionLabels) do assert(not label:IsShown()) end
          pairs=originalPairs
        ''')

    def test_terrain_resources_complete_and_classic_matches_original(self):
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.4.0地形资源-20261024.json').read_text(encoding='utf-8'))
        self.assertFalse(report['unresolved'])
        self.assertGreater(report['counts']['minimap'],1500)
        self.assertGreater(report['counts']['verified-water'],50)
        # Reconstruct original overview at its native resolution, with gutters.
        classic=Image.new('RGBA',(1002,668))
        for p in (ADDON/'Art').glob('v5_classic_*.blp'):
            col,row=map(int,p.stem.split('_')[-2:]);classic.paste(decode_blp(p.read_bytes()).convert('RGBA').crop((1,1,255,255)),(col*254,row*254))
        original=Image.open(STAGE/'previews/World.png').convert('RGBA')
        self.assertLess(max(ImageStat.Stat(ImageChops.difference(original.convert('RGB'),classic.convert('RGB'))).mean),8)

    def test_zone_change_invalidates_only_session_location(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M:FindPlayer();assert(M.lastPlayer)
          M:FocusMap(161);local selected=M.selected
          for _,object in ipairs(objects) do
            if object.events and object.events.ZONE_CHANGED_NEW_AREA then
              event='ZONE_CHANGED_NEW_AREA';invoke(object,'OnEvent');event=nil
            end
          end
          assert(not M.lastPlayer and M.selected==selected)
        ''')

    def test_legacy_terrain_padding_water_and_base_archive(self):
        from turtle_map_archive import Client
        from build_turtle_map_terrain import parse_adt
        client=Client(ROOT,include_terrain=True)
        try:
            water,_=parse_adt(client.read('World\\Maps\\Kalimdor\\Kalimdor_19_12.adt')[0])
            self.assertEqual(len(water),256)
            self.assertTrue(all(c['water'] and c['maximum']<=c['water_level'] for c in water.values()))
            # This modified source has oversized unused MCAL metadata; AreaID
            # extraction must not depend on an unused material parser.
            modified,_=parse_adt(client.read('World\\Maps\\Kalimdor\\Kalimdor_44_40.adt')[0])
            self.assertEqual(len(modified),256)
            base,source=client.read('World\\Maps\\Kalimdor\\Kalimdor_33_48.adt')
            self.assertEqual(source,'Data/terrain.MPQ')
            self.assertEqual(len(parse_adt(base)[0]),256)
        finally:
            for a in client.archives:a.close()

    def test_location_uses_client_locale_aliases_and_style_preferences_persist(self):
        lua=runtime(defaults=True,saved='{layoutVersion=2,notes={{x=700,y=400}},detailStyle="paper",overviewStyle="continuous",cityMaps=false}')
        lua.execute('''
          assert(M.settings.detailStyle=='paper' and M.settings.overviewStyle=='continuous' and not M.settings.cityMaps)
          assert(#M.settings.notes==1)
          GetRealZoneText=function() return 'The Barrens' end
          currentFile='Barrens';M:FindPlayer();assert(M.selected==11 and not M.pendingLocation)
        ''')

    def test_terrain_pool_remains_bounded_across_styles_and_regions(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show()
          for _,style in ipairs({'terrain','paper','terrain'}) do
            M.settings.detailStyle=style;M:RefreshAppearance()
            for _,id in ipairs({11,182,30,301,502,507}) do
              M:FocusMap(id)
              for _,scale in ipairs({4,8,16,32}) do
                M.view.scale=scale;M:RenderArt()
                for _,map in ipairs(M.maps) do
                  if map.atlasPool then assert(#map.atlasPool<=256) end
                end
              end
            end
          end
          M.settings.overviewStyle='classic';M:WorldView()
          for i=1,M.tileUsed do assert(string.find(M.tiles[i].path,'v5_classic_',1,true)) end
        ''')

    def test_style_toolbar_fits_small_and_large_windows(self):
        for screen in ((800,600),(1024,768),(1440,1000)):
            lua=runtime(defaults=True,screen=screen)
            lua.execute('''
              local f=M.frame
              for _,b in ipairs(M.toolbarButtons) do
                assert(b:GetLeft()>=f:GetLeft()+10 and b:GetLeft()+b:GetWidth()<=f:GetLeft()+f:GetWidth()-10)
                assert(b:GetTop()-b:GetHeight()>M.canvas:GetTop())
              end
              M.frame:Show();M:UpdateStyleMenu();M.styleMenu:Show();M:Render()
              assert(M.canvas.width/M.canvas.height>1.499 and M.canvas.width/M.canvas.height<1.501)
            ''')

    def test_all_cities_use_hd_scenery_and_registered_native_interiors(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();M.Cursor=function() return -10,-10 end
          for _,id in ipairs({301,321,341,362,381,382,509}) do
            local city=M.byID[id]
            assert(city and city.city)
            if city.city then
              M:FocusMap(id);M.view.scale=64;M:RenderArt()
              assert(city.cityActive)
              local indoor=false
              for i=1,M.tileUsed do
                local path=M.tiles[i].path
                assert(not string.find(path,'v4_city',1,true))
                if string.find(path,'v7_city',1,true) then indoor=true end
              end
              assert(indoor)
              local x,y=M:MapToWorld(id,.31,.62)
              local a,b=G.Project(city.rect,.31,.62)
              assert(x==a and y==b)
            end
          end
          M:FocusMap(341);M.settings.cityMaps=false;M:RefreshAppearance()
          for i=1,M.tileUsed do assert(not string.find(M.tiles[i].path,'v7_city',1,true)) end
          M.settings.cityMaps=true
          for _,style in ipairs({'terrain','paper','terrain'}) do
            M.settings.detailStyle=style;M:RefreshAppearance()
            M:FocusMap(341);M:FocusMap(382);M:FocusMap(30)
            for _,map in ipairs(M.maps) do for _,t in ipairs(map.atlasPool or {}) do
              if not t.active then assert(not t.path and not t.texture) end
            end end
          end
        ''')

    def test_terrain_water_never_reveals_parchment_and_classic_is_preserved(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();M.Cursor=function() return -10,-10 end
          for _,scale in ipairs({2,8,32,64}) do
            M.view.x=501;M.view.y=334;M.view.scale=scale;M:RenderArt()
            local sea=false
            for i=1,M.tileUsed do
              local path=M.tiles[i].path
              assert(not string.find(path,'v4_paper',1,true))
              if string.find(path,'v6_sea_',1,true) then sea=true end
            end
            assert(sea)
          end
          M:WorldView()
          for i=1,M.tileUsed do assert(string.find(M.tiles[i].path,'v5_classic_',1,true)) end
          M.settings.overviewStyle='continuous';M:RefreshAppearance()
          for i=1,M.tileUsed do assert(not string.find(M.tiles[i].path,'v4_',1,true)) end
          M.settings.detailStyle='paper';M:RefreshAppearance()
          local paper=false;for i=1,M.tileUsed do if string.find(M.tiles[i].path,'v4_paper_',1,true) then paper=true end end
          assert(paper)
        ''')

    def test_region_names_only_one_near_focus_and_font_failure_fallback(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();M.Cursor=function() return -10,-10 end
          local function visible()
            local n=0
            for _,label in ipairs(M.regionLabels or {}) do
              assert(label.font)
              if label:IsShown() then n=n+1;assert(label.mapID==M.detailTarget.id) end
            end
            assert(n<=1);return n
          end
          for _,id in ipairs({11,182,201,30}) do
            M:FocusMap(id);local map=M.byID[id]
            local position=TurtleSeamlessMap_Terrain.labels[id]
            M.view.x=position[1];M.view.y=position[2]
            local unit=math.max(M.canvas.width/map.rect[3],M.canvas.height/map.rect[4])
            M.view.scale=unit*.5;M:RenderArt();assert(visible()==0)
            M.view.scale=unit*.85;M:RenderArt();assert(visible()==1)
            M.view.scale=unit*.65;M:RenderArt();assert(visible()==0)
          end
          M:WorldView();assert(visible()==0)
          M:FocusMap(11);M.settings.detailStyle='paper';M:RefreshAppearance();assert(visible()==0)
        ''')

    def test_full_terrain_audit_and_ungoro_repair_keeps_detailed_core(self):
        report=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.5.0*.json')).read_text(encoding='utf8'))
        self.assertEqual(report['counts']['adt_tiles_audited'],1794)
        self.assertEqual(report['counts']['terrain_chunks_audited'],1794*256)
        self.assertEqual(report['counts']['native_tiles_audited'],1703)
        self.assertFalse(report['unresolved'])
        self.assertGreater(report['counts']['repaired_chunks'],5000)
        self.assertTrue(any(r['continent']=='Kalimdor' and r['x']==32 and r['y']==47 and r['flat_chunks']>150 for r in report['repairs']))
        for check in report['checks']:
            self.assertEqual(check['outside_repair_max_delta'],0)
            self.assertEqual(check['unresolved_context_pixels'],0)
        # Quantization noise must not hide the user's broad flat source defect.
        from refine_turtle_map_terrain import flat_cells
        noisy=Image.new('RGB',(256,256))
        pixels=noisy.load()
        for y in range(256):
            for x in range(256):pixels[x,y]=(82 if (x+y)%2 else 74,73,24)
        self.assertEqual(int(flat_cells(noisy).sum()),256)
        # Real textured ground cannot be mistaken for a uniform source block.
        for y in range(256):
            for x in range(256):pixels[x,y]=(60+(x%16)*8,80+(y%16)*8,24)
        self.assertEqual(int(flat_cells(noisy).sum()),0)

    def test_native_city_model_registration_matches_archive_placement(self):
        from turtle_map_archive import Client
        from refine_turtle_map_terrain import city_placements
        client=Client(ROOT,include_terrain=True,include_wmo=True)
        try:
            placements=city_placements(client)
            report=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.5.0*.json')).read_text(encoding='utf8'))
            for city in report['cities']:
                self.assertEqual(list(placements[city['id']]['placement']),city['placement'])
                raw,_=client.read(city['model'])
                self.assertEqual(hashlib.sha256(raw).hexdigest(),city['root_sha256'])
                self.assertLess(city['placement_error_yards'],.01)
                self.assertGreater(len(city['groups']),50)
                self.assertGreater(len(city['sources']),80)
                self.assertGreater(city['occluded_rock_pixels'],10000)
                # Native indoor textures retain alpha around actual rooms.
                path=next((ADDON/'Art').glob(f'v7_city{city["id"]}_96_*.blp'))
                self.assertGreater(decode_blp(path.read_bytes()).getchannel('A').getextrema()[1],0)
            self.assertEqual({c['id'] for c in report['cities']},{341,382})
        finally:
            for archive in client.archives:archive.close()

    def test_underground_voids_hide_surface_without_rectangular_backing(self):
        from refine_turtle_map_terrain import indoor_voids
        from PIL import ImageDraw
        source=Image.new('RGBA',(256,256))
        draw=ImageDraw.Draw(source)
        draw.ellipse((40,40,216,216),fill=(80,75,65,255))
        draw.ellipse((70,70,186,186),fill=(0,0,0,0))
        draw.rectangle((127,35,129,80),fill=(0,0,0,0))
        result,count=indoor_voids(source)
        self.assertGreater(count,5000)
        self.assertEqual(result.getpixel((128,128))[3],255)
        self.assertEqual(result.getpixel((0,0))[3],0)
        self.assertEqual(result.getpixel((50,128)),source.getpixel((50,128)))
        # A corridor reaching both canvas edges must not enclose the exterior
        # on the opposite side merely because flood fill began at one corner.
        divided=Image.new('RGBA',(256,256));ImageDraw.Draw(divided).rectangle((120,0,135,255),fill=(80,75,65,255))
        result,_=indoor_voids(divided)
        self.assertEqual(result.getpixel((240,128))[3],0)
        self.assertEqual(result.getpixel((15,128))[3],0)

    def test_hd_manifest_covers_world_and_all_seven_city_densities(self):
        report=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.6.0*.json')).read_text(encoding='utf8'))
        self.assertEqual(report['counts']['adt_tiles_audited'],1794)
        self.assertEqual(report['counts']['native_tiles'],1703)
        self.assertEqual(report['counts']['verified_water_tiles'],89)
        self.assertEqual(report['counts']['material_fallback_tiles'],2)
        self.assertFalse(report['unresolved'])
        for scene in report['continents']:
            self.assertEqual([l['density'] for l in scene['levels']],[1,2,4,8,16,32])
        lua=runtime(defaults=True);terrain=lua.globals().TurtleSeamlessMap_Terrain
        self.assertEqual({k for k,_ in terrain.cities.items()},{301,321,341,362,381,382,509})
        for mid,city in terrain.cities.items():
            density=max(v.density for _,v in city.levels.items())
            self.assertEqual(density,96 if mid in (341,382) else 64)
        join=next(c for c in report['cities'] if c['id']=='silithus-aq-join')
        self.assertEqual(join['rect'],[150,495,45,30])
        self.assertTrue(any(k.endswith('outergateenterance.wmo') for k in join['sources']))
        self.assertTrue(any(k.endswith('innergateenterance.wmo') for k in join['sources']))

    def test_hd_world_lod_and_city_pools_are_selected_without_global_navigation(self):
        lua=runtime(defaults=True)
        lua.execute('''
          M.frame:Show();M.Cursor=function() return -10,-10 end
          local selections=mapSets
          M:FocusMap(201);M.view.scale=24;M:RenderArt()
          local high=false
          for i=1,M.tileUsed do if string.find(M.tiles[i].path,'v7_t1_32_',1,true) then high=true end end
          assert(high)
          for _,id in ipairs({301,321,341,362,381,382,509}) do
            M:FocusMap(id);M.view.scale=64;M:RenderArt()
            local high=false
            for i=1,M.tileUsed do
              local path=M.tiles[i].path
              if string.find(path,'v7_city'..id..'_',1,true) then high=true end
            end
            assert(high)
            for _,map in ipairs(M.maps) do if map.atlasPool then assert(#map.atlasPool<=256) end end
          end
          assert(mapSets==selections)
        ''')

    def test_hd_ground_uses_real_material_detail_beyond_a_resized_minimap(self):
        from build_turtle_map_hd import Ground
        from turtle_map_archive import Client
        client=Client(ROOT,include_terrain=True)
        try:
            ground=Ground(client)
            data,_=client.read('World\\Maps\\Kalimdor\\Kalimdor_34_21.adt')
            high,depth=ground.tile(data,512,None,True)
            self.assertEqual(high.size,(512,512));self.assertEqual(depth.shape,(512,512))
            low=high.resize((256,256),Image.Resampling.LANCZOS).resize(high.size,Image.Resampling.LANCZOS)
            delta=ImageChops.difference(high.convert('RGB'),low.convert('RGB'))
            self.assertGreater(max(ImageStat.Stat(delta).mean),1)
            self.assertGreater(len(ground.sources),1)
            self.assertTrue(all(len(s['sha256'])==64 for s in ground.sources.values()))
        finally:
            for archive in client.archives:archive.close()

    def test_vanilla_m2_extra_header_array_and_two_level_indices(self):
        from turtle_map_archive import Client
        from turtle_map_scenery import Scenery
        client=Client(ROOT,include_terrain=True,include_wmo=True,include_model=True)
        try:
            scenery=Scenery(client)
            path='world\\kalimdor\\silithus\\passivedoodads\\ahnqirajstones\\ahn_qirajbrick01.m2'
            meshes=scenery.model('m2',path)
            self.assertFalse(scenery.errors)
            self.assertEqual(len(meshes),2)
            self.assertTrue(all(len(m[0])==42 for m in meshes))
            self.assertTrue(all(len(m[3])%3==0 and max(m[3])<42 for m in meshes))
            self.assertEqual(sum(len(m[3]) for m in meshes),114)
        finally:
            for archive in client.archives:archive.close()

    def test_wmo_export_footer_does_not_hide_stormwind_required_geometry(self):
        import struct
        from turtle_map_archive import Client
        from turtle_map_scenery import wmo_chunks
        client=Client(ROOT,include_wmo=True)
        try:
            raw,_=client.read('world\\wmo\\azeroth\\buildings\\stormwind\\stormwind.wmo')
            root=wmo_chunks(raw)
            self.assertIn(b'TMOM',root);self.assertIn(b'IGOM',root)
            self.assertEqual(len(root[b'TMOM'])%64,0)
            with self.assertRaises(ValueError):wmo_chunks(b'TVOM'+struct.pack('<I',100)+b'x')
        finally:
            for archive in client.archives:archive.close()

    def test_hd_placement_rotation_matches_real_city_bounding_box(self):
        import numpy as np
        import struct
        from turtle_map_archive import Client
        from build_turtle_map_terrain import chunks
        from refine_turtle_map_terrain import city_placements
        from turtle_map_scenery import placement_matrix
        client=Client(ROOT,include_terrain=True,include_wmo=True)
        try:
            for mid,p in city_placements(client).items():
                groups=list(struct.iter_unpack('<I6fi',dict(chunks(client.read(p['path'])[0]))[b'IGOM']))
                lo=[min(row[i] for row in groups) for i in (1,2,3)];hi=[max(row[i] for row in groups) for i in (4,5,6)]
                v=p['placement'];xyz=np.array([[x,y,z] for x in (lo[0],hi[0]) for y in (lo[1],hi[1]) for z in (lo[2],hi[2])])
                world=xyz@placement_matrix(v[5:8]).T+np.array([v[2],v[4],v[3]])
                expected=np.array([v[8],v[10],v[9],v[11],v[13],v[12]])
                self.assertLess(float(abs(np.concatenate((world.min(axis=0),world.max(axis=0)))-expected).max()),.01)
        finally:
            for archive in client.archives:archive.close()

    def test_actual_offline_rasterizer_depth_alpha_and_canvas_clipping(self):
        import numpy as np
        import struct
        from turtle_map_scenery import Scenery,rasterize
        stage=STAGE/'hd-raster-test';stage.mkdir(exist_ok=True)
        def texture(name,color):
            p=stage/(name+'.tex');p.write_bytes(struct.pack('<II',2,2)+bytes(color)*4);return str(p)
        red=texture('red',(255,0,0,255));green=texture('green',(0,255,0,255))
        xyz=np.array([[2,2,1],[30,2,1],[2,30,1]],dtype='f4');normal=np.array([[0,0,1]]*3);uv=np.array([[0,0],[1,0],[0,1]])
        s=Scenery(None);s.models[('m2','low')]=[(xyz,normal,uv,np.array([0,1,2]),red)]
        high=xyz.copy();high[:,2]=2;s.models[('m2','high')]=[(high,normal,uv,np.array([0,1,2]),green)]
        obj=lambda name,uid:dict(kind='m2',uid=uid,path=name,position=[0,0,0],rotation=[0,0,0],scale=1)
        base=Image.new('RGBA',(64,64),(0,0,255,255));depth=np.full((64,64),-1000)
        outputs=[];jobs=[]
        for i,objects in enumerate(([obj('low',1),obj('high',2)],[obj('high',2),obj('low',1)])):
            job=stage/f'{i}.job';outputs.append(s.job(job,base,depth,objects,[0,0,64,64]));jobs.append(job)
        rasterize(jobs)
        images=[Image.frombytes('RGBA',base.size,p.read_bytes()) for p in outputs]
        self.assertEqual(images[0].tobytes(),images[1].tobytes())
        self.assertGreater(images[0].getpixel((6,6))[1],200)
        self.assertEqual((images[0].getpixel((6,6))[0],images[0].getpixel((6,6))[2]),(0,0))
        self.assertEqual(images[0].getpixel((60,60)),(0,0,255,255))
        coverage=outputs[0].with_suffix('.coverage').read_bytes()
        self.assertEqual(coverage[6*64+6],255);self.assertEqual(coverage[60*64+60],0)

    def test_opaque_model_material_does_not_misread_diffuse_alpha_as_a_hole(self):
        from turtle_map_scenery import Scenery
        from build_turtle_seamless_map import encode_blp
        class Source:
            def read(self,name):return encode_blp(Image.new('RGBA',(4,4),(100,150,200,0))),'generated-fixture'
        s=Scenery(Source());opaque=Path(s.texture('fixture.blp',True)).read_bytes();cutout=Path(s.texture('fixture.blp',False)).read_bytes()
        self.assertEqual(set(opaque[8:][3::4]),{255})
        self.assertEqual(set(cutout[8:][3::4]),{0})

    def test_spectral_classifier_finds_shaded_placeholder_but_keeps_texture(self):
        import numpy as np
        from build_turtle_map_hd import spectral_margin
        x=np.arange(256,dtype=float);a=np.empty((256,256,3),dtype='uint8')
        for channel,base in enumerate((55,65,30)):a[:,:,channel]=base+np.floor(x/4)[None,:]
        self.assertGreater(int(spectral_margin(Image.fromarray(a)).sum()),200)
        rng=np.random.default_rng(112);a=rng.integers(30,180,(256,256,3),dtype='uint8')
        self.assertLess(int(spectral_margin(Image.fromarray(a)).sum()),10)

    def test_targeted_aq_fill_preserves_courtyard_and_records_real_material(self):
        from turtle_map_archive import Client
        report=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.6.0*.json')).read_text(encoding='utf8'))
        audit=report['quality_audit'];self.assertEqual(audit['courtyard_before_sha256'],audit['courtyard_after_sha256'])
        self.assertEqual(audit['files_checked'],report['total_files'])
        self.assertEqual(audit['map_data_sha256'],hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest())
        self.assertEqual(len(report['aq_boundary_retouch']['guides']),5)
        self.assertGreater(sum(g['filled_pixels'] for g in report['aq_boundary_retouch']['guides']),100000)
        client=Client(ROOT)
        try:
            material=report['aq_boundary_retouch'];data,_=client.read(material['material'])
            self.assertEqual(hashlib.sha256(data).hexdigest(),material['sha256'])
        finally:
            for archive in client.archives:archive.close()


def compose_preview(lua, reverse=False):
    m=lua.globals().M
    canvas=Image.new('RGBA',(int(m.canvas.width),int(m.canvas.height)))
    # Emulate client frame/layer depth, not the order of draw commands. Reverse
    # same-layer regions to expose accidental dependence on texture ordering.
    entries=[(i,m.tiles[i]) for i in range(1,int(m.tileUsed)+1)]
    entries.sort(key=lambda pair:(pair[1].parent.level,0 if pair[1].layer=='BACKGROUND' else 1,-pair[0] if reverse else pair[0]))
    for _,t in entries:
        path=t.texture
        if path.startswith('Interface\\AddOns\\TurtleSeamlessMap\\Art\\'):
            filename=path.split('\\')[-1]+'.blp'
            im=decode_blp((ADDON/'Art'/filename).read_bytes()).convert('RGBA')
        else:
            im=decode_blp((STAGE/'raw'/(path.replace('\\','/')+'.blp')).read_bytes()).convert('RGBA')
        uv=t.uv
        im=im.crop((uv[1]*im.width,uv[3]*im.height,uv[2]*im.width,uv[4]*im.height))
        x,y=round(t.point[4]),round(-t.point[5])
        w,h=max(1,round(t.point[4]+t.width)-x),max(1,round(-t.point[5]+t.height)-y)
        im=im.resize((w,h),Image.Resampling.BILINEAR)
        if t.alpha!=1:
            im.putalpha(im.getchannel('A').point(lambda a:round(a*t.alpha)))
        canvas.alpha_composite(im,(x,y))
    return canvas


def render_preview(map_id=30, name='continuous-elwynn-preview.jpg', zoom=.8):
    lua=runtime()
    lua.execute('M.frame:Show();'+('M:WorldView();' if map_id is None else f'M:FocusMap({map_id});')+f'M.view.scale=M.view.scale*{zoom};M:Render()')
    compose_preview(lua).convert('RGB').save(STAGE/name)


if __name__=='__main__':
    suite=unittest.defaultTestLoader.loadTestsFromTestCase(SeamlessMapTests)
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        render_preview()
        render_preview(None,'v2-world-preview.jpg',1)
        render_preview(301,'v2-stormwind-preview.jpg',1)
        render_preview(13,'v2-kalimdor-preview.jpg',1)
    raise SystemExit(not result.wasSuccessful())
