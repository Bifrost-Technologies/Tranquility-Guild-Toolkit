local addon = ...
local L = { mode = "GUILD", profession = "Alchemy", hub = "Stormwind City", minimum = 1, maximum = 60, rows = {}, page = 1 }
_G.LookingForProfession = L
L.professions = {"Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Leatherworking", "Mining", "Skinning", "Tailoring", "Cooking", "Fishing", "First Aid"}
L.hubs = {"Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity", "Booty Bay", "Gadgetzan", "Everlook"}
local function public(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function contains(list, v) for _, x in ipairs(list) do if x == v then return true end end end
function L:Settings()
    LookingForProfessionDB = type(LookingForProfessionDB) == "table" and LookingForProfessionDB or {}
    local realm = (GetRealmName and GetRealmName() or "Unknown") .. ":" .. (UnitFactionGroup and UnitFactionGroup("player") or "Unknown")
    LookingForProfessionDB[realm] = LookingForProfessionDB[realm] or { profiles = {}, items = {} }
    self.db = LookingForProfessionDB[realm]; return self.db
end
function L:Key(name)
    if type(name) ~= "string" or #name == 0 or #name > 100 or name:find('[%s%c|/\\"]') then return nil end
    if not name:find("-",1,true) then name = name .. "-" .. ((GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or "Unknown"):gsub("%s", "") end
    return name:lower()
end
function L:Bounds(a,b)
    a,b=tonumber(a),tonumber(b)
    if not a or not b or a%1~=0 or b%1~=0 or a<1 or b>60 or a>b then return false end
    self.minimum,self.maximum=a,b; return true
end
function L:Record(name, profession)
    local key=self:Key(name)
    if not key or not contains(self.professions,profession) then return false end
    self:Settings(); self.db.profiles[key]=self.db.profiles[key] or {}
    self.db.profiles[key][profession]={at=GetServerTime(),source="Manually confirmed"}; return true
end
function L:Forget(name)
    self:Settings();local key=self:Key(name);if key then self.db.profiles[key]=nil end
end
function L:Filter(rows)
    self:Settings();local result,seen={},{}
    for _,r in ipairs(rows) do
        local key=self:Key(r.name)
        if key and not seen[key] and contains(self.hubs,r.zone) and (self.mode=="GUILD" or r.zone==self.hub)
            and type(r.level)=="number" and r.level>=self.minimum and r.level<=self.maximum
            and (self.mode~="GUILD" or r.member==true) then
            seen[key]=true;r.profile=self.db.profiles[key] and self.db.profiles[key][self.profession]
            result[#result+1]=r
        end
    end
    table.sort(result,function(a,b) if not not a.profile ~= not not b.profile then return a.profile~=nil end return a.name<b.name end)
    return result
end
function L:Import()
    local rows={}
    if self.mode=="GUILD" then
        if not GetNumGuildMembers or not GetGuildRosterInfo then return "Guild roster API unavailable." end
        for i=1,GetNumGuildMembers() do
            local name,_,_,level,_,zone,_,_,online=GetGuildRosterInfo(i)
            if public(online)==true or public(online)==1 then rows[#rows+1]={name=public(name),level=public(level),zone=public(zone),member=true} end
        end
    else
        local count=C_FriendList and C_FriendList.GetNumWhoResults or GetNumWhoResults
        local info=C_FriendList and C_FriendList.GetWhoInfo or GetWhoInfo
        if not count or not info then return "WHO API unavailable." end
        local n=public(count()); if type(n)~="number" then return "WHO results restricted." end
        for i=1,math.min(n,1000) do
            local name,_,level,_,_,zone=info(i);name=public(name)
            if type(name)=="table" then local r=name;name=public(r.fullName) or public(r.name);level=public(r.level);zone=public(r.area) or public(r.areaName) end
            rows[#rows+1]={name=name,level=public(level),zone=public(zone)}
        end
    end
    self.rows=self:Filter(rows);self.page=1
    return #self.rows .. " city/hub candidates. Profession unknown unless recorded; roster/WHO may be incomplete."
end
function L:Query()
    if not contains(self.hubs,self.hub) then return nil end
    return ('/who z-"%s" %d-%d'):format(self.hub,self.minimum,self.maximum)
end
function L:ScanRecipes()
    self:Settings()
    if not GetNumTradeSkills or not GetTradeSkillItemLink or not GetTradeSkillLine then return "Legacy recipe API unavailable on this client." end
    local profession=GetTradeSkillLine()
    if not contains(self.professions,profession) then return "Open your profession recipe window first (English profession names)." end
    local getInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
    if not getInfo then return "Item data API unavailable." end
    local count,missing=0,0
    for i=1,GetNumTradeSkills() do
        local link=GetTradeSkillItemLink(i)
        if link then
            local name,_,_,_,required=getInfo(link);local id=tonumber(link:match("item:(%d+)"))
            if name and id and type(required)=="number" then
                self.db.items[id]={name=name,profession=profession,required=required};count=count+1
            else missing=missing+1 end
        end
    end
    return count.." recipe outputs indexed; "..missing.." uncached (scan again). Item use level is not crafter skill."
end
function L:UseItem(id)
    self:Settings();local item=self.db.items[tonumber(id)]
    if not item then return false,"Item not indexed. Open its profession and scan recipes first." end
    self.profession=item.profession
    return true,item.name..": use level "..item.required..". Choose crafter search levels independently."
end
local f=CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent",function(_,_,name) if name==addon then L:Settings() end end)
SLASH_LOOKINGFORPROFESSION1="/lfp"
SlashCmdList.LOOKINGFORPROFESSION=function() L:Show() end
