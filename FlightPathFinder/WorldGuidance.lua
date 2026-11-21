local F=FlightPathFinder
local function call(fn,...)
 if type(fn)~='function'then return end
 local ok,a,b=pcall(fn,...)
 if not ok or (issecretvalue and issecretvalue(a))then return end
 return a,b
end
local function coordinates(point)
 if type(point)~='table'or not point.position or not point.position.GetXY then return end
 local x,y=call(point.position.GetXY,point.position)
 if type(x)=='number'and type(y)=='number'then return point.uiMapID,x,y end
end
function F:WorldWaypointIsOurs()
 if not self.worldWaypoint then return false end
 local id,x,y=coordinates(call(C_Map and C_Map.GetUserWaypoint))
 return id==self.worldWaypoint.map and x and math.abs(x-self.worldWaypoint.x)<.00001 and math.abs(y-self.worldWaypoint.y)<.00001
end
function F:ClearWorldGuidance()
 if self.spiritFrame then self.spiritFrame:Hide()end
 if self:WorldWaypointIsOurs()then
  if self.previousWorldWaypoint then
   call(C_Map.SetUserWaypoint,self.previousWorldWaypoint)
   call(C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint,self.previousSuperTrack==true)
  else call(C_Map.ClearUserWaypoint)end
 end
 self.worldWaypoint=nil;self.previousWorldWaypoint=nil;self.worldWaypointRoute=nil
end
function F:UpdateSpiritGuide()
 local anchor=call(C_Navigation and C_Navigation.GetFrame)
 if not anchor then self.spiritGuideStatus='Client exposes no native world-navigation anchor for the spirit guide.'end
 if not anchor or (anchor.IsForbidden and anchor:IsForbidden())or not self.worldWaypoint or self.db.spiritGuide=='off'then if self.spiritFrame then self.spiritFrame:Hide()end;return end
 if not self.spiritFrame then
  local f=CreateFrame('Frame',nil,UIParent);self.spiritFrame=f;f:SetSize(84,100);f:SetFrameStrata('HIGH');f:EnableMouse(false)
  f.glow=f:CreateTexture(nil,'ARTWORK');f.glow:SetSize(80,80);f.glow:SetPoint('CENTER',0,3);f.glow:SetTexture('Interface\\Cooldown\\star4');f.glow:SetBlendMode('ADD');f.glow:SetVertexColor(.05,.65,1,.8)
  f.core=f:CreateTexture(nil,'OVERLAY');f.core:SetSize(28,28);f.core:SetPoint('CENTER',0,3);f.core:SetTexture('Interface\\Cooldown\\star4');f.core:SetBlendMode('ADD');f.core:SetVertexColor(.6,.95,1,1)
  f.wolf=CreateFrame('PlayerModel',nil,f);f.wolf:SetAllPoints();f.wolf:SetAlpha(.6);f.wolf:EnableMouse(false)
  f.wolf:SetScript('OnModelLoaded',function(model)model:SetModelScale(.7);model:SetFacing(.6)end)
  f.label=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');f.label:SetPoint('TOP',f,'BOTTOM',0,3);f.label:SetTextColor(.3,.85,1)
  f:SetScript('OnUpdate',function(_,elapsed)f.elapsed=(f.elapsed or 0)+elapsed;local pulse=.65+.3*math.sin(f.elapsed*3);f.glow:SetAlpha(pulse);f.core:SetAlpha(.8+.2*math.sin(f.elapsed*5));f:SetAlpha(.8+.15*math.sin(f.elapsed*2))end)
 end
 local f=self.spiritFrame;f:ClearAllPoints();f:SetPoint('CENTER',anchor,'CENTER',0,22)
 local wolf=self.db.spiritGuide=='wolf'
 f.wolf:SetShown(wolf);f.core:SetShown(not wolf);f.glow:Show()
 if wolf and not f.wolfRequested then f.wolfRequested=true;call(f.wolf.SetModel,f.wolf,'Creature\\Wolf\\Wolf.m2')end
 f.label:SetText(wolf and 'Spirit guide'or 'Follow the wisp');f:Show();self.spiritGuideStatus='Spirit guide attached to the native upcoming-waypoint anchor.'
end
function F:WorldGuidePoint()
 local points=self.path and self.path.points;local player=WorldNavigation and WorldNavigation:Position()
 if not points or #points<2 or not player then return end
 if self.spiritArcRoute~=self.path then
  self.spiritArcRoute=self.path;self.spiritArcs={0};self.spiritGuideArc=nil;self.spiritPlayerArc=nil;self.spiritSampleAt=nil
  for i=2,#points do local a,b=points[i-1],points[i];self.spiritArcs[i]=self.spiritArcs[i-1]+math.sqrt((b.x-a.x)^2+(b.y-a.y)^2)end
 end
 local arcs=self.spiritArcs;local index=self.route==self.path and self.routeIndex or self.pathIndex or 2
 local first=math.max(2,index-4);local best,bestDistance,bestFraction
 for i=first,#points do local a,b=points[i-1],points[i]
  if a.map==player.map and b.map==player.map then
   local dx,dy=b.x-a.x,b.y-a.y;local length=dx*dx+dy*dy
   local t=length>0 and math.max(0,math.min(1,((player.x-a.x)*dx+(player.y-a.y)*dy)/length))or 0
   local x,y=a.x+dx*t,a.y+dy*t;local distance=(player.x-x)^2+(player.y-y)^2
   if not bestDistance or distance<bestDistance then best,bestDistance,bestFraction=i,distance,t end
  end
 end
 if not best then return end
 local playerArc=arcs[best-1]+(arcs[best]-arcs[best-1])*bestFraction
 local lead=math.max(3,math.min(80,tonumber(self.db.spiritLeadYards)or 12))
 local now=GetTime();local dt=self.spiritSampleAt and math.max(.001,math.min(.25,now-self.spiritSampleAt))or .1
 local nativeSpeed=call(GetUnitSpeed,'player');local observedSpeed=self.spiritPlayerArc and math.max(0,(playerArc-self.spiritPlayerArc)/dt)or 0
 local speed=math.max(type(nativeSpeed)=='number'and nativeSpeed or 0,observedSpeed)
 local current=self.spiritGuideArc
 if not current or playerArc-current>math.max(40,lead*3)then
  -- Initial placement, or recovery only when genuinely far behind.
  current=playerArc+lead
 else
  local gap=current-playerArc;local error=lead-gap
  -- Match player speed at the requested gap; accelerate as the gap closes.
  local running=math.max(0,speed+error*2)
  if gap<lead*.5 then running=math.max(running,speed*1.8+8)end
  current=current+running*dt
 end
 current=math.min(arcs[#points],math.max(0,current))
 self.spiritGuideArc=current;self.spiritPlayerArc=playerArc;self.spiritSampleAt=now
 local lo,hi=2,#points
 while lo<hi do local mid=math.floor((lo+hi)/2);if arcs[mid]<current then lo=mid+1 else hi=mid end end
 local a,b=points[lo-1],points[lo];local length=arcs[lo]-arcs[lo-1];local t=length>0 and math.max(0,math.min(1,(current-arcs[lo-1])/length))or 1
 return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t,map=a.map}
end
function F:UpdateWorldGuidance()
 if not self.db or not self.db.pathing or self.db.worldGuidance==false or not self.path then self:ClearWorldGuidance();return end
 if not(C_Map and C_Map.SetUserWaypoint and C_Map.GetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint)then
  self.worldGuidanceStatus='Native in-world waypoint API unavailable on this client.';return
 end
 if self.worldWaypointRoute~=self.path then self:ClearWorldGuidance();self.worldGuidanceSuspended=false;self.worldWaypointRoute=self.path end
 if self.worldGuidanceSuspended then return end
 if self.worldWaypoint and not self:WorldWaypointIsOurs()then
  self.worldGuidanceSuspended=true;self.worldWaypoint=nil;self.worldGuidanceStatus='World waypoint changed manually; route world guidance paused.';return
 end
 local map=call(C_Map.GetBestMapForUnit,'player');if not map then return end
 if C_Map.CanSetUserWaypointOnMap and call(C_Map.CanSetUserWaypointOnMap,map)~=true then self.worldGuidanceStatus='Native world waypoints are not supported on the current map.';return end
 local point=self:WorldGuidePoint();if not point then return end
 local id,pos=call(C_Map.GetMapPosFromWorldPos,point.map,call(CreateVector2D,point.x,point.y),map)
 if id~=map or not pos or not pos.GetXY then return end
 local x,y=call(pos.GetXY,pos);if type(x)~='number'or type(y)~='number'or x<0 or x>1 or y<0 or y>1 then return end
 if self.worldWaypoint and self.worldWaypoint.map==map and math.abs(self.worldWaypoint.x-x)<.00001 and math.abs(self.worldWaypoint.y-y)<.00001 then self:UpdateSpiritGuide();return end
 if not self.worldWaypoint then self.previousWorldWaypoint=call(C_Map.GetUserWaypoint);self.previousSuperTrack=call(C_SuperTrack.IsSuperTrackingUserWaypoint)end
 local waypoint=call(UiMapPoint.CreateFromCoordinates,map,x,y);if not waypoint then return end
 local ok=pcall(C_Map.SetUserWaypoint,waypoint)
 if not ok then self.worldGuidanceStatus='Client rejected the route world waypoint.';return end
 self.worldWaypoint={map=map,x=x,y=y};call(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
 self:UpdateSpiritGuide()
 self.worldGuidanceStatus='Native route waypoint with spirit guide; not a painted ground line.'
end
local update=F.UpdatePath
function F:UpdatePath(...)local result=update(self,...);self:UpdateWorldGuidance();return result end
local stop=F.StopPath
function F:StopPath(...)self:ClearWorldGuidance();return stop(self,...)end
SLASH_FLIGHTPATHWORLDGUIDANCE1='/fpfworld'
SlashCmdList.FLIGHTPATHWORLDGUIDANCE=function(text)
 text=(text or ''):lower()
 local lead=tonumber(text:match('^lead%s+(%d+)$'))
 if lead then F.db.spiritLeadYards=math.max(3,math.min(80,lead));F:UpdateWorldGuidance()
 elseif text=='wisp'or text=='wolf'then F.db.spiritGuide=text;F.db.worldGuidance=true;F.worldGuidanceSuspended=false;F:UpdateWorldGuidance()
 elseif text=='off'then F.db.worldGuidance=false;F:ClearWorldGuidance()
 elseif text=='on'then F.db.worldGuidance=true;F.worldGuidanceSuspended=false;F:UpdateWorldGuidance()end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage((F.worldGuidanceStatus and (F.worldGuidanceStatus..' '..(F.spiritGuideStatus or '')))or 'Select a route. /fpfworld on, off, wisp, wolf or lead 12.')end
end
-- Position-based lead catches up after sprints or displacement, without a speed cap.
local guideTicker=CreateFrame('Frame');local elapsed=0
guideTicker:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed>=.1 then elapsed=0;if F.db and F.path then F:UpdateWorldGuidance()end end end)
