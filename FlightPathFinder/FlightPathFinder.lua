local F={queue={},queued={},nodes={},maps={},pins={}};_G.FlightPathFinder=F
local function pub(v)if issecretvalue and issecretvalue(v)then return nil end;return v end
F.Public=pub
function F:Call(fn,...)if type(fn)~='function'then return end;local ok,a,b,c,d=pcall(fn,...);if ok then return pub(a),pub(b),pub(c),pub(d)end end
function F:Number(v,lo,hi)v=pub(v);return type(v)=='number'and v==v and v>=lo and v<=hi and v end
function F:Vector(v)if not v or not v.GetXY then return end;local x,y=self:Call(v.GetXY,v);if self:Number(x,0,1)and self:Number(y,0,1)then return x,y end end
function F:Init()
 FlightPathFinderDB=type(FlightPathFinderDB)=='table'and FlightPathFinderDB or {};self.db=FlightPathFinderDB
 if self.db.enabled==nil then self.db.enabled=true end;if self.db.neutral==nil then self.db.neutral=true end;self.db.size=self:Number(self.db.size,24,64)or 38
 FlightPathFinderCharDB=type(FlightPathFinderCharDB)=='table'and FlightPathFinderCharDB or {};self.character=FlightPathFinderCharDB;self.character.nodes=self.character.nodes or {}
 self:QueueMap(1414);self:QueueMap(1415);self:QueueMap(946);self:QueueMap(947)
 local api=C_Map
 if api and api.GetMapChildrenInfo then
  for _,root in ipairs({947,946,1414,1415})do local rows=self:Call(api.GetMapChildrenInfo,root,nil,true);if type(rows)=='table'then for i=1,math.min(2000,#rows)do local row=rows[i];if row then self:QueueMap(pub(row.mapID))end end end end
 end
 self:QueueMap(self:Call(api and api.GetBestMapForUnit,'player'))
end
function F:Rescan()
 self.queue={};self.queued={};self.maps={};self:Init()
end
function F:QueueMap(id)
 if not self:Number(id,1,999999)or id%1~=0 or self.queued[id]or #self.queue>=2000 then return false end
 self.queued[id]=true;self.queue[#self.queue+1]=id;return true
end
function F:MapRank(id)
 local depth,seen=0,{};local current=id
 for _=1,20 do if seen[current]then break end;seen[current]=true;local info=self:Call(C_Map and C_Map.GetMapInfo,current);if type(info)~='table'then break end;local parent=pub(info.parentMapID);if not self:Number(parent,1,999999)then break end;current=parent;depth=depth+1 end
 local info=self:Call(C_Map and C_Map.GetMapInfo,id);local kind=type(info)=='table'and pub(info.mapType);return(kind==3 and 100 or 0)+depth
end
function F:ScanMap(map,force)
 if not self.db or not self:Number(map,1,999999)or map%1~=0 then return false end
 local time=GetTime and GetTime()or GetServerTime();if not force and self.maps[map]and time-self.maps[map]<60 then return true end
 local api=C_TaxiMap;local rows=self:Call(api and api.GetTaxiNodesForMap,map)
 if type(rows)~='table'then self.status='Native flight-node API/data unavailable for this map.';return false end
 self.maps[map]=time;local rank=self:MapRank(map);local info=self:Call(C_Map and C_Map.GetMapInfo,map);local zone=type(info)=='table'and pub(info.name)or('Map '..map)
 for i=1,math.min(1000,#rows)do local row=rows[i]
  if type(row)=='table'then
   local id,faction,name=pub(row.nodeID),pub(row.faction),pub(row.name);local x,y=self:Vector(pub(row.position))
   if self:Number(id,1,999999)and id%1==0 and(faction==2 or faction==0)and type(name)=='string'and #name>0 and #name<=200 and not name:find('[%c|]')and x and y then
    local node=self.nodes[id];local n=self.nodeCount or 0
    if node or n<2000 then
     if not node then node={id=id,views={}};self.nodes[id]=node;self.nodeCount=n+1 end
     node.name=name;node.faction=faction;node.views[map]={x=x,y=y};local atlas=pub(row.atlasName);if type(atlas)=='string'and #atlas<=100 then node.atlas=atlas end
     if not node.rank or rank>node.rank or node.map==map then node.rank=rank;node.map=map;node.x=x;node.y=y;node.zone=zone end
     local detailed=self:Call(C_Map and C_Map.GetMapInfoAtPosition,map,x,y)
     local detailID=type(detailed)=='table'and pub(detailed.mapID)
     if self:Number(detailID,1,999999)and detailID~=map then
      local detailRank=self:MapRank(detailID)
      if detailRank>(node.rank or -1)then local dx,dy=self:Convert(map,x,y,detailID);if dx then node.map,node.x,node.y,node.rank=detailID,dx,dy,detailRank;node.zone=pub(detailed.name)or node.zone;node.views[detailID]={x=dx,y=dy}end end
      self:QueueMap(detailID)
     end
     local unknown=pub(row.isUndiscovered);if type(unknown)=='boolean'then self.character.nodes[id]=not unknown end
    end
   end
  end
 end
 self.status='Live client flight-node data. Physically visit a flight master to learn its route.';return true
end
function F:List(query)
 local list={};query=type(query)=='string'and query:lower()or ''
 for _,node in pairs(self.nodes)do if(node.faction==2 or self.db.neutral)and(query==''or(node.name..' '..(node.zone or '')):lower():find(query,1,true))then list[#list+1]=node end end
 table.sort(list,function(a,b)if a.zone~=b.zone then return(a.zone or '')<(b.zone or '')end;return a.name<b.name end);return list
end
function F:Convert(map,x,y,target)
 if not CreateVector2D or not C_Map or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos then return end
 local vec=self:Call(CreateVector2D,x,y);if not vec then return end
 local continent,world=self:Call(C_Map.GetWorldPosFromMapPos,map,vec);if not self:Number(continent,0,999999)or not world then return end
 local result,pos=self:Call(C_Map.GetMapPosFromWorldPos,continent,world,target);if result==target then return self:Vector(pos)end
end
function F:Position(node,map)
 local v=node.views[map];if v then return v.x,v.y end
 local x,y=self:Convert(node.map,node.x,node.y,map);if x then return x,y end
 local a,b,c,d=self:Call(C_Map and C_Map.GetMapRectOnMap,node.map,map)
 if self:Number(a,0,1)and self:Number(b,0,1)and self:Number(c,0,1)and self:Number(d,0,1)and b>a and d>c then return a+node.x*(b-a),c+node.y*(d-c)end
end
function F:Locate(node)
 if not node then return false end
 if not WorldMapFrame then local load=C_AddOns and C_AddOns.LoadAddOn or LoadAddOn;if load then pcall(load,'Blizzard_WorldMap')end end
 if not WorldMapFrame or not WorldMapFrame.SetMapID then return false end
 WorldMapFrame:Show();WorldMapFrame:SetMapID(node.map);self.selected=node.id;self:Render();return true
end
local frame=CreateFrame('Frame')
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','TAXIMAP_OPENED','TAXI_NODE_STATUS_CHANGED'})do pcall(frame.RegisterEvent,frame,event)end
frame:SetScript('OnEvent',function(_,event,name)
 if event=='ADDON_LOADED'then if name=='FlightPathFinder'then F:Init()end;return end
 if not F.db then return end
 local map=F:Call(C_Map and C_Map.GetBestMapForUnit,'player');if map then F:ScanMap(map,true)end
 if event=='TAXIMAP_OPENED'or event=='TAXI_NODE_STATUS_CHANGED'then for _,id in ipairs({1414,1415})do F:ScanMap(id,true)end end
 if F.Refresh then F:Refresh()end
end)
local elapsed=0;frame:SetScript('OnUpdate',function(_,dt)
 if not F.db then return end;elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 for _=1,2 do local map=table.remove(F.queue,1);if map then F:ScanMap(map)end end
 if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()then local id=WorldMapFrame.GetMapID and WorldMapFrame:GetMapID();if id then F:ScanMap(id)end end
 if F.Render then F:Render()end;if F.Refresh then F:Refresh()end
end)
SLASH_FLIGHTPATHFINDER1='/fpf';SLASH_FLIGHTPATHFINDER2='/flightpaths';SlashCmdList.FLIGHTPATHFINDER=function()F:Show()end
