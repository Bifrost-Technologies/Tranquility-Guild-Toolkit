local T=_G.Tranquility
local I={}
function I:Refresh()
    if not self.frame then return end
    local lines={
        "GETTING STARTED",
        "Type /tranq or /tq, or click the TQ button by the minimap. Each tool opens its own movable panel; Escape closes it.",
        "At character selection, open AddOns. Keep Tranquility enabled and disable any Tranquility: feature you do not want. Reload after changes. Optional tools do not require each other.","",
        "RECRUITMENT",
        "Prepare WHO gives you a command to copy and enter in Blizzard chat. Search manually, then Import WHO results. Only an explicitly empty guild field qualifies as guildless; unknown data is excluded.",
        "Select a player to prepare /ginvite. Greeting prepares /w Name Hello Name! plus your editable message. Copy and send each yourself. Mark contacted skips that name on later imports; Ignore is separate. Neither action claims an invite succeeded.","",
        "AUCTIONS AND LOOT",
        "Search the AH yourself. Add an item ID and Read AH results, or record an observed per-unit asking price in copper. Comparisons need three prior days. Current samples expire after 15 minutes. Expensive asks are research hints, never guaranteed demand or profit.",
        "Loot records visible dungeon/open-world loot and roll observations while enabled. Seen, received and rolled are distinct and may overlap. Unknown NPCs/bosses stay unknown. DB provides optional Classic reference routes, not verified Forever drop tables.","",
        "PARTY TOOLS",
        "Summons: start the list, then physically click Summon next for each ritual. Players already in your zone and unknown zones are skipped. Reagents, helpers and game rules still apply. It stops in combat or on close.",
        "Dungeon: Start monitoring; assign your target as tank/healer if roles are unmarked. Nameplate counts are partial. Low HP flashes need at least three observed mobs. Mana/cast estimates include other effects. Verbose stays local; Broadcast sends one short party summary per click (15-second cooldown). Monitoring stops on close.",
        "Gear: target a nearby player and click Inspect. Scores describe equipment rarity/level, not wealth or skill. Incomplete inspections are marked. Snapshots last only this session.",
        "Regions: prepare one zone query, run it yourself, then Record current WHO. Counts describe returned results only; WHO limits and stale results apply. No background scanner.",
        "Phases: read the regional channel label or enter it manually and compare your guildmate's label. This is a hint, not a verified world-layer ID; the game controls transitions.","",
        "PRIVACY AND LOCAL DATA",
        "No account login, external application, network service or telemetry. Recruitment history stores names by realm. Loot stores observed item sources; auction history stores prices by realm/faction. Phase reports store the peer name you enter. Session-only gear/dungeon data is not saved.",
        "Logout or Blizzard's manual /reload saves SavedVariables. Disable a module to stop its collection. The buttons below erase its loaded persistent data; disabled-module data can be deleted from its SavedVariables file with the game closed.",
        "In-game restricted values remain unavailable; blocked operations are not retried or bypassed.","",
        "LOCAL DIAGNOSTICS (latest 20)",
    }
    for _,err in ipairs(T.errors) do lines[#lines+1]=err end
    if #T.errors==0 then lines[#lines+1]="No captured errors. Report your game build, enabled modules and reproduction steps with any Lua error." end
    self.setList(table.concat(lines,"\n\n"))
end
function I:Reset(id,key)
    local module=T.modules[id]
    if not module or not module.ready or not key or not T.db[key] then T:Notify("That module is not loaded."); return end
    local target=T.db[key]
    for k in pairs(target) do target[k]=nil end
    if module.init then module.init(module.object) end
    local object=module.object
    if id=="Recruitment" then object.rows={}; object.selected=nil end
    if id=="Auctions" then object.snapshots={} end
    if id=="Phases" then object.current=nil; object.stale=true end
    if id=="Loot" then object.contexts={}; object.recentSources={}; object.seen={}; object.seenOrder={}; object.rolls={} end
    if object.Refresh then object:Refresh() end
    T:Notify(id .. " local saved data cleared.")
    self:Refresh()
end
function I:CreateUI()
    local UI=T.featureUI
    self.frame=UI.Panel("TranquilityInfo","TRANQUILITY / HELP AND SETTINGS",940,755)
    local f=self.frame
    self.setList=UI.ScrollText(f,22,-65,870,465)
    UI.Button(f,"Toggle minimap button",22,-550,205,function()
        TranquilityDB.hideLauncher=not TranquilityDB.hideLauncher
        if T.launcher then T.launcher:SetShown(not TranquilityDB.hideLauncher) end
        T:Notify("Launcher preference saved; /tranq always works. A newly enabled launcher appears after reload.")
    end)
    UI.Button(f,"Refresh diagnostics",245,-550,185,function() self:Refresh() end)
    UI.Button(f,"Global settings",448,-550,165,function() T:ShowRecruitSettings() end)
    UI.Label(f,"Erase local saved data: type DELETE, then click a module below. This cannot be undone.",22,-601,870,28)
    local confirm=UI.Edit(f,"",22,-636,110)
    local controls={{"Recruitment","recruitment"},{"Auctions","auction"},{"Loot","loot"},{"Regions","population"},{"Phases","layers"}}
    for i,item in ipairs(controls) do
        UI.Button(f,item[1],148+(i-1)*145,-636,133,function()
            if confirm:GetText()~="DELETE" then T:Notify("Type DELETE to confirm data removal."); return end
            confirm:SetText(""); confirm:ClearFocus(); self:Reset(item[1],item[2])
        end)
    end
    self:Refresh()
end
T:Register("Info",I)
