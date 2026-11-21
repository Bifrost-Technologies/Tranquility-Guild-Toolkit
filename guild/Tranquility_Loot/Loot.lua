local TG = _G.Tranquility
local L = { contexts = {}, recentSources = {}, seen = {}, rolls = {} }
TG.loot = L
local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function str(value) value = public(value); return type(value) == "string" and value or nil end
local function num(value) value = public(value); return type(value) == "number" and value or nil end
local function itemID(link) link = str(link); return link and tonumber(link:match("item:(%d+)")) end
local function copy(source)
    local result = {}; for key, value in pairs(source or {}) do result[key] = value end; return result
end
function L:Init()
    TG.db.loot = TG.db.loot or { items = {} }
    self.db = TG.db.loot; self.db.items = self.db.items or {}
end
function L:Context()
    local instance, kind, difficulty, difficultyName = GetInstanceInfo()
    return { zone = str(GetRealZoneText()) or "Unknown zone", subzone = str(GetSubZoneText()) or "",
        instance = kind ~= "none" and str(instance) or "Open world", difficulty = str(difficultyName) or tostring(difficulty or ""),
        mapID = C_Map and public(C_Map.GetBestMapForUnit("player")) or nil }
end
function L:SourceKey(source)
    return table.concat({ source.zone or "", source.instance or "", source.difficulty or "",
        source.boss or "", source.npcID or "", source.sourceType or "Unknown source" }, "|")
end
function L:Record(link, state, source, quantity, unique)
    if not self.db then return end
    local id = itemID(link)
    if not id or unique and self.seen[unique] then return end
    if unique then self.seen[unique] = true; self.seenOrder = self.seenOrder or {}; self.seenOrder[#self.seenOrder+1] = unique; if #self.seenOrder > 2000 then self.seen[table.remove(self.seenOrder,1)] = nil end end
    source = copy(source or self:Context())
    local item = self.db.items[id] or { id = id, sources = {}, observations = 0, received = 0, rolls = 0 }
    item.link, item.name = str(link), str(link):match("%[([^%]]+)%]") or ("Item " .. id)
    item.lastSeen = GetServerTime()
    item.observations = item.observations + 1
    if state == "received by me" then item.received = item.received + (quantity or 1) end
    if state == "roll offered" then item.rolls = item.rolls + 1 end
    local key = self:SourceKey(source)
    local location = item.sources[key] or source
    location.states = location.states or {}
    location.states[state] = (location.states[state] or 0) + 1
    location.lastSeen = item.lastSeen
    item.sources[key] = location
    item.recent = item.recent or {}
    table.insert(item.recent, 1, { state = state, quantity = quantity or 1, at = item.lastSeen, source = key })
    if #item.recent > 25 then table.remove(item.recent) end
    self.db.items[id] = item
    if self.frame and self.frame:IsShown() then self:Refresh() end
end
function L:SourceSummary(id)
    local item = self.db and self.db.items[id]
    if not item then return "Source unknown." end
    local sources = {}
    for _, source in pairs(item.sources) do sources[#sources + 1] = source end
    table.sort(sources, function(a, b) return a.lastSeen > b.lastSeen end)
    local lines = {}
    for index = 1, math.min(3, #sources) do
        local source = sources[index]
        lines[#lines + 1] = ("%s / %s%s%s [%s]"):format(source.zone, source.instance or "Unknown instance",
            source.boss and (" | Boss: " .. source.boss) or " | Boss: unknown / not identified",
            source.npcID and (" | NPC " .. source.npcID .. (source.npcName and (" " .. source.npcName) or "")) or "",
            source.sourceType or "location observed; drop source unknown")
    end
    return ("Seen in Forever: %s. Received by me: %d; rolls offered: %d. See Loot journal for all sources.")
        :format(table.concat(lines, "; "), item.received, item.rolls)
end
function L:RememberSource(id, source)
    local previous = self.recentSources[id]
    local now = GetTime()
    local ambiguous = previous and now - previous.at < 120 and
        (previous.ambiguous or self:SourceKey(previous.source) ~= self:SourceKey(source))
    self.recentSources[id] = { source = source, at = now, ambiguous = ambiguous }
end
function L:RecentSource(id)
    local recent = self.recentSources[id]
    if recent and not recent.ambiguous and GetTime() - recent.at < 120 then return copy(recent.source) end
    local source = self:Context(); source.sourceType = "location observed; drop source unknown"
    return source
end
function L:ReadWindow()
    if not GetNumLootItems or not GetLootSlotLink then return end
    self.windowSerial = (self.windowSerial or 0) + 1
    for slot = 1, GetNumLootItems() do
        local link = str(GetLootSlotLink(slot))
        local id = itemID(link)
        if id then
            local source = self:Context()
            source.sourceType = "loot window; source unidentified"
            local sources = GetLootSourceInfo and { GetLootSourceInfo(slot) } or {}
            local recorded = false
            -- AOE loot can have multiple corpses; retain each supplied source.
            for index = 1, #sources, 2 do
                local guid, quantity = str(sources[index]), num(sources[index + 1])
                if guid then
                    local specific = copy(source)
                    specific.npcID = tonumber(guid:match("^[^-]+%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-(%d+)%-"))
                    specific.sourceType = specific.npcID and "loot-source creature GUID" or "loot-source object/container GUID"
                    for _, unit in ipairs({ "target", "mouseover" }) do
                        if public(UnitGUID(unit)) == guid then specific.npcName = str(GetUnitName(unit, false)); break end
                    end
                    self:Record(link, "seen in loot window", specific, quantity)
                    self:RememberSource(id, specific); recorded = true
                end
            end
            if not recorded then self:Record(link, "seen in loot window", source); self:RememberSource(id, source) end
        end
    end
end
-- Match localized self-loot format strings without evaluating Lua or relying on English text.
function L:MatchFormat(message, format)
    if not format then return nil end
    local pattern, tokens, index = {}, {}, 1
    while index <= #format do
        local char = format:sub(index, index)
        if char == "%" then
            local token = format:sub(index + 1):match("^(%d+%$[sd])") or format:sub(index + 1, index + 1)
            local kind = token:sub(-1)
            if kind == "s" or kind == "d" then
                pattern[#pattern + 1] = kind == "s" and "(.+)" or "(%d+)"
                tokens[#tokens + 1] = kind
                index = index + #token + 1
            else pattern[#pattern + 1] = "%%"; index = index + 2 end
        else
            pattern[#pattern + 1] = char:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            index = index + 1
        end
    end
    local values = { message:match("^" .. table.concat(pattern) .. "$") }
    if #values == 0 then return nil end
    local quantity = 1
    for i, kind in ipairs(tokens) do if kind == "d" then quantity = tonumber(values[i]) or 1 end end
    return quantity
end
function L:ChatLoot(message)
    message = str(message)
    if not message then return end
    local link = message:match("(|Hitem:[^|]+|h.-|h)")
    local id = itemID(link)
    if not id then return end
    local quantity = self:MatchFormat(message, LOOT_ITEM_SELF_MULTIPLE) or self:MatchFormat(message, LOOT_ITEM_SELF)
    local source = self:RecentSource(id)
    self:Record(link, quantity and "received by me" or "loot message observed (recipient unconfirmed)", source, quantity)
end
function L:Roll(rollID, retries, context)
    rollID = num(rollID)
    if not rollID or not GetLootRollItemLink then return end
    local link = str(GetLootRollItemLink(rollID))
    local id = itemID(link)
    if not id then
        if (retries or 0) < 4 then
            local atStart = context or self:Context()
            C_Timer.After(0.25, function() self:Roll(rollID, (retries or 0) + 1, atStart) end)
        end
        return
    end
    local source = self:RecentSource(id)
    if context and source.sourceType == "location observed; drop source unknown" then
        source = copy(context); source.sourceType = "roll offered; source unidentified"
    end
    self.rolls[rollID] = { link = link, source = source }
    self:Record(link, "roll offered", source, 1, "roll:" .. rollID)
end
function L:History(encounterID, lootKey)
    encounterID, lootKey = num(encounterID), num(lootKey)
    if not encounterID or not C_LootHistory or not C_LootHistory.GetSortedInfoForDrop or not C_LootHistory.GetSortedDropsForEncounter then return end
    local info = C_LootHistory.GetInfoForEncounter and C_LootHistory.GetInfoForEncounter(encounterID)
    local drops = lootKey and { C_LootHistory.GetSortedInfoForDrop(encounterID, lootKey) }
        or C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}
    for _, drop in ipairs(drops) do
        local key, link = num(drop.lootListKey), str(drop.itemHyperlink)
        if key and link then
            local source = copy(self.contexts[encounterID] or { zone = "Unknown zone", instance = "Unknown instance" })
            source.boss = info and str(info.encounterName) or source.boss
            source.sourceType = "encounter loot history"
            self:Record(link, "roll offered", source, 1, "history:" .. encounterID .. ":" .. key)
            local state = num(drop.playerRollState)
            if state then self:Record(link, "roll state " .. state, source, 1, "state:" .. encounterID .. ":" .. key .. ":" .. state) end
            if drop.winner then
                -- Winner recorded as a state, without exporting names or claiming the item was received.
                local isSelf = public(drop.winner.isSelf)
                if isSelf ~= nil then self:Record(link, isSelf and "roll won by me" or "roll won by another player", source,
                    1, "winner:" .. encounterID .. ":" .. key) end
            end
        end
    end
end
function L:OnEvent(event, a, b, c, d)
    if TranquilityDB and TranquilityDB.automatic and TranquilityDB.automatic.loot==false then return end
    if not self.db then return end
    if event == "LOOT_OPENED" then self:ReadWindow()
    elseif event == "CHAT_MSG_LOOT" then self:ChatLoot(a)
    elseif event == "START_LOOT_ROLL" then self:Roll(a)
    elseif event == "LOOT_HISTORY_UPDATE_DROP" then self:History(a, b)
    elseif event == "LOOT_HISTORY_UPDATE_ENCOUNTER" then self:History(a)
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local id = itemID(a)
        if id then self:Record(a, "roll won by me", self:RecentSource(id), num(b)) end
    elseif event == "ENCOUNTER_START" and num(a) then
        local context = self:Context(); context.boss = str(b); self.contexts[a] = context
    elseif event == "ENCOUNTER_LOOT_RECEIVED" and num(a) and num(b) then
        local source = copy(self.contexts[a] or self:Context())
        source.sourceType = "encounter loot event"
        local link = str(c) or ("|Hitem:" .. b .. "|h[Item " .. b .. "]|h")
        self:Record(link, "boss loot observed", source, num(d))
    end
end
function L:Refresh()
    if not self.frame then return end
    local filter, list = (self.filter or ""):lower(), {}
    for id, item in pairs(self.db.items) do
        if filter == "" or tostring(id) == filter or item.name:lower():find(filter, 1, true) then list[#list + 1] = item end
    end
    table.sort(list, function(a, b) return a.lastSeen > b.lastSeen end)
    local lines = {}
    for _, item in ipairs(list) do
        lines[#lines + 1] = ("%s [%d] — %d observations; %d received by me; %d rolls offered")
            :format(item.name, item.id, item.observations, item.received, item.rolls)
        for _, source in pairs(item.sources) do
            local states = {}; for state, count in pairs(source.states) do states[#states + 1] = state .. ": " .. count end
            lines[#lines + 1] = ("  %s / %s | Boss: %s | NPC: %s %s\n  %s | %s")
                :format(source.zone, source.instance or "Unknown", source.boss or "unknown", source.npcID or "unknown",
                    source.npcName or "", source.sourceType or "unknown source", table.concat(states, ", "))
        end
        lines[#lines + 1] = ""
    end
    self.setList(#list == 0 and "No matching loot recorded yet. Recording starts while this addon is loaded." or table.concat(lines, "\n"))
end
function L:CreateUI()
    self:Init()
    local UI = TG.featureUI
    self.frame = UI.Panel("TranquilityLootFrame", "TRANQUILITY / LOOT SOURCE JOURNAL", 910, 630)
    UI.Label(self.frame, "Dungeon + open-world loot, group rolls (including passes/losses), and loot chat are recorded silently.\nSeen, received, and rolled are separate observations, not unique drop counts or drop-rate statistics.", 22, -55, 855, 40)
    local filter = UI.Edit(self.frame, "", 110, -108, 260)
    UI.Label(self.frame, "Name / ID:", 22, -115, 85)
    filter:SetScript("OnTextChanged", function(box) self.filter = box:GetText(); self:Refresh() end)
    UI.Button(self.frame, "Watch item ID", 395, -108, 145, function() TG:OpenModule("Auctions"); if TG.auction and TG.auction.db then TG.auction:AddItem(filter:GetText()) end end)
    UI.Button(self.frame, "Auctions", 555, -108, 120, function() TG:OpenModule("Auctions") end)
    self.setList = UI.ScrollText(self.frame, 22, -155, 845, 400)
    UI.Label(self.frame, "All item/source aggregates persist; each item keeps its latest 25 event details. Observations can overlap.\nA source-less message records your location, not an invented NPC. Logout saves your local journal. No data is transmitted.", 22, -575, 855, 40)
    self:Refresh()
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "LOOT_OPENED", "CHAT_MSG_LOOT", "START_LOOT_ROLL", "LOOT_HISTORY_UPDATE_DROP",
    "LOOT_HISTORY_UPDATE_ENCOUNTER", "LOOT_ITEM_ROLL_WON", "ENCOUNTER_START", "ENCOUNTER_LOOT_RECEIVED" }) do
    TG:RegisterObservedEvent(events, event, "Loot")
end
events:SetScript("OnEvent", function(_, event, ...) L:OnEvent(event, ...) end)

TG:Register("Loot", L, "loot", function(self) self:Init() end)
