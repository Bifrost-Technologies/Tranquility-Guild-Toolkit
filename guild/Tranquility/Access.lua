if _G.TranquilityAccess then return end
local A={required="dedicated member",roster={},threshold=nil}
_G.TranquilityAccess=A
A.denial="You are not a member of Tranquility. Please join our guild to access Tranquility Guild Toolkit. Join our Discord below to get started."
A.discord="https://discord.gg/CMjbSRYt6"
function A:Public(v)if issecretvalue and issecretvalue(v)then return nil end;return v end
function A:Read(fn,...)if type(fn)~="function"then return nil end;local ok,v=pcall(fn,...);return ok and self:Public(v)or nil end
function A:Key(n)if type(n)~="string"then return ""end;if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName and GetRealmName()or "")end;return n:lower()end
function A:Native()
 if type(GetGuildInfo)~="function"then return nil end
 local ok,guild,rank,index=pcall(GetGuildInfo,"player")
 if not ok then return nil end;guild,rank,index=self:Public(guild),self:Public(rank),self:Public(index)
 if type(guild)~="string"or guild:lower()~="tranquility"or type(rank)~="string"or type(index)~="number"or index<0 or index%1~=0 then return nil end
 return rank,index
end
function A:RefreshRoster()
 local threshold
 local n=self:Read(GuildControlGetNumRanks)
 if type(n)=="number"and n>=1 and n<=20 then for i=1,n do local rank=self:Read(GuildControlGetRankName,i);if type(rank)=="string"and rank:lower()==self.required then threshold=i-1 end end end
 local roster={};n=self:Read(GetNumGuildMembers)
 if type(n)=="number"and n>=0 and n<=2000 and type(GetGuildRosterInfo)=="function"then
  for i=1,n do
   local values={pcall(GetGuildRosterInfo,i)};local ok,name,rank,index,guid=values[1],values[2],values[3],values[4],values[18]
   name,rank,index,guid=self:Public(name),self:Public(rank),self:Public(index),self:Public(guid)
   if ok and type(name)=="string"and type(rank)=="string"and type(index)=="number"and index>=0 and index%1==0 then
    roster[self:Key(name)]={name=name,rank=rank,index=index,guid=type(guid)=="string"and guid or nil}
    if rank:lower()==self.required then threshold=index end
   end
  end
 end
 self.roster=roster;self.threshold=threshold
 local rank,index=self:Native();if rank and rank:lower()==self.required then self.threshold=index end
end
function A:RankAllowed()
 local rank,index=self:Native();if not rank then return false end
 local d=_G.TranquilityDB;local ban=d and d.security and d.security.bans and d.security.bans[self:Key(self:Read(GetUnitName,"player",true))]
 if index~=0 and ban and ban.blocked then return false end
 if rank:lower()==self.required or index==0 then return true end
 return self.threshold~=nil and index<self.threshold
end
function A:Allowed()
 local guild=self:Read(GetGuildInfo,"player")
 return type(guild)=="string"and guild:lower()=="tranquility"
end
function A:Member(who)
 if self:Key(who)==self:Key(self:Read(GetUnitName,"player",true))then local rank,index=self:Native();if rank then return {name=who,rank=rank,index=index,guid=self:Read(UnitGUID,"player")}end end
 return self.roster[self:Key(who)]
end
function A:Dedicated(who)local db=_G.TranquilityDB;local bans=db and db.security and db.security.bans;local ban=bans and bans[self:Key(who)];if ban and ban.blocked then return false end;local r=self:Member(who);return r and (r.index==0 or r.rank:lower()==self.required or self.threshold and r.index<self.threshold)or false end
function A:Admin(who)
 local r=self:Member(who or self:Read(GetUnitName,"player",true));if not r then return false end
 if r.index==0 then return true end
 local db=_G.TranquilityDB;local configured=db and db.security and db.security.adminRanks
 return self:Dedicated(r.name)and configured and configured[r.rank:lower()]==true or false
end
function A:HideTools()
 local T=_G.Tranquility
 if T then
  if T.defense then T.defense:Stop()end
  if T.enemyMarkers then T.enemyMarkers:Hide()end
  if T.frame then T.frame:Hide()end;if T.launcher then T.launcher:Hide()end
  for _,record in pairs(T.modules or {})do local object=record.object;if object.frame then object.frame:Hide()end;if object.Stop then pcall(object.Stop,object)end end
  for _,f in ipairs(UISpecialFrames or {})do if type(f)=="string"and f:match("^Tranquility")and f~="TranquilityAccessRequired"and _G[f]and _G[f].Hide then pcall(_G[f].Hide,_G[f])end end
  if T.work then for _,field in ipairs({"frame","adminFrame","verifyFrame","configFrame","contractFrame","payrollFrame"})do if T.work[field]then T.work[field]:Hide()end end end
 end
 local L=_G.TranquilityLFG
 if L then L.active=nil;L.entries={};L.profiles={};L.queue={};if L.options then L.options.auto=false end
  for _,field in ipairs({"frame","profileFrame","builderFrame","discordFrame"})do if L[field]then L[field]:Hide()end end
 end
end
function A:ShowDenied()
 self:HideTools()
 local d=_G.TranquilityDB;if d and d.security then d.security.accessClosed=false end
 if not self.frame then
  local f=CreateFrame("Frame","TranquilityAccessRequired",UIParent,"BackdropTemplate");self.frame=f
  f:SetSize(620,270);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.035,.045,.065,1)
  local text=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");text:SetPoint("TOPLEFT",26,-36);text:SetSize(565,115);text:SetText(self.denial)
  local link=CreateFrame("EditBox",nil,f,"InputBoxTemplate");self.discordBox=link;link:SetSize(550,30);link:SetPoint("TOPLEFT",35,-170);link:SetAutoFocus(false);link:SetText(self.discord)
  link:SetScript("OnEditFocusGained",function(box)box:SetText(self.discord);box:HighlightText()end)
  link:SetScript("OnEscapePressed",function(box)box:ClearFocus();f:Hide()end)
  local hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");hint:SetPoint("TOPLEFT",30,-215);hint:SetSize(560,26);hint:SetText("Copy this invite into your browser or Discord. No code or rank is required for addon access.")
  f:SetScript("OnHide",function()link:ClearFocus();local db=_G.TranquilityDB;if db then db.security=db.security or {};db.security.accessClosed=true end end)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5);close:SetScript("OnClick",function()f:Hide()end)
  table.insert(UISpecialFrames,"TranquilityAccessRequired")
 end
 self.frame:Show();return false
end
function A:Require()if self:Allowed()then return true end;return self:ShowDenied()end
function A:Refresh()
 self:RefreshRoster();local allowed=self:Allowed()
 if not allowed then self:HideTools();if self.wasAllowed~=false and not(_G.TranquilityDB and TranquilityDB.security and TranquilityDB.security.accessClosed)then self:ShowDenied()end
 else
  if self.frame then self.frame:Hide()end
  local T=_G.Tranquility;if T then for id in pairs(T.modules or {})do T:Initialize(id)end;if T.EnsureLauncher then T:EnsureLauncher()end end
 end
 self.wasAllowed=allowed
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_ENTERING_WORLD"})do pcall(frame.RegisterEvent,frame,event)end
frame:SetScript("OnEvent",function()A:Refresh()end)
