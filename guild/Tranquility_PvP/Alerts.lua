local T=Tranquility;local D=T.defense;local A=TranquilityAccess
function D:Danger()
 local s=self:Settings();local own=self:OwnPosition();if not own then return {}end
 local cells,w,h=self:Cells(own.map);local list={};local myFaction=A:Read(UnitFactionGroup,'player')=='Horde'and 'H'or 'A'
 for _,c in ipairs(cells)do if c.faction~=myFaction and GetServerTime()-c.at<=15 then
  local distance=math.sqrt(((c.x-own.x)*w)^2+((c.y-own.y)*h)^2)
  if c.count>=(s.alertCount or 5)and distance<=(s.alertRange or 300)then list[#list+1]={cell=c,distance=distance}end
 end end
 table.sort(list,function(a,b)return a.distance<b.distance end);return list
end
function D:CheckAlerts()
 if not A:Allowed()or not self:Settings().enabled then return end
 local s=self:Settings();local list=self:Danger();local first=list[1];self.danger=first
 if not first or not s.alerts then if self.alertFrame then self.alertFrame:Hide()end;return end
 if not self.alertFrame then
  local f=CreateFrame('Frame','TranquilityPvPDanger',UIParent,'BackdropTemplate');self.alertFrame=f;f:SetSize(520,70);f:SetPoint('TOP',0,-145);f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});f:SetBackdropColor(.12,.025,.025,.9)
  f.text=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');f.text:SetPoint('CENTER');f.text:SetSize(480,54);f:EnableMouse(false)
 end
 self.alertFrame.text:SetText((first.cell.approx and 'Possible enemy concentration'or 'Recent enemy sightings')..'\n'..first.cell.count..' observed · about '..math.floor(first.distance+.5)..' yards · '..(GetServerTime()-first.cell.at)..'s old');self.alertFrame:Show()
 if s.sound and GetServerTime()-(self.lastSound or 0)>=30 and PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound,SOUNDKIT.RAID_WARNING);self.lastSound=GetServerTime()end
end
local scan=D.Scan
function D:Scan()scan(self);self:CheckAlerts()end
local stop=D.Stop
function D:Stop()stop(self);self.danger=nil;if self.alertFrame then self.alertFrame:Hide()end end
if T.Register then T:Register('PvP',D,nil,function()if D:Settings().enabled then D:SeedUnits()end end)end
