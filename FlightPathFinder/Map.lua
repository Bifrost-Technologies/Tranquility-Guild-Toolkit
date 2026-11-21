local F=FlightPathFinder
function F:Render()
 local map=WorldMapFrame
 if not self.db or not self.db.enabled or not map or not map.IsShown or not map:IsShown()or not map.GetCanvas or map.IsForbidden and map:IsForbidden()then for _,pin in ipairs(self.pins)do pin:Hide()end;return end
 local canvas=map:GetCanvas();if not canvas or canvas.IsForbidden and canvas:IsForbidden()then return end
 local id=map:GetMapID();local width,height=self:Call(canvas.GetWidth,canvas),self:Call(canvas.GetHeight,canvas)
 if not self:Number(width,1,100000)or not self:Number(height,1,100000)then return end
 local count=0
 for _,node in ipairs(self:List())do local x,y=self:Position(node,id)
  if x and self:Number(x,0,1)and self:Number(y,0,1)and count<200 then
   count=count+1;local pin=self.pins[count]
   if not pin then
    pin=CreateFrame('Button',nil,canvas);self.pins[count]=pin;pin:RegisterForClicks('LeftButtonUp');pin:EnableMouse(true)
    pin.icon=pin:CreateTexture(nil,'ARTWORK');pin.icon:SetAllPoints()
    pin.caption=pin:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');pin.caption:SetPoint('TOP',pin,'BOTTOM',0,-1);pin.caption:SetWidth(160)
    pin:SetScript('OnEnter',function(p)
     if not GameTooltip or not p.node then return end;local n=p.node;GameTooltip:SetOwner(p,'ANCHOR_RIGHT');GameTooltip:SetText(n.name)
     GameTooltip:AddLine('Flight master / departure point',.6,.85,1);GameTooltip:AddLine((n.zone or 'Map '..n.map)..(' · %.1f, %.1f'):format(n.x*100,n.y*100),1,1,1)
     local known=self.character.nodes[n.id];GameTooltip:AddLine(self:DiscoveryText(n),1,.85,.35)
     GameTooltip:AddLine(n.faction==0 and 'Neutral flight hub'or (n.faction==1 and 'Horde flight point'or 'Alliance flight point'),.6,.85,1);GameTooltip:AddLine('Click to locate. Visit the flight master to unlock or fly.',.8,.8,.8,true);GameTooltip:Show()
    end);pin:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
    pin:SetScript('OnClick',function(p)if p.node then self:Locate(p.node)end end)
   end
   pin.node=node;pin:SetParent(canvas);pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',x*width,-y*height);pin:SetSize(self.db.size,self.db.size)
   local atlas=node.atlas; -- Preserve the client-provided flight marker artwork.
   local applied=false;if atlas and pin.icon.SetAtlas then local ok,value=pcall(pin.icon.SetAtlas,pin.icon,atlas);applied=ok and value~=false end
   if not applied then pin.icon:SetTexture('Interface\\AddOns\\FlightPathFinder\\FlightPathIcon')end
   pin.icon:SetVertexColor(1,1,1)
   pin.caption:SetText(self.db.labels and node.name or '');pin:SetAlpha(self.selected==node.id and 1 or .92);pin:Show()
  end
 end
 for i=count+1,#self.pins do self.pins[i]:Hide()end
end
