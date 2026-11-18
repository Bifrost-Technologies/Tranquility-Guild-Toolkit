-- Rule verified 2026-11-15: highest party member more than 12 levels above enemy.
-- https://us.forums.blizzard.com/en/wow/t/2416343/1
if _G.TranquilityXPWarning then return end
local X={enabled=true,seen={},lastSent=-1000}
_G.TranquilityXPWarning=X
local function value(fn,...)
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,...)
    if not ok or issecretvalue and issecretvalue(v) then return nil end
    return v
end
function X:Assess(enemy)
    local level=value(UnitLevel,enemy)
    if type(level)~="number" or level<1 or level>100 or value(UnitIsPlayer,enemy)~=false or value(UnitCanAttack,"player",enemy)~=true then return end
    local highest,name=0,nil
    for i=0,4 do
        local unit=i==0 and "player" or "party"..i
        local n=value(UnitLevel,unit)
        if value(UnitExists,unit)==true and type(n)=="number" and n>highest and n<=100 then
            local candidate=value(GetUnitName,unit,true)
            if type(candidate)=="string" and not candidate:find("[%c|]") then highest,name=n,candidate end
        end
    end
    if name and highest-level>12 then return name,highest,level end
end
function X:Check(enemy)
    if not TranquilityAccess or not TranquilityAccess:Allowed()then return end
    if not self.enabled or value(IsInGroup)~=true or value(IsInRaid)==true then return end
    if type(IsInInstance)~="function" then return end
    local ok,inside,kind=pcall(IsInInstance)
    if not ok or issecretvalue and (issecretvalue(inside) or issecretvalue(kind)) or not inside or kind~="party" then return end
    local name,high,low=self:Assess(enemy)
    if not name then return end
    local now=GetTime();local key=name..":"..high..":"..low
    if self.seen[key] or now-self.lastSent<120 then return end
    local message=("[Tranquility XP] %s (level %d) is %d levels above this level %d enemy. Under the current dungeon rule, this kill gives the party no XP (gap >12). Higher-level enemies may still give XP."):format(name,high,high-low,low)
    if #message>255 then message=("[Tranquility XP] A level %d member is too high for this level %d enemy: party kill XP is zero when the gap exceeds 12. Check party levels."):format(high,low) end
    self.seen[key]=true;self.lastSent=now
    local api=C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    local channel=LE_PARTY_CATEGORY_INSTANCE and value(IsInGroup,LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    local sent=api and pcall(api,message,channel)
    if not sent and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(message.." (Party chat unavailable.)") end
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_TARGET_CHANGED","NAME_PLATE_UNIT_ADDED","GROUP_ROSTER_UPDATE","PLAYER_ENTERING_WORLD","CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_INSTANCE_CHAT","CHAT_MSG_INSTANCE_CHAT_LEADER"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event,arg)
    if event:find("^CHAT_MSG_") then
        if not (issecretvalue and issecretvalue(arg)) and type(arg)=="string" and arg:find("[Tranquility XP]",1,true) then X.lastSent=GetTime() end
        return
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" then X.seen={} end
    X:Check(event=="NAME_PLATE_UNIT_ADDED" and arg or "target")
end)
SLASH_TRANQUILITYXP1="/tranqxp"
SlashCmdList.TRANQUILITYXP=function(text)
    if TranquilityAccess and not TranquilityAccess:Require()then return end
    text=(text or ""):lower()
    if text=="off" then X.enabled=false elseif text=="on" then X.enabled=true end
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Dungeon XP warnings "..(X.enabled and "ON" or "OFF")..". /tranqxp on | off. Compares observed enemy levels; unknown levels are skipped.") end
end
