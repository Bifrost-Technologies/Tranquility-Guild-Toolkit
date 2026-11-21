local F=FlightPathFinder
function F:StopPath(reason)
 self.pathGeneration=(self.pathGeneration or 0)+1
 if self.cancelPath then self.cancelPath();self.cancelPath=nil end
 self.path=nil;self.pathIndex=nil;self.pathStatus=reason
 for _,line in ipairs(self.pathLines or {})do line:Hide()end
 if self.pathHUD then self.pathHUD:Hide()end
end
function F:RouteTo(node)
 self:StopPath('Select a flight master to plan a walking route.')
 if not self.db.pathing or not node then return false end
 local N=WorldNavigation
 if not N then self.pathStatus='Enable WorldNavigation for road and terrain routing.';return false end
 local from=N:Position();local vector=self:Call(CreateVector2D,node.x,node.y)
 local map,world=self:Call(C_Map and C_Map.GetWorldPosFromMapPos,node.map,vector)
 local x,y;if world and world.GetXY then x,y=self:Call(world.GetXY,world)end
 if not from or not N:Finite(x)or not N:Finite(y)or map~=from.map then self.pathStatus='World coordinates unavailable or destination is on another continent.';return false end
 local destination={x=x,y=y,map=map}
 -- A flight master personally visited supplies a confirmed standing height.
 local known=self.character.approaches and self.character.approaches[node.id]
 if known and known.map==map and math.abs(known.x-x)<30 and math.abs(known.y-y)<30 then destination=N:Copy(known)end
 self.selected=node.id;self.pathStatus='Planning a road-preferred terrain route…'
 local generation=self.pathGeneration;self.pathOrigin=from;self.pathRequested=GetTime()
 self.cancelPath=N:Request(from,destination,function(route,reason)
  if self.pathGeneration~=generation or not self.db.pathing then return end
  self.path=route;self.pathIndex=2
  self.pathStatus=route and ('Follow the mapped approach to '..node.name..'. '..route.source)or reason
  self:Refresh();self:RenderPath()
 end)
 return true
end
function F:RenderPath()
 local now=GetTime();if self.lastPathDraw and now-self.lastPathDraw<.15 then return end;self.lastPathDraw=now
 self.pathLines=self.pathLines or {};for _,line in ipairs(self.pathLines)do line:Hide()end;self.mapSegmentsDrawn=0
 local map=WorldMapFrame
 if not self.db.pathing or not self.path or not map or not map:IsShown()or not map.GetCanvas or(map.IsForbidden and map:IsForbidden())then return end
 local canvas=map:GetCanvas();if not canvas then return end
 if not self.routeOverlay then self.routeOverlay=CreateFrame('Frame',nil,canvas);self.routeOverlay:EnableMouse(false)end
 local overlay=self.routeOverlay;overlay:SetParent(canvas);overlay:ClearAllPoints();overlay:SetAllPoints(canvas)
 overlay:SetFrameLevel(canvas:GetFrameLevel()+100);overlay:Show()
 if not overlay.CreateLine then self.pathDrawStatus='Map line API unavailable.';return end
 local id=map:GetMapID();local width,height=self:Call(canvas.GetWidth,canvas),self:Call(canvas.GetHeight,canvas)
 if not self:Number(width,1,100000)or not self:Number(height,1,100000)then return end
 local function project(p)
  local which,pos=self:Call(C_Map and C_Map.GetMapPosFromWorldPos,p.map,self:Call(CreateVector2D,p.x,p.y),id)
  if which~=id or not pos or not pos.GetXY then return end
  local x,y=self:Call(pos.GetXY,pos)
  if type(x)=='number'and type(y)=='number'and x==x and y==y then return x,y end
 end
 local points=self.path.points
 -- Collapse only collinear world segments, preserving route bends across the whole map.
 if self.drawRoute~=self.path then
  local simple={points[1]}
  for i=2,#points-1 do
   local p,q,r=simple[#simple],points[i],points[i+1]
   local ax,ay=q.x-p.x,q.y-p.y;local bx,by=r.x-q.x,r.y-q.y
   local length=math.sqrt((ax*ax+ay*ay)*(bx*bx+by*by))
   if p.map~=q.map or q.map~=r.map or length==0 or (ax*bx+ay*by)/length<.9999 then simple[#simple+1]=q end
  end
  simple[#simple+1]=points[#points];self.drawPoints=simple;self.drawRoute=self.path;self.drawProjection=nil
 end
 if not self.drawProjection or self.drawProjection.map~=id then
  local projected={map=id,points={}}
  for i,p in ipairs(self.drawPoints)do local x,y=project(p);projected.points[i]=x and {x=x,y=y}or false end
  self.drawProjection=projected
 end
 local function clip(ax,ay,bx,by)
  local dx,dy=bx-ax,by-ay;local lo,hi=0,1
  local function edge(p,q)
   if p==0 then return q>=0 end
   local r=q/p;if p<0 then if r>hi then return false end;lo=math.max(lo,r)else if r<lo then return false end;hi=math.min(hi,r)end;return true
  end
  if edge(-dx,ax)and edge(dx,1-ax)and edge(-dy,ay)and edge(dy,1-ay)then return ax+dx*lo,ay+dy*lo,ax+dx*hi,ay+dy*hi end
 end
 local projected=self.drawProjection.points;local count=0
 for i=2,#projected do
  local p,q=projected[i-1],projected[i]
  if p and q then
   local ax,ay,bx,by=clip(p.x,p.y,q.x,q.y)
   if ax then
    count=count+1;local line=self.pathLines[count]
    if not line then line=overlay:CreateLine(nil,'OVERLAY');self.pathLines[count]=line end
    line:SetThickness(4);line:SetColorTexture(.05,.85,1,1)
    line:SetStartPoint('TOPLEFT',overlay,ax*width,-ay*height);line:SetEndPoint('TOPLEFT',overlay,bx*width,-by*height);line:Show()
   end
  end
 end
 self.mapSegmentsDrawn=count;self.pathDrawStatus=count>0 and ('World map: '..count..' cyan segments')or 'No route segment projects onto this map; open your current zone map.'
end
function F:UpdatePath()
 if not self.db.pathing or not self.path or not WorldNavigation then return end
 local N=WorldNavigation;local p=N:Position()
 if not p then if self.pathHUD then self.pathHUD:Hide()end;self.pathStatus='Position unavailable; guidance paused.';return end
 local points=self.path.points;local nextPoint=points[self.pathIndex]
 if not nextPoint or p.map~=nextPoint.map then self:StopPath('Route ended or map changed. Select the flight master again.');return end
 while N:Distance(p,nextPoint)<=1.5 do
  self.pathIndex=self.pathIndex+1;nextPoint=points[self.pathIndex]
  if not nextPoint then self:StopPath('Approach reached. Find and speak to the flight master.');return end
 end
 local distance=N:SegmentDistance(p,points[self.pathIndex-1],nextPoint)
 -- Keep the selected route while off course; replacing it is an explicit user action.
 if not self.pathHUD then
  local hud=CreateFrame('Frame','FlightPathFinderDirections',UIParent,'BackdropTemplate');self.pathHUD=hud;hud:SetSize(580,90);hud:SetPoint('TOP',0,-100)
  hud:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});hud:SetBackdropColor(.035,.045,.065,.95)
  hud.text=hud:CreateFontString(nil,'OVERLAY','GameFontHighlight');hud.text:SetPoint('TOPLEFT',hud,65,-10);hud.text:SetSize(505,70);hud.arrow=hud:CreateTexture(nil,'OVERLAY');hud.arrow:SetSize(42,42);hud.arrow:SetPoint('LEFT',12,0);hud.arrow:SetTexture('Interface\\Minimap\\MinimapArrow');hud.arrow:SetVertexColor(.1,.85,1);hud.text:SetTextColor(.4,.75,1)
 end
 self:RenderPath()
 if self.RenderMinimapPath then self:RenderMinimapPath()end
 local dx,dy=nextPoint.x-p.x,nextPoint.y-p.y
 local bearing=math.atan2 and math.atan2(dy,dx)or(dx>0 and math.atan(dy/dx)or dx<0 and math.atan(dy/dx)+(dy>=0 and math.pi or -math.pi)or dy>=0 and math.pi/2 or -math.pi/2)
 local delta=(bearing-(self:Call(GetPlayerFacing)or 0)+math.pi)%(2*math.pi)-math.pi
 if self.pathHUD.arrow then self.pathHUD.arrow:SetRotation(delta)end
 local turn=math.abs(delta)<.3 and 'Ahead'or delta>0 and 'Turn left'or 'Turn right'
 local visual=(self.mapSegmentsDrawn or 0)>0 and 'Cyan route drawn on the world map.'or(self.minimapSegmentsDrawn or 0)>0 and 'Cyan route drawn on the minimap.'or 'Follow the direction arrow; open your current zone map for the route.'
 self.pathHUD.text:SetText(('%s · waypoint %d/%d · %.0f yards\n%s\n%s'):format(turn,self.pathIndex,#points,N:Distance(p,nextPoint),visual,self.path.imageBased and 'Map-image estimate; ground obstacles may differ.'or 'No 3D ground line is drawn.'))
 self.pathHUD:Show()

end
local render=F.Render
function F:Render()render(self);self:RenderPath()end
local locate=F.Locate
function F:Locate(node)local ok=locate(self,node);if node and self.db.pathing then self:RouteTo(node)end;return ok end
local events=CreateFrame('Frame');events:RegisterEvent('TAXIMAP_OPENED')
events:SetScript('OnEvent',function()
 if not F.character or not WorldNavigation then return end
 local p=WorldNavigation:Position();if not p then return end
 F.character.approaches=F.character.approaches or {}
 for _,node in pairs(F.nodes)do
  local map,pos=F:Call(C_Map and C_Map.GetWorldPosFromMapPos,node.map,F:Call(CreateVector2D,node.x,node.y))
  local x,y;if pos and pos.GetXY then x,y=F:Call(pos.GetXY,pos)end
  if map==p.map and type(x)=='number'and type(y)=='number'and (p.x-x)^2+(p.y-y)^2<900 then F.character.approaches[node.id]=WorldNavigation:Copy(p)end
 end
end)

SLASH_FLIGHTPATHDRAWSTATUS1='/fpfdebug'
SlashCmdList.FLIGHTPATHDRAWSTATUS=function()
 local map=WorldMapFrame;local shown=map and map:IsShown();local id=map and map.GetMapID and map:GetMapID()
 local message=('Flight path: %s points | map %s (%s) | %s map lines | %s minimap lines | %s'):format(F.path and #F.path.points or 0,tostring(id),shown and 'open'or 'closed',F.mapSegmentsDrawn or 0,F.minimapSegmentsDrawn or 0,F.pathDrawStatus or F.pathStatus or 'No route selected')
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(message)end
end
