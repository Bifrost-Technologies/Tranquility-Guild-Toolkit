local F=FlightPathFinder
function F:RenderMinimapPath()
 self.minimapSegmentsDrawn=0
 self.miniLines=self.miniLines or {};for _,line in ipairs(self.miniLines)do line:Hide()end
 if not self.db or not self.db.pathing or not self.path or not Minimap or not WorldNavigation then return end
 if not self.minimapRouteOverlay then self.minimapRouteOverlay=CreateFrame('Frame',nil,Minimap);self.minimapRouteOverlay:SetAllPoints(Minimap);self.minimapRouteOverlay:EnableMouse(false)end
 local overlay=self.minimapRouteOverlay;overlay:SetFrameLevel(Minimap:GetFrameLevel()+20);if not overlay.CreateLine then return end
 local position=WorldNavigation:Position();if not position then return end
 local radius=self:Call(C_Minimap and C_Minimap.GetViewRadius)
 if type(radius)~='number'or radius<=0 then
  local zoom=self:Call(Minimap.GetZoom,Minimap)or 0
  -- Native minimap outdoor yard diameters; unsupported zoom values skip drawing.
  local indoors=self:Call(IsIndoors)==true
  local diameters=indoors and {300,240,180,120,80,50}or {466.6667,400,333.3333,266.6667,200,133.3333}
  radius=diameters[zoom+1]and diameters[zoom+1]/2
 end
 if not radius then return end
 local width,height=Minimap:GetWidth(),Minimap:GetHeight();local scale=math.min(width,height)/2/radius
 local rotate=self:Call(GetCVar,'rotateMinimap')=='1';local angle=rotate and(self:Call(GetPlayerFacing)or 0)or 0
 local function project(p)
  if p.map~=position.map then return end
  -- WoW world x points north; y points west. Rotate into minimap axes.
  local east,north=position.y-p.y,p.x-position.x
  return (east*math.cos(angle)+north*math.sin(angle))*scale,(-east*math.sin(angle)+north*math.cos(angle))*scale
 end
 local index=0;local limit=math.min(width,height)/2-3
 for i=math.max(2,self.pathIndex or 2),math.min(#self.path.points,(self.pathIndex or 2)+150)do
  local ax,ay=project(self.path.points[i-1]);local bx,by=project(self.path.points[i])
  if ax and bx then
   -- Clip segments to the circular minimap; never place route lines outside it.
   local dx,dy=bx-ax,by-ay;local a=dx*dx+dy*dy;local b=2*(ax*dx+ay*dy);local c=ax*ax+ay*ay-limit*limit
   local first,last=0,1
   if a>0 then local discriminant=b*b-4*a*c
    if discriminant<0 then first,last=1,0 else local root=math.sqrt(discriminant);first=math.max(0,(-b-root)/(2*a));last=math.min(1,(-b+root)/(2*a))end
   elseif c>0 then first,last=1,0 end
   if first<=last then
    index=index+1;local line=self.miniLines[index]
    if not line then line=overlay:CreateLine(nil,'OVERLAY');self.miniLines[index]=line end
    line:SetThickness(2);line:SetColorTexture(.15,.8,1,.9)
    line:SetStartPoint('CENTER',Minimap,ax+dx*first,ay+dy*first);line:SetEndPoint('CENTER',Minimap,ax+dx*last,ay+dy*last);line:Show()
   end
  end
 end
 self.minimapSegmentsDrawn=index
end
local update=F.UpdatePath
function F:UpdatePath(...)local result=update(self,...);self:RenderMinimapPath();return result end
local stop=F.StopPath
function F:StopPath(...)local result=stop(self,...);for _,line in ipairs(self.miniLines or {})do line:Hide()end;return result end
