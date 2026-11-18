local TG = _G.Tranquility
local C_Item = C_Item or { GetItemInfo = GetItemInfo }; local G = { records = {}, slots = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 },
    weights = { [0] = 0, [1] = 1, [2] = 2, [3] = 4, [4] = 8, [5] = 12, [6] = 16, [7] = 2, [8] = 2 } }
TG.gear = G
local function public(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
function G:Score(items)
    local score, level, empty, unknown, counts = 0, 0, 0, 0, {}
    local twoHanded = items[16] and items[16].equipLoc == "INVTYPE_2HWEAPON" and items[17] and items[17].empty
    for _, slot in ipairs(self.slots) do
        local item = twoHanded and slot == 17 and items[16] or items[slot]
        if not item or item.unknown then unknown = unknown + 1
        elseif item.empty then empty = empty + 1
        else
            score = score + item.level * (self.weights[item.quality] or 0)
            level = level + item.level
            counts[item.quality] = (counts[item.quality] or 0) + 1
        end
    end
    return { score = score / #self.slots, ilvl = level / #self.slots, empty = empty, unknown = unknown, counts = counts }
end
function G:Inspect()
    if InCombatLockdown() then self.message = "Inspect after combat."; self:Refresh(); return end
    local guid = public(UnitGUID("target"))
    if not guid or not CanInspect or public(CanInspect("target", false)) ~= true then
        self.message = "Target a nearby player who can be inspected."; self:Refresh(); return
    end
    if self.lastRequest and GetTime() - self.lastRequest < 5 then
        self.message = "Wait five seconds between inspect requests."; self:Refresh(); return
    end
    self.pending, self.lastRequest = guid, GetTime()
    self.requestSerial = (self.requestSerial or 0) + 1
    local requestSerial = self.requestSerial
    local ok = pcall(NotifyInspect, "target")
    if not ok then self.pending = nil; self.message = "Client blocked inspection."; self:Refresh(); return end
    self.message = "Waiting for inspect data..."; self:Refresh()
    C_Timer.After(15, function()
        if self.pending == guid and self.requestSerial == requestSerial then self.pending = nil; self.message = "Inspect timed out. Stay near the player and try again."; self:Refresh() end
    end)
end
function G:Read(guid)
    if InCombatLockdown() then
        self.pending = nil; self.message = "Combat interrupted inspection. Try again afterwards."; self:Refresh(); return
    end
    guid = public(guid)
    if not self.pending or guid ~= self.pending or public(UnitGUID("target")) ~= guid then return end
    local items, name = {}, public(GetUnitName("target", true))
    if not name then return end
    for _, slot in ipairs(self.slots) do
        local rawLink, rawTexture = GetInventoryItemLink("target", slot), GetInventoryItemTexture("target", slot)
        local restricted = issecretvalue and (issecretvalue(rawLink) or issecretvalue(rawTexture))
        local link, texture = public(rawLink), public(rawTexture)
        if restricted then items[slot] = { unknown = true }
        elseif not link then items[slot] = texture and { unknown = true } or { empty = true }
        else
            local infoAPI = C_Item.GetItemInfo or GetItemInfo
            local itemName, _, quality, level, _, _, _, _, equipLoc
            if infoAPI then itemName, _, quality, level, _, _, _, _, equipLoc = infoAPI(link) end
            if C_Item.GetDetailedItemLevelInfo then level = public(C_Item.GetDetailedItemLevelInfo(link)) or level end
            itemName, quality, level = public(itemName), public(quality), public(level)
            if type(itemName) == "string" and type(quality) == "number" and quality >= 0 and quality <= 8 and quality % 1 == 0 and type(level) == "number" and level >= 0 and level < math.huge then
                items[slot] = { quality = quality, level = level, equipLoc = public(equipLoc) }
            else items[slot] = { unknown = true } end
        end
    end
    local record = self:Score(items)
    record.name, record.at = name, GetServerTime()
    self.records[guid] = record
    self.message = record.unknown > 0 and "Some item data is unknown. Score and item level are lower bounds; inspect again shortly."
        or "Equipment snapshot recorded. Rarity score is not a gold balance or player skill rating."
    self.pending = nil
    self:Refresh()
end
function G:Refresh()
    if not self.frame then return end
    local entries, lines = {}, {}
    for _, record in pairs(self.records) do entries[#entries + 1] = record end
    table.sort(entries, function(a, b) return a.score > b.score end)
    for _, record in ipairs(entries) do
        lines[#lines + 1] = ("%s — avg iLvl %.1f%s | Gear score %.1f\nEpics: %d | Rares: %d | Uncommon: %d | Empty: %d | Unknown: %d\n")
            :format(record.name, record.ilvl, record.unknown > 0 and "+ (incomplete)" or "", record.score,
                record.counts[4] or 0, record.counts[3] or 0, record.counts[2] or 0, record.empty, record.unknown)
    end
    self.setList(#lines > 0 and table.concat(lines, "\n") or "Inspect a nearby player to start the session ranking.")
    self.status:SetText(self.message or "Only manually inspected players are shown; no automatic whispers.")
end
function G:CreateUI()
    local UI = TG.featureUI
    self.frame = UI.Panel("TranquilityGearFrame", "TRANQUILITY / INSPECTED GEAR RANKING", 820, 540)
    UI.Label(self.frame, "Score uses item rarity and level. Purple > blue > green. Incomplete inspections are marked.\nEmpty slots contribute zero; a two-handed weapon covers its empty off-hand slot.", 22, -55, 775, 65)
    UI.Button(self.frame, "Inspect target", 22, -135, 145, function() self:Inspect() end)
    UI.Button(self.frame, "Clear session", 180, -135, 145, function() self.records = {}; self:Refresh() end)
    self.setList = UI.ScrollText(self.frame, 22, -185, 750, 270)
    self.status = UI.Label(self.frame, "", 22, -480, 775, 40)
    self:Refresh()
end
local events = CreateFrame("Frame")
TG:RegisterObservedEvent(events, "INSPECT_READY", "Gear")
events:SetScript("OnEvent", function(_, _, guid) G:Read(guid) end)

TG:Register("Gear", G)
