local count=0
local function check(v,why)assert(v,why);count=count+1 end
local time,guild=10000,"Tranquility"
local w={};setmetatable(w,{__index=function()return function()end end})
function w:SetText(s)self.text=s end;function w:GetText()return self.text or ""end
function w:Show()self.shown=true end;function w:IsShown()return self.shown end
function w:CreateFontString()return setmetatable({},{__index=w})end
CreateFrame=function()return setmetatable({},{__index=w})end
UIParent={};UISpecialFrames={};SlashCmdList={}
GetServerTime=function()return time end
GetUnitName=function()return "Me-Realm"end
GetNormalizedRealmName=function()return "Realm"end
UnitGUID=function()return "fixture-guid"end
TranquilityDB={security={vaultUnlocked={character=GetUnitName("player",true):lower(),guid="fixture-guid",confirmed=true}}}
GetGuildInfo=function()return guild,"Dedicated Member",3 end
C_ChatInfo={RegisterAddonMessagePrefix=function()end}
assert(loadfile("TranquilityLFG/Access.lua"))()
assert(loadfile("TranquilityLFG/LFG.lua"))()
local l=TranquilityLFG
check(l:Join("DUNGEON",{"Scarlet Monastery","Stratholme"},"HEALER","Have quests",5),"Member queues for multiple dungeons")
l:Receive("L|DUNGEON|TANK|Scarlet Monastery|Ready|5|10000","Tank-Realm","GUILD")
l:Receive("L|DUNGEON|DPS|Maraudon|Ready|5|10000","Other-Realm","GUILD")
l.mode="DUNGEON";l.activities={"Scarlet Monastery"}
check(#l:List()==2,"Only overlapping dungeon choices match")
l:Receive("L|DUNGEON|TANK|Scarlet Monastery|Spoof|5|10000","Outsider-Realm","WHISPER")
check(not l.entries["outsider-realm"],"Non-guild transport rejected")
l:Receive("L|DUNGEON|INVALID|Scarlet Monastery|Spoof|5|10000","Invalid-Realm","GUILD")
check(not l.entries["invalid-realm"],"Invalid roles rejected")
l:Receive("L|DUNGEON|TANK|Scarlet Monastery|Spoof|500|10000","Invalid-Realm","GUILD")
check(not l.entries["invalid-realm"],"Invalid group sizes rejected")
local invited
InviteUnit=function(n)invited=n end
check(l:Invite("Tank-Realm")and invited=="Tank-Realm","Clicked invite targets listed guildmate")
check(not l:Invite("Missing-Realm"),"Unlisted players cannot be invited")
l:Receive("X|10000","Tank-Realm","GUILD");check(not l.entries["tank-realm"],"Leave removes listing")
time=10121;check(#l:List()==0,"Stale listings expire")
guild="Other";check(not l:Join("DUNGEON",{"Scarlet Monastery"},"DPS","",5),"Other guilds cannot queue")
l:Receive("L|DUNGEON|TANK|Scarlet Monastery|Ready|5|10121","Tank-Realm","GUILD")
check(not l.entries["tank-realm"],"Other guilds cannot read board")
guild="Tranquility";time=10200
for _,mode in ipairs(l.modes)do check(l:Join(mode,{"Team"},"DPS","Plan only",5),mode.." queue supported");time=time+6 end
l:Show();check(l.frame and #l.rows==6,"Guild board opens")
l:Leave();check(not l.active,"Explicit leave stops queue")
print("PASS: "..count.." guild LFG assertions")
