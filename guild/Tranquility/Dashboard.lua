-- Shared dashboard shell; each addon ships its own copy and owns its frames.
local addon,namespace=...
local O=namespace and namespace.featureUI and namespace or Tranquility
local D={};O.dashboardUI=D
local function text(parent,value,x,y,w,h,font)
 local t=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');t:SetPoint('TOPLEFT',x,y);t:SetSize(w,h);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(value);return t
end
local function skin(frame,depth)
 if depth>8 then return end
 if frame.IsObjectType and frame:IsObjectType('Button')and not frame:IsObjectType('CheckButton')and frame.GetText and frame:GetText()and frame:GetText()~=''and not(frame.IsProtected and frame:IsProtected())then
  frame:SetNormalTexture('Interface\\Buttons\\WHITE8X8');frame:GetNormalTexture():SetVertexColor(.055,.22,.3,1)
  frame:SetPushedTexture('Interface\\Buttons\\WHITE8X8');frame:GetPushedTexture():SetVertexColor(.08,.36,.45,1)
 end
 if frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do skin(child,depth+1)end end
end
function D:New(name,title)
 local d=setmetatable({pages={},order={},buttons={}},{__index=self})
 local f=CreateFrame('Frame',name,UIParent,'BackdropTemplate');d.frame=f;f:SetSize(1180,730);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});f:SetBackdropColor(.025,.033,.045,.99);f:SetBackdropBorderColor(.12,.36,.46,1)
 d.brand=text(f,title,18,-17,1050,26,'GameFontNormalLarge');d.brand:SetTextColor(.15,.8,1)
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT');drag:SetPoint('TOPRIGHT',-45,0);drag:SetHeight(48);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton');drag:SetScript('OnDragStart',function()f:StartMoving()end);drag:SetScript('OnDragStop',function()f:StopMovingOrSizing()end)
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4);close:SetScript('OnClick',function()f:Hide()end)
 table.insert(UISpecialFrames,name)
 local sidebar=CreateFrame('Frame',nil,f,'BackdropTemplate');sidebar:SetPoint('TOPLEFT',12,-52);sidebar:SetPoint('BOTTOMLEFT',12,36);sidebar:SetWidth(198);sidebar:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});sidebar:SetBackdropColor(.035,.055,.07,1)
 local nav=CreateFrame('ScrollFrame',nil,sidebar,'UIPanelScrollFrameTemplate');nav:SetPoint('TOPLEFT',6,-8);nav:SetPoint('BOTTOMRIGHT',-24,8)
 local list=CreateFrame('Frame',nil,nav);list:SetSize(165,1);nav:SetScrollChild(list);d.list=list
 d.title=text(f,'',228,-57,910,26,'GameFontNormalLarge');d.title:SetTextColor(.3,.8,1)
 d.subtitle=text(f,'',228,-88,910,34)
 local viewport=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');viewport:SetPoint('TOPLEFT',222,-126);viewport:SetPoint('BOTTOMRIGHT',-34,38);d.viewport=viewport
 local body=CreateFrame('Frame',nil,viewport);body:SetSize(924,560);viewport:SetScrollChild(body);d.body=body
 d.message=text(body,'',18,-24,865,300)
 d.footer=text(f,'Select a page on the left. Scroll within larger pages.',228,-704,905,18);d.footer:SetTextColor(.45,.6,.65)
 f:SetScript('OnShow',function()f:SetScale(math.min(1,math.max(.4,(GetScreenWidth()-32)/1180),math.max(.4,(GetScreenHeight()-32)/730)))end)
 f:Hide();return d
end
function D:Add(id,label,description,open)
 self.pages[id]={label=label,description=description,open=open};self.order[#self.order+1]=id
 local b=CreateFrame('Button',nil,self.list,'BackdropTemplate');b:SetSize(165,29);b:SetPoint('TOPLEFT',0,-(#self.order-1)*33);b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});b:SetBackdropColor(.04,.1,.13,1)
 b.caption=text(b,label,9,-7,150,18);b:SetScript('OnClick',function()self:Select(id)end);b:SetScript('OnEnter',function()if self.active~=id then b:SetBackdropColor(.06,.22,.28,1)end end);b:SetScript('OnLeave',function()b:SetBackdropColor(self.active==id and .06 or .04,self.active==id and .3 or .1,self.active==id and .39 or .13,1)end)
 self.buttons[id]=b;self.list:SetHeight(#self.order*33)
end
function D:Select(id)
 local page=self.pages[id];if not page then return false end
 if self.active==id and self.current then self.frame:Show();return true end
 local previous=self.current
 -- Hide before opening: legacy pages may hide other windows in their Show method.
 if previous then previous:Hide()end
 self.current=nil;self.active=id;self.title:SetText(page.label);self.subtitle:SetText(page.description or '')
 self.message:Hide();self.frame:Show();self.viewport:SetVerticalScroll(0)
 for key,b in pairs(self.buttons)do local selected=key==id;b:SetBackdropColor(selected and .06 or .04,selected and .3 or .1,selected and .39 or .13,1);b.caption:SetTextColor(selected and .4 or .75,selected and .95 or .83,1)end
 local ok,panel,reason=pcall(page.open)
 if not ok then reason='Could not open this page: '..tostring(panel);panel=nil end
 if not panel then self.body:SetHeight(560);self.message:SetText(reason or 'Enable the required addon in the character-selection AddOns menu, then reload.');self.message:Show();return false end
 if panel==self.frame then return false end
 local function protected(frame)
  if frame.IsProtected and frame:IsProtected()then return true end
  if frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do if protected(child)then return true end end end
  return false
 end
 if protected(panel)then
  self.body:SetHeight(560);self.message:SetText('This page uses protected WoW controls and opens in its own window. The dashboard can always be closed.');self.message:Show()
  return true
 end
 local w,h=panel:GetWidth(),panel:GetHeight();local width=self.viewport:GetWidth();if width<1 then width=924 end
 local scale=math.min(1,(width-8)/math.max(1,w));panel:SetParent(self.body);panel:ClearAllPoints();panel:SetScale(scale);panel:SetPoint('TOPLEFT',self.body,'TOPLEFT',0,0);panel:SetClampedToScreen(false);panel:SetMovable(false);panel:RegisterForDrag();panel:SetScript('OnDragStart',nil);panel:SetScript('OnDragStop',nil);panel:SetFrameStrata('DIALOG');panel:SetFrameLevel(self.body:GetFrameLevel()+2)
 self.body:SetWidth(width);self.body:SetHeight(math.max(self.viewport:GetHeight(),h*scale+8));self.current=panel;skin(panel,0);panel:Show();return true
end
function D:Overview(lines)
 local f=CreateFrame('Frame',nil,UIParent);f:SetSize(900,540)
 text(f,'WELCOME',24,-22,850,28,'GameFontNormalLarge'):SetTextColor(.2,.8,1)
 text(f,lines,24,-72,840,390,'GameFontHighlight');f:Hide();return f
end
