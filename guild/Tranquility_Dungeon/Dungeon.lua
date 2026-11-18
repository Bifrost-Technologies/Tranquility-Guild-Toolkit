local TG = _G.Tranquility
local D = { active = false, manualMobs = 0, flashMobs = 3, lowHP = 35, lowMana = 20, history = {} }
TG.dungeon = D
local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function percent(current, maximum)
    current, maximum = public(current), public(maximum)
    if type(current) ~= "number" or type(maximum) ~= "number" or current ~= current or maximum ~= maximum or maximum <= 0 or maximum == math.huge or current == math.huge then return nil end
    return math.max(0, math.min(100, current / maximum * 100))
end
local function fmt(value) return value and ("%.0f%%"):format(value) or "unavailable / restricted" end
function D:Units()
    local units = { "player" }
    local raid = public(IsInRaid()) == true
    local count = public(raid and GetNumGroupMembers() or GetNumSubgroupMembers())
    count = type(count) == "number" and math.min(40, math.max(0, math.floor(count))) or 0
    for index = 1, count do
        local unit = (raid and "raid" or "party") .. index
        if public(UnitExists(unit)) and public(UnitIsUnit(unit, "player")) == false then units[#units + 1] = unit end
    end
    return units
end
function D:SetRole(role, unit)
    local guid = unit and public(UnitGUID(unit))
    self[role], self[role .. "GUID"] = guid and unit or nil, guid
    self.pull, self.lastMana = nil, nil
end
function D:FindRoles()
    for _, role in ipairs({ "tank", "healer" }) do
        local selectedGUID, match = self[role .. "GUID"], nil
        for _, unit in ipairs(self:Units()) do
            if selectedGUID and public(UnitGUID(unit)) == selectedGUID then match = unit; break end
            local assigned = UnitGroupRolesAssigned and public(UnitGroupRolesAssigned(unit))
            if not selectedGUID and assigned == role:upper() then match = unit; break end
        end
        if match then
            self[role] = match
            self[role .. "GUID"] = public(UnitGUID(match))
        else self[role], self[role .. "GUID"] = nil, nil end
    end
end
function D:RoleFromTarget(role)
    for _, unit in ipairs(self:Units()) do
        if public(UnitIsUnit(unit, "target")) == true then
            self:SetRole(role, unit)
            self.message = "Assigned " .. role .. "."
            self:Sample(); return
        end
    end
    self.message = "Target a party member (or yourself) to assign that role."
    self:Refresh()
end
function D:MobCount()
    if self.manualMobs > 0 then return self.manualMobs, "manual" end
    if not C_NamePlate or not C_NamePlate.GetNamePlates or not self.tank then return nil, "unknown" end
    local count, known = 0, false
    local plates = public(C_NamePlate.GetNamePlates())
    if type(plates) ~= "table" then return nil, "unknown" end
    for _, plate in ipairs(plates) do
        local unit = public(plate.namePlateUnitToken)
        if type(unit) == "string" then
            local hostile = public(UnitCanAttack("player", unit))
            local fighting = public(UnitAffectingCombat(unit))
            local targetingTank = public(UnitIsUnit(unit .. "target", self.tank))
            if hostile == true and fighting == true and targetingTank ~= nil then
                known = true
                if targetingTank == true then count = count + 1 end
            end
        end
    end
    return known and count or nil, "visible targets (partial)"
end
function D:BeginPull()
    self.pull = { casts = 0, manaSpent = 0, maxMobs = 0, samples = 0, started = GetTime(),
        tankGUID = self.tankGUID, healerGUID = self.healerGUID }
    self.lastMana = nil
end
function D:Pressure(hp, mana, mobs)
    local critical = hp and hp <= self.lowHP
    local exhausted = mana and mana <= self.lowMana
    if not hp then return "Tank HP unavailable: no automatic pull assessment.", false end
    if not mobs then return "Mob count unknown; no pull-size assessment.", false end
    if mobs >= self.flashMobs and critical then
        return exhausted and "High pressure: tank low + healer low mana. Stop adding mobs."
            or "High pressure: tank low with 3+ observed mobs. Reduce the next pull.", true
    end
    if exhausted then return "Healer mana low. Pause for recovery before pulling again.", false end
    if critical then return "Tank HP low. Below the 3-mob flash threshold; inspect the pull.", false end
    if not mana then return "Healer mana unavailable; pull readiness is unknown.", false end
    return "No threshold crossed in available samples. This does not establish a safe pull size.", false
end
function D:CastsRemaining(mana, pull)
    if not mana or not pull or pull.casts < 3 then return nil end
    local average = pull.manaSpent / pull.casts
    if average < 0.1 then return nil end
    return math.max(0, math.floor((mana - self.lowMana) / average)), average
end
function D:ReadSample()
    if not self.active then self:Refresh(); return end
    self:FindRoles()
    local hp = self.tank and percent(UnitHealth(self.tank), UnitHealthMax(self.tank))
    local mana = self.healer and percent(UnitPower(self.healer, 0), UnitPowerMax(self.healer, 0))
    local mobs, source = self:MobCount()
    local inCombat = self.tank and public(UnitAffectingCombat(self.tank))
    if self.pull and (self.pull.tankGUID ~= self.tankGUID or self.pull.healerGUID ~= self.healerGUID) then
        self.pull, self.lastMana = nil, nil
    end
    if inCombat == true and not self.pull then self:BeginPull() end
    local pull = self.pull
    if pull and inCombat == true then
        pull.samples = pull.samples + 1
        if hp then
            if not pull.minHP or hp < pull.minHP then pull.minHP, pull.mobsAtLow, pull.mobSource = hp, mobs, source end
            if pull.previousHP and hp >= pull.previousHP + 1 then
                pull.beforeRecovery = math.min(pull.beforeRecovery or 100, pull.previousHP)
            end
            pull.previousHP = hp
        else pull.restrictedHP = true; pull.previousHP = nil end
        if mobs then pull.maxMobs = math.max(pull.maxMobs, mobs) end
        if mana then
            pull.minMana = math.min(pull.minMana or 100, mana)
            if self.lastMana then pull.manaSpent = pull.manaSpent + math.max(0, self.lastMana - mana) end
        end
        self.lastMana = mana
    elseif pull and inCombat == false then
        self.lastPull = pull
        table.insert(self.history, 1, pull)
        if #self.history > 20 then table.remove(self.history) end
        self.pull, self.lastMana = nil, nil
    end
    self.hp, self.mana, self.mobs, self.mobSource = hp, mana, mobs, source
    self.assessment, self.flash = self:Pressure(hp, mana, mobs)
    self:Refresh()
end
function D:Sample()
    local ok, err = pcall(self.ReadSample, self)
    if not ok then
        self.active, self.flash, self.pull = false, false, nil
        self.lastMana, self.hp, self.mana, self.mobs = nil, nil, nil, nil
        self.assessment = "Client data unavailable; monitoring paused. Start manually after resolving the issue."
        TG:Fault("Dungeon", err)
        self:Refresh()
    end
end
function D:OnCast(unit)
    unit = public(unit)
    if not self.active or not self.healer or type(unit) ~= "string" or not self.pull then return end
    if public(UnitIsUnit(unit, self.healer)) ~= true then return end
    self.pull.casts = self.pull.casts + 1
end
function D:Report(verbose)
    local pull = self.pull or self.lastPull
    local castsLeft, average = self:CastsRemaining(self.mana, pull)
    local count = self.mobs and (self.mobs .. " (" .. self.mobSource .. ")") or "unknown"
    if not verbose then
        return ("Tranquility: tank %s; healer mana %s; mobs %s. %s%s"):format(fmt(self.hp), fmt(self.mana), count,
            self.assessment or "Helper not running.", castsLeft and (" Est. " .. castsLeft .. " casts to 20% mana.") or "")
    end
    local lines = {
        "Titan dungeon stats — " .. (self.active and "monitoring" or "stopped"),
        "Tank HP: " .. fmt(self.hp) .. " | Healer mana: " .. fmt(self.mana),
        "Mobs now: " .. count .. " | Flash: HP <=35% AND mobs >=3.",
        self.assessment or "Assign roles and start monitoring.",
    }
    if pull then
        lines[#lines + 1] = ("%s pull: lowest tank HP %s at %s mobs (%s); peak observed mobs %d.")
            :format(self.pull and "Current" or "Last", fmt(pull.minHP), pull.mobsAtLow or "unknown",
                pull.mobSource or "unknown", pull.maxMobs)
        lines[#lines + 1] = "Lowest HP before observed recovery: " .. fmt(pull.beforeRecovery) ..
            ". Recovery is not proof of a heal; low HP is not proof of too many mobs."
        lines[#lines + 1] = ("Healer completed casts: %d | Measured mana drops: %.1f percentage points | Lowest mana: %s.")
            :format(pull.casts, pull.manaSpent, fmt(pull.minMana))
        lines[#lines + 1] = castsLeft and ("Estimate: %d more casts before 20%% mana; %.1f%% observed mana loss per completed cast.")
            :format(castsLeft, average) or "Casts remaining: unavailable (needs >=3 completed casts and public mana samples)."
    end
    lines[#lines + 1] = "Nameplates give a partial count. Mana changes include other effects; cast estimates are approximate. No automatic chat spam."
    return table.concat(lines, "\n")
end
function D:Broadcast(verbose)
    if not IsInGroup() then self.message = "Join a party before broadcasting."; self:Refresh(); return end
    if self.lastBroadcast and GetTime() - self.lastBroadcast < 15 then
        self.message = "Wait 15 seconds between party broadcasts."; self:Refresh(); return
    end
    local report = self:Report(verbose)
    local channel = (LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"
    -- Party broadcast is a single concise, ASCII message and runs only on button click.
    local message = report:gsub("[\r\n]+", " ")
    if #message > 250 then message = message:sub(1, 247) .. "..." end
    local api = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    local ok = api and pcall(api, message, channel)
    self.lastBroadcast = GetTime()
    self.message = ok and "Party summary submitted." or "Client blocked chat. No automatic retry."
    self:Refresh()
end
function D:Refresh()
    if not self.frame then return end
    local function name(unit)
        return unit and public(GetUnitName(unit, true)) or "Unassigned"
    end
    self.roles:SetText("Tank: " .. (name(self.tank) or "Restricted") .. " | Healer: " .. (name(self.healer) or "Restricted"))
    self.setStats(self:Report(true))
    self.status:SetText(self.message or "Verbose prints privately. Broadcast sends one short party summary on demand.")
    self.glow:SetAlpha(self.active and self.flash and (math.floor(GetTime() * 2) % 2 == 0 and 0.32 or 0.06) or 0)
end
function D:CreateUI()
    local UI = TG.featureUI
    self.frame = UI.Panel("TranquilityDungeonFrame", "TRANQUILITY / DUNGEON PRESSURE", 870, 580)
    local f = self.frame
    self.glow = f:CreateTexture(nil, "BACKGROUND")
    self.glow:SetAllPoints(); self.glow:SetColorTexture(1, 0.08, 0.03, 1); self.glow:SetAlpha(0)
    UI.Label(f, "Quiet local stats. Flash requires low tank HP with at least 3 observed mobs. Public values only.\nAssign unmarked Classic roles with your target. Enable enemy nameplates for a partial automatic mob count.", 22, -55, 825, 40)
    UI.Button(f, "Start", 22, -108, 90, function()
        self.active = true; self:FindRoles(); self.message = "Monitoring started."; self:Sample()
    end)
    UI.Button(f, "Stop", 122, -108, 90, function()
        self.active, self.flash, self.pull = false, false, nil
        self.lastMana, self.hp, self.mana, self.mobs = nil, nil, nil, nil
        self.assessment = "Monitoring stopped. Start again for current stats."
        self:Refresh()
    end)
    UI.Button(f, "Target = tank", 222, -108, 125, function() self:RoleFromTarget("tank") end)
    UI.Button(f, "Target = healer", 357, -108, 130, function() self:RoleFromTarget("healer") end)
    UI.Label(f, "Mobs (0=auto):", 508, -115, 105)
    local count = UI.Edit(f, "0", 620, -108, 45)
    count:SetNumeric(true)
    UI.Button(f, "Set", 680, -108, 70, function()
        local value = tonumber(count:GetText())
        if value and value >= 0 and value <= 100 and value % 1 == 0 then
            self.manualMobs = value; self.message = "Mob count source: " .. (value == 0 and "visible nameplates" or "manual override")
        else self.message = "Enter a whole mob count from 0 to 100." end
        self:Sample()
    end)
    self.roles = UI.Label(f, "", 22, -153, 825, 24)
    self.setStats = UI.ScrollText(f, 22, -190, 790, 260)
    UI.Button(f, "Verbose (only me)", 22, -474, 175, function()
        self:Sample()
        for line in self:Report(true):gmatch("[^\n]+") do DEFAULT_CHAT_FRAME:AddMessage("|cffffca59" .. line .. "|r") end
        self.message = "Detailed stats printed only in your chat window."; self:Refresh()
    end)
    UI.Button(f, "Broadcast to party", 212, -474, 180, function() self:Sample(); self:Broadcast(false) end)
    UI.Button(f, "Gear ranking", 410, -474, 135, function() TG:OpenModule("Gear") end)
    self.status = UI.Label(f, "", 22, -520, 825, 38)
        self.frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.active then return end
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.5 then self.elapsed = 0; self:Sample() end
    end)
    self.frame:SetScript("OnHide", function() self.active, self.flash, self.pull = false, false, nil end)
    self:Refresh()
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_ENTERING_WORLD" }) do TG:RegisterObservedEvent(events, event, "Dungeon") end
events:SetScript("OnEvent", function(_, event, unit)
    if not D.frame then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then D:OnCast(unit)
    elseif event == "PLAYER_ENTERING_WORLD" then
        D.pull, D.lastPull, D.lastMana, D.hp, D.mana, D.mobs = nil, nil, nil, nil, nil, nil
        D.assessment = "Area changed; waiting for fresh samples."; D:Refresh()
    else D:Sample() end
end)

TG:Register("Dungeon", D)
