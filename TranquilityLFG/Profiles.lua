local L=TranquilityLFG
L.profiles={};L.rolesByClass={WARRIOR="TANK,DPS",PALADIN="TANK,HEALER,DPS",SHAMAN="HEALER,DPS",DRUID="TANK,HEALER,DPS",PRIEST="HEALER,DPS",MAGE="DPS",WARLOCK="DPS",ROGUE="DPS",HUNTER="DPS"}
local send=L.Send
function L:Send(parts)
 local result=send(self,parts)
 if result and not ({DC2=true,DR2=true,DA2=true})[parts[1]]then
  local packet=table.remove(self.queue)
  local insert=#self.queue+1
  for i,queued in ipairs(self.queue)do if queued:match("^D[CRA]2|")then insert=i;break end end
  table.insert(self.queue,insert,packet)
 end
 return result
end
function L:Public(v)if issecretvalue and issecretvalue(v)then return nil end;return v end
function L:Read(fn,...)if type(fn)~="function"then return nil end;local ok,v=pcall(fn,...);return ok and self:Public(v)or nil end
function L:Key(n)if type(n)~="string"then return ""end;if not n:find("-",1,true)then n=n.."-"..(GetNormalizedRealmName and GetNormalizedRealmName()or "")end;return n:lower()end
function L:Me()return GetUnitName("player",true)end
function L:Clock()return GetServerTime()end
function L:Int(v,low,high)local n=tonumber(v);return n and n==n and n%1==0 and n>=low and n<=high and n end
function L:Clean(s,max)return type(s)=="string"and #s>0 and #s<=max and not s:find("[%c|]")and s end
function L:Settings()
 if not self.db then TranquilityLFGDB=TranquilityLFGDB or {};self.db=TranquilityLFGDB end
 if self.db.discoverable==nil then self.db.discoverable=true end
 if not self.profileInitialized then self.role=self.db.roles and self.db.roles:match("^[^,]+")or self.role;self.profileInitialized=true end
 self.options=self.options or {diversity=true,carry=false,minLevel=18,maxLevel=24,entryLevel=10,auto=false,ranked=false,bracket=10}
 return self.db
end
function L:CanLead()
 if not self:Allowed()then return false end
 if self:Read(IsInGroup)==true then return self:Read(UnitIsGroupLeader,"player")==true end
 return true
end
function L:HasRole(p,role)return p and type(p.roles)=="string"and (","..p.roles..","):find(","..role..",",1,true)~=nil end
function L:OwnProfile()
 self:Settings();local class
 if type(UnitClass)=="function"then local _,token=UnitClass("player");class=self:Public(token)end
 if not self.rolesByClass[class]then class="UNKNOWN"end
 local allowed=self.rolesByClass[class]or "DPS";local roles=self.db.roles or self.role or "DPS"
 local chosen={};for r in roles:gmatch("[^,]+")do if (","..allowed..","):find(","..r..",",1,true)then chosen[#chosen+1]=r end end
 if #chosen==0 then chosen={"DPS"}end
 local mode=self.active and self.active.mode or self.mode
 local bracket=self.active and self.active.bracket or mode=="ARENA"and (tonumber((self.activities[1]or "2v2"):match("^(%d)v%d$"))or 2)or self.options.bracket
 local rating,rank=-1,-1
 local index=({[2]=1,[3]=2,[5]=3,[10]=4})[bracket]
 if index and GetPersonalRatedInfo then rating=self:Read(GetPersonalRatedInfo,index)or -1 end
 if rating==-1 and GetArenaTeam and mode=="ARENA"then
  for i=1,3 do local values={pcall(GetArenaTeam,i)};if values[1]and self:Public(values[3])==bracket then rating=self:Public(values[12])or -1 end end
 end
 if UnitPVPRank then rank=self:Read(UnitPVPRank,"player")or -1 end
 return {name=self:Me(),class=class,level=self:Int(self:Read(UnitLevel,"player"),1,100)or 0,roles=table.concat(chosen,","),loot=self.db.loot or "AUTO",leader=self.db.leader==true and self:CanLead(),ready=self.active~=nil,mode=mode,ranked=self.active and self.active.ranked==true or not self.active and self.options.ranked==true,bracket=bracket,rating=self:Int(rating,0,5000)or -1,rank=self:Int(rank,0,100)or -1,at=self:Clock(),available=self.db.discoverable==true,wants=self.db.wants or {}}
end
function L:PublishProfile()
 local p=self:OwnProfile();self.profileAt=self:Clock();self.profiles[self:Key(p.name)]=p
 local result=self:Send({"H2",p.class,tostring(p.level),p.roles,p.loot,p.leader and "1"or "0",p.ready and "1"or "0",p.mode,p.ranked and "1"or "0",tostring(p.bracket),tostring(p.rating),tostring(p.rank),p.available and "1"or "0",tostring(p.at)})
 local ids={};for id in pairs(p.wants)do ids[#ids+1]=id end;table.sort(ids)
 if #ids>0 then self:Send({"W2",table.concat(ids,","),tostring(p.at)})end
 return result
end
function L:Directory()
 local out={};for k,p in pairs(self.profiles)do if self:Clock()-p.at>150 then self.profiles[k]=nil elseif p.available then out[#out+1]=p end end
 table.sort(out,function(a,b)if a.ready~=b.ready then return a.ready end;return a.name<b.name end);return out
end
function L:SetDiscoverable(on)
 self:Settings();self.db.discoverable=on==true
 if not on then self:Leave();self.options.auto=false end
 self:PublishProfile();self:Refresh()
end
local join=L.Join
function L:Join(mode,activities,role,note,size)
 self:Settings();size=tonumber(size)
 if type(activities)~="table"then return false end
 local class=self:OwnProfile().class
 if not (","..(self.rolesByClass[class]or "DPS")..","):find(","..tostring(role)..",",1,true)then self:Notify("Choose a role supported by your class profile.");return false end
 if mode=="ARENA"then local n=type(activities[1])=="string"and tonumber(activities[1]:match("^(%d)v%d$"));if (n~=2 and n~=3 and n~=5)or #activities~=1 or size~=n then self:Notify("Arena: choose exactly 2v2, 3v3 or 5v5 and the matching team size.");return false end end
 if mode=="PVP"or mode=="RBG"then if not ({[10]=true,[15]=true,[40]=true})[size]then self:Notify("Choose a 10, 15 or 40 player battleground team. Ranked modes depend on client availability.");return false end end
 if mode=="DUNGEON"and size~=5 then self:Notify("Dungeon builder targets five-person parties.");return false end
 if self.options.carry then
  local p=self:OwnProfile()
  if mode~="DUNGEON"or not p.leader or not self:CanLead()or p.level>=self.options.minLevel or p.level<self.options.entryLevel then self:Notify("Carry mode is for the volunteering leader below the normal level range, above the chosen entry minimum.");return false end
 end
 if type(note)~="string"then return false end
 local discoverable=self.db.discoverable;self.db.discoverable=true
 local result=join(self,mode,activities,role,note,size)
 if not result then self.db.discoverable=discoverable else self:Notify("READY listing published. Volunteer as leader to preview and arm the role/loot-aware group builder.")end;return result
end
local publish=L.Publish
function L:Publish()
 if self.active then
  if self.active.ranked==nil then self.active.ranked=self.options and self.options.ranked==true end
  if not self.active.bracket then self.active.bracket=self.active.mode=="ARENA"and tonumber(self.active.activity:sub(1,1))or self.options and self.options.bracket or 10 end
 end
 publish(self);if self.OwnProfile then self:PublishProfile()end
end
local leave=L.Leave
function L:Leave()leave(self);self:Settings();self.options.auto=false;self.plan=nil;self:PublishProfile()end
local receive=L.Receive
function L:Receive(text,sender,channel)
 if not self:Allowed()or channel~="GUILD"or not self:Clean(sender,100)or type(text)~="string"or #text>240 or text:find("[%c]")then return end
 if text=="Q2"then if self:Clock()-(self.profileReply or 0)>=20 then self.profileReply=self:Clock();if self.active then self:Publish()else self:PublishProfile()end end;return end
 local a={};for v in (text.."|"):gmatch("(.-)|")do a[#a+1]=v end
 if a[1]=="W2"then
  local p=self.profiles[self:Key(sender)];local at=self:Int(a[3],0,9999999999)
  if #a~=3 or not p or not at or at<p.at or math.abs(self:Clock()-at)>150 or #a[2]>80 then return end
  local wants,count={},0;for id in a[2]:gmatch("[^,]+")do local n=self:Int(id,1,9999999);if not n or wants[n]then return end;wants[n]=true;count=count+1 end
  if count>8 then return end;p.wants=wants;return
 elseif a[1]=="H2"then
  if #a~=14 or not (self.rolesByClass[a[2]]or a[2]=="UNKNOWN")or not self.labels[a[8]]or not ({AUTO=true,HEAL=true,SPELL=true,STRENGTH=true,AGILITY=true,DEFENSE=true})[a[5]]then return end
  local level,bracket,rating,rank,at=self:Int(a[3],0,100),self:Int(a[10],2,40),self:Int(a[11],-1,5000),self:Int(a[12],-1,100),self:Int(a[14],0,9999999999)
  if not level or not bracket or not rating or not rank or not at or math.abs(self:Clock()-at)>150 then return end
  for _,i in ipairs({6,7,9,13})do if a[i]~="0"and a[i]~="1"then return end end
  local roles,seen,n=a[4],{},0
  for r in roles:gmatch("[^,]+")do if seen[r]or not (","..(self.rolesByClass[a[2]]or "DPS")..","):find(","..r..",",1,true)then return end;seen[r]=true;n=n+1 end
  if n<1 or n>3 or #roles>15 then return end
  local k=self:Key(sender);local old=self.profiles[k];if old and old.at>at then return end
  local count=0;for _ in pairs(self.profiles)do count=count+1 end;if count>=250 and not old then return end
  self.profiles[k]={name=sender,class=a[2],level=level,roles=roles,loot=a[5],leader=a[6]=="1",ready=a[7]=="1",mode=a[8],ranked=a[9]=="1",bracket=bracket,rating=rating,rank=rank,available=a[13]=="1",at=at};self:Refresh();return
 end
 receive(self,text,sender,channel)
end
function L:ProfileTick()
 self:Settings()
 if not self:Allowed()then self.profiles={};self.plan=nil;self.options.auto=false;return end
 for k,p in pairs(self.profiles)do if self:Clock()-p.at>150 then self.profiles[k]=nil end end
 for k,e in pairs(self.entries)do if self:Clock()-e.at>120 then self.entries[k]=nil end end
 if self:Clock()-(self.profileAt or 0)>=50 then self:PublishProfile()end
 if self.FormTick then self:FormTick()end
end
local f=CreateFrame("Frame");f:RegisterEvent("ADDON_LOADED");f:RegisterEvent("PLAYER_GUILD_UPDATE");f:RegisterEvent("PLAYER_LOGOUT");f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED"and name~="TranquilityLFG"then return end
 if event=="PLAYER_LOGOUT"then L:Send({"H2","UNKNOWN","0","DPS","AUTO","0","0","DUNGEON","0","10","-1","-1","0",tostring(L:Clock())});return end
 L:Settings();if L:Allowed()then L:PublishProfile();L:Send({"Q2"})else L.profiles={};L.options.auto=false end
end)
local elapsed=0;f:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;L:ProfileTick()end end)
