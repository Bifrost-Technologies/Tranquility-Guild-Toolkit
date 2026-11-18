local TG = _G.Tranquility
local L = {}
TG.layers = L
local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function text(value)
    value = public(value)
    if type(value) ~= "string" or #value > 160 or value:find("[%c|]") then return nil end
    return value:match("^%s*(.-)%s*$")
end
local function number(value)
    value = public(value)
    if type(value) == "number" and value > 0 and value < 9007199254740992 and value % 1 == 0 then return value end
end
function L:Settings()
    TG.db.layers = TG.db.layers or { family = "English", history = {} }
    return TG.db.layers
end
function L:ReadAPI(method, ...)
    if self:Settings().blockedAPI then
        self.tracking=false; if self.track then self.track:SetChecked(false) end
        return false
    end
    local function pack(...) return { n = select("#", ...), ... } end
    self.readInProgress = true
    local result = pack(pcall(method, ...))
    self.readInProgress = false
    if self:Settings().blockedAPI then
        self.tracking=false; if self.track then self.track:SetChecked(false) end
        return false
    end
    return (unpack or table.unpack)(result, 1, result.n)
end
function L:ParseLabel(value)
    value = text(value)
    if not value or value == "" then return nil end
    if value:match("^%[.*%]$") then value = value:sub(2,-2) end
    value = value:gsub("^%d+%.%s*", "")
    local family, id = value:match("^(.-)[%s#%-]+(%d+)$")
    id, family = tonumber(id), family and text(family)
    if not family or family == "" or not number(id) then return nil end
    return { family = family, instance = id, label = family .. " " .. ("%.0f"):format(id) }
end
function L:HintForLog()
    local row = self:Current()
    return row and row.label or nil
end
function L:Context()
    return text(GetRealmName and GetRealmName()) or "Unknown realm", text(GetZoneText and GetZoneText()) or "Unknown zone"
end
function L:Current()
    local config, now = self:Settings(), GetServerTime()
    local realm, zone = self:Context()
    local manual = config.manual
    if manual and not manual.invalidated and manual.realm == realm and manual.zone == zone and now >= manual.at and now - manual.at <= 300 then return manual end
    if self.current and not self.stale and self.current.realm == realm and self.current.zone == zone and now >= self.current.at and now - self.current.at <= 120 then return self.current end
    return nil
end
function L:Remember(row)
    local config = self:Settings()
    local last = config.history[#config.history]
    if not last or last.label ~= row.label or last.realm ~= row.realm or last.zone ~= row.zone then
        config.history[#config.history + 1] = { label = row.label, realm = row.realm, zone = row.zone, at = row.at, source = row.source }
        while #config.history > 25 do table.remove(config.history, 1) end
    end
end
function L:SetManual(label)
    local row = self:ParseLabel(label)
    if not row then return false end
    row.realm, row.zone = self:Context(); row.at, row.source = GetServerTime(), "manual observation (expires in 5 minutes)"
    self:Settings().manual = row; self:Remember(row); return true
end
function L:SetPeer(name, label, zone, realm)
    local row = self:ParseLabel(label)
    name, zone = text(name), text(zone)
    if not row or not name or name == "" then return false end
    row.name, row.zone, row.at, row.source = name, zone ~= "" and zone or nil, GetServerTime(), "manual guildmate report"
    row.realm = text(realm); if row.realm == "" then row.realm = nil end
    self:Settings().peer = row; return true
end
function L:Compare(own, peer)
    if not own or not peer then return "unavailable", "Record both channel labels to compare." end
    if GetServerTime() - peer.at > 600 then return "stale", "Guildmate report is over 10 minutes old; ask for an updated label." end
    if peer.realm and own.realm ~= peer.realm or peer.zone and own.zone ~= peer.zone then return "context", "Different realm/city context: these channel numbers are not comparable." end
    if own.family:lower() ~= peer.family:lower() then return "context", "Different channel families: compare the same regional channel." end
    local status = own.instance == peer.instance and "matching" or "different"
    local message = status == "matching" and "Matching channel hint; check visibility/party phase to confirm the same world copy."
        or "Different channel hints; possible different copies. Join the party and use the game's refresh notice if offered."
    if not peer.zone then message = message .. " Guildmate city was not provided." end
    if not peer.realm then message = message .. " Guildmate realm was not provided." end
    return status, message
end
function L:ReadChannels()
    self.raw, self.current, self.stale = {}, nil, false
    local config, rows, seen = self:Settings(), {}, {}
    if config.blockedAPI then self.channelStatus = "Client blocked " .. config.blockedAPI .. ". Automatic reads stopped; enter your visible label manually."; return false end
    local lockdown = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    if lockdown then
        local ok, restricted = self:ReadAPI(lockdown)
        if not ok or public(restricted) ~= false then self.channelStatus = "Chat data is restricted; enter your observed label manually."; return false end
    end
    local function add(localID, name, count)
        localID, name = number(localID), text(name)
        if not name or name == "" then return end
        local key = tostring(localID) .. ":" .. name
        if seen[key] then if type(public(count)) == "number" then seen[key].members = public(count) end; return end
        local row = { localID = localID, name = name, members = public(count) }
        seen[key] = row; rows[#rows + 1] = row
    end
    if type(GetChannelList) == "function" then
        local ok, list = self:ReadAPI(function() return { GetChannelList() } end)
        if ok then for index = 1, math.min(#list,600), 3 do if public(list[index+2]) ~= true then add(list[index], list[index+1]) end end end
    end
    if type(GetNumDisplayChannels) == "function" and type(GetChannelDisplayInfo) == "function" then
        local ok, count = self:ReadAPI(GetNumDisplayChannels)
        count = ok and public(count)
        if type(count) == "number" then
            for index = 1, math.min(200,count) do
                local read, name, header, _, localID, members, active = self:ReadAPI(GetChannelDisplayInfo,index)
                if read and public(header) ~= true and public(active) == true then add(localID,name,members) end
            end
        end
    end
    local candidates = {}
    for _, row in ipairs(rows) do
        local hint = self:ParseLabel(row.name)
        local family = hint and hint.family or row.name
        if family:lower() == config.family:lower() then
            local infoAPI = C_ChatInfo and C_ChatInfo.GetChannelInfoFromIdentifier
            if infoAPI then
                local ok, info = self:ReadAPI(infoAPI,row.name)
                if ok and type(public(info)) == "table" then row.channelInstance = number(public(info).instanceID) end
            end
            if not row.channelInstance and type(GetChannelName) == "function" then
                local ok, _, _, instance = self:ReadAPI(GetChannelName,row.localID or row.name)
                if ok then row.channelInstance = number(instance) end
            end
            row.regional = nil
            if C_ChatInfo and C_ChatInfo.IsChannelRegional and row.localID then
                local ok, regional = self:ReadAPI(C_ChatInfo.IsChannelRegional,row.localID)
                if ok then row.regional = public(regional) end
            end
            if row.regional ~= false then
                if hint then hint.source = "number in channel name"
                elseif row.channelInstance then hint = {family=family,instance=row.channelInstance,label=family .. " " .. ("%.0f"):format(row.channelInstance),source="channel instance metadata"} end
                if hint then candidates[hint.family:lower() .. ":" .. tostring(hint.instance)] = hint end
            end
        end
        self.raw[#self.raw + 1] = row
    end
    local count, selected = 0, nil
    if config.blockedAPI then self.channelStatus = "Client blocked " .. config.blockedAPI .. ". Automatic reads stopped; enter your visible label manually."; return false end
    for _, row in pairs(candidates) do count, selected = count + 1, row end
    if count == 1 then
        selected.realm, selected.zone = self:Context()
        selected.at = GetServerTime(); self.current = selected; self:Remember(selected)
        self.channelStatus = "Read-only channel observation. This is a phase hint, not a verified world layer ID."
    elseif count > 1 then self.channelStatus = "Several matching channel identities are present; enter the exact visible label manually."
    else self.channelStatus = "No numbered regional channel label/instance is exposed. Enter the label you see manually; local shortcuts and member counts are never used as a phase ID." end
    return count == 1
end
function L:Lines()
    local config, own = self:Settings(), self:Current()
    local lines = { "REGIONAL CHANNEL / PHASE HINT", own and ("You: " .. own.label .. " | " .. own.zone .. " | " .. own.source) or "Your channel hint is unavailable or stale; Refresh status or enter it below.",
        self.channelStatus or "Channel data is read only when you open this panel or click Refresh status.",
        "Channel numbers are compared as hints. They are not confirmed server world-layer numbers.", "" }
    if self.stale then lines[#lines + 1] = "World/phase notification received; channel snapshot needs Refresh status." end
    if config.peer then
        local _, message = self:Compare(own,config.peer)
        lines[#lines + 1] = "Guildmate report: " .. config.peer.name .. " — " .. config.peer.label
        lines[#lines + 1] = message
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Layer number: not available from a verified client API."
    lines[#lines + 1] = "WHO has no layer selector here. A world refresh is not proof that WHO will return a different population."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Party phase signals:"
    if self.lastEvent then lines[#lines + 1] = "Last client notification: " .. self.lastEvent .. " (does not identify a layer)" end
    local count = 0
    if GetNumGroupMembers then count = public(GetNumGroupMembers()) elseif GetNumSubgroupMembers then count = public(GetNumSubgroupMembers()) end
    count = public(count); if type(count) ~= "number" then count = 0 end
    for index = 1, math.min(40, count) do
        local unit = IsInRaid and public(IsInRaid()) == true and ("raid" .. index) or ("party" .. index)
        if public(UnitExists(unit)) then
            local name = public(GetUnitName(unit, true)) or "<name unavailable>"
            local same
            if UnitInPhase then local ok, value = pcall(UnitInPhase, unit); if ok then same = public(value) end end
            local status = same == true and "same phase (client signal)" or same == false and "different phase/world instance (client signal)" or "phase status unavailable"
            lines[#lines + 1] = name .. ": " .. status
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "To join a friend's world copy: join their party, stand somewhere safe/out of combat, then use Blizzard's blue world-refresh notice and select Refresh Now. The game decides which copy you enter."
    lines[#lines + 1] = "This panel does not derive layer IDs from NPC GUIDs, force a layer switch, or auto-accept a world refresh. Check that party members are visible after the transition."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Raw channel data (shortcut/member count are NOT phase IDs):"
    for _, row in ipairs(self.raw or {}) do
        lines[#lines + 1] = ("%s | shortcut %s | channel instance %s | members %s | regional %s")
            :format(row.name, tostring(row.localID or "?"), tostring(row.channelInstance or "?"), tostring(row.members or "?"), tostring(row.regional))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Recent channel observations (not confirmed layer transitions):"
    for index = #config.history, math.max(1,#config.history-9), -1 do
        local row = config.history[index]
        lines[#lines + 1] = ("%s | %s | %s | %s"):format(tostring(row.at), row.label, row.zone, row.source)
    end
    return table.concat(lines, "\n")
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "UNIT_PHASE", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD" }) do TG:RegisterObservedEvent(events, event, "Layers") end
events:SetScript("OnEvent", function(_, event)
    L.lastEvent = event .. " at " .. tostring(GetServerTime())
    L.stale = true
    if TG.db and TG.db.layers and TG.db.layers.manual then TG.db.layers.manual.invalidated = true end
    if L.frame and L.frame:IsShown() then L.setList(L:Lines()) end
end)
function L:Show()
    if not self.frame then
        local UI = TG.featureUI
        self.frame = UI.Panel("TranquilityLayers", "REGIONAL CHANNEL / PHASE COMPARISON", 880, 670)
        self.setList = UI.ScrollText(self.frame, 22, -65, 825, 310)
        UI.Label(self.frame,"Channel family",22,-402,110)
        self.family = UI.Edit(self.frame,self:Settings().family,135,-394,160)
        UI.Button(self.frame,"Use family",310,-394,110,function()
            local value = text(self.family:GetText()); self.family:ClearFocus()
            if value and value ~= "" then
                local label = self:ParseLabel(value)
                self:Settings().family = label and label.family or value
                self:Settings().manual = nil; self:ReadChannels(); self.setList(self:Lines())
            end
        end)
        UI.Button(self.frame,"Refresh status",440,-394,150,function() self:ReadChannels(); self.setList(self:Lines()) end)
        self.track = CreateFrame("CheckButton",nil,self.frame,"UICheckButtonTemplate")
        self.track:SetPoint("TOPLEFT",610,-394); self.track:SetSize(25,25); self.track:SetChecked(false)
        UI.Label(self.frame,"Track while open",643,-402,185)
        self.track:SetScript("OnClick",function(box) self.tracking=box:GetChecked() and true or false; self.elapsed=0 end)
        self.frame:SetScript("OnUpdate",function(_,elapsed)
            if not self.tracking then return end
            self.elapsed=(self.elapsed or 0)+elapsed
            if self.elapsed >= 2 then
                self.elapsed=0
                local ok=pcall(self.ReadChannels,self)
                if not ok or self:Settings().blockedAPI then self.tracking=false; self.track:SetChecked(false) end
                self.setList(self:Lines())
            end
        end)
        self.frame:SetScript("OnHide",function() self.tracking=false; self.track:SetChecked(false) end)
        UI.Label(self.frame,"My label",22,-447,100)
        self.mine = UI.Edit(self.frame,"",135,-439,250)
        UI.Button(self.frame,"Save my label",400,-439,150,function()
            self.mine:ClearFocus()
            if not self:SetManual(self.mine:GetText()) then TG:Notify("Enter a label such as English 46.") end
            self.setList(self:Lines())
        end)
        UI.Button(self.frame,"Use detected",570,-439,140,function() self:Settings().manual=nil; self:ReadChannels(); self.setList(self:Lines()) end)
        UI.Label(self.frame,"Guildmate",22,-490,110)
        self.peerName = UI.Edit(self.frame,"",135,-482,180)
        UI.Label(self.frame,"Their label",330,-490,100)
        self.peerLabel = UI.Edit(self.frame,"",440,-482,220)
        UI.Label(self.frame,"Their city",22,-532,110)
        self.peerZone = UI.Edit(self.frame,"",135,-524,180)
        UI.Label(self.frame,"Their realm",330,-532,100)
        self.peerRealm = UI.Edit(self.frame,"",440,-524,220)
        UI.Button(self.frame,"Compare",680,-482,140,function()
            self.peerName:ClearFocus(); self.peerLabel:ClearFocus(); self.peerZone:ClearFocus(); self.peerRealm:ClearFocus()
            if not self:SetPeer(self.peerName:GetText(),self.peerLabel:GetText(),self.peerZone:GetText(),self.peerRealm:GetText()) then TG:Notify("Enter a guildmate and their label, such as English 52.") end
            self.setList(self:Lines())
        end)
        self.share = UI.Edit(self.frame,"",215,-575,620)
        UI.Button(self.frame,"Prepare share text",22,-575,175,function()
            local row = self:Current()
            if row then self.share:SetText(("Channel hint: %s | %s | %s (unconfirmed layer)"):format(row.label,row.zone,row.realm)); self.share:SetFocus(); self.share:HighlightText(0,-1)
            else TG:Notify("Refresh or enter your current channel label first.") end
        end)
        UI.Label(self.frame,"Copy share text manually. No guild/party messages or channel joins are sent. City/realm fields are optional, but improve the comparison.",22,-621,820,35)
    end
    local config = self:Settings()
    self.family:SetText(config.family); self.mine:SetText(config.manual and config.manual.label or "")
    self.peerName:SetText(config.peer and config.peer.name or ""); self.peerLabel:SetText(config.peer and config.peer.label or "")
    self.peerZone:SetText(config.peer and config.peer.zone or ""); self.peerRealm:SetText(config.peer and config.peer.realm or "")
    self:ReadChannels(); self.setList(self:Lines()); self.frame:Show()
end

TG:Register("Phases", L, "layers", function(self) local db=self:Settings(); db.family=db.family or "English"; db.history=db.history or {} end)
