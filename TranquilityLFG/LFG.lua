local L={prefix="TQLFG1",entries={},queue={},mode="DUNGEON",role="DPS",activities={}}
_G.TranquilityLFG=L
L.modes={"DUNGEON","PVP","ARENA","RBG"}
L.labels={DUNGEON="Dungeons",PVP="Battlegrounds / world PvP",ARENA="Arena planning",RBG="Rated battleground planning"}
L.presets={DUNGEON={"Scarlet Monastery","Ragefire Chasm","The Deadmines","Wailing Caverns","Shadowfang Keep","Blackfathom Deeps","The Stockade","Gnomeregan","Razorfen Kraul","Razorfen Downs","Uldaman","Zul'Farrak","Maraudon","Sunken Temple","Blackrock Depths","Lower Blackrock Spire","Upper Blackrock Spire","Dire Maul","Stratholme","Scholomance"},PVP={"Warsong Gulch","Arathi Basin","Alterac Valley","World PvP"},ARENA={"2v2","3v3","5v5"},RBG={"Rated battleground team"}}
local function value(v)if issecretvalue and issecretvalue(v)then return nil end;return v end
local function clean(s,max)return type(s)=="string"and #s>0 and #s<=max and not s:find("[%c|]")and s end
local function now()return GetServerTime()end
local function identity(n)
 if type(n)~="string"then return ""end
 if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end
 return n:lower()
end
local function mine()return GetUnitName("player",true)end
function L:Allowed()return TranquilityAccess and TranquilityAccess:Allowed()or false end
function L:Notify(text)self.notice=text;self:Refresh()end
function L:Send(parts)
 if not self:Allowed()or #self.queue>=50 then return false end
 local packet=table.concat(parts,"|");if #packet>240 then return false end
 self.queue[#self.queue+1]=packet;return true
end
function L:Publish()
 local e=self.active;if not e then return end
 self:Send({"L",e.mode,e.role,e.activity,e.note,tostring(e.size),tostring(now())})
 self.published=now()
end
function L:Join(mode,activities,role,note,size)
 if not self:Allowed()then self:Notify("This board is only for members of Tranquility.");return false end
 local valid=false;for _,m in ipairs(self.modes)do if m==mode then valid=true end end
 if not valid or (role~="TANK"and role~="HEALER"and role~="DPS")or type(activities)~="table"or #activities<1 or #activities>5 then return false end
 note=note or "";size=tonumber(size or 5)
 if #note>90 or note:find("[%c|]")or not size or size%1~=0 or size<2 or size>40 then return false end
 local names,seen={},{}
 for _,name in ipairs(activities)do name=clean(name,45);if not name or name:find(";",1,true)then return false end
  local key=name:lower();if not seen[key]then names[#names+1]=name;seen[key]=true end
 end
 local activity=table.concat(names,";")
 if #activity>90 then self:Notify("Choose fewer / shorter activities (90 bytes total).");return false end
 if now()-(self.joinedAt or 0)<5 then return false end
 self.joinedAt=now();self.active={mode=mode,role=role,activity=activity,note=note~=""and note or "-",size=size}
 self:Publish();self.entries[identity(mine())]={name=mine(),mode=mode,role=role,activity=activity,note=note,size=size,at=now()}
 self:Notify("Listed to guild addon users. Invite players manually from the matching roster.");return true
end
function L:Leave()
 if self.active then self:Send({"X",tostring(now())})end
 self.active=nil;self.entries[identity(mine())]=nil;self:Notify("You left the guild board.")
end
function L:Receive(text,sender,channel)
 if not self:Allowed()or channel~="GUILD"or not clean(sender,100)or type(text)~="string"or #text>240 or text:find("[%c]")then return end
 local p={};for s in (text.."|"):gmatch("(.-)|")do p[#p+1]=s end
 local who=identity(sender)
 if p[1]=="Q"and #p==1 then
  if self.active and now()-(self.replyAt or 0)>=10 then self.replyAt=now();self:Publish()end;return
 end
 local stamp=tonumber(p[p[1]=="L"and 7 or 2])
 if not stamp or stamp~=stamp or stamp>now()+60 or stamp<now()-180 then return end
 local old=self.entries[who];if old and stamp<old.at then return end
 if p[1]=="X"and #p==2 then self.entries[who]=nil;self:Refresh();return end
 if p[1]~="L"or #p~=7 or not self.labels[p[2]]or (p[3]~="TANK"and p[3]~="HEALER"and p[3]~="DPS")or not clean(p[4],90)or not clean(p[5],90)then return end
 local size=tonumber(p[6]);if not size or size%1~=0 or size<2 or size>40 then return end
 local seen,n={},0;for name in p[4]:gmatch("[^;]+")do if #name>45 then return end;seen[name]=true;n=n+1 end
 if n<1 or n>5 then return end
 local total=0;for _ in pairs(self.entries)do total=total+1 end
 if not old and total>=250 then return end
 self.entries[who]={name=sender,mode=p[2],role=p[3],activity=p[4],note=p[5]=="-"and ""or p[5],size=size,at=stamp}
 self:Refresh()
end
function L:Matches(entry)
 if entry.mode~=self.mode then return false end
 if #self.activities==0 then return true end
 for activity in entry.activity:gmatch("[^;]+")do for _,selected in ipairs(self.activities)do if activity:lower()==selected:lower()then return true end end end
 return false
end
function L:List()
 local list={}
 for who,e in pairs(self.entries)do if now()-e.at>120 then self.entries[who]=nil elseif self:Matches(e)then list[#list+1]=e end end
 table.sort(list,function(a,b)if a.role~=b.role then return a.role<b.role end;return a.name<b.name end)
 return list
end
function L:Invite(who)
 if not self:Allowed()or identity(who)==identity(mine())then return false end
 local e=self.entries[identity(who)];if not e or now()-e.at>120 then return false end
 local api=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
 if api then local ok,result=pcall(api,who);if ok and result~=false then self:Notify("Invitation attempted for "..who.."; acceptance is not confirmed.");return true end end
 self:Notify("Invite API unavailable or blocked. Copy the /invite command below and send it yourself.")
 if self.inviteCommand then self.inviteCommand:SetText("/invite "..who);self.inviteCommand:SetFocus();self.inviteCommand:HighlightText(0,-1)end
 return false
end
local function label(f,text,x,y,w,h)local t=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h or 24);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetText(text);return t end
local function button(f,text,x,y,w,fn)local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28);b:SetText(text);b:SetScript("OnClick",fn);return b end
local function edit(f,text,x,y,w)local b=CreateFrame("EditBox",nil,f,"InputBoxTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28);b:SetAutoFocus(false);b:SetMaxLetters(90);b:SetText(text);b:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);return b end
function L:Show()
 if not TranquilityAccess:Require()then return end
 if not self.frame then
  local f=CreateFrame("Frame","TranquilityLFGPanel",UIParent,"BackdropTemplate");self.frame=f
  f:SetSize(940,700);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.025,.04,.065,.98)
  label(f,"TRANQUILITY — GUILD GROUP FINDER",24,-20,840,30)
  button(f,"X",880,-14,32,function()f:Hide()end)
  for i,m in ipairs(self.modes)do local mode=m;button(f,self.labels[m],24+(i-1)*225,-64,212,function()self.mode=mode;self.activities={};self.preset=1;self.page=1;self.activity:SetText(self.presets[mode][1]);self:Refresh()end)end
  label(f,"Activity",24,-110,110);self.activity=edit(f,self.presets[self.mode][1],135,-106,370)
  button(f,"Next preset",520,-106,170,function()self.preset=(self.preset or 1)%#self.presets[self.mode]+1;self.activity:SetText(self.presets[self.mode][self.preset])end)
  button(f,"Add / filter",706,-106,208,function()
   local name=self.activity:GetText();if not clean(name,45)or name:find(";",1,true)then return end
   for _,a in ipairs(self.activities)do if a:lower()==name:lower()then return end end
   if #self.activities<5 then self.activities[#self.activities+1]=name;self.page=1;self:Refresh()end
  end)
  self.selection=label(f,"",24,-150,690,40)
  button(f,"Clear selection",730,-148,184,function()self.activities={};self:Refresh()end)
  self.roleButton=button(f,"Role: DPS",24,-198,185,function()local nextRole={DPS="TANK",TANK="HEALER",HEALER="DPS"};self.role=nextRole[self.role];self.roleButton:SetText("Role: "..self.role)end)
  label(f,"Group size",230,-204,100);self.size=edit(f,"5",335,-198,70)
  label(f,"Notes",425,-204,70);self.note=edit(f,"",500,-198,414)
  button(f,"Queue selected activities",24,-246,280,function()
   if #self.activities==0 then self.activities={self.activity:GetText()}end
   self:Join(self.mode,self.activities,self.role,self.note:GetText(),self.size:GetText())
  end)
  button(f,"Leave queue",320,-246,280,function()self:Leave()end)
  button(f,"Refresh guild board",616,-246,298,function()if now()-(self.queried or 0)>=10 then self.queried=now();self:Send({"Q"})end end)
  label(f,"Matching guild members — invite from a row. Party formation and matchmaking remain manual.",24,-296,880)
  self.rows={}
  for i=1,6 do local row={};self.rows[i]=row;local y=-332-(i-1)*40
   row.text=label(f,"",24,y,700,36)
   row.invite=button(f,"Invite",752,y,162,function()if row.name then self:Invite(row.name)end end)
  end
  button(f,"Previous",24,-584,150,function()self.page=math.max(1,(self.page or 1)-1);self:Refresh()end)
  button(f,"Next",190,-584,150,function()self.page=(self.page or 1)+1;self:Refresh()end)
  self.inviteCommand=edit(f,"",365,-584,549)
  self.status=label(f,"",24,-630,890,50)
  table.insert(UISpecialFrames,"TranquilityLFGPanel")
 end
 self.frame:Show();self:Refresh();if self:Allowed()then self:Send({"Q"})end
end
function L:Refresh()
 if not self.frame or not self.frame:IsShown()then return end
 local allowed=self:Allowed();local list=allowed and self:List()or {}
 self.page=math.min(self.page or 1,math.max(1,math.ceil(#list/6)))
 self.selection:SetText("Selected: "..(#self.activities>0 and table.concat(self.activities," / ")or "All listed activities in this tab").."\nMode: "..self.labels[self.mode])
 for i,row in ipairs(self.rows)do local e=list[(self.page-1)*6+i];row.name=e and e.name
  row.text:SetText(e and (e.name.." | "..e.role.." | "..e.activity:gsub(";"," / ").." | "..e.size.." players\n"..e.note)or "—")
  row.invite:SetEnabled(e~=nil and identity(e.name)~=identity(mine()))
 end
 self.status:SetText(not allowed and "Only Tranquility guild members can publish or read this board."or ((self.active and "QUEUED"or "NOT QUEUED").." | "..#list.." matching listings | "..(self.notice or "Guild addon messages only. Arena/RBG modes plan teams; they do not enable unavailable game modes.")))
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","CHAT_MSG_ADDON","PLAYER_GUILD_UPDATE","GROUP_ROSTER_UPDATE"})do frame:RegisterEvent(event)end
frame:SetScript("OnEvent",function(_,event,...)
 if event=="ADDON_LOADED"then if (...)=="TranquilityLFG"then TranquilityLFGDB=TranquilityLFGDB or {};L.db=TranquilityLFGDB end
 elseif event=="CHAT_MSG_ADDON"then local prefix,text,channel,sender=...;if prefix==L.prefix then L:Receive(text,sender,channel)end
 elseif event=="PLAYER_GUILD_UPDATE"then if not L:Allowed()then L.active=nil;L.entries={};L.queue={}end;L:Refresh()
 elseif event=="GROUP_ROSTER_UPDATE"and L.active and IsInGroup and IsInGroup()and UnitIsGroupLeader and not UnitIsGroupLeader("player")then L:Leave()end
end)
local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix;if register then register(L.prefix)end
local elapsed=0
frame:SetScript("OnUpdate",function(_,dt)
 elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
 if not L:Allowed()then return end
 local packet=table.remove(L.queue,1);local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
 if packet and send then pcall(send,L.prefix,packet,"GUILD")end
 if L.active and now()-(L.published or 0)>=40 then L:Publish()end
 if L.active then local own=L.entries[identity(mine())];if own then own.at=now()end end
 L:Refresh()
end)
SLASH_TRANQUILITYLFG1="/tqlfg";SlashCmdList.TRANQUILITYLFG=function()L:Show()end
