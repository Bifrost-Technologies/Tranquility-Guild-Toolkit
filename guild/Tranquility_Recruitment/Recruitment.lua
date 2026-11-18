local T=_G.Tranquility
local R={rows={},page=1,zonePage=1}
T.recruitment=R
local defaultMessage="Tranquility is a leveling and PvP guild. Find dungeon groups, enjoy guild repairs, and explore Azeroth together. Interested? Reply for an invite."
function R:Init()
    self.db=T.db.recruitment
    self.db.realms=self.db.realms or {}
    local realm=GetRealmName() or "Unknown"
    self.db.realms[realm]=self.db.realms[realm] or {contacted={},ignored={}}
    self.history=self.db.realms[realm]
    self.history.contacted=self.history.contacted or {};self.history.ignored=self.history.ignored or {}
    self.db.message=self.db.message or defaultMessage
    self.group=T.recruitGroupByKey[self.db.group] and self.db.group or "cities"
    local group=T.recruitGroupByKey[self.group]
    self.minimum,self.maximum=group.min,group.max
    self.slowUntil=type(self.db.slowUntil)=="number" and self.db.slowUntil or 0
    if self.slowUntil>GetServerTime()+600 then self.slowUntil=0 end
    if not self.subscribed then
        T.who:Subscribe(function(rows,status)
            self.latestRows,self.latestStatus=rows,status
            if not self.batchActive then self:Import(rows,status)
            else self.status="New WHO results are available. Your current batch stays unchanged until you click Import current WHO.";self:Refresh() end
        end)
        self.subscribed=true
    end
end
function R:Bounds()
    local group=T.recruitGroupByKey[self.group]
    if group.locked then
        self.minimum,self.maximum=group.min,group.max
        if self.minBox then self.minBox:SetText(tostring(group.min));self.maxBox:SetText(tostring(group.max)) end
    end
    return self.minimum,self.maximum
end
function R:ReadBounds()
    local group=T.recruitGroupByKey[self.group]
    if group.locked then self:Bounds();return true end
    if not self.minBox then return true end
    local low,high=tonumber(self.minBox:GetText()),tonumber(self.maxBox:GetText())
    if not low or not high or low<1 or high>60 or low>high or low%1~=0 or high%1~=0 then T:Notify("Enter whole-number levels from 1 to 60.");return false end
    self.minimum,self.maximum=low,high;return true
end
function R:Allowed(row)
    local low,high=self:Bounds()
    return row and row.guildless and type(row.level)=="number" and row.level>=low and row.level<=high
        and not self.history.contacted[row.name:lower()] and not self.history.ignored[row.name:lower()]
end
function R:Import(rows,status)
    self.rows,self.page,self.selected={},1,nil
    self.rawGuildless=0
    local eligible={}
    for _,row in ipairs(rows or {}) do
        if row.guildless then self.rawGuildless=self.rawGuildless+1 end
        if self:Allowed(row) then eligible[#eligible+1]=row end
    end
    table.sort(eligible,function(a,b)return a.name:lower()<b.name:lower()end)
    self.eligibleObserved=#eligible
    for i=1,math.min(#eligible,T:RecruitSettings().batch) do self.rows[#self.rows+1]=eligible[i] end
    self.batchActive=true
    self.status=(status or "")..("\n%d eligible observed; %d in this batch. Copy/send invites yourself, then mark contacted."):format(#eligible,#self.rows)
    self:Refresh()
end
function R:ImportCurrent()
    if not self:ReadBounds() then return end
    local rows,status=T.who:Read();self:Import(rows,status)
end
function R:Eligible()
    local rows={}
    for _,row in ipairs(self.rows) do if self:Allowed(row) then rows[#rows+1]=row end end
    return rows
end
function R:Choose(row)
    if not self:Allowed(row) then return false end
    self.selected=row;self:Refresh();return true
end
function R:Pacing()
    local settings=T:RecruitSettings()
    local slow=GetServerTime()<self.slowUntil
    local interval=slow and settings.slow or settings.normal
    local since=self.lastInvitePreparedAt
    if slow and self.warningAt then since=math.max(since or 0,self.warningAt) end
    return interval,since and math.max(0,since+interval-GetTime()) or 0,slow
end
function R:Select(row)
    if not self:Allowed(row) then return false end
    local present=false;for _,current in ipairs(self.rows) do if current==row then present=true;break end end
    if not present then return false end
    local _,remaining=self:Pacing()
    local recopy=self.lastPreparedName==row.name and self.context=="invite"
    if remaining>0 and not recopy then self.status=("Wait %ds before preparing another invite command."):format(math.ceil(remaining));self:Refresh();return false end
    self.selected=row
    if not recopy then self.lastInvitePreparedAt=GetTime() end
    self.lastPreparedName=row.name;self.context="invite"
    T:Prepare(self.command,"/ginvite "..row.name)
    self.status="Invite text highlighted for "..row.name..". Press Ctrl+C, paste into Blizzard chat, and press Enter yourself. Clipboard and delivery are not confirmed."
    self:Refresh();return true
end
function R:Mark(kind)
    if not self.selected or kind~="contacted" and kind~="ignored" then return end
    self.history[kind][self.selected.name:lower()]=GetServerTime()
    self.selected=nil;self:Refresh()
end
function R:PrepareGreeting()
    if not self.selected then T:Notify("Select a player first.");return end
    local message=self.db.message:gsub("[\r\n]"," ")
    local text="/w "..self.selected.name.." Hello "..self.selected.name.."! "..message
    if #text>255 then T:Notify("Greeting is too long for this name. Shorten the message.");return end
    self.context="greeting";T:Prepare(self.command,text)
    self.status="Greeting highlighted. Press Ctrl+C, paste into chat and send it yourself. Invite-command pacing does not send or delay this greeting."
    self:Refresh()
end
function R:RateKind(message)
    message=T.Text(message);if not message then return nil end
    local lower=message:lower()
    local rate=lower:find("too fast",1,true) or lower:find("too quickly",1,true) or lower:find("too rapidly",1,true)
    for _,key in ipairs({"ERR_GENERIC_THROTTLE","ERR_CHAT_THROTTLED"}) do local localized=T.Text(_G[key]);if localized and message==localized then rate=true end end
    if not rate then return nil end
    return lower:find("guild",1,true) and lower:find("invit",1,true) and "invite" or "generic"
end
function R:OnRateWarning(message)
    local kind=self:RateKind(message)
    if not kind then return false end
    local recent=self.context=="invite" and self.lastInvitePreparedAt and GetTime()-self.lastInvitePreparedAt>=0 and GetTime()-self.lastInvitePreparedAt<=10
    if kind~="invite" and not recent then return false end
    self.warningAt=GetTime();self.slowUntil=GetServerTime()+T:RecruitSettings().window;self.db.slowUntil=self.slowUntil
    self.status="Rate warning observed after a recent invite command. Invite-command preparation uses the warning interval temporarily. WHO and greeting timing are unchanged; actual chat sends remain manual."
    self:Refresh();return true
end
function R:SelectGroup(key)
    local group=T.recruitGroupByKey[key];if not group then return end
    self.group,self.db.group=key,key;self.minimum,self.maximum=group.min,group.max
    self.zonePage,self.randomBag=1,nil;self.rows={};self.batchActive=false;self.selected=nil;self.context="who"
    if self.zoneBox then self.zoneBox:SetText(group.zones[1]);self.minBox:SetText(tostring(group.min));self.maxBox:SetText(tostring(group.max)) end
    self.status="Group selected. Prepare one WHO query, run it yourself, then import its results."
    self:Refresh()
end
function R:PrepareWho(zone)
    if not self:ReadBounds() then return false end
    local low,high=self:Bounds()
    local query=T.who:Query(zone,low,high)
    if not query then T:Notify("Enter a valid zone without quotes or control characters.");return false end
    self.context="who";self.lastZone=zone
    if self.zoneBox then self.zoneBox:SetText(zone) end
    T:Prepare(self.command,query)
    self.status="WHO command highlighted. Copy it into chat and run it yourself. Your current batch stays frozen until Import current WHO."
    self:Refresh();return true
end
function R:RandomRegion(random)
    random=random or math.random
    if not self.randomBag or #self.randomBag==0 then
        self.randomBag={};for _,zone in ipairs(T.recruitGroupByKey[self.group].zones) do self.randomBag[#self.randomBag+1]=zone end
        for i=#self.randomBag,2,-1 do local pick=random(i);self.randomBag[i],self.randomBag[pick]=self.randomBag[pick],self.randomBag[i] end
        if #self.randomBag>1 and self.randomBag[#self.randomBag]==self.lastZone then self.randomBag[1],self.randomBag[#self.randomBag]=self.randomBag[#self.randomBag],self.randomBag[1] end
    end
    local zone=table.remove(self.randomBag)
    return self:PrepareWho(zone)
end
function R:Shuffle()
    for i=#self.rows,2,-1 do local pick=math.random(i);self.rows[i],self.rows[pick]=self.rows[pick],self.rows[i] end
    self.page=1;self:Refresh()
end
function R:RefreshPacing()
    if not self.pacingLabel then return end
    local interval,remaining,slow=self:Pacing()
    self.pacingLabel:SetText(("Invite commands: %ds interval | %s%s"):format(interval,remaining>0 and ("next new command in "..math.ceil(remaining).."s") or "ready",
        slow and (" | Warning cooldown: "..math.ceil(self.slowUntil-GetServerTime()).."s left") or " | You send every invite yourself"))
    for _,button in ipairs(self.inviteButtons or {}) do button:SetEnabled(button.row~=nil and (remaining<=0 or button.row.name==self.lastPreparedName and self.context=="invite")) end
end
function R:Refresh()
    if not self.frame then return end
    local rows=self:Eligible();self.page=math.max(1,math.min(self.page,math.max(1,math.ceil(#rows/8))))
    for i,button in ipairs(self.buttons) do
        local row=rows[(self.page-1)*8+i];local invite=self.inviteButtons[i];invite.row=row
        if row then
            button:SetText((self.selected==row and "> " or "")..row.name.." | "..tostring(row.level).." | "..(row.zone or "Zone unavailable"))
            button:SetScript("OnClick",function()self:Choose(row)end);button:Show()
            invite:SetScript("OnClick",function()self:Select(row)end);invite:Show()
        else button:Hide();invite:Hide() end
    end
    local group=T.recruitGroupByKey[self.group];local pages=math.ceil(#group.zones/6)
    self.zonePage=math.max(1,math.min(self.zonePage,pages))
    for i,button in ipairs(self.zoneButtons) do
        local zone=group.zones[(self.zonePage-1)*6+i]
        if zone then button:SetText(zone);button:SetScript("OnClick",function()self:PrepareWho(zone)end);button:Show() else button:Hide() end
    end
    self.zonePageLabel:SetText(("Zones %d/%d"):format(self.zonePage,pages))
    local low,high=self:Bounds();self.rangeLabel:SetText(group.label.." | Levels "..low.."-"..high..(group.locked and " only (fixed)" or ""))
    self.count:SetText(("Batch: %d remaining / %d imported | %d eligible observed | Page %d/%d | Selected: %s"):format(#rows,#self.rows,self.eligibleObserved or 0,self.page,math.max(1,math.ceil(#rows/8)),self.selected and self.selected.name or "none"))
    self.statusLabel:SetText(self.status or "Prepare one WHO query, import up to 50 eligible players, then invite each manually.")
    self:RefreshPacing()
end
function R:CreateUI()
    local UI=T.featureUI
    self.frame=UI.Panel("TranquilityRecruitment","TRANQUILITY / MANUAL RECRUITMENT",900,880)
    local f=self.frame
    UI.Label(f,"One manually searched region per batch. Choose a player and click Invite to highlight /ginvite Name.\nPress Ctrl+C, paste into Blizzard chat and press Enter yourself. Mark contacted only after your own action.",22,-54,850,42)
    for i,group in ipairs(T.recruitGroups) do UI.Button(f,group.label,22+(i-1)*172,-103,160,function()self:SelectGroup(group.key)end) end
    UI.Label(f,"Zone",22,-150,45);self.zoneBox=UI.Edit(f,T.recruitGroupByKey[self.group].zones[1],72,-142,230)
    UI.Label(f,"Levels",315,-150,50);self.minBox=UI.Edit(f,tostring(self.minimum),365,-142,42);self.maxBox=UI.Edit(f,tostring(self.maximum),427,-142,42)
    self.minBox:SetNumeric(true);self.maxBox:SetNumeric(true)
    UI.Button(f,"Prepare WHO",490,-142,155,function()self:PrepareWho(self.zoneBox:GetText())end)
    UI.Button(f,"Random region",660,-142,190,function()self:RandomRegion()end)
    UI.Button(f,"<",22,-182,35,function()self.zonePage=self.zonePage-1;self:Refresh()end)
    UI.Button(f,">",63,-182,35,function()self.zonePage=self.zonePage+1;self:Refresh()end)
    self.zoneButtons={};for i=1,6 do self.zoneButtons[i]=UI.Button(f,"",110+(i-1)*124,-182,118,function()end) end
    self.zonePageLabel=UI.Label(f,"",22,-218,100,24);self.rangeLabel=UI.Label(f,"",135,-218,700,24)
    UI.Label(f,"Copy text",22,-253,80);self.command=UI.Edit(f,"",105,-245,745)
    self.command:SetScript("OnEnterPressed",function(box)box:ClearFocus()end)
    UI.Label(f,"Highlighted text is ready for your Ctrl+C. The addon does not write the clipboard or send chat commands.",105,-279,745,24)
    UI.Button(f,"Import current WHO",22,-311,180,function()self:ImportCurrent()end)
    UI.Button(f,"Shuffle batch",215,-311,140,function()self:Shuffle()end)
    UI.Button(f,"Global settings",370,-311,150,function()T:ShowRecruitSettings()end)
    UI.Button(f,"Greeting",535,-311,115,function()self:PrepareGreeting()end)
    UI.Button(f,"Mark contacted",665,-311,180,function()self:Mark("contacted")end)
    self.count=UI.Label(f,"",22,-353,850,26)
    self.buttons,self.inviteButtons={},{}
    for i=1,8 do
        self.buttons[i]=UI.Button(f,"",22,-385-(i-1)*32,680,function()end)
        self.inviteButtons[i]=UI.Button(f,"Invite",718,-385-(i-1)*32,130,function()end)
    end
    UI.Button(f,"Previous",22,-655,105,function()self.page=self.page-1;self:Refresh()end)
    UI.Button(f,"Next",140,-655,105,function()self.page=self.page+1;self:Refresh()end)
    UI.Button(f,"Invite selected",260,-655,150,function()if self.selected then self:Select(self.selected)end end)
    UI.Button(f,"Ignore selected",425,-655,150,function()self:Mark("ignored")end)
    UI.Button(f,"Clear batch",590,-655,130,function()self.rows={};self.selected=nil;self.batchActive=false;self:Refresh()end)
    UI.Label(f,"Greeting",22,-707,80);local message=UI.Edit(f,self.db.message,105,-699,745);message:SetMaxLetters(180)
    message:SetScript("OnTextChanged",function(box)self.db.message=box:GetText()end)
    self.pacingLabel=UI.Label(f,"",22,-743,850,28);self.statusLabel=UI.Label(f,"",22,-781,850,55)
    UI.Button(f,"Reset contacted",22,-837,150,function()self.history.contacted={};self:Refresh()end)
    UI.Button(f,"Reset ignored",185,-837,150,function()self.history.ignored={};self:Refresh()end)
    UI.Label(f,"History records your Mark contacted action; prepared text is not a confirmed invite.",355,-844,490,28)
    f:SetScript("OnUpdate",function(_,elapsed)self.elapsed=(self.elapsed or 0)+elapsed;if self.elapsed>=0.2 then self.elapsed=0;self:RefreshPacing()end end)
    self:Refresh()
end
local events=CreateFrame("Frame")
T:RegisterObservedEvent(events,"UI_ERROR_MESSAGE","Recruitment")
T:RegisterObservedEvent(events,"CHAT_MSG_SYSTEM","Recruitment")
events:SetScript("OnEvent",function(_,event,a,b)if R.db then R:OnRateWarning(event=="UI_ERROR_MESSAGE" and b or a)end end)
T:Register("Recruitment",R,"recruitment",function(self)self:Init()end)
