local TG = _G.Tranquility
-- Classic reference routes, not a claim that Forever's loot tables are identical.
TG.farmItems = {
    { id = 2770, name = "Copper Ore", kind = "Mining", where = "Copper veins: Elwynn Forest / Durotar / Dun Morogh; follow hills and caves." },
    { id = 2771, name = "Tin Ore", kind = "Mining", where = "Tin veins: The Barrens / Hillsbrad Foothills; follow rocky edges." },
    { id = 2772, name = "Iron Ore", kind = "Mining", where = "Iron deposits: Arathi Highlands / Thousand Needles." },
    { id = 765, name = "Silverleaf", kind = "Herbalism", where = "Near trees: Durotar / Tirisfal Glades / Elwynn Forest." },
    { id = 2447, name = "Peacebloom", kind = "Herbalism", where = "Open ground: Durotar / Tirisfal Glades / Dun Morogh." },
    { id = 2449, name = "Earthroot", kind = "Herbalism", where = "Hills and cliffs: Durotar / Tirisfal Glades / Dun Morogh." },
    { id = 2450, name = "Briarthorn", kind = "Herbalism", where = "The Barrens / Silverpine Forest; vegetation around hills." },
    { id = 2318, name = "Light Leather", kind = "Skinning", where = "Skin low-level beasts: Elwynn Forest / Durotar / The Barrens." },
    { id = 783, name = "Light Hide", kind = "Skinning", where = "Uncommon skinning result from low-level beasts; same routes as light leather." },
    { id = 2319, name = "Medium Leather", kind = "Skinning", where = "Skin mid-level beasts: Hillsbrad Foothills / Wetlands / The Barrens." },
    { id = 2589, name = "Linen Cloth", kind = "Humanoid drops", where = "Low-level humanoids: Westfall / Silverpine Forest. Dungeon: The Deadmines; trash, no fixed boss." },
    { id = 2592, name = "Wool Cloth", kind = "Humanoid drops", where = "Humanoids around levels 16-30. Dungeon: The Stockade / Shadowfang Keep; trash, no fixed boss." },
    { id = 4306, name = "Silk Cloth", kind = "Humanoid drops", where = "Mid-level humanoids. Dungeon: Scarlet Monastery; trash and bosses, no exclusive boss." },
    { id = 1482, name = "Shadowfang", kind = "Weapon", gear = true,
        where = "Dungeon: Shadowfang Keep (Silverpine Forest). Rare BoE trash drop; no verified Forever boss source. Verify realm availability before farming." },
    { id = 1121, name = "Feet of the Lynx", kind = "Armor", gear = true,
        where = "World BoE drop / chests around the low-to-mid 20s. No exclusive dungeon or boss. Rare random drop; verify Forever availability." },
}
TG.farmByID = {}
for _, item in ipairs(TG.farmItems) do TG.farmByID[item.id] = item end

function TG:FarmSource(itemID)
    if self.loot and self.loot.db and self.loot.db.items[itemID] then return self.loot:SourceSummary(itemID) end
    local observed = self.db.farmSources and self.db.farmSources[itemID]
    local reference = self.farmByID[itemID]
    if observed then
        return ("Observed in Forever: %s | Boss: %s | Difficulty: %s"):format(
            observed.instance, observed.boss, observed.difficulty)
    end
    if reference then return "Classic reference (Forever unverified): " .. reference.where end
    return "Source unknown. No verified dungeon/boss record yet. Boss drops observed by this addon are saved here."
end


local DB = {}
function DB:Show()
    if not self.frame then
        local UI=TG.featureUI
        self.frame=UI.Panel("TranquilityReference", "TRANQUILITY / REFERENCE DATABASE", 840, 600)
        self.setList=UI.ScrollText(self.frame,22,-70,775,475)
    end
    local lines={"Classic reference routes; verify availability on your realm. Observed sources take priority.", ""}
    for _,item in ipairs(TG.farmItems) do lines[#lines+1]=item.name .. " [" .. item.id .. "]\n" .. item.where .. "\n" end
    self.setList(table.concat(lines,"\n")); self.frame:Show()
end
TG:Register("DB",DB)
