local L=TranquilityLFG
local function label(f,text,x,y,w,h,big)local t=f:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge"or "GameFontHighlightSmall");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h or 24);t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetText(text);return t end
local function button(f,text,x,y,w,fn)local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28);b:SetText(text);b:SetScript("OnClick",fn);return b end
local function edit(f,text,x,y,w,max,multi)
 local parent=f;local scroll
 if multi then scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",x,y);scroll:SetSize(w-24,140);parent=scroll end
 local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate");e:SetPoint("TOPLEFT",multi and 4 or x,multi and 0 or y);e:SetSize(multi and w-32 or w,multi and 140 or 28);e:SetMaxLetters(max or 90);e:SetAutoFocus(false)
 if multi then e:SetMultiLine(true);e:SetFontObject("ChatFontNormal");scroll:SetScrollChild(e);e:SetScript("OnTextChanged",function(s)
  local lines=0;for line in (s:GetText().."\n"):gmatch("(.-)\n")do lines=lines+math.max(1,math.ceil(#line/math.max(10,math.floor((w-32)/7))))end;s:SetHeight(math.max(140,lines*15))
 end)end
 e:SetText(text or "");e:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);return e
end
local function check(f,text,x,y,w,fn)local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");c:SetPoint("TOPLEFT",x,y);c:SetSize(26,26);label(f,text,x+32,y-5,w or 220);c:SetScript("OnClick",function(s)fn(s:GetChecked()==true)end);return c end
local function panel(name,title,w,h)
 local f=CreateFrame("Frame",name,UIParent,"BackdropTemplate");f:SetSize(w,h);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.025,.04,.065,1)
 local sw=UIParent.GetWidth and UIParent:GetWidth();local sh=UIParent.GetHeight and UIParent:GetHeight()
 if type(sw)=="number"and type(sh)=="number"and sw>20 and sh>20 then f:SetScale(math.min(1,(sw-20)/w,(sh-20)/h))end
 label(f,title,24,-20,w-90,32,true):SetTextColor(.4,.9,.75);button(f,"X",w-56,-14,32,function()f:Hide()end);table.insert(UISpecialFrames,name);return f
end
L.presets.PVP={"Warsong Gulch","Arathi Basin","Alterac Valley","World PvP"}
function L:SetPage(mode)
 self:Settings();if self.options.auto then self:StopForming("Formation paused while changing activities.")end
 self.mode=mode;self.directoryView=false;self.activities={};self.preset=1;self.page=1
 self.activity:SetText(self.presets[mode][1]);self.size:SetText(mode=="DUNGEON"and "5"or mode=="ARENA"and "2"or "10")
 self.options.bracket=mode=="ARENA"and 2 or 10
 if mode~="DUNGEON"then local level=self:OwnProfile().level;self.options.minLevel=math.max(1,math.floor(level/10)*10);self.options.maxLevel=math.min(100,self.options.minLevel+9);self.options.carry=false end
 self:Refresh()
end
function L:ShowProfile()
 if not TranquilityAccess:Require()then return end
 if not self.profileFrame then
  local f=panel("TranquilityLFGProfile","YOUR AVAILABILITY & LOOT PROFILE",800,590);self.profileFrame=f
  self.profileInfo=label(f,"",24,-64,740,68)
  self.availableCheck=check(f,"Discoverable without queueing",24,-152,600,function(on)self:SetDiscoverable(on)end)
  self.leaderCheck=check(f,"Volunteer as leader (green flag)",24,-194,600,function(on)self.db.leader=on;if not on then self.options.auto=false end;self:PublishProfile();self:Refresh()end)
  button(f,"Use selected role only",24,-244,350,function()self.db.roles=self.role;self:PublishProfile();self:Refresh()end)
  button(f,"Flexible: all my class roles",400,-244,350,function()self.db.roles=self.rolesByClass[self:OwnProfile().class]or "DPS";self:PublishProfile();self:Refresh()end)
  self.lootButton=button(f,"Loot: AUTO",24,-294,726,function()
   local choices={AUTO="HEAL",HEAL="SPELL",SPELL="STRENGTH",STRENGTH="AGILITY",AGILITY="DEFENSE",DEFENSE="AUTO"};self.db.loot=choices[self.db.loot or "AUTO"]or "AUTO";self:PublishProfile();self:Refresh()
  end)
  label(f,"Desired dungeon item IDs (up to 8, comma-separated)",24,-344,740)
  self.wishlist=edit(f,"",24,-378,550,80)
  button(f,"Save wishlist",594,-378,156,function()
   local wants,n={},0;for raw in self.wishlist:GetText():gmatch("[^,%s]+")do local id=self:Int(raw,1,9999999);if not id or wants[id]then self:Notify("Use distinct numeric item IDs, at most eight.");return end;wants[id]=true;n=n+1 end
   if n>8 then return end;self.db.wants=wants;self:PublishProfile();self:Notify("Wishlist shared. The builder penalizes exact shared needs as well as armor/stat overlap.")
  end)
  label(f,"Ready queue = available NOW for the selected activity. Directory = open to deliberate invites, not a readiness promise. Profiles/ranks are shared by the character's addon. Different roles can still compete for weapons, jewelry or off-spec items.",24,-438,740,100)
 end
 self.profileFrame:Show();local p=self:OwnProfile();self.availableCheck:SetChecked(self.db.discoverable);self.leaderCheck:SetChecked(self.db.leader==true)
 local ids={};for id in pairs(self.db.wants or {})do ids[#ids+1]=id end;table.sort(ids);self.wishlist:SetText(table.concat(ids,","));self:Refresh()
end
function L:ShowBuilder()
 if not TranquilityAccess:Require()then return end
 if not self.builderFrame then
  local f=panel("TranquilityLFGBuilder","LEADER GROUP BUILDER · ROLE & LOOT BALANCE",920,700);self.builderFrame=f
  self.diversityCheck=check(f,"Optimize loot diversity",24,-64,320,function(on)self.options.diversity=on;self.plan=nil;self.options.auto=false end)
  self.carryCheck=check(f,"Carry run: only I am the lower-level member",400,-64,450,function(on)self.options.carry=on;self.plan=nil;self.options.auto=false end)
  label(f,"Normal minimum",24,-112,150);self.minLevel=edit(f,"18",176,-106,80,3)
  label(f,"Maximum",286,-112,110);self.maxLevel=edit(f,"24",390,-106,80,3)
  label(f,"Carry entry floor",500,-112,170);self.entryLevel=edit(f,"10",680,-106,80,3)
  label(f,"Ranked minimum rating",24,-156,210);self.minRating=edit(f,"0",245,-150,100,4)
  label(f,"Tanks",360,-156,55);self.tankSlots=edit(f,"auto",418,-150,65,4)
  label(f,"Healers",498,-156,65);self.healerSlots=edit(f,"auto",570,-150,65,4)
  button(f,"Apply filters",662,-150,230,function()
   local a,b,c,r=self:Int(self.minLevel:GetText(),1,100),self:Int(self.maxLevel:GetText(),1,100),self:Int(self.entryLevel:GetText(),1,100),self:Int(self.minRating:GetText(),0,5000)
   if not a or not b or not c or not r or a>b or c>a then self:Notify("Use valid levels: entry ≤ normal minimum ≤ maximum, plus a valid minimum rating.");return end
   local t,h=self.tankSlots:GetText(),self.healerSlots:GetText();local tanks=t=="auto"and nil or self:Int(t,0,40);local heals=h=="auto"and nil or self:Int(h,0,40)
   if t~="auto"and not tanks or h~="auto"and not heals then return end
   self.options.tanks,self.options.healers=tanks,heals;self.options.minLevel,self.options.maxLevel,self.options.entryLevel,self.options.minRating=a,b,c,r;self.plan=nil;self.options.auto=false;self:Notify("Filters saved. Dungeon roles stay 1 tank / 1 healer / 3 DPS. Entry floor is a planning setting, not verified access.")
  end)
  button(f,"Build best available team",24,-206,270,function()local p,why=self:BuildPlan();self.plan=p;self:Notify(p and "Team proposal ready. Loot score is a heuristic, not a guarantee of exclusive drops."or why)end)
  button(f,"Start auto formation",318,-206,270,function()self:StartForming()end)
  button(f,"Pause formation",612,-206,280,function()self:StopForming()end)
  self.planInfo=label(f,"",24,-256,860,270)
  button(f,"Review observed dungeon loot",24,-542,410,function()
   local items=self:DungeonLoot(self.activities[1]or self.active and self.active.activity or "")
   local lines={"Observed journal items for this activity (not a complete drop table):"};for i=1,math.min(#items,12)do lines[#lines+1]=items[i].name.." ["..items[i].id.."]"end
   if #items==0 then lines[#lines+1]="No observed sources yet. Add desired IDs to each member's wishlist; no drop tables are invented."end
   self.planInfo:SetText(table.concat(lines,"\n"));self.showingLoot=true
  end)
  button(f,"Back to proposed team",454,-542,438,function()self.showingLoot=false;self:Refresh()end)
  label(f,"One pending invite at a time. Formation uses READY matching players, never the passive directory. Native restrictions stop failed invitations; a timeout skips that player for five minutes. Only the actual leader's client sends invites. No dungeon/BG/arena matchmaking queue is entered.",24,-600,860,70)
 end
 self.minLevel:SetText(tostring(self.options.minLevel));self.maxLevel:SetText(tostring(self.options.maxLevel));self.entryLevel:SetText(tostring(self.options.entryLevel));self.minRating:SetText(tostring(self.options.minRating or 0));self.tankSlots:SetText(self.options.tanks and tostring(self.options.tanks)or "auto");self.healerSlots:SetText(self.options.healers and tostring(self.options.healers)or "auto");self.diversityCheck:SetChecked(self.options.diversity);self.carryCheck:SetChecked(self.options.carry)
 self.showingLoot=false;self.builderFrame:Show();self:Refresh()
end
function L:ShowDiscord()
 if not TranquilityAccess:Require()then return end
 local db=self:MirrorDB()
 if not self.discordFrame then
  local f=panel("TranquilityLFGDiscord","TRANQUILITY · DISCORD LOUNGE",960,740);self.discordFrame=f
  label(f,"Public-channel snapshots via the trusted officer/bot. Not a direct live Discord connection. Replies wait for handoff; nothing is posted merely by typing here.",24,-64,900,48)
  label(f,"Trusted in-game relay",24,-126,200);self.relayInput=edit(f,db.relay,230,-120,360,100)
  label(f,"Allowed channel names",24,-166,200);self.channelsInput=edit(f,"general,lfg",230,-160,500,150)
  button(f,"Save local relay trust",610,-120,320,function()
   local relay=self.relayInput:GetText();if not self:Clean(relay,100)then return end
   local channels={};local n=0;for c in self.channelsInput:GetText():gmatch("[^,%s]+")do if not self:Clean(c,32)then return end;channels[c]=true;n=n+1 end;if n>8 then return end
   db.relay=relay;db.channels=channels;self:Notify("Relay trust saved locally. Configure the existing bot's actual public channel IDs separately.")
  end)
  self.discordMessages=label(f,"",24,-218,900,190)
  button(f,"Previous",24,-414,130,function()self.discordPage=math.max(1,(self.discordPage or 1)-1);self:Refresh()end)
  button(f,"Next",170,-414,130,function()self.discordPage=(self.discordPage or 1)+1;self:Refresh()end)
  self.discordChannel=edit(f,"general",326,-414,170,32);self.discordReply=edit(f,"",24,-458,690,120)
  button(f,"Queue reply",736,-458,194,function()self:ReplyDiscord(self.discordChannel:GetText(),self.discordReply:GetText())end)
  self.discordTransfer=edit(f,"",24,-506,900,16000,true)
  button(f,"Import bot snapshot",24,-660,270,function()self:ImportDiscord(self.discordTransfer:GetText());self:Refresh()end)
  button(f,"Copy relay reply export",318,-660,290,function()self.discordTransfer:SetText(self:DiscordReplyExport());self.discordTransfer:SetFocus();self.discordTransfer:HighlightText(0,-1)end)
  button(f,"Show Discord invite",632,-660,298,function()self.discordTransfer:SetText(self.discordInvite);self.discordTransfer:SetFocus();self.discordTransfer:HighlightText(0,-1)end)
 end
 self.discordFrame:Show();self:Refresh()
end
function L:Show()
 if not TranquilityAccess:Require()then return end
 self:Settings()
 if not self.frame then
  local f=panel("TranquilityLFGPanel","TRANQUILITY · GUILD GROUP FINDER",1000,750);self.frame=f
  for i,item in ipairs({{"Dungeons","DUNGEON"},{"Battlegrounds","PVP"},{"Arena partners","ARENA"}})do local mode=item[2];button(f,item[1],24+(i-1)*316,-66,300,function()self:SetPage(mode)end)end
  label(f,"Activity",24,-114,90);self.activity=edit(f,self.presets[self.mode][1],112,-108,310,45)
  button(f,"Next preset",438,-108,160,function()
   self.preset=(self.preset or 1)%#self.presets[self.mode]+1;local a=self.presets[self.mode][self.preset];self.activity:SetText(a)
   if self.mode=="ARENA"then self.size:SetText(a:sub(1,1));self.options.bracket=tonumber(a:sub(1,1))end
   if self.mode=="PVP"then local sizes={10,15,40,10};self.size:SetText(tostring(sizes[self.preset]));self.options.bracket=sizes[self.preset]end
  end)
  button(f,"Add activity/filter",614,-108,200,function()local a=self.activity:GetText();if self:Clean(a,45)and not a:find(";",1,true)and #self.activities<5 then for _,v in ipairs(self.activities)do if a==v then return end end;self.activities[#self.activities+1]=a;self.page=1;self:Refresh()end end)
  button(f,"Clear",830,-108,140,function()self.activities={};self:Refresh()end)
  self.selection=label(f,"",24,-150,940,42)
  self.roleButton=button(f,"Role: DPS",24,-200,170,function()
   local roles,index={},1;for r in (self.rolesByClass[self:OwnProfile().class]or "DPS"):gmatch("[^,]+")do roles[#roles+1]=r;if r==self.role then index=#roles end end
   self.role=roles[index%#roles+1];self.db.roles=self.role;self:PublishProfile();self:Refresh()
  end)
  label(f,"Team size",212,-206,100);self.size=edit(f,"5",310,-200,60,2)
  self.rankedButton=button(f,"Casual",390,-200,170,function()self.options.ranked=not self.options.ranked;self:Refresh()end)
  label(f,"Notes",576,-206,60);self.note=edit(f,"",640,-200,330,90)
  button(f,"Queue · ready now",24,-248,220,function()
   if #self.activities==0 then self.activities={self.activity:GetText()}end
   self.options.bracket=tonumber(self.size:GetText())or 10;self:Join(self.mode,self.activities,self.role,self.note:GetText(),self.size:GetText())
  end)
  button(f,"Leave ready queue",258,-248,220,function()self:Leave()end)
  button(f,"Who has LFG active?",492,-248,240,function()self.directoryView=not self.directoryView;self.page=1;self:Send({"Q2"});self:Refresh()end)
  button(f,"Refresh",746,-248,224,function()if self:Clock()-(self.queried or 0)>=10 then self.queried=self:Clock();self:Send({"Q2"});self:Send({"Q"})end end)
  self.rosterLabel=label(f,"",24,-298,940,24)
  self.rows={}
  for i=1,6 do local row={};self.rows[i]=row;local y=-334-(i-1)*42
   row.flag=CreateFrame("Frame",nil,f);row.flag:SetPoint("TOPLEFT",24,y);row.flag:SetSize(14,18)
   row.pole=row.flag:CreateTexture(nil,"ARTWORK");row.pole:SetPoint("TOPLEFT",0,0);row.pole:SetSize(2,18);row.pole:SetColorTexture(.4,1,.55,1)
   row.banner=row.flag:CreateTexture(nil,"ARTWORK");row.banner:SetPoint("TOPLEFT",2,0);row.banner:SetSize(12,9);row.banner:SetColorTexture(.3,.95,.4,1)
   row.text=label(f,"",48,y,720,38);row.invite=button(f,"Invite",790,y,180,function()if row.name then self:Invite(row.name)end end)
  end
  button(f,"Previous",24,-600,140,function()self.page=math.max(1,(self.page or 1)-1);self:Refresh()end)
  button(f,"Next",178,-600,140,function()self.page=(self.page or 1)+1;self:Refresh()end)
  button(f,"Confirm invite",334,-600,210,function()if self.pendingInvite then local who=self.pendingInvite;self.pendingInvite=nil;self:Invite(who,true)end end)
  button(f,"My profile",560,-600,190,function()self:ShowProfile()end)
  button(f,"Group builder",766,-600,204,function()self:ShowBuilder()end)
  button(f,"Discord lounge",24,-642,220,function()self:ShowDiscord()end)
  self.inviteCommand=edit(f,"",260,-642,710,100)
  self.status=label(f,"",24,-690,940,42)
 end
 self.frame:Show();self:PublishProfile();self:Send({"Q2"});self:Refresh()
end
function L:Refresh()
 if not self.frame or not self.frame:IsShown()then return end;self:Settings()
 local list={}
 if self:Allowed()then if self.directoryView then list=self:Directory()else for _,e in ipairs(self:List())do local p=self.profiles[self:Key(e.name)];if not p or self.mode=="DUNGEON"or p.ranked==self.options.ranked and p.bracket==tonumber(self.size:GetText())then list[#list+1]=e end end end end
 self.page=math.min(self.page or 1,math.max(1,math.ceil(#list/6)))
 self.roleButton:SetText("Role: "..self.role);self.rankedButton:SetText(self.mode=="DUNGEON"and "PvP category: N/A"or self.options.ranked and "Ranked planning"or "Casual / skirmish");self.rankedButton:SetEnabled(self.mode~="DUNGEON")
 self.selection:SetText("Selected: "..(#self.activities>0 and table.concat(self.activities," / ")or "All listed activities").."\n"..(self.mode=="DUNGEON"and "Five-person dungeon groups · optional loot diversity and leader-carry filters"or self.mode=="PVP"and "10v10 / 15v15 / 40v40 planning · native mode availability still applies"or "Find 2v2 / 3v3 / 5v5 partners · ratings are client-reported native observations"))
 self.rosterLabel:SetText(self.directoryView and "ACTIVE ADDON DIRECTORY · available ≠ ready · discoverability can be switched off in My profile"or "READY QUEUE · green flag = volunteered leader · armor, loot intent and rating help guide invites")
 for i,row in ipairs(self.rows)do local e=list[(self.page-1)*6+i];local p=e and (self.profiles[self:Key(e.name)]or e);row.name=e and e.name;row.flag:SetShown(p and p.leader==true)
  local rating=p and ((p.rating and p.rating>=0 and "Rating "..p.rating or "Rating unavailable")..(p.rank and p.rank>=0 and " · Honor rank "..p.rank or ""))or ""
  row.text:SetText(e and (e.name.." · "..(p.class or "profile pending").." L"..(p.level or "?").." · "..(p.roles or e.role or "?").." · "..(p.ready==false and "AVAILABLE"or "READY").."\n"..(p.class and self:Armor(p).."/"..self:LootIntent(p,e.role or "DPS").." · "or "")..(self.mode~="DUNGEON"and rating.." · "or "")..(e.activity or "Not queued"))or "—")
  row.invite:SetEnabled(e~=nil and self:Key(e.name)~=self:Key(self:Me())and self:CanLead()and self.db.leader==true)
 end
 self.status:SetText(not self:Allowed()and "Tranquility guild membership is required."or ((self.active and "READY"or "NOT QUEUED").." · "..#list.." shown · "..(self.options.auto and "AUTO FORMING · "or "")..(self.notice or "Native guild addon messages; invites never mean acceptance. Use My profile to manage discoverability.")))
 if self.profileFrame and self.profileFrame:IsShown()then local p=self:OwnProfile();self.profileInfo:SetText(p.name.." · "..p.class.." level "..p.level.."\nRoles: "..p.roles.." · "..(p.leader and "LEADER"or "Member").."\nRatings: "..(p.rating>=0 and tostring(p.rating)or "unavailable on this client/bracket"));self.lootButton:SetText("Loot intent: "..(self.db.loot or "AUTO").." · click to cycle")end
 if self.builderFrame and self.builderFrame:IsShown()and not self.showingLoot then
  local lines={self.options.auto and "FORMATION ACTIVE"or "Propose a team, inspect it, then start forming.","Normal levels "..self.options.minLevel.."–"..self.options.maxLevel.." · "..(self.options.carry and "Leader carry only"or "Regular run").." · Diversity "..(self.options.diversity and "ON"or "OFF")}
  if self.plan then lines[#lines+1]="Loot overlap score: "..self.plan.score.." (lower is better; not a guarantee)";for _,m in ipairs(self.plan.members)do local p=m.profile;lines[#lines+1]=m.role.." · "..p.name.." · "..p.class.." L"..p.level.." · "..self:Armor(p).." / "..self:LootIntent(p,m.role)..(m.existing and " [in party]"or "")end end
  if self.pendingMember then lines[#lines+1]="Waiting for "..self.pendingMember.." to accept."end
  self.planInfo:SetText(table.concat(lines,"\n"))
 end
 if self.discordFrame and self.discordFrame:IsShown()then local db=self:MirrorDB();self.discordPage=math.min(self.discordPage or 1,math.max(1,math.ceil(#db.messages/4)));local lines={}
  for i=#db.messages-(self.discordPage-1)*4,math.max(1,#db.messages-self.discordPage*4+1),-1 do local m=db.messages[i];lines[#lines+1]="#"..m.channel.." · "..m.author.." · "..(date and date("%m-%d %H:%M",m.at)or m.at).."\n"..m.text end
  self.discordMessages:SetText(#lines>0 and table.concat(lines,"\n\n")or "No mirrored messages yet. Configure a trusted relay and public channel names, then import a bot snapshot. Discord invite: "..self.discordInvite)
 end
end
