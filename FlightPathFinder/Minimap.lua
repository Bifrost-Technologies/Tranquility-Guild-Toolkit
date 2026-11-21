local F=FlightPathFinder
function F:SetMarkersEnabled(on)
 self.db.enabled=on==true;self:Render();self:Refresh();self:RefreshMinimap()
end
function F:SetPathingEnabled(on)
 self.db.pathing=on==true
 if not self.db.pathing and self.StopPath then self:StopPath('Pathing disabled.')
 elseif self.db.pathing then
  if self.selected and self.nodes[self.selected] and self.RouteTo then self:RouteTo(self.nodes[self.selected])
  else self.pathStatus='Select a flight master in the directory or click its map marker to draw a route.';self:Show() end
 end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('Flight paths: '..(self.pathStatus or 'Pathing enabled. Select a destination.'))end
 self:RefreshMinimap();self:Refresh()
end
function F:RefreshMinimap()
 if self.minimapChecks then
  self.minimapChecks.markers:SetChecked(self.db.enabled==true)
  self.minimapChecks.pathing:SetChecked(self.db.pathing==true)
 end
end
function F:PlaceMinimap()
 if not self.minimap then return end
 local angle=math.rad(self.db.minimapAngle or 225)
 self.minimap:ClearAllPoints();self.minimap:SetPoint('CENTER',Minimap,'CENTER',math.cos(angle)*82,math.sin(angle)*82)
end
function F:EnsureMinimap()
 if not self.db or not Minimap or self.minimap then return end
 local b=CreateFrame('Button','FlightPathFinderMinimap',Minimap);self.minimap=b;b.dragged=false
 b:SetSize(30,30);b:SetFrameStrata('MEDIUM');b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton')
 local icon=b:CreateTexture(nil,'ARTWORK');icon:SetAllPoints();icon:SetTexture('Interface\\AddOns\\FlightPathFinder\\FlightPathIcon')
 local border=b:CreateTexture(nil,'OVERLAY');border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder');border:SetSize(52,52);border:SetPoint('TOPLEFT',0,0)
 b:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight');self:PlaceMinimap()
 local menu=CreateFrame('Frame','FlightPathFinderMinimapMenu',UIParent,'BackdropTemplate');self.minimapMenu=menu
 menu:SetSize(265,90);menu:SetPoint('TOPRIGHT',b,'BOTTOMLEFT',0,-4);menu:SetFrameStrata('DIALOG');menu:SetClampedToScreen(true);menu:EnableMouse(true)
 menu:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});menu:SetBackdropColor(.035,.045,.065,1);menu:SetBackdropBorderColor(.2,.55,.8,1)
 self.minimapChecks={}
 for i,entry in ipairs({{'markers','Enable markers'},{'pathing','Enable route guidance'}})do
  local key=entry[1];local box=CreateFrame('CheckButton',nil,menu,'UICheckButtonTemplate');box:SetSize(26,26);box:SetPoint('TOPLEFT',12,-12-(i-1)*34)
  local text=box:CreateFontString(nil,'OVERLAY','GameFontHighlight');text:SetPoint('LEFT',box,'RIGHT',4,0);text:SetText(entry[2]);text:SetTextColor(.4,.75,1)
  box:SetScript('OnClick',function(s)if key=='markers'then self:SetMarkersEnabled(s:GetChecked()==true)else self:SetPathingEnabled(s:GetChecked()==true)end end)
  self.minimapChecks[key]=box
 end
 table.insert(UISpecialFrames,'FlightPathFinderMinimapMenu');menu:Hide()
 b:SetScript('OnClick',function(_,mouse)
  if b.dragged then b.dragged=false;return end
  if mouse=='RightButton'then menu:Hide();self:Show()
  elseif menu:IsShown()then menu:Hide()else self:RefreshMinimap();menu:Show()end
 end)
 b:SetScript('OnDragStart',function()
  b.dragged=true;menu:Hide()
  b:SetScript('OnUpdate',function()
   local x,y=self:Call(GetCursorPosition);local cx,cy=self:Call(Minimap.GetCenter,Minimap);local scale=self:Call(Minimap.GetEffectiveScale,Minimap)
   if not x or not y or not cx or not cy or not scale or scale<=0 then return end
   local dx,dy=x/scale-cx,y/scale-cy
   local angle=math.atan2 and math.atan2(dy,dx)or (dx==0 and (dy>=0 and math.pi/2 or -math.pi/2)or math.atan(dy/dx)+(dx<0 and math.pi or 0))
   self.db.minimapAngle=math.deg(angle);self:PlaceMinimap()
  end)
 end)
 b:SetScript('OnDragStop',function()b:SetScript('OnUpdate',nil)end)
 b:SetScript('OnEnter',function()
  if not GameTooltip then return end
  GameTooltip:SetOwner(b,'ANCHOR_LEFT');GameTooltip:SetText('Flight Path Finder');GameTooltip:AddLine('Click: markers / pathing\nRight-click: flight directory\nDrag: move icon',.4,.75,1,true);GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
end
