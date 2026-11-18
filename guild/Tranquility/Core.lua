local addonName = ...
local T = { version = "1.0.0-beta.10", modules = {}, db = {}, errors = {}, farmItems = {}, farmByID = {} }
_G.Tranquility = T
local catalog = {
    {"Recruitment", "Recruitment", "Guildless WHO results, manual greetings and invite commands."},
    {"Auctions", "Auction opportunities", "Record asking prices and compare daily lows; sources and ignore list."},
    {"Loot", "Loot journal", "Remember dungeon, open-world and roll observations."},
    {"Dungeon", "Dungeon pressure", "Local tank / healer statistics; party report on click."},
    {"Summons", "Summons", "Zone-aware party list; one physical click per ritual."},
    {"Regions", "Region samples", "Keep manually collected WHO population samples."},
    {"Gear", "Gear snapshots", "Inspect your target for rarity and average item level."},
    {"Phases", "Phase hints", "Compare regional channel labels with a guildmate."},
    {"DB", "Reference database", "Optional Classic gathering routes and item sources."},
    {"Info", "Help and settings", "Getting started, privacy, module controls and diagnostics."},
}
T.catalog = catalog
function T.Public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
function T.Text(value)
    value = T.Public(value)
    return type(value) == "string" and value or nil
end
function T:Notify(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff60d6c8Tranquility:|r " .. tostring(message)) end
end
function T:Fault(module, message)
    table.insert(self.errors, 1, module .. ": " .. tostring(message))
    while #self.errors > 20 do table.remove(self.errors) end
end
function T:RegisterObservedEvent(frame, event, owner)
    -- Only public, passive events. Never subscribe to restricted combat-log events.
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then return false end
    if owner~="Core"and not frame.tranquilityGuarded then
        frame.tranquilityGuarded=true;local native=frame.SetScript
        frame.SetScript=function(f,kind,handler)
            if (kind=="OnEvent"or kind=="OnUpdate")and handler then
                native(f,kind,function(...)if TranquilityAccess and TranquilityAccess:Allowed()then return handler(...)end end)
            else native(f,kind,handler)end
        end
    end
    local ok, err = pcall(frame.RegisterEvent, frame, event)
    if not ok then self:Fault(owner, "Unavailable event " .. event .. ": " .. tostring(err)) end
    return ok
end
function T:Register(id, module, savedKey, init)
    self.modules[id] = { object = module, savedKey = savedKey, init = init, ready = false }
end
function T:Initialize(id)
    if not TranquilityAccess or not TranquilityAccess:Allowed()then return end
    local record = self.modules[id]
    if not record or record.ready then return end
    if record.savedKey then
        local variable = "Tranquility" .. id .. "DB"
        if type(_G[variable]) ~= "table" then _G[variable] = {} end
        self.db[record.savedKey] = _G[variable]
    end
    local ok, err = pcall(function() if record.init then record.init(record.object) end end)
    record.ready = ok
    if not ok then self:Fault(id, err) end
end
function T:OpenModule(id)
    if not TranquilityAccess or not TranquilityAccess:Require()then return end
    local record = self.modules[id]
    if not record or not record.ready then self:Notify("Enable Tranquility " .. id .. " in the character-selection AddOns menu, then reload."); return end
    if InCombatLockdown and InCombatLockdown() then self:Notify("Open panels after combat."); return end
    local object = record.object
    local ok, err = pcall(function()
        if object.Show then object:Show()
        else
            if not object.frame then object:CreateUI() end
            object.frame:Show()
            if object.Refresh then object:Refresh() end
        end
    end)
    if not ok then self:Fault(id, err); self:Notify("Could not open " .. id .. ". See Help and settings for diagnostics.") end
end
function T:FarmSource(id)
    if self.loot and self.loot.db and self.loot.db.items[id] then return self.loot:SourceSummary(id) end
    return "Source unknown. Enable Tranquility DB for reference routes or Loot to record observations."
end
function T:Prepare(box, command)
    box:SetText(command); box:SetFocus(); box:HighlightText(0, -1)
end
function T:Show()
    if not TranquilityAccess or not TranquilityAccess:Require()then return end
    local UI = self.featureUI
    if not self.frame then
        local f = UI.Panel("TranquilityHome", "TRANQUILITY / GUILD TOOLKIT", 780, 715)
        self.frame = f
        UI.Label(f, "Open a tool below. Disable optional tools in WoW's AddOns menu.\nYour data stays local; recruitment and messaging always require your own actions.", 22, -55, 730, 40)
        self.moduleLabels = {}
        for i, item in ipairs(catalog) do
            local y = -108 - (i-1)*46
            UI.Button(f, item[2], 22, y, 200, function() self:OpenModule(item[1]) end)
            self.moduleLabels[item[1]] = UI.Label(f, "", 238, y-3, 515, 40)
        end
        UI.Button(f,"PvP command center",22,-646,355,function()if self.defense then self.defense:Show()else self:Notify("Enable Tranquility: PvP in the AddOns menu.")end end)
        UI.Button(f,"Flight Path Finder",396,-646,360,function()if _G.FlightPathFinder then FlightPathFinder:Show()else self:Notify("Enable Flight Path Finder in AddOns, then /fpf.")end end)
        self.footer = UI.Label(f, "", 22, -585, 730, 55)
        UI.Button(f,"Uber summons requests",22,-558,200,function()
            if _G.Uber then _G.Uber:Show()else self:Notify("Enable the standalone Uber addon, then /uber.")end
        end)
        UI.Button(f,"Tranquility guild LFG",238,-558,250,function()
            if _G.TranquilityLFG then _G.TranquilityLFG:Show()else self:Notify("Enable TranquilityLFG, then /tqlfg.")end
        end)
        UI.Button(f,"Tradesman & guild jobs",506,-558,250,function()if self.work then self.work:Show()end end)
    end
    for _, item in ipairs(catalog) do
        local module = self.modules[item[1]]
        self.moduleLabels[item[1]]:SetText((module and module.ready and "|cff72d9acLoaded|r — " or "|cffaaaaaaDisabled|r — ") .. item[3])
    end
    self.footer:SetText("/tranq or /tq opens this menu. Version " .. self.version ..
        "\nUse Help and settings for instructions and local data controls.")
    self.frame:Show()
end
function T:EnsureLauncher()
    if self.launcher or not TranquilityAccess or not TranquilityAccess:Allowed()or not TranquilityDB or TranquilityDB.hideLauncher or not Minimap then return end
    local b=CreateFrame("Button","TranquilityLauncher",Minimap,"UIPanelButtonTemplate");b:SetSize(32,25);b:SetPoint("TOPLEFT",-12,8);b:SetText("TQ")
    b:SetScript("OnClick",function()T:Show()end);self.launcher=b
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN"}) do T:RegisterObservedEvent(events, event, "Core") end
events:SetScript("OnEvent", function(_, event, name, action)
    if event == "ADDON_LOADED" then
        if name == addonName then
            TranquilityDB = type(TranquilityDB) == "table" and TranquilityDB or {}
            TranquilityDB.schema = 1
        else
            local id = type(name) == "string" and name:match("^Tranquility_(.+)$")
            if id then T:Initialize(id) end
        end
    elseif event == "PLAYER_LOGIN" then
        if not TranquilityAccess then return end
        if not TranquilityAccess:Allowed()then if not(TranquilityDB and TranquilityDB.security and TranquilityDB.security.vaultClosed)then TranquilityAccess:Require()end;return end
        T:EnsureLauncher()
    elseif type(name) == "string" and name:match("^Tranquility") then
        T:Fault(name, event .. " " .. tostring(action))
        if T.layers and T.layers.readInProgress then T.layers:Settings().blockedAPI = tostring(action) end
        -- Do not retry, bypass or suppress Blizzard's warning.
    end
end)
SLASH_TRANQUILITY1 = "/tranq"
SLASH_TRANQUILITY2 = "/tq"
SlashCmdList.TRANQUILITY = function(text)
    local code=(text or ""):match("^%s*verify%s+(%x+)%s*$");if code and T.work then T.work:SubmitVerification(code);TranquilityAccess:Require();return end
    if not TranquilityAccess or not TranquilityAccess:Require()then return end
    local key = (text or ""):lower():match("^%s*(%S+)")
    if key=="jobs"or key=="work"then if T.work then T.work:Show()end
    elseif key=="flights"or key=="flightpaths"then if _G.FlightPathFinder then FlightPathFinder:Show()else T:Notify("Enable Flight Path Finder in AddOns.")end
    elseif key=="defense"or key=="pvp"then if T.defense then T.defense:Show()else T:Notify("Enable Tranquility: PvP in the AddOns menu.")end
    elseif key == "settings" then T:ShowRecruitSettings()
    elseif key == "help" then T:OpenModule("Info")
    elseif key then
        for _, item in ipairs(catalog) do if item[1]:lower() == key then T:OpenModule(item[1]); return end end
        T:Show()
    else T:Show() end
end
