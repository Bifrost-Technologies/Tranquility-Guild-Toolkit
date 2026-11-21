local L=LookingForProfession
local function label(f,text,x,y,w,h)
    local v=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");v:SetPoint("TOPLEFT",x,y);v:SetSize(w,h or 24);v:SetJustifyH("LEFT");v:SetJustifyV("TOP");v:SetText(text);return v
end
local function button(f,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,f,"BackdropTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});b:SetBackdropColor(.06,.24,.36,1)
    b.text=label(b,text,8,-6,w-16,20);b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s)s:SetBackdropColor(.08,.36,.48,1)end)
    b:SetScript("OnLeave",function(s)s:SetBackdropColor(.06,.24,.36,1)end);return b
end
local function edit(f,text,x,y,w)
    local b=CreateFrame("EditBox",nil,f,"InputBoxTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,26);b:SetAutoFocus(false);b:SetMaxLetters(255);b:SetText(text)
    b:SetScript("OnEscapePressed",function(s)s:ClearFocus()end);return b
end
function L:Status(text) self.status:SetText(text or "") end
function L:ReadBounds()
    if not self:Bounds(self.low:GetText(),self.high:GetText()) then self:Status("Enter whole levels 1-60, minimum <= maximum.");return false end
    return true
end
function L:Refresh()
    self.heading:SetText(self.mode=="GUILD" and "GUILD ONLY / ONLINE CRAFTERS IN HUBS" or "PUBLIC CITY / PROFESSION CANDIDATES")
    self.profButton.text:SetText(self.profession);self.hubButton.text:SetText(self.hub)
    local total=math.max(1,math.ceil(#self.rows/9));self.page=math.max(1,math.min(self.page,total))
    for i,b in ipairs(self.resultButtons) do
        local r=self.rows[(self.page-1)*9+i];b.row=r
        if r then
            local record=self.db.profiles[self:Key(r.name)];local p=record and record[self.profession]
            b.text:SetText(r.name.." | "..r.level.." | "..r.zone.." | "..(p and ("Recorded "..self.profession) or "Profession unknown"));b.text:SetTextColor(p and .35 or .8,p and .8 or .85,p and .6 or .9);b:Show()
        else b:Hide() end
    end
    self.pagination:SetText(("Page %d / %d - %d candidates"):format(self.page,total,#self.rows))
end
function L:Show()
    self:Settings()
    if not self.frame then
        local f=CreateFrame("Frame","LookingForProfessionFrame",UIParent,"BackdropTemplate");self.frame=f
        f:SetSize(1000,720);f:SetPoint("CENTER");f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
        if GetScreenWidth and GetScreenHeight then f:SetScale(math.min(1,(GetScreenWidth()-30)/1000,(GetScreenHeight()-30)/720)) end
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.035,.045,.065,1);f:SetBackdropBorderColor(.15,.55,.8,1)
        table.insert(UISpecialFrames,"LookingForProfessionFrame")
        label(f,"LFP / LOOKING FOR PROFESSION FINDER",22,-20,860,30):SetTextColor(.3,.72,1)
        button(f,"Close",900,-16,75,function()f:Hide()end)
        for i,entry in ipairs({{"GUILD","Guild only"},{"PUBLIC","Public cities"}}) do
            local mode=entry[1]
            button(f,entry[2],20,-80-(i-1)*42,165,function()self.mode=mode;self.rows={};self.page=1;self:Status("Import a fresh snapshot for this page.");self:Refresh()end)
        end
        label(f,"Cities and crafting hubs only.\n\nClick a player to prepare a profession question.\n\nSend messages yourself. Record a profession after their reply.\n\nBlue / dark gray\nGreen = recorded",24,-190,155,230)
        self.heading=label(f,"",210,-65,750,28)
        self.profButton=button(f,self.profession,210,-100,230,function()
            local n=1;for i,p in ipairs(self.professions)do if p==self.profession then n=i%#self.professions+1 end end
            self.profession=self.professions[n];self:Refresh()
        end)
        self.hubButton=button(f,self.hub,455,-100,230,function()
            local n=1;for i,p in ipairs(self.hubs)do if p==self.hub then n=i%#self.hubs+1 end end
            self.hub=self.hubs[n];self.rows={};self:Refresh()
        end)
        label(f,"Levels",705,-106,55);self.low=edit(f,"1",765,-100,65);self.high=edit(f,"60",855,-100,65)
        button(f,"Prepare city WHO",210,-142,220,function()
            if not self:ReadBounds() then return end
            self.command:SetText(self:Query());self.command:SetFocus();self.command:HighlightText()
            self:Status("Copy into chat, run WHO, then Import snapshot. Only selected-city results are retained on Public cities.")
        end)
        button(f,"Import snapshot",445,-142,220,function()
            if not self:ReadBounds() then return end
            local ok,result=pcall(self.Import,self);self:Status(ok and result or "Snapshot unavailable or restricted.");self:Refresh()
        end)
        button(f,"Refresh guild roster",680,-142,270,function()
            local request=C_GuildInfo and C_GuildInfo.GuildRoster or GuildRoster
            if request then pcall(request) end;self:Status("Roster refresh requested. Import snapshot after the roster updates.")
        end)
        self.command=edit(f,"",215,-184,730)
        button(f,"Scan open recipes",210,-226,210,function()local ok,result=pcall(self.ScanRecipes,self);self:Status(ok and result or "Recipe data unavailable.")end)
        self.item=edit(f,"Item ID",440,-226,130)
        button(f,"Find item profession",590,-226,210,function()local _,message=self:UseItem(self.item:GetText());self:Status(message);self:Refresh()end)
        label(f,"Item use levels do not prove crafter level or skill. Choose search levels above.",210,-264,740)
        self.resultButtons={}
        for i=1,9 do
            local b=button(f,"",210,-292-(i-1)*30,740,function(s)
                if not s.row then return end;self.name:SetText(s.row.name)
                self.command:SetText("/w "..s.row.name.." Hi! Do you have "..self.profession.."? I am looking for a crafter.")
                self.command:SetFocus();self.command:HighlightText()
            end);self.resultButtons[i]=b
        end
        button(f,"Previous",210,-568,100,function()self.page=self.page-1;self:Refresh()end)
        button(f,"Next",320,-568,100,function()self.page=self.page+1;self:Refresh()end)
        self.pagination=label(f,"",445,-574,500)
        self.name=edit(f,"Player name",215,-610,250)
        button(f,"Record selected profession",480,-610,280,function()
            if self:Record(self.name:GetText(),self.profession) then self:Status("Profession recorded locally from your confirmation.")else self:Status("Enter a valid player name.")end;self:Refresh()
        end)
        button(f,"Forget player",775,-610,175,function()self:Forget(self.name:GetText());self:Refresh()end)
        self.status=label(f,"Import a roster or city WHO snapshot to start.",210,-655,740,48)
    end
    self:Refresh();self.frame:Show()
end
