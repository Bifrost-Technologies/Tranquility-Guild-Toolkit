local T = _G.Tranquility
local P = { page = 1 }
T.population = P
P.zones = {"Stormwind City", "Ironforge", "Darnassus", "Dalaran", "Elwynn Forest", "Dun Morogh", "Teldrassil", "Zephras Isle", "Westfall", "Loch Modan", "Darkshore", "Redridge Mountains", "Wetlands", "Duskwood", "Mount Hyjal", "Winterspring", "Eastern Plaguelands", "Western Plaguelands", "Burning Steppes", "Searing Gorge", "Silithus", "Un'Goro Crater", "Felwood", "Blasted Lands", "Azshara", "Blackrock Mountain", "Blackrock Depths", "Blackrock Spire", "Stratholme", "Scholomance", "Dire Maul", "Molten Core", "Onyxia's Lair", "Warsong Gulch", "Arathi Basin", "Alterac Valley", "Feralas", "Tanaris", "The Hinterlands", "Stranglethorn Vale", "Badlands", "Swamp of Sorrows", "Deadwind Pass", "Desolace", "Dustwallow Marsh", "Shen'dralas", "Riverglades"}
function P:Init()
    self.db = T.db.population
    self.db.samples = self.db.samples or {}
    self.db.ignored = self.db.ignored or {}
end
function P:Record(rows)
    local groups = {}
    for _, row in ipairs(rows) do
        local zone = row.zone
        if zone and zone ~= "" then groups[zone]=(groups[zone] or 0)+1 end
    end
    for zone, count in pairs(groups) do self.db.samples[zone]={count=count,at=GetServerTime()} end
    self:Refresh()
end
function P:Refresh()
    if not self.frame then return end
    for i, button in ipairs(self.buttons) do
        local zone = self.zones[(self.page-1)*10+i]
        if zone then
            local sample = self.db.samples[zone]
            button:SetText(zone .. (sample and (" | " .. sample.count .. " observed") or " | not sampled"))
            button:SetScript("OnClick",function() T:Prepare(self.query,T.who:Query(zone)) end); button:Show()
        else button:Hide() end
    end
    self.pageLabel:SetText("Page " .. self.page .. "/" .. math.ceil(#self.zones/10))
    local lines = {"Snapshots are manual WHO samples, not live player totals or proven demand for portals/summons."}
    local entries = {}
    for zone,sample in pairs(self.db.samples) do if not self.db.ignored[zone] then entries[#entries+1]={zone=zone,sample=sample} end end
    table.sort(entries,function(a,b) return a.sample.count > b.sample.count end)
    for _,row in ipairs(entries) do lines[#lines+1]=("%s: %d observed | sampled at %s"):format(row.zone,row.sample.count,date("%Y-%m-%d %H:%M",row.sample.at)) end
    self.setList(table.concat(lines,"\n"))
end
function P:CreateUI()
    local UI=T.featureUI
    self.frame=UI.Panel("TranquilityRegions","TRANQUILITY / REGION SAMPLES",850,710)
    local f=self.frame
    UI.Label(f,"Click a zone to prepare its WHO command. Enter it in Blizzard chat yourself.\nOnce the result arrives, click Record current WHO. No background searches or messages.",22,-55,805,42)
    self.buttons={}
    for i=1,10 do self.buttons[i]=UI.Button(f,"",22,-108-(i-1)*30,390,function() end) end
    UI.Button(f,"Previous",22,-420,105,function() self.page=math.max(1,self.page-1); self:Refresh() end)
    UI.Button(f,"Next",140,-420,105,function() self.page=math.min(math.ceil(#self.zones/10),self.page+1); self:Refresh() end)
    self.pageLabel=UI.Label(f,"",265,-426,140)
    self.query=UI.Edit(f,"",22,-468,780)
    UI.Button(f,"Record current WHO",435,-108,190,function() self:Record(T.who:Read()) end)
    UI.Button(f,"Clear samples",640,-108,160,function() self.db.samples={}; self:Refresh() end)
    self.setList=UI.ScrollText(f,435,-155,355,290)
    UI.Label(f,"Ignore zone",22,-520,100)
    local ignore=UI.Edit(f,"",130,-512,285)
    UI.Button(f,"Ignore",430,-512,105,function() self.db.ignored[ignore:GetText()]=true; self:Refresh() end)
    UI.Button(f,"Restore",550,-512,105,function() self.db.ignored[ignore:GetText()]=nil; self:Refresh() end)
    UI.Label(f,"The sample records the actual zone on each returned row, regardless of the selected zone.\nLocal results may be capped, old or incomplete. Zero returned rows do not establish an empty zone.\nAll zones remain editable through the WHO command field; region names depend on your client language.",22,-570,805,75)
    self:Refresh()
end
T:Register("Regions",P,"population",function(self) self:Init() end)
