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
from PIL import Image

ADDON = ROOT / 'Interface/AddOns/TurtleSeamlessMap'
STAGE = ROOT / 'PluginHistory/staging/turtle-seamless-map'

MOCK = r'''
objects={};now=10;mouseX=600;mouseY=400;ctrl=false;shift=false;mapFile='Elwynn'
mapSets=0;nativeUpdates=0;trackerResets=0;questClicks=0;atlasClicks=0;messages={}
UISpecialFrames={};SlashCmdList={};STANDARD_TEXT_FONT='missing-user-font.ttf'
local methods={}
function newObject(kind,name,parent,template)
 local o=setmetatable({kind=kind,name=name,parent=parent,template=template,width=0,height=0,shown=true,scale=1,alpha=1,level=1,scripts={},points={}}, {__index=methods})
 table.insert(objects,o);if name then _G[name]=o end;return o
end
function methods:SetWidth(v) assert(v>0 and v==v);self.width=v end
function methods:SetHeight(v) assert(v>0 and v==v);self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...};table.insert(self.points,self.point) end
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
function methods:RegisterEvent(event) end
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
function methods:SetTexture(...) self.texture=(...);return 1 end
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
function SetMapToCurrentZone() mapSets=mapSets+1;mapFile='Elwynn' end
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


def runtime(with_plugins=True, saved=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().FONT_CONTRACT = (ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8')
    lua.execute(MOCK)
    for name in ['MapData.lua','Geometry.lua','Core.lua','Compat.lua']:
        lua.execute((ADDON/name).read_text(encoding='utf-8'), name=name)
    if not with_plugins:
        lua.execute('ModernMapMarkersCore=nil;pfMap=nil;pfQuest=nil')
    if saved:
        lua.execute('TurtleSeamlessMapDB='+saved)
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
          M.frame:Show();pfMap:ShowMapID(40);assert(M.selected==39 and M.frame:IsShown())
        ''')

    def test_all_runtime_art_present_valid_and_bounded(self):
        expected=set()
        for _,m in self.lua.globals().M.maps.items():
            if m.rect:
                for _,tile in m.tiles.items():
                    expected.add(tile[1]+'.blp')
                if m.backing:
                    for _,tile in m.backing.items():
                        expected.add(tile[1]+'.blp')
                if m.sea:
                    for _,tile in m.sea.items():
                        expected.add(tile[1]+'.blp')
        actual={p.name for p in (ADDON/'Art').glob('*.blp')}
        self.assertEqual(expected,actual)
        self.assertEqual(len(actual),792)
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
          assert(seen['Interface\\\\AddOns\\\\TurtleSeamlessMap\\\\Art\\\\v2_694_1'])
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
          M.view.x=c.rect[1]+c.rect[3]*1.1;M:Render();assert(not c.cityActive)
          local x,y=G.Screen(M.view,M.canvas.width,M.canvas.height,c.rect[1]+c.rect[3]/2,c.rect[2]+c.rect[4]/2)
          M.Cursor=function() return x,y end
          M:Zoom(1.01);M:Render();assert(c.cityActive)
          invoke(M.canvas,'OnMouseDown','LeftButton');assert(M.zoomFocus==nil)
        ''')

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


def render_preview(map_id=30, name='continuous-elwynn-preview.jpg', zoom=.8):
    lua=runtime()
    lua.execute('M.frame:Show();'+('M:WorldView();' if map_id is None else f'M:FocusMap({map_id});')+f'M.view.scale=M.view.scale*{zoom};M:Render()')
    m=lua.globals().M
    canvas=decode_blp((ADDON/'Art/v2_sea_694_1.blp').read_bytes()).convert('RGBA').resize((int(m.canvas.width),int(m.canvas.height)))
    for i in range(1,int(m.tileUsed)+1):
        t=m.tiles[i]
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
    canvas.convert('RGB').save(STAGE/name)


if __name__=='__main__':
    suite=unittest.defaultTestLoader.loadTestsFromTestCase(SeamlessMapTests)
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        render_preview()
        render_preview(None,'v2-world-preview.jpg',1)
        render_preview(301,'v2-stormwind-preview.jpg',1)
        render_preview(13,'v2-kalimdor-preview.jpg',1)
    raise SystemExit(not result.wasSuccessful())
