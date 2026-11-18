local W=Tranquility.work;local T=Tranquility;local A=TranquilityAccess
function W:ShowContracts()
 if not A:Require()then return end
 if not self.contractFrame then
  local U=T.featureUI;local f=U.Panel('TranquilityPlayerContracts','PLAYER HELP / MERCENARY CONTRACTS',980,740);self.contractFrame=f
  U.Label(f,'Player-funded offers. Guide quests / dungeon help: one helper. Mercenary contracts: up to 40 accepted mercenaries, each earning the stated reward. Completion and payment require the requester’s review.',24,-60,920,56)
  self.contractRows={};for i=1,4 do local index=i;self.contractRows[i]=U.Button(f,'',24,-130-(i-1)*38,920,function()self.contractSelected=self.contractVisible[index];self:RefreshContracts()end)end
  U.Button(f,'Previous',24,-288,170,function()self.contractPage=math.max(1,(self.contractPage or 1)-1);self:RefreshContracts()end);U.Button(f,'Next',210,-288,170,function()self.contractPage=(self.contractPage or 1)+1;self:RefreshContracts()end)
  U.Button(f,'Accept contract',400,-288,250,function()self:ContractAction(self.contractSelected,'ACCEPT')end);U.Button(f,'Report complete',674,-288,270,function()self:ContractAction(self.contractSelected,'REPORT')end)
  self.contractDetail=U.Label(f,'',24,-335,920,92)
  self.contractParticipant=U.Edit(f,'',24,-435,350);self.contractParticipant:SetMaxLetters(100)
  U.Button(f,'Approve named helper',390,-435,270,function()self:ReviewContract(self.contractSelected,self.contractParticipant:GetText(),false);self:RefreshContracts()end)
  U.Button(f,'I paid this helper',674,-435,270,function()self:ReviewContract(self.contractSelected,self.contractParticipant:GetText(),true);self:RefreshContracts()end)
  self.contractCategory='GUIDE';self.contractType=U.Button(f,'Guide / quest help',24,-495,280,function()self.contractCategory=self.contractCategory=='GUIDE'and 'MERC'or 'GUIDE';self.contractType:SetText(self.contractCategory=='GUIDE'and 'Guide / quest help'or 'Mercenary contract')end)
  U.Label(f,'Gold per helper',320,-495,150);self.contractGold=U.Edit(f,'0',475,-495,100);U.Label(f,'Days',600,-495,80);self.contractDays=U.Edit(f,'7',690,-495,100)
  self.contractTitle=U.Edit(f,'Describe location and objective',24,-545,920);self.contractTitle:SetMaxLetters(80)
  U.Button(f,'Post player-funded offer',24,-590,450,function()local g=tonumber(self.contractGold:GetText());local cents=g and math.floor(g*10000+.5);if cents then self:CreateContract(self.contractCategory,self.contractTitle:GetText(),cents,tonumber(self.contractDays:GetText()))end;self:RefreshContracts()end)
  U.Button(f,'Close selected offer',495,-590,450,function()self:ContractAction(self.contractSelected,'CLOSE');self:RefreshContracts()end)
  U.Label(f,'Accepting requires the Guide / Mercenaries job role. The requester must be online to accept claims. “I paid” records your manual payment; it never sends money. Do not post more rewards than you can fund.',24,-642,920,60)
 end;self.contractFrame:Show();self:Send({'Q1'});self:RefreshContracts()
end
function W:RefreshContracts()
 if not self.contractFrame or not self.contractFrame:IsShown()then return end;if not A:Allowed()then self.contractFrame:Hide();return end
 local list={};for _,c in pairs(self:Contracts())do list[#list+1]=c end;table.sort(list,function(a,b)return a.id>b.id end);self.contractPage=math.max(1,math.min(self.contractPage or 1,math.max(1,math.ceil(#list/4))));self.contractVisible={}
 for i,b in ipairs(self.contractRows)do local c=list[(self.contractPage-1)*4+i];self.contractVisible[i]=c and c.id;b:SetText(c and (c.category..' / '..c.title..' / '..c.reward/10000 ..'g each / '..(c.closed and 'CLOSED'or 'OPEN'))or 'No offer');b:SetEnabled(c~=nil)end
 local c=self.contractSelected and self:Contracts()[self.contractSelected];local lines={};if c then for who,status in pairs(c.participants)do lines[#lines+1]=who..' '..status end end
 self.contractDetail:SetText(c and (c.owner..' / '..c.title..'\n'..table.concat(lines,' · '))or 'Select a contract. To approve/pay a helper enter their exact Name-Realm above. No automatic delivery claim establishes success.')
end
function W:ShowPayroll()
 if not A:Require()or not A:Admin()then return end
 if not self.payrollFrame then
  local U=T.featureUI;local f=U.Panel('TranquilityPayroll','OFFICER / JOB ROLES & DAILY PAYROLL',920,640);self.payrollFrame=f
  U.Label(f,'Guide 1g · Summoner 5g · Professions 5–15g · Mercenaries 5g · Loot Goblin 5–25g. Select awards based on reviewed work, supply/demand, dungeon runs and bank value. UTC-day local ledger; native bank limits still apply.',24,-65,870,70)
  self.payrollName=U.Edit(f,'Name-Realm',24,-155,870);self.payrollName:SetMaxLetters(100);self.payrollName:SetScript("OnEnterPressed",function(box)local who=box:GetText();local stats=self:SummonStats(who);local d=self:DB();local remote=d.summonReports and d.summonReports[A:Key(who)];self:Notice(who..": local corroborated summons today "..stats.summons..", guild recipients "..stats.guildies..(remote and remote.day==math.floor(GetServerTime()/86400)and (" / Provider-reported "..remote.summons..", guild recipients "..remote.guildies)or " / No current provider report"));box:ClearFocus()end)
  self.payrollRoleIndex=1;local roles={'Guide','Summoner','Professions','Mercenaries','Loot Goblin'}
  self.payrollRole=U.Button(f,roles[1],24,-205,870,function()self.payrollRoleIndex=self.payrollRoleIndex%#roles+1;self.payrollRole:SetText(roles[self.payrollRoleIndex])end)
  U.Button(f,'Assign job role',24,-255,420,function()self:AssignJobRole(self.payrollName:GetText(),roles[self.payrollRoleIndex],true)end);U.Button(f,'Remove job role',470,-255,424,function()self:AssignJobRole(self.payrollName:GetText(),roles[self.payrollRoleIndex],false)end)
  U.Label(f,'Award gold',24,-320,150);self.payrollGold=U.Edit(f,'5',185,-312,200)
  self.payrollReason=U.Edit(f,'Reviewed work / supply demand / dungeon evidence',24,-365,870);self.payrollReason:SetMaxLetters(100)
  U.Button(f,'Approve daily award (does not pay)',24,-420,870,function()local ok=self:PayrollAward(self.payrollName:GetText(),roles[self.payrollRoleIndex],tonumber(self.payrollGold:GetText()),self.payrollReason:GetText());self:Notice(ok and 'Payroll approved once for this UTC day/role. Pay manually and record in native bank logs.'or 'Award rejected: check assigned role, bounds, evidence and duplicate day.');end)
  self.telemetry=U.Edit(f,'',24,-475,870)
  U.Button(f,'Copy bank / LFG bot status snapshot',24,-520,870,function()self.telemetry:SetText(self:TelemetryExport());self.telemetry:SetFocus();self.telemetry:HighlightText(0,-1)end)
  U.Label(f,'Bot status is a timestamped snapshot, not a live remote bank API. Summoner qualification needs >1 corroborated summon/day; missing logs flag review, never revoke a native rank automatically.',24,-568,870,56)
 end;self.payrollFrame:Show()
end
