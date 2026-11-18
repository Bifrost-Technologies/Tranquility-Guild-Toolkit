local passed=0
local function check(v,why)assert(v,why);passed=passed+1 end
local clock,player,level,class,guild=10000,"Leader-Realm",20,"PALADIN","Tranquility"
local group,leader,combat={},true,false
local widget={};setmetatable(widget,{__index=function()return function()end end})
function widget:SetText(t)self.text=t end;function widget:GetText()return self.text or ""end
function widget:SetScript(e,fn)self.scripts[e]=fn end
function widget:Show()self.shown=true end;function widget:IsShown()return self.shown==true end
function widget:SetChecked(v)self.checked=v end;function widget:GetChecked()return self.checked end
function widget:CreateFontString()return setmetatable({text=""},{__index=widget})end;widget.CreateTexture=widget.CreateFontString
CreateFrame=function()return setmetatable({text="",scripts={}},{__index=widget})end
UIParent={};UISpecialFrames={};SlashCmdList={}
GetServerTime=function()return clock end;GetNormalizedRealmName=function()return "Realm"end
GetGuildInfo=function()return guild end;UnitClass=function()return class,class end;UnitLevel=function()return level end
GetUnitName=function(unit)if unit=="player"then return player end;local n=unit:match("^party(%d+)$");return n and group[tonumber(n)]end
IsInGroup=function()return #group>0 end;GetNumGroupMembers=function()return #group>0 and #group+1 or 0 end
UnitIsGroupLeader=function()return leader end;InCombatLockdown=function()return combat end
GetPersonalRatedInfo=function(i)return 1800+i end;UnitPVPRank=function()return 7 end
C_ChatInfo={RegisterAddonMessagePrefix=function()end};local invited={};InviteUnit=function(name)invited[#invited+1]=name end
for _,file in ipairs({"LFG","Profiles","Builder","Mirror","Interface"})do assert(loadfile("TranquilityLFG/"..file..".lua"))()end
local l=TranquilityLFG;l:Settings();l.db.leader=true;l.role="HEALER";l.db.roles="HEALER"
check(l:OwnProfile().class=="PALADIN"and l:OwnProfile().level==20,"Native class and level profile")
l:PublishProfile();check(#l:Directory()==1 and not l:Directory()[1].ready,"Loaded members discoverable without queueing")
l:Receive("H2|MAGE|20|DPS|AUTO|0|0|DUNGEON|0|10|1804|7|1|10000","Available-Realm","GUILD")
check(l.profiles["available-realm"]and not l.profiles["available-realm"].ready,"Passive directory member is not READY")
check(l:Invite("Available-Realm",true)and invited[1]=="Available-Realm","Leader deliberately invites available unqueued member")
l:Receive("H2|MAGE|20|DPS|AUTO|0|1|DUNGEON|0|10|0|7|1|10000","Forged-Realm","WHISPER")
check(not l.profiles["forged-realm"],"Profile transport requires guild channel")
l:Receive("H2|MAGE|20|TANK|AUTO|0|1|DUNGEON|0|10|0|7|1|10000","Bad-Realm","GUILD")
check(not l.profiles["bad-realm"],"Impossible class role rejected")
check(l:Join("DUNGEON",{"The Deadmines"},"HEALER","Ready",5),"Ready dungeon listing")
local function add(name,c,role,lev,wants)
 local p={name=name.."-Realm",class=c,roles=role,level=lev or 20,loot="AUTO",ready=true,available=true,at=clock,mode="DUNGEON",ranked=false,bracket=10,rating=1800,rank=7,wants=wants}
 l.profiles[l:Key(p.name)]=p;l.entries[l:Key(p.name)]={name=p.name,mode="DUNGEON",role=role:match("^[^,]+"),activity="The Deadmines",note="",size=5,at=clock};return p
end
local warrior=add("Tank","WARRIOR","TANK");local mage=add("Mage","MAGE","DPS");local lock=add("Warlock","WARLOCK","DPS");local priest=add("Priest","PRIEST","DPS");local rogue=add("Rogue","ROGUE","DPS");local druid=add("Druid","DRUID","TANK,HEALER,DPS");add("Shaman","SHAMAN","DPS");add("Hunter","HUNTER","DPS")
local plan,why=l:BuildPlan();check(plan and #plan.members==5,why or "Five-person group generated")
local roles,cloth={TANK=0,HEALER=0,DPS=0},0
for _,m in ipairs(plan.members)do roles[m.role]=roles[m.role]+1;if l:Armor(m.profile)=="CLOTH"then cloth=cloth+1 end end
check(roles.TANK==1 and roles.HEALER==1 and roles.DPS==3,"Builder always fills correct dungeon roles")
check(cloth<=1,"Loot optimizer avoids three competing cloth DPS when alternatives exist")
local score=l:LootConflict({class="PALADIN",level=40,loot="AUTO"},"HEALER",{class="PALADIN",level=40,loot="AUTO"},"TANK")
check(score<l:LootConflict(mage,"DPS",lock,"DPS"),"Holy versus protection differs from shared caster loot")
check(l:Armor({class="HUNTER",level=20})=="LEATHER"and l:Armor({class="HUNTER",level=40})=="MAIL","Armor proficiency respects level-40 transition")
group={"Warlock-Realm"};check(l:LootWarning(mage,"DPS")~=nil,"Shared caster armor/stat warns softly where relevant");group={}
local itemScore=l:LootConflict({class="WARRIOR",level=20,loot="AUTO",wants={[123]=true}},"TANK",{class="MAGE",level=20,loot="AUTO",wants={[123]=true}},"DPS")
check(itemScore>=20,"Exact shared wishlist item adds strong conflict")
check(l:StartForming(),"Leader can start automatic formation")
local before=#invited;l:FormTick();check(#invited==before+1 and l.pendingMember,"One invitation attempted")
l:FormTick();check(#invited==before+1,"No invitation burst while acceptance pending")
combat=true;clock=clock+4;l:FormTick();check(#invited==before+1,"Combat skips this tick without dropping work")
combat=false;leader=false;group={l.pendingMember};l:FormTick();check(not l.options.auto,"Losing actual leadership stops formation")
group={};leader=true
level=12;l.options.carry=true;clock=clock+6
check(l:Join("DUNGEON",{"The Deadmines"},"HEALER","Carry me",5),"Level-12 leader can request carry above entry floor")
local low=add("LowOther","ROGUE","DPS",12)
local carry=l:BuildPlan();check(carry~=nil,"Carry team can be composed")
for _,m in ipairs(carry.members)do check(m.profile.name==player or m.profile.level>=18,"Only leader is below the normal minimum")end
check(not l:Eligible(low,l:OwnProfile()),"Another underlevel member cannot join automatic carry selection")
l.options.carry=false;check(not l:BuildPlan(),"Regular run does not admit underlevel leader")
level=20;l.db.leader=false;l.options.carry=true;clock=clock+6
check(not l:Join("DUNGEON",{"The Deadmines"},"HEALER","",5),"Carry flag without volunteering as leader rejected")
l.options.carry=false;l.db.leader=true
l:Show();l:SetPage("PVP");l.options.ranked=true;l.options.bracket=10;clock=clock+6
check(l:Join("PVP",{"Warsong Gulch"},"HEALER","Ranked",10),"10v10 ranked listing supported")
check(l:OwnProfile().rating==1804 and l:OwnProfile().rank==7,"Native bracket rating and honor rank displayed separately")
l:SetPage("ARENA");clock=clock+6
check(l:Join("ARENA",{"2v2"},"HEALER","Partner",2),"2v2 partner listing")
clock=clock+6;check(not l:Join("ARENA",{"3v3"},"HEALER","",2),"Arena team size cannot mismatch bracket")
clock=clock+6;check(l:Join("ARENA",{"3v3"},"HEALER","",3),"3v3 supported")
clock=clock+6;check(l:Join("ARENA",{"5v5"},"HEALER","",5),"5v5 supported")
GetPersonalRatedInfo=function()error('restricted')end;l.active=nil
check(l:OwnProfile().rating==-1,"Unavailable native rating stays unavailable rather than invented")
l:SetDiscoverable(false);check(not l:OwnProfile().available and not l.active,"Discovery opt-out leaves queue and directory")
l:SetDiscoverable(true);l:ShowProfile();l:ShowBuilder();l:ShowDiscord()
check(l.profileFrame:IsShown()and l.builderFrame:IsShown()and l.discordFrame:IsShown(),"All rich setup panels initialize")
local db=l:MirrorDB();db.relay=player;db.channels={general=true}
check(l:ImportDiscord("DC2|12345|general|DiscordName|Hello guild|"..clock.."|PUBLIC")==1,"Trusted relay imports public snapshot")
check(l:ImportDiscord("DC2|12345|general|DiscordName|Duplicate|"..clock.."|PUBLIC")==0,"Repeated Discord messages deduplicated")
l:Receive("DC2|12346|general|Fake|Forged|"..clock.."|PUBLIC","Other-Realm","GUILD")
check(#db.messages==1,"Untrusted guild sender cannot impersonate Discord relay")
check(l:ImportDiscord("DC2|12347|private|Person|Do not share|"..clock.."|PUBLIC")==0,"Unconfigured channels never mirrored")
check(l:ReplyDiscord("general","Ready for a dungeon"),"Reply queue supports members without Discord")
check(db.outbox[1].status~="Posted to Discord","Addon does not falsely claim network posting")
local id=db.outbox[1].id
check(l:ImportDiscord("DA2|"..id.."|"..player.."|general|12348|"..clock)==1 and db.outbox[1].status=="Posted to Discord","Actual bot acknowledgement can mark posting")
check(not l:ReplyDiscord("private","No"),"Replies bound to configured public aliases")
guild="Other";l:ProfileTick();check(not l:StartForming(),"Non-guild members cannot auto-form")
guild="Tranquility";group={};leader=true;level=20;class="PALADIN";clock=clock+6
l.queue={};l.entries={};l.profiles={};l.db.leader=true;l.db.roles="HEALER";l.mode="DUNGEON";l.activities={"The Deadmines"}
l.options.minLevel=18;l.options.maxLevel=24;l.options.carry=false;l.options.diversity=true
check(l:Join("DUNGEON",l.activities,"HEALER","Ready",5),"Leader requeues after changing context")
add("Tank2","WARRIOR","TANK");add("Mage2","MAGE","DPS");add("Rogue2","ROGUE","DPS");add("Shaman2","SHAMAN","DPS");add("Druid2","DRUID","TANK,DPS");add("Hunter2","HUNTER","DPS")
InviteUnit=function()error('native blocked')end
check(l:StartForming(),"A plan can be inspected before an API block")
l:FormTick();check(not l.options.auto,"Native failure stops formation without retries")
InviteUnit=function(name)invited[#invited+1]=name end
check(l:StartForming(),"Leader may explicitly restart after resolving permissions")
l:FormTick();local unanswered=l.pendingMember;clock=clock+26;l:FormTick()
check(unanswered and l.inviteCooldown[l:Key(unanswered)]>clock,"Unanswered invitation gets cooldown, not repeated spam")
l:StopForming();l.options.diversity=false
local regular=l:BuildPlan();check(regular and regular.score==0,"Diversity OFF preserves role/level composition without loot penalties")
l.profiles["stale-realm"]={name="Stale-Realm",at=clock-160};l.entries["stale-realm"]={name="Stale-Realm",at=clock-160}
l:ProfileTick();check(not l.profiles["stale-realm"]and not l.entries["stale-realm"],"Stale directory and ready rows expire even without viewing the board")
local countBefore=0;for _ in pairs(l.profiles)do countBefore=countBefore+1 end
l:Receive("H2|MAGE|20|DPS|AUTO|0|1|DUNGEON|0|10|99999|7|1|"..clock,"BadRating-Realm","GUILD")
local countAfter=0;for _ in pairs(l.profiles)do countAfter=countAfter+1 end
check(countBefore==countAfter,"Out-of-range remote rating rejected")
clock=clock+6;check(l:ReplyDiscord("general","Second reply"),"Second reply is separately tracked")
local second=db.outbox[#db.outbox]
l:Receive("DA2|"..second.id.."|"..player.."|general|55555|"..clock,"Untrusted-Realm","GUILD")
check(second.status~="Posted to Discord","Forged posting acknowledgement rejected")
l.queue={"DC2|1|general|Name|Text|10000|PUBLIC"};l:Send({"Q2"})
check(l.queue[1]=="Q2","LFG readiness/discovery packets take priority over Discord snapshots")
print("PASS: "..passed.." advanced guild LFG assertions")
