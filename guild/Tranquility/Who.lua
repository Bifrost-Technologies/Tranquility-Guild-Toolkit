local T = _G.Tranquility
T.who = { listeners = {} }
local W = T.who
function W:Subscribe(callback) self.listeners[#self.listeners+1] = callback end
function W:Read()
    local api = C_FriendList
    local countAPI = api and api.GetNumWhoResults or GetNumWhoResults
    local infoAPI = api and api.GetWhoInfo or GetWhoInfo
    if not countAPI or not infoAPI then return {}, "WHO result API unavailable." end
    local ok, count, total = pcall(countAPI)
    count, total = T.Public(count), T.Public(total)
    if not ok or type(count) ~= "number" then return {}, "WHO results unavailable or restricted." end
    local rows, seen = {}, {}
    for i = 1, math.min(count, 1000) do
        local good, first, guild, level, _, class, zone = pcall(infoAPI, i)
        first = T.Public(first)
        local row
        if good and type(first) == "table" then
            local guild
            if not (issecretvalue and issecretvalue(first.fullGuildName)) then
                guild = T.Text(first.fullGuildName)
                if first.fullGuildName == nil then guild = T.Text(first.guild) end
            end
            row = { name = T.Text(first.fullName) or T.Text(first.name), guild = guild, level = T.Public(first.level), class = T.Text(first.filename) or T.Text(first.classStr), zone = T.Text(first.area) or T.Text(first.areaName) }
        elseif good then row = { name = T.Text(first), guild = T.Text(guild), level = T.Public(level), class = T.Text(class), zone = T.Text(zone) } end
        if row and self:ValidName(row.name) and not seen[row.name:lower()] then
            seen[row.name:lower()] = true
            row.guildless = row.guild ~= nil and row.guild:match("^%s*$") ~= nil
            rows[#rows+1] = row
        end
    end
    return rows, ("%d readable / %d returned; %s matched. The client controls its result cap."):format(#rows, count, type(total)=="number" and tostring(total) or "unknown")
end
function W:ValidName(name)
    return type(name) == "string" and #name > 0 and #name <= 100 and not name:find("[%s%c|/\\%[%]\"]")
end
function W:Import()
    self.rows, self.status = self:Read()
    self.at = GetServerTime()
    for _, callback in ipairs(self.listeners) do
        local ok, err = pcall(callback, self.rows, self.status)
        if not ok then T:Fault("WHO", err) end
    end
    return self.rows
end
function W:Query(zone,minimum,maximum)
    zone = T.Text(zone)
    if not zone or #zone > 100 or zone:find('[%c|"]') then return nil end
    local query='/who z-"' .. zone .. '"'
    if minimum~=nil or maximum~=nil then
        minimum,maximum=tonumber(minimum),tonumber(maximum)
        if not minimum or not maximum or minimum<1 or maximum>60 or minimum>maximum or minimum%1~=0 or maximum%1~=0 then return nil end
        query=query .. (" %d-%d"):format(minimum,maximum)
    end
    return query
end
local frame = CreateFrame("Frame")
T:RegisterObservedEvent(frame, "WHO_LIST_UPDATE", "WHO")
frame:SetScript("OnEvent", function() W:Import() end)
-- WHO requests are entered by the user in Blizzard chat. Never send or repeat searches here.
