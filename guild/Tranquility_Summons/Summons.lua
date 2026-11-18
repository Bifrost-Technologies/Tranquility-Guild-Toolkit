local TG = _G.Tranquility
local S = { spellID = 698, delay = 10, attempted = {} }
TG.summons = S

local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

function S:Zone(unit, raidIndex)
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, unit)
        mapID = ok and public(mapID) or nil
        if type(mapID) ~= "number" then mapID = nil end
        -- Climb out of subzones/micro maps to compare whole zones.
        for _ = 1, 10 do
            if not mapID then break end
            local good, info = pcall(C_Map.GetMapInfo, mapID)
            info = good and public(info) or nil
            if type(info) ~= "table" then break end
            if public(info.mapType) == (Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3) then
                local name = public(info.name)
                return type(name) == "string" and name ~= "" and name or nil
            end
            mapID = public(info.parentMapID)
            if type(mapID) ~= "number" or mapID <= 0 then break end
        end
    end
    if raidIndex and GetRaidRosterInfo then
        local _, _, _, _, _, _, zone = GetRaidRosterInfo(raidIndex)
        zone = public(zone)
        if type(zone) == "string" and zone ~= "" then return zone end
    end
    if unit == "player" then return public(GetRealZoneText()) end
end

function S:Scan()
    local ownZone = self:Zone("player")
    local candidates, lines, unknown = {}, {}, 0
    local raid = public(IsInRaid()) == true
    local count = public(raid and GetNumGroupMembers() or GetNumSubgroupMembers())
    count = type(count) == "number" and math.min(40, math.max(0, math.floor(count))) or 0
    for index = 1, count do
        local unit = (raid and "raid" or "party") .. index
        if public(UnitExists(unit)) == true and public(UnitIsUnit(unit, "player")) == false then
            local guid, name = public(UnitGUID(unit)), public(GetUnitName(unit, true))
            local zone = self:Zone(unit, raid and index or nil)
            local connected, dead = public(UnitIsConnected(unit)), public(UnitIsDeadOrGhost(unit))
            local status = "Unknown zone"
            if not zone or not ownZone then
                unknown = unknown + 1
            elseif zone == ownZone then
                status = "Already in your zone"
            elseif connected ~= true or dead ~= false then
                status = "Offline / dead / unavailable"
            elseif guid and name and self.attempted[guid] then
                status = "Attempted this chain"
            elseif guid and name then
                status = "Waiting"
                candidates[#candidates + 1] = { unit = unit, guid = guid, name = name, zone = zone }
            end
            lines[#lines + 1] = (name or "Unknown player") .. "  |  " .. (zone or "Unknown") .. "  |  " .. status
        end
    end
    self.candidates, self.lines, self.unknown = candidates, lines, unknown
    self.ownZone = ownZone
    return candidates
end

function S:Stop(message)
    self.active, self.inFlight, self.casting = false, nil, nil
    self.message = message or "Chain stopped."
    self:Refresh()
end

function S:Start()
    if InCombatLockdown() then return end
    local _, class = UnitClass("player")
    if public(class) ~= "WARLOCK" then self.message = "Ritual of Summoning requires a warlock."; self:Refresh(); return end
    if not IsPlayerSpell or public(IsPlayerSpell(self.spellID)) ~= true then
        self.message = "Learn Ritual of Summoning before starting a chain."; self:Refresh(); return
    end
    if self.inFlight then return end
    self.active, self.attempted, self.readyAt = true, {}, 0
    self.message = "Chain started. Click Summon next for each ritual."
    self:Refresh()
end

function S:IsIdle()
    for _, method in ipairs({ UnitCastingInfo, UnitChannelInfo }) do
        local ok, value = pcall(method, "player")
        if not ok or (issecretvalue and issecretvalue(value)) or value ~= nil then return false end
    end
    return type(UnitCastingInfo) == "function" and type(UnitChannelInfo) == "function"
end

function S:Refresh()
    if not self.frame or InCombatLockdown() then return end
    self.button:SetAttribute("type", nil)
    local candidates = self:Scan()
    self.next = candidates[1]
    local remaining = math.max(0, (self.readyAt or 0) - GetTime())
    local ready = self.active and not self.inFlight and remaining == 0 and self.next ~= nil
        and self:IsIdle()
    if ready then
        self.button:SetAttribute("unit", self.next.unit)
        self.button:SetAttribute("spell", self.spellID)
        self.button:SetAttribute("type", "spell")
    end
    self.button:SetEnabled(ready and true or false)
    self.button:SetText(self.inFlight and "Ritual in progress..." or remaining > 0
        and ("Wait %ds"):format(math.ceil(remaining)) or "Summon next (click)")
    self.nextLabel:SetText("Your zone: " .. (self.ownZone or "Unknown") .. "\nNext: " ..
        (self.next and (self.next.name .. " — " .. self.next.zone) or "No eligible party members"))
    self.list:SetText(table.concat(self.lines, "\n"))
    self.status:SetText((self.message or "Start a chain to prepare summons.") .. "\n" ..
        #candidates .. " waiting. " .. self.unknown .. " unknown zone(s), skipped.")
end

function S:BeforeClick()
    if InCombatLockdown() then return end
    -- Re-read zone and unit identity immediately before the secure action.
    self:Refresh()
    if self.button:GetAttribute("type") ~= "spell" then return end
    self.inFlight = self.next
    self.casting = false
    local request = self.inFlight
    C_Timer.After(3, function()
        if self.inFlight == request and not self.casting then
            self.inFlight = nil
            self.message = "Ritual did not start. Check mana, shards, helpers, and game errors; click to retry."
            self:Refresh()
        end
    end)
end

function S:SpellEvent(event, unit, castGUID, spellID)
    if public(unit) ~= "player" or public(spellID) ~= self.spellID or not self.inFlight then return end
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        self.casting = true
        self:Refresh()
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local request = self.inFlight
        C_Timer.After(0.15, function()
            if self.inFlight ~= request or not self:IsIdle() then return end
            if self.casting or event == "UNIT_SPELLCAST_SUCCEEDED" then
                self.attempted[request.guid] = true
                self.readyAt = GetTime() + self.delay
                self.message = "Ritual ended for " .. request.name .. ". Next click ready in 10 seconds."
            else
                self.message = "Ritual failed to start. Fix the game error, then retry or Skip next."
            end
            self.inFlight, self.casting = nil, nil
            self:Refresh()
        end)
    end
end

function S:CreateUI()
    local frame = CreateFrame("Frame", "TranquilitySummonsFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    if not self.uberButton then
        self.uberButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        self.uberButton:SetSize(180,26);self.uberButton:SetPoint("BOTTOMLEFT",22,10)
        self.uberButton:SetText("Uber summons requests")
        self.uberButton:SetScript("OnClick",function()if _G.Uber then _G.Uber:Show()else print("Enable Uber, then /uber.")end end)
    end

    table.insert(UISpecialFrames,"TranquilitySummonsFrame")
    frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function() if not InCombatLockdown() then frame:StartMoving() end end)
    frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    frame:SetSize(720, 550)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.035, 0.045, 0.065, 0.98)
    local function label(content, x, y, width, height)
        local item = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        item:SetPoint("TOPLEFT", x, y); item:SetSize(width, height)
        item:SetJustifyH("LEFT"); item:SetJustifyV("TOP"); item:SetText(content)
        return item
    end
    label("TRANQUILITY  /  SUMMONS", 22, -22, 600, 24)
    label("Party / raid zone check: skip everyone already in your zone.\nEach ritual requires a click. Next becomes ready 10 seconds after the ritual ends.\nBring the required helpers and reagents. Unknown zones are skipped.", 22, -58, 670, 60)
    local function action(content, x, y, width, callback)
        local item = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        item:SetPoint("TOPLEFT", x, y); item:SetSize(width, 28); item:SetText(content)
        item:SetScript("OnClick", function() if not InCombatLockdown() then callback() end end)
        return item
    end
    action("Start chain", 22, -135, 120, function() self:Start() end)
    action("Stop chain", 152, -135, 120, function() self:Stop() end)
    action("Skip next", 282, -135, 120, function()
        if self.next and not self.inFlight then self.attempted[self.next.guid] = true; self:Refresh() end
    end)
    action("Recruitment", 412, -135, 120, function() self:Stop(); frame:Hide(); TG:OpenModule("Recruitment") end)
    action("Close", 542, -135, 120, function() self:Stop(); frame:Hide() end)
    self.nextLabel = label("", 22, -180, 660, 42)
    self.button = CreateFrame("Button", "TranquilitySummonNext", frame,
        "SecureActionButtonTemplate,UIPanelButtonTemplate")
    self.button:SetPoint("TOPLEFT", 22, -232); self.button:SetSize(300, 36)
    self.button:RegisterForClicks("AnyUp", "AnyDown")
    self.button:SetAttribute("useOnKeyDown", false)
    self.button:SetAttribute("checkselfcast", false)
    self.button:SetAttribute("checkfocuscast", false)
    self.button:SetScript("PreClick", function(_, _, down) if not down then self:BeforeClick() end end)
    self.button:SetScript("PostClick", function(_, _, down) if not down then self:Refresh() end end)
    RegisterStateDriver(self.button, "visibility", "[combat] hide; show")
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 22, -287); scroll:SetSize(650, 155)
    local child = CreateFrame("Frame", nil, scroll); child:SetSize(640, 1000)
    scroll:SetScrollChild(child)
    self.list = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.list:SetPoint("TOPLEFT"); self.list:SetWidth(630); self.list:SetJustifyH("LEFT")
    self.list:SetSpacing(5)
    self.status = label("", 22, -465, 660, 65)
    frame:SetScript("OnHide", function() self:Stop() end)
    frame:Hide()
    self:Refresh()
        frame:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed=(self.elapsed or 0)+elapsed
        if self.elapsed >= 1 then self.elapsed=0; self:Refresh() end
    end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED" }) do
    TG:RegisterObservedEvent(events, event, "Summons")
end
events:SetScript("OnEvent", function(_, event, ...)
    if not S.frame then return end
    if event:find("UNIT_SPELLCAST_", 1, true) == 1 then S:SpellEvent(event, ...)
    elseif event == "PLAYER_REGEN_DISABLED" then
        S.active, S.inFlight, S.casting = false, nil, nil
        S.message = "Combat stopped the chain. Start again after combat."
    else S:Refresh() end
end)

TG:Register("Summons", S)

