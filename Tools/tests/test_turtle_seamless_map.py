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
function methods:SetTexture(...) self.texture=(...);self.textureSets=(self.textureSets or 0)+1;return 1 end
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


def runtime(with_plugins=True, saved=None, screen=None):
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
        expected.add('SeaPaper.blp')
        self.assertEqual(expected,actual)
        self.assertEqual(len(actual),865)
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
                if string.find(path,'v2_sea_',1,true) then assert(texture.layer=='BACKGROUND')
                else assert(texture.layer=='ARTWORK') end
                assert(texture.paintPass==M.paintPass or not texture:IsShown())
              end
            end
          end
          local frames=#objects
          for i=1,50 do M:RenderArt() end
          assert(#objects==frames)
          for _,map in ipairs(M.maps) do
            for _,texture in ipairs(map.textures or {}) do assert(texture.textureSets==1) end
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

    def test_only_cursor_zone_draws_detail_and_visits_nodes(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M:FocusMap(30)
          local focusX,focusY
          M.Cursor=function() return focusX,focusY end
          local function point(map,u,v)
            local x,y=M:MapToWorld(map,u,v)
            focusX,focusY=G.Screen(M.view,M.canvas.width,M.canvas.height,x,y)
          end
          -- Wide view contains both Elwynn and Westfall; only the pointed
          -- region may expose detail art or enumerate its nodes.
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
          now=now+.11;invoke(M.frame,'OnUpdate');assert(not M.pendingLocation)
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
              assert(#map.tiles==24 and map.artWidth==1504 and map.artHeight==1004)
              local x,y=M:MapToWorld(map.id,0,0)
              local ax,ay=G.Project(map.artRect,251/1504,168/1004)
              assert(math.abs(ax-x)<1e-7 and math.abs(ay-y)<1e-7)
              x,y=M:MapToWorld(map.id,1,1)
              ax,ay=G.Project(map.artRect,1253/1504,836/1004)
              assert(math.abs(ax-x)<1e-7 and math.abs(ay-y)<1e-7)
            end
          end
          local map=M.byID[301]
          local x,y=M:MapToWorld(301,.15,.35);assert(G.Hit(map,x,y),'Port label remains part of the city')
          x,y=M:MapToWorld(301,.94,.90);assert(not G.Hit(map,x,y),'Corner compass is not city territory')
          x,y=M:MapToWorld(301,.50,.075);assert(not G.Hit(map,x,y),'Title ribbon is not city territory')
        ''')
        report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.2资源-20261024.json').read_text(encoding='utf-8'))
        self.assertEqual(report['city_tiles'],168)
        self.assertEqual(report['total_art_files'],865)
        for entry in report['written']:
            self.assertEqual(hashlib.sha256((ADDON/'Art'/entry['file']).read_bytes()).hexdigest(),entry['sha256'])

    def test_ocean_keeps_paper_and_wave_detail_across_zoom(self):
        lua=runtime()
        lua.execute('''
          M.frame:Show();M.view.x=501;M.view.y=334;M.view.scale=8;M:Render()
          assert(M.canvas.backdrop.tile and M.canvas.backdrop.tileSize==128)
          assert(string.find(M.canvas.backdrop.bgFile,'SeaPaper',1,true))
        ''')
        first=compose_preview(lua)
        lua.execute('M.view.scale=32;M:Render()')
        closer=compose_preview(lua)
        self.assertEqual(first.tobytes(),closer.tobytes())
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


def compose_preview(lua, reverse=False):
    m=lua.globals().M
    canvas=Image.new('RGBA',(int(m.canvas.width),int(m.canvas.height)))
    tile=decode_blp((ADDON/'Art/SeaPaper.blp').read_bytes()).convert('RGBA').resize((128,128))
    for y in range(0,canvas.height,128):
        for x in range(0,canvas.width,128):canvas.paste(tile,(x,y))
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
