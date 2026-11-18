local T=_G.Tranquility
local A={threshold=1.75,snapshots={}}
T.auction=A
local function number(value) value=T.Public(value); return type(value)=="number" and value or nil end
local function money(value)
    if not value then return "--" end
    return ("%dg %ds %dc"):format(math.floor(value/10000),math.floor(value/100)%100,math.floor(value)%100)
end
function A:Init()
    self.db=T.db.auction
    self.db.markets=self.db.markets or {}; self.db.custom=self.db.custom or {}; self.db.ignored=self.db.ignored or {}
    self.marketKey=(GetRealmName() or "Unknown") .. ":" .. (UnitFactionGroup("player") or "Unknown")
    self.db.markets[self.marketKey]=self.db.markets[self.marketKey] or {}
    self.history=self.db.markets[self.marketKey]
    self.watch={}
    for _,item in ipairs(T.farmItems) do self.watch[#self.watch+1]=item end
    for _,item in ipairs(self.db.custom) do self.watch[#self.watch+1]=item end
end
function A:Baseline(id,day)
    local sum,count=0,0
    for _,record in ipairs(self.history[id] or {}) do
        if record.day < day and record.day >= day-14 then sum=sum+record.price; count=count+1 end
    end
    return count>=3 and sum/count or nil,count
end
function A:Record(id,price,quantity)
    if not number(id) or id~=id or id<=0 or id%1~=0 or id>2147483647 or not number(price) or price~=price or price<=0 or price>1e12 then return false end
    local day=math.floor(GetServerTime()/86400)
    local kept,found={},false
    for _,record in ipairs(self.history[id] or {}) do
        if record.day>=day-30 then
            if record.day==day then record.price=math.min(record.price,price); found=true end
            kept[#kept+1]=record
        end
    end
    if not found then kept[#kept+1]={day=day,price=price} end
    self.history[id]=kept
    self.snapshots[id]={price=price,quantity=quantity,at=GetServerTime()}
    self:Refresh(); return true
end
function A:AddItem(value)
    local id=tonumber(value)
    if not id or id<=0 or id%1~=0 then T:Notify("Enter a valid item ID."); return end
    for _,item in ipairs(self.watch) do if item.id==id then return end end
    if #self.watch>=100 then T:Notify("Watchlist limit: 100. Remove an item first."); return end
    local api=C_Item and C_Item.GetItemInfo or GetItemInfo
    if not api then T:Notify("Item data unavailable on this client."); return end
    local name,_,_,_,_,_,_,_,_,_,_,_,_,bindType=api(id)
    name=T.Text(name)
    if not name then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        T:Notify("Item data is not cached; try Add again shortly."); return
    end
    if number(bindType)==1 or number(bindType)==4 then T:Notify("Soulbound and quest items cannot be auction farm candidates."); return end
    local item={id=id,name=name}
    self.db.custom[#self.db.custom+1]=item; self.watch[#self.watch+1]=item; self:Refresh()
end
function A:ReadCurrentResults(id)
    id=tonumber(id)
    if not id or id<=0 or id%1~=0 or id>2147483647 then self.status="Enter the exact searched item ID."; self:Refresh(); return end
    if not self.open then self.status="Open the Auction House and search the item in Blizzard's auction UI first."; self:Refresh(); return end
    if InCombatLockdown() then return end
    local minimum,quantity=nil,0
    local function add(price,units)
        price,units=number(price),number(units)
        if price and price>0 and price<=1e12 and units and units>0 and units<=1e9 then minimum=minimum and math.min(minimum,price) or price; quantity=quantity+units end
    end
    local api=C_AuctionHouse
    if api and api.MakeItemKey and api.GetNumCommoditySearchResults then
        local commodity=number(api.GetNumCommoditySearchResults(id))
        if commodity and commodity>0 then
            if commodity>10000 then self.status="Result set too large to sample in one click."; self:Refresh(); return end
            if not api.HasFullCommoditySearchResults or T.Public(api.HasFullCommoditySearchResults(id))~=true then self.status="Incomplete commodity results. Finish loading them in Blizzard's UI first."; self:Refresh(); return end
            for i=1,commodity do local info=T.Public(api.GetCommoditySearchResultInfo(id,i)); if type(info)=="table" then add(info.unitPrice,info.quantity) end end
        else
            local infoAPI=C_Item and C_Item.GetItemInfo or GetItemInfo
            local _,_,_,level=infoAPI(id)
            local key=api.MakeItemKey(id,number(level) or 0,0,0)
            if not api.HasFullItemSearchResults or T.Public(api.HasFullItemSearchResults(key))~=true then self.status="No complete base-variant result set. Check the item/variant; alternatively enter its observed unit price below."; self:Refresh(); return end
            local count=number(api.GetNumItemSearchResults(key)) or 0
            if count>10000 then self.status="Result set too large to sample in one click."; self:Refresh(); return end
            for i=1,count do
                local info=T.Public(api.GetItemSearchResultInfo(key,i))
                if type(info)=="table" then local q=number(info.quantity); local p=number(info.buyoutAmount); if q and q>0 and p then add(p/q,q) end end
            end
        end
    elseif GetNumAuctionItems and GetAuctionItemInfo and GetAuctionItemLink then
        local count,total=GetNumAuctionItems("list")
        count,total=number(count),number(total)
        if not count or not total or count<total then self.status="Classic results are paginated. A page is not a market-wide minimum; record an observed unit price explicitly instead."; self:Refresh(); return end
        for i=1,count do
            local link=T.Text(GetAuctionItemLink("list",i))
            if link and tonumber(link:match("item:(%d+)"))==id then
                local _,_,units,_,_,_,_,_,_,buyout=GetAuctionItemInfo("list",i)
                units,buyout=number(units),number(buyout)
                if units and units>0 and buyout then add(buyout/units,units) end
            end
        end
    else self.status="Auction result API unavailable. Use the manual unit-price field."; self:Refresh(); return end
    if minimum then self:Record(id,minimum,quantity); self.status="Current complete result set recorded. Asking price is not sale value."
    else self.snapshots[id]=nil; self.status="No readable priced listings in this result set. Previous current sample cleared." end
    self:Refresh()
end
function A:ReadResults(id)
    local ok=pcall(self.ReadCurrentResults,self,id)
    if not ok then self.status="Auction data unavailable or restricted. No automatic retry; use an observed unit price instead."; self:Refresh() end
end
function A:Refresh()
    if not self.frame then return end
    local rows,day,now={},math.floor(GetServerTime()/86400),GetServerTime()
    for _,item in ipairs(self.watch) do
        local s=self.snapshots[item.id]
        local base,days=self:Baseline(item.id,day)
        local fresh=s and now-s.at<=900
        local ratio=fresh and base and s.price/base
        rows[#rows+1]={item=item,s=s,base=base,days=days,ratio=ratio,candidate=not self.db.ignored[item.id] and ratio and ratio>=self.threshold}
    end
    table.sort(rows,function(a,b) if not not a.candidate~=not not b.candidate then return not not a.candidate end; return (a.ratio or 0)>(b.ratio or 0) end)
    local lines={}
    for _,row in ipairs(rows) do
        local label=self.db.ignored[row.item.id] and "Ignored" or row.candidate and "|cffffd070FARM CANDIDATE|r" or row.base and "Below threshold / no fresh comparison" or ("Learning %d/3 prior days"):format(row.days)
        lines[#lines+1]=("%s [%d] — %s\nUnit ask: %s | Prior daily-low mean: %s | Ratio: %s\n%s\n"):format(row.item.name,row.item.id,label,money(row.s and row.s.price),money(row.base),row.ratio and ("%.0f%%"):format(row.ratio*100) or "unavailable",T:FarmSource(row.item.id))
    end
    self.setList(#lines>0 and table.concat(lines,"\n") or "Enable Tranquility DB for a starter watchlist, or add an item ID above.")
    self.statusLabel:SetText(self.status or ("Market: " .. self.marketKey .. ". Samples older than 15 minutes are excluded from comparisons."))
end
function A:CreateUI()
    local UI=T.featureUI
    self.frame=UI.Panel("TranquilityAuctions","TRANQUILITY / AUCTION OPPORTUNITIES",920,700)
    local f=self.frame
    UI.Label(f,"Search in Blizzard's Auction House, then read the current results or record the observed unit price.\nCandidates: >=175% of the mean of prior daily lows (14-day window; at least 3 prior days).\nAn expensive listing does not establish demand, sales or profit. Verify variants and saleability yourself.",22,-55,870,65)
    UI.Label(f,"Item ID",22,-143,65)
    local id=UI.Edit(f,"",92,-135,100)
    UI.Button(f,"Add",205,-135,65,function() self:AddItem(id:GetText()) end)
    UI.Button(f,"Read AH results",285,-135,160,function() self:ReadResults(id:GetText()) end)
    UI.Button(f,"Ignore",460,-135,95,function() local n=tonumber(id:GetText()); if n then self.db.ignored[n]=true; self:Refresh() end end)
    UI.Button(f,"Restore",570,-135,95,function() local n=tonumber(id:GetText()); if n then self.db.ignored[n]=nil; self:Refresh() end end)
    UI.Button(f,"Remove custom",680,-135,170,function()
        local n=tonumber(id:GetText())
        for i=#self.db.custom,1,-1 do if self.db.custom[i].id==n then table.remove(self.db.custom,i) end end
        self:Init(); self:Refresh()
    end)
    UI.Label(f,"Unit price in copper",22,-188,155)
    local price=UI.Edit(f,"",187,-180,135); price:SetNumeric(true)
    UI.Button(f,"Record observed price",340,-180,195,function()
        local n,p=tonumber(id:GetText()),tonumber(price:GetText())
        local watched=false; for _,item in ipairs(self.watch) do if item.id==n then watched=true end end
        if not watched or not self:Record(n,p) then T:Notify("Add this item first and enter a positive price in copper.")
        else self.status="Manually entered asking price recorded; availability and market coverage are unverified."; self:Refresh() end
    end)
    UI.Button(f,"Loot sources",550,-180,130,function() T:OpenModule("Loot") end)
    self.setList=UI.ScrollText(f,22,-230,850,370)
    self.statusLabel=UI.Label(f,"",22,-625,870,45)
    self:Refresh()
end
local events=CreateFrame("Frame")
T:RegisterObservedEvent(events,"AUCTION_HOUSE_SHOW","Auctions")
T:RegisterObservedEvent(events,"AUCTION_HOUSE_CLOSED","Auctions")
events:SetScript("OnEvent",function(_,event) A.open=event=="AUCTION_HOUSE_SHOW" end)
T:Register("Auctions",A,"auction",function(self) self:Init() end)
