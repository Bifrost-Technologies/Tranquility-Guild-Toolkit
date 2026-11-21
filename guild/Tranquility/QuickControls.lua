local T=Tranquility
local controls={}
T.quickControls=controls
local function add(group,key,label,tip)controls[#controls+1]={group=group,key=key,label=label,tip=tip}end
add('markers','enabled','Enhanced nameplates','Local outlines, labels and icons on enemy nameplates the game exposes. Requires WoW enemy nameplates to be visible (normally V).')
for _,r in ipairs({{'players','Enemy player highlights'},{'npcs','Enemy NPC highlights'},{'boxes','Nameplate outlines'},{'names','Names and player / NPC labels'},{'icons','Skull icons'},{'target','Current-target highlight'},{'focus','Focus-target highlight'}})do add('markers',r[1],r[2],'Requires Enhanced nameplates. Changes apply immediately; hidden or distant units are not revealed.')end
add('native','nameplateShowEnemies','WoW enemy nameplates','Changes the game enemy-nameplate setting, normally toggled with V. Change this out of combat.')
for _,r in ipairs({{'enabled','PvP scouting and heatmap'},{'share','Share sightings with guild'},{'friendly','Include friendly player sightings'},{'fallback','Allow approximate scout locations'},{'alerts','Approaching-enemy alerts'},{'sound','Enemy alert sounds'}})do add('pvp',r[1],r[2],'Requires the Tranquility PvP module. Scouting must be on for sharing, sightings and alerts; sounds also require alerts. Approximate locations are labeled as estimates.')end
add('loot','enabled','Automatic loot journal','Passively record loot and roll observations. OFF stops new records and preserves existing history; it does not change game Auto Loot.')
for _,r in ipairs({{'enabled','Flight-path map markers'},{'neutral','Include neutral flight hubs'},{'labels','Flight-path labels'}})do add('flight',r[1],r[2],'Requires Flight Path Finder. Uses its existing settings; these switches also update its panel.')end
add('launcher','enabled','Tranquility minimap button','Show or hide the TQ minimap launcher. /tranq always opens the menu for guild members.')
function T:QuickState(row)
 if row.group=='markers'then local c=self.enemyMarkers and self.enemyMarkers:Config();return c and c[row.key]==true,c~=nil end
 if row.group=='pvp'then local d=self.defense;return d and d:Settings()[row.key]==true,d~=nil end
 if row.group=='flight'then local f=_G.FlightPathFinder;return f and f.db and f.db[row.key]==true,f and f.db~=nil end
 if row.group=='loot'then local m=self.modules.Loot;return not(TranquilityDB and TranquilityDB.automatic and TranquilityDB.automatic.loot==false),m and m.ready==true end
 if row.group=='native'then local ok,value=pcall(function()return GetCVar('nameplateShowEnemies')end);return ok and value=='1',ok and value~=nil end
 return not(TranquilityDB and TranquilityDB.hideLauncher),true
end
function T:SetQuickFeature(row,on)
 if not TranquilityAccess or not TranquilityAccess:Allowed()then return false,'Join Tranquility to use these features.'end
 local _,available=self:QuickState(row);if not available then return false,'Enable the required addon in the AddOns menu, then reload.'end
 on=on==true
 if row.group=='markers'then self.enemyMarkers:Config()[row.key]=on;self.enemyMarkers:Update();self.enemyMarkers:Refresh()
 elseif row.group=='pvp'then
  local d=self.defense;d:Settings()[row.key]=on
  if row.key=='enabled'then
   if on then d:SeedUnits()else local shown=d.frame and d.frame:IsShown();d:Stop();if shown then d.frame:Show()end end
  end
  if d.CheckAlerts then d:CheckAlerts()end;if d.Render then d:Render()end;if d.Refresh then d:Refresh()end
 elseif row.group=='flight'then local f=FlightPathFinder;f.db[row.key]=on;f:Render();f:Refresh()
 elseif row.group=='loot'then TranquilityDB.automatic=TranquilityDB.automatic or {};TranquilityDB.automatic.loot=on
 elseif row.group=='native'then
  if InCombatLockdown and InCombatLockdown()then return false,'Change WoW nameplate visibility after combat.'end
  local ok=pcall(SetCVar,'nameplateShowEnemies',on and '1'or '0');local actual=self:QuickState(row)
  if not ok or actual~=on then return false,'The client did not accept the nameplate setting.'end
 else TranquilityDB.hideLauncher=not on;self:EnsureLauncher()end
 return true,row.label..(on and ' ON.'or ' OFF.')
end
function T:RefreshQuickControls()
 if not self.quickRows then return end
 for i,row in ipairs(controls)do
  local on,available=self:QuickState(row);local view=self.quickRows[i]
  view.check:SetChecked(on==true);view.check:SetEnabled(available==true)
  view.label:SetText(row.label..(not available and ' |cff999999[addon unavailable]|r'or ''))
 end
 local e=self.enemyMarkers;local c=e and e:Config();local native=self:QuickState({group='native'})
 self.quickSummary:SetText(not(c and c.enabled)and 'Nameplate enhancements OFF.'or(not native and 'Enhancements ON; WoW enemy nameplates are hidden. Enable the switch above or press V.'or(e.status or 'Enhancements ON. Waiting for visible enemy nameplates.')))
end
function T:BuildQuickControls()
 if self.quickRows then return end
 local U=self.featureUI;local panel=self.quickPanel
 U.Label(panel,'FEATURE SWITCHES',22,-20,850,24):SetTextColor(.2,.8,1)
 U.Label(panel,'Saved immediately. Unavailable addons are marked. Hover a switch for requirements.',22,-55,850,30)
 self.quickRows={}
 for i,row in ipairs(controls)do
  local column=(i-1)%2;local line=math.floor((i-1)/2);local x=22+column*445;local y=-100-line*35
  local check=CreateFrame('CheckButton',nil,panel,'UICheckButtonTemplate');check:SetSize(26,26);check:SetPoint('TOPLEFT',x,y)
  local label=U.Label(panel,'',x+31,y-5,395,27);self.quickRows[i]={check=check,label=label}
  check:SetScript('OnClick',function(b)local ok,msg=self:SetQuickFeature(row,b:GetChecked());self.quickFeedback:SetText(msg);self:RefreshQuickControls()end)
  check:SetScript('OnEnter',function(b)if GameTooltip then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');GameTooltip:SetText(row.label);GameTooltip:AddLine(row.tip,1,1,1,true);GameTooltip:Show()end end)
  check:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
 end
 local bottom=110+math.ceil(#controls/2)*35
 panel:SetHeight(bottom+135)
 self.quickSummary=U.Label(panel,'',22,-bottom,850,55)
 self.quickFeedback=U.Label(panel,'Feature settings do not start combat or farming.',22,-bottom-62,850,45)
 local elapsed=0;panel:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed>=.5 then elapsed=0;T:RefreshQuickControls()end end)
end
