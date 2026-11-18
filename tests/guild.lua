-- Public edition contract tests. Run from repository root with Lua 5.1+ or Fengari.
local passed=0
local function check(value,message) assert(value,message); passed=passed+1 end
local noop=function() end
local now=86400*100
local combat=false
local frames,who,timers,casts,messages,inspect={}, {}, {}, {}, {}, {}
local secret={}
issecretvalue=function(v) return v==secret end
local Widget={}
function Widget:SetScript(key,fn) self.scripts[key]=fn end
function Widget:RegisterEvent(key) check(key~="COMBAT_LOG_EVENT_UNFILTERED","Never register restricted combat log"); self.events[key]=true end
function Widget:SetText(value) self.text=value end
function Widget:GetText() return self.text or "" end
function Widget:SetAttribute(key,value) self.attributes[key]=value end
function Widget:GetAttribute(key) return self.attributes[key] end
function Widget:Show() self.shown=true end
function Widget:Hide() local shown=self.shown; self.shown=false; if shown and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Widget:IsShown() return self.shown end
function Widget:SetShown(value) if value then self:Show() else self:Hide() end end
function Widget:SetChecked(value) self.checked=value end
function Widget:GetChecked() return self.checked end
function Widget:SetEnabled(value) self.enabled=value end
function Widget:SetFocus() self.focus=true end
function Widget:ClearFocus() self.focus=false end
function Widget:HighlightText() self.highlighted=true end
function Widget:GetStringHeight() return 150 end
for _,method in ipairs({"SetPoint","SetSize","SetJustifyH","SetJustifyV","SetWidth","SetHeight","SetTextColor","SetFrameStrata","SetClampedToScreen","EnableMouse","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","SetBackdrop","SetBackdropColor","SetAutoFocus","SetMaxLetters","SetNumeric","SetAllPoints","SetColorTexture","SetAlpha","SetSpacing","RegisterForClicks","SetScrollChild"}) do Widget[method]=noop end
CreateFrame=function(_,name)
    local frame=setmetatable({scripts={},events={},attributes={},shown=true,name=name},{__index=Widget})
    frames[#frames+1]=frame; if name then _G[name]=frame end; return frame
end
Widget.CreateFontString=function() return CreateFrame() end
Widget.CreateTexture=function() return CreateFrame() end
RegisterStateDriver=noop
GetTime=function() return now end
GetServerTime=function() return now end
GetRealmName=function() return "TestRealm" end
GetRealZoneText=function() return "Elwynn Forest" end
GetSubZoneText=function() return "Goldshire" end
GetInstanceInfo=function() return "Elwynn Forest","none",0,"" end
UnitFactionGroup=function() return "Alliance" end
UnitClass=function() return "Warlock","WARLOCK" end
InCombatLockdown=function() return combat end
IsInRaid=function() return false end
IsInGroup=function() return false end
GetNumGroupMembers=function() return 0 end
GetNumSubgroupMembers=function() return 0 end
UnitExists=function(unit) return unit=="player" end
UnitIsUnit=function(a,b) return a==b end
UnitGUID=function(unit) return unit=="player" and "me" or nil end
GetUnitName=function(unit) return unit=="player" and "Caster" or nil end
UnitGroupRolesAssigned=function() return "NONE" end
UnitCastingInfo=function() return nil end
UnitChannelInfo=function() return nil end
IsPlayerSpell=function() return true end
UnitHealth=function() return secret end
UnitHealthMax=function() return secret end
UnitPower=function() return secret end
UnitPowerMax=function() return secret end
UnitAffectingCombat=function() return false end
UnitIsConnected=function() return true end
UnitIsDeadOrGhost=function() return false end
CanInspect=function() return false end
NotifyInspect=function(unit) inspect[#inspect+1]=unit end
GetInventoryItemLink=function() return nil end
GetInventoryItemTexture=function() return nil end
SendChatMessage=function(message) messages[#messages+1]=message end
local function prohibited() error("Public edition invoked an automated gameplay action") end
SendWho=prohibited; GuildInvite=prohibited; CastSpellByName=prohibited; RunMacroText=prohibited; ReloadUI=prohibited
C_GuildInfo={Invite=prohibited}
C_FriendList={GetNumWhoResults=function() return #who,150 end,GetWhoInfo=function(i) return who[i] end,SendWho=prohibited}
C_Timer={After=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end,NewTicker=prohibited}
C_Item={GetItemInfo=function(id) return "Item "..tostring(id),nil,2,10,nil,nil,nil,nil,"",nil,nil,nil,nil,0 end}
GetItemInfo=C_Item.GetItemInfo
C_Map={GetBestMapForUnit=function() return 1 end,GetMapInfo=function() return {name="Elwynn Forest",mapType=3} end}
Enum={UIMapType={Zone=3}}
date=os.date
local files={Recruitment="Recruitment",Regions="Regions",Auctions="Auctions",Loot="Loot",Dungeon="Dungeon",Summons="Summons",Gear="Gear",Phases="Phases",DB="Database",Info="Info",PvP="PvP"}
local order={"DB","Loot","Auctions","Recruitment","Regions","Summons","Dungeon","Gear","Phases","Info","PvP"}
local function dispatch(event,...)
    local snapshot={}; for _,frame in ipairs(frames) do snapshot[#snapshot+1]=frame end
    for _,frame in ipairs(snapshot) do if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,...) end end
end
local function boot(enabled)
    frames,who,timers,messages,inspect={},{},{},{},{}
    UIParent=CreateFrame(); Minimap=CreateFrame(); UISpecialFrames={}; SlashCmdList={}
    DEFAULT_CHAT_FRAME={AddMessage=noop}; GameTooltip={SetOwner=noop,SetText=noop,Show=noop,Hide=noop}
    TranquilityDB=nil
    for id in pairs(files) do _G["Tranquility"..id.."DB"]=nil end
    TranquilityAccess=nil;GetGuildInfo=function()return "Tranquility","Dedicated Member",3 end
    assert(loadfile("guild/Tranquility/Access.lua"))()
    assert(loadfile("guild/Tranquility/Vault.lua"))()
    assert(loadfile("guild/Tranquility/Core.lua"))("Tranquility",{})
    assert(loadfile("guild/Tranquility/UI.lua"))("Tranquility",{})
    assert(loadfile("guild/Tranquility/RecruitData.lua"))("Tranquility",{})
    assert(loadfile("guild/Tranquility/Settings.lua"))("Tranquility",{})
    assert(loadfile("guild/Tranquility/Who.lua"))("Tranquility",{})
    for _,file in ipairs({"WorkBoard","Verification","WorkUI","Contracts","ContractUI"})do assert(loadfile("guild/Tranquility/"..file..".lua"))()end
    dispatch("ADDON_LOADED","Tranquility")
    for _,id in ipairs(order) do
        if enabled[id] then
            assert(loadfile("guild/Tranquility_"..id.."/"..files[id]..".lua"))("Tranquility_"..id,{})
            if id=="PvP"then for _,name in ipairs({"Alerts","Interface"})do assert(loadfile("guild/Tranquility_PvP/"..name..".lua"))()end end
            dispatch("ADDON_LOADED","Tranquility_"..id)
        end
    end
    TranquilityDB.security=TranquilityDB.security or {};TranquilityDB.security.vaultUnlocked={character="caster-testrealm",guid="me",confirmed=true}
    dispatch("PLAYER_LOGIN")
    check(#timers==0 and #messages==0 and #inspect==0,"Startup is passive")
    return Tranquility
end
-- Core only, each feature alone, the whole suite, and every single-feature-disabled case.
local all={}; for id in pairs(files) do all[id]=true end
local cases={{}}
for id in pairs(files) do cases[#cases+1]={[id]=true} end
cases[#cases+1]=all
for excluded in pairs(files) do local enabled={}; for id in pairs(files) do if id~=excluded then enabled[id]=true end end; cases[#cases+1]=enabled end
for _,enabled in ipairs(cases) do
    local T=boot(enabled)
    SlashCmdList.TRANQUILITY("")
    check(T.frame:IsShown(),"Home opens in every module combination")
    for _,item in ipairs(T.catalog) do
        T:OpenModule(item[1])
        if enabled[item[1]] then
            check(T.modules[item[1]].ready,"Optional module initialized: "..item[1])
            check(T.modules[item[1]].object.frame and T.modules[item[1]].object.frame:IsShown(),"Optional UI opens: "..item[1])
            T.modules[item[1]].object.frame:Hide()
        end
    end
    check(#T.errors==0,table.concat(T.errors,"\n"))
    check(#timers==0 and #messages==0 and #inspect==0,"Opening panels never initiates game actions")
end
local T=boot(all)
check(T.db.loot==TranquilityLootDB and T.db.auction==TranquilityAuctionsDB,"Feature SavedVariables are independently mounted")
check(TranquilityDB.loot==nil and _G.TitansRecruitBridge==nil,"No duplicate or custom-edition SavedVariables")
local R=T.recruitment
local function row(name,guild,zone) return {fullName=name,fullGuildName=guild,level=10,area=zone or "Stormwind City"} end
who={row("Alice",""),row("Éowyn-Realm",""),row("Guilded","Guild"),row("Unknown",nil),row("Restricted",secret),row("Alice",""),row("Bad Name",""),row("SpaceGuild","  ")}
dispatch("WHO_LIST_UPDATE")
check(#R.rows==3,"Deduplicate; include only explicit guildless; retain accented names")
T:OpenModule("Recruitment")
R:Select(R.rows[1]); check(R.command:GetText()=="/ginvite Alice","Manual invite text")
R:PrepareGreeting(); check(R.command:GetText():match("^/w Alice Hello Alice!"),"Personalized manual greeting")
check(#messages==0,"Greeting preparation sends nothing")
R:Mark("contacted"); check(#R:Eligible()==2,"Contacted names skipped")
T.who:Import(); check(#R:Eligible()==2,"Skip history survives next WHO import")
now=now+4;R:Select(R:Eligible()[1]); R:Mark("ignored"); check(#R:Eligible()==1,"Ignore list separate from contacted")
check(T.who:Query('Stormwind City')=='/who z-"Stormwind City"',"Manual WHO command")
check(T.who:Query('bad" injected')==nil and not T.who:ValidName("Name\n/invite Bad"),"Reject command injection")
who={{fullName="RestrictedGuild",fullGuildName=secret,guild="",level=10,area="Ironforge"}}
dispatch("WHO_LIST_UPDATE")
R:ImportCurrent()
check(#R.rows==0,"Never infer guildless from a fallback when the primary guild field is restricted")
who={}
for i=1,200 do who[i]=row("Player"..i,"") end
dispatch("WHO_LIST_UPDATE")
R:ImportCurrent()
check(#T.who.rows==200 and #R.rows==50 and R.eligibleObserved==200,"Read all WHO rows while preparing only one fifty-player manual batch")
R.page=25; R:Refresh(); check(R.page==7,"The complete fifty-player batch is accessible through pagination")
local old=C_FriendList
C_FriendList=nil
GetNumWhoResults=function() return 1,1 end
GetWhoInfo=function() return "Legacy","",10,"Human","Mage","Ironforge" end
local legacy=T.who:Read(); check(#legacy==1 and legacy[1].guildless and legacy[1].zone=="Ironforge","Legacy WHO tuple compatibility")
C_FriendList=old
local A=T.auction
local id=2770
for i=1,3 do now=now+86400; A:Record(id,100,5) end
now=now+86400
local base,days=A:Baseline(id,math.floor(now/86400)); check(base==100 and days==3,"Auction baseline requires separate prior days")
A:Record(id,200,4); A:Record(id,250,1)
check(#A.history[id]==4 and A.history[id][4].price==200,"Same-day repeated samples cannot inflate baseline sample count")
A:AddItem(999); check(A.watch[#A.watch].id==999,"Watchlist works without reference DB")
A.open=true
C_AuctionHouse={MakeItemKey=function() return {} end,GetNumCommoditySearchResults=function() return 1 end,HasFullCommoditySearchResults=function() return false end,GetCommoditySearchResultInfo=prohibited}
A:ReadResults(id); check(A.status:find("Incomplete"),"Discard incomplete market result sets")
C_AuctionHouse.HasFullCommoditySearchResults=function() return true end
C_AuctionHouse.GetCommoditySearchResultInfo=function() return {unitPrice=300,quantity=10} end
A:ReadResults(id); check(A.snapshots[id].price==300 and A.snapshots[id].quantity==10,"Read complete current results without searching")
C_AuctionHouse.HasFullCommoditySearchResults=function() return secret end
A:ReadResults(id); check(A.status:find("Incomplete"),"Restricted completeness is not treated as complete")
C_AuctionHouse.GetNumCommoditySearchResults=function() error("Unavailable client API") end
A:ReadResults(id); check(A.status:find("unavailable or restricted"),"Client read failure produces a bounded manual fallback")
check(not A:Record(id,0/0) and not A:Record(id,math.huge) and not A:Record(1.5,100),"Reject non-finite prices and invalid item IDs")
local D=T.dungeon
local _,flash=D:Pressure(20,10,1); check(not flash,"Single mob cannot trigger pressure flash")
_,flash=D:Pressure(20,10,3); check(flash,"Three mobs and low HP trigger local flash")
_,flash=D:Pressure(nil,10,3); check(not flash,"Restricted HP yields no assessment")
check(D:CastsRemaining(50,{casts=2,manaSpent=10})==nil,"No ungrounded cast estimate")
check(D:CastsRemaining(50,{casts=3,manaSpent=15})==6,"Cast estimate reserves low-mana threshold")
T:OpenModule("Dungeon"); D.active=true; D.frame:Hide(); check(not D.active,"Close stops dungeon monitoring")
local L=T.loot
local link="|Hitem:777|h[Test drop]|h"
L:Record(link,"roll offered",{zone="Westfall",instance="The Deadmines",boss="Unknown"},1,"roll:1")
L:Record(link,"roll offered",nil,1,"roll:1")
L:Record(link,"received by me",{zone="Westfall",instance="Open world"},2)
check(L.db.items[777].rolls==1 and L.db.items[777].received==2,"Roll deduplication and received quantities remain distinct")
check(T:FarmSource(777):find("Westfall"),"Auction sources use observed journal evidence")
local G=T.gear
local items={}; for _,slot in ipairs(G.slots) do items[slot]={empty=true} end
items[16]={quality=3,level=20,equipLoc="INVTYPE_2HWEAPON"}
local score=G:Score(items); check(score.counts[3]==2 and score.unknown==0,"Two-handed weapon covers empty offhand")
local previousGUID,previousName=UnitGUID,GetUnitName
local previousLink,previousTexture=GetInventoryItemLink,GetInventoryItemTexture
UnitGUID=function(unit) return unit=="target" and "inspected-target" or "me" end
GetUnitName=function(unit) return unit=="target" and "Inspected" or "Caster" end
GetInventoryItemLink=function(_,slot) return slot==1 and secret or nil end
GetInventoryItemTexture=function() return nil end
G.pending="inspected-target";G:Read("inspected-target")
check(G.records["inspected-target"].unknown==1,"Restricted inventory slots remain unknown rather than being scored as empty")
local previousCanInspect=CanInspect
CanInspect=function() return true end
local firstTimer=#timers+1
G:Inspect();local firstRequest=G.requestSerial
now=now+6;G:Inspect()
check(G.requestSerial==firstRequest+1,"Each inspect request has a distinct timeout identity")
now=now+9;timers[firstTimer].fn()
check(G.pending=="inspected-target","An old timeout cannot cancel a newer request for the same player")
now=now+6;timers[firstTimer+1].fn()
check(G.pending==nil,"The current request can still time out normally")
CanInspect=previousCanInspect
UnitGUID,GetUnitName=previousGUID,previousName
GetInventoryItemLink,GetInventoryItemTexture=previousLink,previousTexture
inspect={}
local P=T.population
P:Record({{zone="Ironforge"},{zone="Ironforge"},{zone="Westfall"}})
check(P.db.samples.Ironforge.count==2,"Region samples group actual result zones")
local phases=T.layers
check(phases:ParseLabel("English 46").instance==46,"Parse regional label")
check(phases:ParseLabel("46. English")==nil,"Local channel shortcut is not a phase ID")
T:OpenModule("Info")
local I=T.modules.Info.object
I:Reset("Recruitment","recruitment")
check(#R:Eligible()==0 and next(R.history.contacted)==nil and #T.who.listeners==1,"Reset clears local history without duplicate subscription")
I:Reset("Loot","loot"); check(next(L.db.items)==nil,"Reset erases feature data in place")
dispatch("ADDON_ACTION_FORBIDDEN","Tranquility_Phases","TestRestrictedAPI")
check(#T.errors==1,"Capture blocked-action diagnostic without bypassing warning")
combat=true
local before=#frames; T:OpenModule("Summons"); check(#frames==before,"No secure UI construction in combat")
combat=false
T:OpenModule("Summons"); T.summons:Start()
check(#messages==0 and #inspect==0,"Summons list preparation never casts or sends chat")
local S=T.summons
check(S:IsIdle(),"Public idle cast state can prepare a manual ritual")
local originalCasting=UnitCastingInfo
UnitCastingInfo=function() return secret end
check(not S:IsIdle(),"Restricted cast state disables manual ritual preparation")
S:Refresh();check(S.button:GetAttribute("type")==nil,"Unknown cast state clears the secure action outside combat")
UnitCastingInfo=originalCasting
local originalInfo=C_Map.GetMapInfo
C_Map.GetMapInfo=function() return secret end
check(S:Zone("player")=="Elwynn Forest","Restricted map info falls back only to the player's public zone label")
C_Map.GetMapInfo=originalInfo
local findRoles=D.FindRoles
D.FindRoles=function() error("Simulated unavailable client data") end
D.active=true;local priorErrors=#T.errors;D:Sample()
check(not D.active and not D.flash and D.hp==nil,"Unavailable dungeon data stops monitoring and clears stale assessments")
check(#T.errors==priorErrors+1,"Dungeon failure is recorded once for local diagnostics")
table.remove(T.errors,1);D.FindRoles=findRoles
local previousGroup,previousChat=IsInGroup,SendChatMessage
local broadcasts={}
IsInGroup=function() return true end
SendChatMessage=function(message,channel) broadcasts[#broadcasts+1]={message=message,channel=channel} end
D:Broadcast(false);D:Broadcast(false)
check(#broadcasts==1 and broadcasts[1].channel=="PARTY" and #broadcasts[1].message<=250,"Party broadcasts require an explicit call and honor the cooldown")
check(broadcasts[1].message:match("^Tranquility:"),"Public party text uses only the public guild branding")
now=now+16;D:Broadcast(false);check(#broadcasts==2,"A new explicit broadcast is allowed after its cooldown")
IsInGroup,SendChatMessage=previousGroup,previousChat
T.work:Show();T.work:ShowContracts();check(T.work.frame:IsShown()and T.work.contractFrame:IsShown(),"Member job and contract panels open")
GetGuildInfo=function()return "Tranquility","Guild Master",0 end;T.work:ShowAdmin();T.work:ShowPayouts();T.work:ShowVerification();T.work:ShowPayroll();check(T.work.adminFrame:IsShown()and T.work.payrollFrame:IsShown(),"Authorized administration panels open")
print(("PASS: %d assertions; %d module configurations; public edition contracts"):format(passed,#cases))
