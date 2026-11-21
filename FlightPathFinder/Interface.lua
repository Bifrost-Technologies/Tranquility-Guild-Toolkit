local F=FlightPathFinder
local function label(f,text,x,y,w,h)local t=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');t:SetPoint('TOPLEFT',x,y);t:SetSize(w,h or 26);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(text);return t end
local function button(f,text,x,y,w,fn)local b=CreateFrame('Button',nil,f,'BackdropTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(w,28);b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});b:SetBackdropColor(.06,.24,.36,1);b.caption=label(b,text,8,-5,w-16);b:SetScript('OnClick',fn);return b end
function F:Show()
 if not self.db then return end
 if not self.frame then
  local f=CreateFrame('Frame','FlightPathFinderPanel',UIParent,'BackdropTemplate');self.frame=f;f:SetSize(900,700);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true)
  if GetScreenWidth and GetScreenHeight then f:SetScale(math.min(1,(GetScreenWidth()-40)/900,(GetScreenHeight()-40)/700))end
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});f:SetBackdropColor(.025,.045,.075,1)
  local logo=f:CreateTexture(nil,'ARTWORK');logo:SetSize(40,40);logo:SetPoint('TOPLEFT',24,-16);logo:SetTexture('Interface\\AddOns\\FlightPathFinder\\FlightPathIcon')
  label(f,'FLIGHT PATH FINDER',78,-24,740,32):SetTextColor(.4,.75,1);button(f,'X',842,-20,34,function()f:Hide()end);table.insert(UISpecialFrames,'FlightPathFinderPanel')
  label(f,'Your faction’s flight masters · Native client coordinates · Large world-map markers',24,-66,850,30)
  label(f,'Search town / region',24,-112,190);self.search=CreateFrame('EditBox',nil,f,'InputBoxTemplate');self.search:SetPoint('TOPLEFT',220,-104);self.search:SetSize(650,28);self.search:SetAutoFocus(false);self.search:SetMaxLetters(100);self.search:SetScript('OnTextChanged',function()self.page=1;self:Refresh()end);self.search:SetScript('OnEscapePressed',function(b)b:ClearFocus()end)
  self.options={};for i,pair in ipairs({{'enabled','Large map markers'},{'neutral','Include neutral hubs'},{'labels','Show map labels'}})do local key=pair[1];local box=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate');self.options[key]=box;box:SetSize(26,26);box:SetPoint('TOPLEFT',24+(i-1)*290,-152);label(f,pair[2],60+(i-1)*290,-157,240);box:SetScript('OnClick',function(b)self.db[key]=b:GetChecked()==true;self:Render();self:Refresh()end)end
  self.rows={};for i=1,7 do local row={};self.rows[i]=row;row.text=label(f,'',24,-204-(i-1)*52,620,46);row.button=button(f,'Route / show map',680,-204-(i-1)*52,190,function()self:Locate(row.node)end)end
  button(f,'Previous',24,-586,185,function()self.page=math.max(1,(self.page or 1)-1);self:Refresh()end);button(f,'Next',224,-586,185,function()self.page=(self.page or 1)+1;self:Refresh()end)
  button(f,'Marker size',424,-586,190,function()self.db.size=self.db.size>=62 and 26 or self.db.size+6;self:Render();self:Refresh()end)
  button(f,'Rescan flight points',630,-586,240,function()self:Rescan();self:Refresh()end)
  self.info=label(f,'',24,-634,850,52)
  button(f,'Route guidance',24,-550,185,function()self:SetPathingEnabled(not self.db.pathing)end)
  button(f,'Navigation status',680,-550,190,function()if WorldNavigation then WorldNavigation:Show()end end)
 end
 self.frame:Show();self:Refresh()
end
function F:Refresh()
 if not self.db or not self.frame or not self.frame:IsShown()then return end
 local list=self:List(self.search:GetText());self.page=math.max(1,math.min(self.page or 1,math.max(1,math.ceil(#list/7))))
 for i,row in ipairs(self.rows)do local n=list[(self.page-1)*7+i];row.node=n;row.text:SetText(n and(n.name..(n.faction==0 and ' · Neutral'or n.faction==1 and ' · Horde'or ' · Alliance')..'\n'..(n.zone or 'Map '..n.map)..' · '..self:DiscoveryText(n)..(' · %.1f, %.1f'):format(n.x*100,n.y*100))or '');row.button:SetEnabled(n~=nil)end
 for key,box in pairs(self.options)do box:SetChecked(self.db[key]==true)end
 self.info:SetText(#list..' flight points · '..self.db.size..'px · Pathing '..(self.db.pathing and 'ON'or 'OFF')..'\n'..(self.pathStatus or self.status or 'Loading native flight-node coordinates…'))
end
