local T=Tranquility
local originalOpen=T.OpenModule
local function openObject(object,method,field)
 if not object or not object[method or 'Show']then return nil,'Enable the required addon in the character-selection AddOns menu, then reload.'end
 object[method or 'Show'](object);return object[field or 'frame']
end
function T:BuildDashboard()
 if self.dashboard then return end
 local d=self.dashboardUI:New('TranquilityDashboard','TRANQUILITY  /  GUILD TOOLKIT');self.dashboard=d;self.frame=d.frame
 local overview=d:Overview('Your guild tools, in one workspace.\n\nSelect a page on the left to open its controls here. Larger pages scroll within the content panel.\n\nRecruitment: /ginvite only is recommended. Enable messages only when you need them; unsolicited messages may be reported.\n\nUse Feature switches for saved marker, scouting and journal settings. Optional addons that are disabled show a clear availability message.\n\nUse each service’s Start/Stop controls. Switching pages can stop tools that stop when hidden.')
 d:Add('home','Overview','Guild services and local tools.',function()return overview end)
 for _,row in ipairs(self.catalog)do local id,title,description=row[1],row[2],row[3]
  d:Add(id,title,description,function()local record=self.modules[id];if not record or not record.ready then return nil,'Enable Tranquility '..id..' in AddOns, then reload.'end;originalOpen(self,id);return record.object.frame end)
 end
 d:Add('features','Feature switches','Saved switches. Hover a switch for its requirements.',function()
  if not self.quickPanel then self.quickPanel=CreateFrame('Frame',nil,UIParent);self.quickPanel:SetSize(900,660);self.quickPanel:Hide()end
  self:BuildQuickControls();self:RefreshQuickControls();return self.quickPanel
 end)
 d:Add('pvp','PvP command center','Guild scouting, alerts and local sightings.',function()return openObject(self.defense)end)
 d:Add('flights','Flight Path Finder','Map and minimap route guidance.',function()return openObject(FlightPathFinder)end)
 d:Add('lfp','Profession finder','Guild crafters and public crafting hubs.',function()if LookingForProfession then LookingForProfession.mode='GUILD'end;return openObject(LookingForProfession)end)
 d:Add('lfg','Guild groups','Tranquility group finder.',function()return openObject(TranquilityLFG)end)
 d:Add('uber','Uber services','Summons, portals and phase keepers.',function()return openObject(Uber)end)
 for _,row in ipairs({{'work','Tradesman & jobs','Show','frame'},{'contracts','Mercenary contracts','ShowContracts','contractFrame'},{'payroll','Officer payroll','ShowPayroll','payrollFrame'},{'work-admin','Job administration','ShowAdmin','adminFrame'},{'payouts','Payout policy','ShowPayouts','configFrame'},{'verification','Discord verification','ShowVerification','verifyFrame'}})do
  local id,title,method,field=row[1],row[2],row[3],row[4];d:Add(id,title,'Guild work and services.',function()return openObject(self.work,method,field)end)
 end
 d:Add('settings','Recruit settings','Manual recruitment pacing and batch settings.',function()self:ShowRecruitSettings();return self.settingsFrame end)
end
function T:Show()
 if not TranquilityAccess or not TranquilityAccess:Require()then return end
 self:BuildDashboard();self.dashboard:Select(self.dashboard.active or 'home')
end
function T:OpenModule(id)
 if not TranquilityAccess or not TranquilityAccess:Require()then return end
 self:BuildDashboard();return self.dashboard:Select(id)
end
