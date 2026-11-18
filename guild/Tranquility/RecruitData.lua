local T=_G.Tranquility
T.recruitGroups={
    {key="cities",label="Cities",min=1,max=60,zones={"Stormwind City","Ironforge","Darnassus","Dalaran"}},
    {key="starting",label="Starting areas",min=1,max=60,zones={"Elwynn Forest","Dun Morogh","Teldrassil","Zephras Isle"}},
    {key="dungeon13",label="13-25 recruits",min=13,max=25,locked=true,zones={
        "Hall of Thanes","Ruins of Lordaeron","The Deadmines","Wailing Caverns","The Stockade","Shadowfang Keep",
        "Blackfathom Deeps","Excavation Site","Ironforge","Stormwind City","Darnassus","Redridge Mountains",
        "Westfall","Loch Modan","Darkshore","Wetlands","Duskwood","Elwynn Forest","Dun Morogh","Teldrassil",
        "Zephras Isle","The Barrens","Ashenvale","Stonetalon Mountains","Silverpine Forest","Hillsbrad Foothills"}},
    {key="high",label="High level",min=50,max=60,zones={"Mount Hyjal","Winterspring","Eastern Plaguelands","Western Plaguelands","Burning Steppes","Searing Gorge","Silithus","Un'Goro Crater","Felwood","Blasted Lands","Azshara","Blackrock Mountain","Blackrock Depths","Blackrock Spire","Stratholme","Scholomance","Dire Maul","Molten Core","Onyxia's Lair","Feralas","Tanaris","The Hinterlands","Stranglethorn Vale","Badlands","Swamp of Sorrows","Deadwind Pass","Desolace","Dustwallow Marsh","Shen'dralas","Riverglades"}},
    {key="pvp",label="Battlegrounds",min=50,max=60,zones={"Warsong Gulch","Arathi Basin","Alterac Valley"}},
}
T.recruitGroupByKey={}
for _,group in ipairs(T.recruitGroups) do T.recruitGroupByKey[group.key]=group end
