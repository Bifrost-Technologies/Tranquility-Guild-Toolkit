local TG=_G.Tranquility
local E={pool={},defaults={enabled=true,players=true,npcs=true,names=true,boxes=true,icons=true,target=true}}
TG.enemyMarkers=E
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function read(fn,...)
 if type(fn)~='function'then return nil end
 local ok,v=pcall(fn,...);if ok and public(v)then return v end
end
function E:Config()
 if not TranquilityDB then return nil end
 TranquilityDB.enemyMarkers=type(TranquilityDB.enemyMarkers)=='table'and TranquilityDB.enemyMarkers or {}
 for k,v in pairs(self.defaults)do if TranquilityDB.enemyMarkers[k]==nil then TranquilityDB.enemyMarkers[k]=v end end
 return TranquilityDB.enemyMarkers
end
function E:Kind(unit)
 if read(UnitExists,unit)~=true or read(UnitCanAttack,'player',unit)~=true or read(UnitIsDeadOrGhost,unit)==true then return nil end
 local player=read(UnitIsPlayer,unit)
 if player==nil then return nil end
 return player and 'players'or 'npcs'
end
function E:Hide()
 for _,f in ipairs(self.pool)do f:Hide()end
end
function E:Overlay(index)
 local f=self.pool[index];if f then return f end
 f=CreateFrame('Frame',nil,UIParent);self.pool[index]=f;f:EnableMouse(false);f:SetFrameStrata('HIGH');f:SetSize(150,36)
 f.edges={}
 for i=1,4 do local t=f:CreateTexture(nil,'OVERLAY');t:SetTexture('Interface\\Buttons\\WHITE8X8');f.edges[i]=t end
 f.edges[1]:SetPoint('TOPLEFT');f.edges[1]:SetPoint('TOPRIGHT');f.edges[1]:SetHeight(2)
 f.edges[2]:SetPoint('BOTTOMLEFT');f.edges[2]:SetPoint('BOTTOMRIGHT');f.edges[2]:SetHeight(2)
 f.edges[3]:SetPoint('TOPLEFT');f.edges[3]:SetPoint('BOTTOMLEFT');f.edges[3]:SetWidth(2)
 f.edges[4]:SetPoint('TOPRIGHT');f.edges[4]:SetPoint('BOTTOMRIGHT');f.edges[4]:SetWidth(2)
 f.label=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');f.label:SetPoint('BOTTOM',f,'TOP',0,4);f.label:SetWidth(230)
 f.icon=f:CreateTexture(nil,'OVERLAY');f.icon:SetPoint('RIGHT',f,'LEFT',-5,0);f.icon:SetSize(22,22);f.icon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcon_8')
 return f
end
function E:Update()
 self:Hide();if not TranquilityAccess or not TranquilityAccess:Allowed()then return end;local c=self:Config();if not c or not c.enabled then return end
 local plates=read(C_NamePlate and C_NamePlate.GetNamePlates)
 if type(plates)~='table'then self.status='Nameplate API unavailable.';return end
 local count,players,npcs=0,0,0
 for i=1,math.min(#plates,100)do
  local plate=plates[i]
  if public(plate)and plate and not (plate.IsForbidden and plate:IsForbidden())and read(plate.IsShown,plate)==true then
   local unit=plate.namePlateUnitToken
   if public(unit)and type(unit)=='string'then
    local kind=self:Kind(unit)
    if kind and c[kind]then
     count=count+1;if kind=='players'then players=players+1 else npcs=npcs+1 end
     local f=self:Overlay(count);f:ClearAllPoints();f:SetPoint('CENTER',plate,'CENTER',0,0)
     local selected=c.target and read(UnitIsUnit,unit,'target')==true
     local focused=c.focus and read(UnitIsUnit,unit,'focus')==true
     local r,g,b=1,kind=='players'and .15 or .65,kind=='players'and .25 or .1
     if focused then r,g,b=.8,.4,1 end
     if selected then r,g,b=.3,.9,1 end
     for _,edge in ipairs(f.edges)do edge:SetVertexColor(r,g,b,1);if c.boxes then edge:Show()else edge:Hide()end end
     local name=read(UnitName,unit);name=type(name)=='string'and name:gsub('[%c|]','')or 'Unknown'
     local distance=c.ranges and self.Distance and self:Distance(unit)
     f.label:SetText((selected and 'TARGET | 'or focused and 'FOCUS | 'or '')..(kind=='players'and 'PLAYER: 'or 'NPC: ')..name..(distance and (' ~%.0f yd'):format(distance)or ''));f.label:SetTextColor(r,g,b)
     if c.names then f.label:Show()else f.label:Hide()end
     if c.icons then f.icon:Show()else f.icon:Hide()end
     f:Show()
    end
   end
  end
 end
 self.status=('%d enemy players / %d enemy NPCs currently exposed by nameplates'):format(players,npcs)
end
function E:Toggle(key)
 local c=self:Config();if not c then return end;c[key]=not c[key];self:Update();self:Refresh()
end
function E:Refresh()
 local c=self:Config();if not c or not self.frame then return end
 for key,button in pairs(self.buttons)do button:SetText((c[key]and '[ON] 'or '[OFF] ')..self.labels[key])end
 self.info:SetText(c.enabled and (self.status or 'Waiting for nameplates.')or 'All enemy highlight effects hidden.')
end
function E:Show()
 if not TranquilityAccess or not TranquilityAccess:Require()then return end
 if not self:Config()then return end
 if not self.frame then
  local U=TG.featureUI;self.frame=U.Panel('TranquilityEnemyMarkers','ENEMY NAMEPLATE HIGHLIGHTS',660,545)
  U.Label(self.frame,'Enemy players: red | Enemy NPCs: amber | Current target: cyan\nLocal visual icons do not change party raid markers. Game nameplate range and visibility apply.',24,-60,610,50)
  self.labels={enabled='All effects',players='Enemy players',npcs='Enemy NPCs',boxes='Outline boxes',names='Names and type',icons='Skull icons',target='Target emphasis',focus='Focus emphasis',ranges='Range labels'};self.buttons={}
  for i,key in ipairs({'enabled','players','npcs','boxes','names','icons','target','focus','ranges'})do
   self.buttons[key]=U.Button(self.frame,'',24+((i-1)%2)*310,-125-math.floor((i-1)/2)*48,290,function()E:Toggle(key)end)
  end
  U.Label(self.frame,'Enable enemy nameplates in game settings (normally V). These effects highlight exposed nameplates, not distant or hidden mob models. /tqenemies hide instantly hides effects; /tqenemies on restores them.',24,-425,610,60)
  self.info=U.Label(self.frame,'',24,-495,610,30)
 end
 self.frame:Show();self:Update();self:Refresh()
end
SLASH_TQENEMIES1='/tqenemies'
SlashCmdList.TQENEMIES=function(message)
 if not TranquilityAccess or not TranquilityAccess:Require()then return end
 local c=E:Config();if not c then return end
 if message=='hide'or message=='off'then c.enabled=false;E:Hide();E:Refresh()
 elseif message=='on'then c.enabled=true;E:Update();E:Refresh()
 elseif message=='toggle'then E:Toggle('enabled')else E:Show()end
end
local tick=CreateFrame('Frame');local elapsed=0
tick:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
 local ok=pcall(E.Update,E)
 if not ok then E:Hide();E.status='Highlight update unavailable; restricted nameplates skipped.'end
 if E.frame and E.frame:IsShown()then E:Refresh()end
end)
