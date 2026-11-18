local T=_G.Tranquility;local W=T.work;local A=_G.TranquilityAccess
local function money(n)return ("%dg %ds %dc"):format(math.floor(n/10000),math.floor(n%10000/100),n%100)end
local function gold(s)if type(s)~="string"or not s:match("^%d+%.?%d?%d?%d?%d?$")then return nil end;local v=tonumber(s);return v and v>=0 and v<=10000 and math.floor(v*10000+.5)or nil end
function W:Show()
 if not A:Require()then return end;self:DB()
 if not self.frame then
  local U=T.featureUI;local f=U.Panel("TranquilityWorkBoard","TRANQUILITY / TRADESMAN & MERCENARY BOARD",980,740);self.frame=f
  U.Label(f,"Guild orders, verified deliveries and officer-reviewed rewards. Bank observations are evidence to review, not proof of guilt. No automatic gold transfers.",24,-58,920,44)
  self.rows={}
  for i=1,5 do local index=i;self.rows[i]=U.Button(f,"",24,-120-(i-1)*42,920,function()self.selected=self.visible[index];self:Refresh()end)end
  U.Button(f,"Previous",24,-340,145,function()self.page=math.max(1,(self.page or 1)-1);self:Refresh()end)
  U.Button(f,"Next",184,-340,145,function()self.page=(self.page or 1)+1;self:Refresh()end)
  U.Button(f,"Refresh postings",350,-340,200,function()self:Send({"Q1"})end)
  U.Button(f,"Admin / post jobs",570,-340,180,function()self:ShowAdmin()end)
  U.Button(f,"Discord verification",770,-340,174,function()self:ShowVerification()end)
  self.detail=U.Label(f,"",24,-390,920,164)
  U.Button(f,"Claim selected job",24,-564,280,function()if self.selected then self:Claim(self.selected)end end)
  U.Button(f,"Report delivery done",334,-564,280,function()if self.selected then self:Submit(self.selected)end end)
  U.Button(f,"Inspect bank log",644,-564,300,function()
   local j=self.selected and self:DB().jobs[self.selected];if not j then return end
   self.scanTab=j.tab
   if not self.bankOpen or not A:Admin()then self:Notice("An authorized officer must open the guild bank and inspect the selected job tab.");return end
   if QueryGuildBankLog then local ok=pcall(QueryGuildBankLog,j.tab);if not ok then self:Notice("Native bank-log query was unavailable.")end else self:ScanBank(j.tab)end
  end)
  U.Button(f,"Player help / mercenary contracts",24,-610,445,function()self:ShowContracts()end)
  U.Button(f,"Officer payroll / job roles",490,-610,454,function()self:ShowPayroll()end)
  self.status=U.Label(f,"",24,-650,920,62)
 end
 self.frame:Show();self:Send({"Q1"});self:Refresh()
end
function W:ShowAdmin()
 if not A:Require()or not A:Admin()then self:Notice("Guild Master is the default administrator. Additional admin rank names must be configured by the Guild Master.");return end
 if not self.adminFrame then
  local U=T.featureUI;local f=U.Panel("TranquilityWorkAdmin","TRADESMAN / POST & REVIEW GUILD ORDERS",980,745);self.adminFrame=f
  self.professionIndex=1;self.profession=U.Button(f,W.professions[1],24,-65,440,function()self.professionIndex=self.professionIndex%#self.professions+1;self.profession:SetText(self.professions[self.professionIndex])end)
  self.kind="ITEM";self.kindButton=U.Button(f,"Item deposit job",488,-65,455,function()self.kind=self.kind=="ITEM"and "SERVICE"or "ITEM";self.kindButton:SetText(self.kind=="ITEM"and "Item deposit job"or "Service / mercenary job")end)
  U.Label(f,"Order title",24,-112,180);self.title=U.Edit(f,"",205,-104,738);self.title:SetMaxLetters(60)
  U.Label(f,"Item ID (0 for service)",24,-157,190);self.item=U.Edit(f,"0",220,-149,100);self.item:SetScript("OnEnterPressed",function(box)if self.professions[self.professionIndex]=="Loot Goblin"then local quote=self:LootBuybackQuote(box:GetText(),self.quantity:GetText());if quote then self.reward:SetText(tostring(quote/10000))end end;box:ClearFocus()end)
  U.Label(f,"Quantity",350,-157,100);self.quantity=U.Edit(f,"1",450,-149,100)
  U.Label(f,"Bank tab",580,-157,90);self.tab=U.Edit(f,"1",675,-149,90)
  U.Label(f,"Reward in gold",24,-203,190);self.reward=U.Edit(f,"0",220,-195,100)
  U.Label(f,"Days to expire",350,-203,120);self.days=U.Edit(f,"7",485,-195,80)
  U.Button(f,"Post guild order",600,-195,343,function()
   local amount=gold(self.reward:GetText());if not amount or not self:Create(self.professions[self.professionIndex],self.title:GetText(),self.item:GetText(),self.quantity:GetText(),self.tab:GetText(),amount,self.days:GetText(),self.kind)then self:Notice("Check title, item, quantity, bank tab, reward and expiry. Posting requires native administrator rank.")end
  end)
  U.Label(f,"Select a job in the main board first. Only its posting officer can approve delivery and record its payout. A baseline read never retroactively proves a deposit.",24,-255,920,50)
  U.Button(f,"Approve delivery",24,-322,290,function()if self.selected then self:Review(self.selected,true)end end)
  U.Button(f,"Flag for investigation",336,-322,290,function()if self.selected then self:Review(self.selected,false)end end)
  self.paidCheck=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");self.paidCheck:SetPoint("TOPLEFT",24,-372);self.paidCheck:SetSize(26,26)
  U.Label(f,"I manually paid the approved recipient and verified the native guild limits.",62,-379,875)
  U.Button(f,"Record manual payout once",24,-420,450,function()if self.paidCheck:GetChecked()and self.selected then if self:ConfirmPaid(self.selected)then self.paidCheck:SetChecked(false)end else self:Notice("Actually pay and verify first; tick the confirmation only after doing so.")end end)
  U.Button(f,"Five payout ranks / admin policy",495,-420,448,function()self:ShowPayouts()end)
  U.Label(f,"Member name to suspend / restore",24,-480,340);self.suspendName=U.Edit(f,"",370,-472,573);self.suspendName:SetMaxLetters(100)
  U.Label(f,"Review reason",24,-525,160);self.suspendReason=U.Edit(f,"",205,-517,738);self.suspendReason:SetMaxLetters(70)
  U.Button(f,"Suspend toolkit access",24,-566,445,function()self:Suspend(self.suspendName:GetText(),true,self.suspendReason:GetText())end)
  U.Button(f,"Restore toolkit access",490,-566,453,function()self:Suspend(self.suspendName:GetText(),false,self.suspendReason:GetText())end)
  self.auditText=U.Label(f,"",24,-618,920,90)
 end
 self.adminFrame:Show();self:Refresh()
end
function W:ShowPayouts()
 local own=A:Member(GetUnitName("player",true));if not A:Require()or not own or own.index~=0 then self:Notice("Only the native Guild Master can set payout/admin rank policy.");return end
 if not self.configFrame then
  local U=T.featureUI;local f=U.Panel("TranquilityPayoutPolicy","GUILD MASTER / FIVE PAYOUT RANKS",840,610);self.configFrame=f
  U.Label(f,"Map the five payroll roles to native guild ranks. Guide 1g; Summoner 5g; Professions 5–15g; Mercenaries 5g; Loot Goblin 5–25g. Variable awards require officer review. UTC-day ledger; native bank reset is separate.",24,-65,780,70)
  self.payoutRows={}
  for i=1,5 do local y=-160-(i-1)*55;local r={};self.payoutRows[i]=r;U.Label(f,"Rank "..i,24,y+5,90);r.rank=U.Edit(f,({"Guide","Summoner","Professions","Mercenaries","Loot Goblin"})[i],125,y,440);r.gold=U.Edit(f,({"1","5","15","5","25"})[i],600,y,185)end
  U.Label(f,"Additional admin rank names (comma-separated; Guild Master always included)",24,-447,780)
  self.adminRanks=U.Edit(f,"",24,-475,760);self.adminRanks:SetMaxLetters(160)
  U.Button(f,"Save exact rank policy",24,-525,760,function()
   local rows={};for _,r in ipairs(self.payoutRows)do local amount=gold(r.gold:GetText());if not amount then self:Notice("Fill all five amounts, including the fifth. No values are guessed.");return end;rows[#rows+1]={rank=r.rank:GetText(),amount=amount}end
   if self:SetPayouts(rows,self.adminRanks:GetText())then self:Notice("Rank payout ledger policy saved. Guild repairs/withdraw limits still use native guild controls.")else self:Notice("Use five distinct actual rank names with valid amounts.")end
  end)
 end
 self.configFrame:Show()
end
function W:ShowVerification()
 if not A:Require()or not A:Admin()then return end
 if not self.verifyFrame then
  local U=T.featureUI;local f=U.Panel("TranquilityVerification","DISCORD / NATIVE CHARACTER VERIFICATION",900,680);self.verifyFrame=f
  U.Label(f,"The bot issues a random, expiring code bound to a Discord account and character. Import its request, have that exact character type /tranq verify <code>, then click to request Dedicated Member. The addon observes the actual native rank before confirming.",24,-62,845,84)
  self.verifyInput=U.Edit(f,"",24,-165,845);self.verifyInput:SetMaxLetters(16000)
  U.Button(f,"Import bot request lines",24,-210,410,function()self:ImportVerification(self.verifyInput:GetText())end)
  U.Button(f,"Refresh native guild roster",455,-210,414,function()local api=C_GuildInfo and C_GuildInfo.GuildRoster or GuildRoster;if api then pcall(api)end;A:RefreshRoster();self:Refresh()end)
  self.verificationDetail=U.Label(f,"",24,-265,845,170)
  U.Button(f,"Next request",24,-460,180,function()self.verifyIndex=(self.verifyIndex or 1)+1;self:Refresh()end)
  U.Button(f,"Send in-game vault code",215,-460,280,function()if self.verifyCode then self:IssueVault(self.verifyCode)end end)
  U.Button(f,"Request native promotion",510,-460,359,function()if self.verifyCode then self:PromoteVerified(self.verifyCode)end;self:Refresh()end)
  self.verifyExport=U.Edit(f,"",24,-520,845);self.verifyExport:SetMaxLetters(16000)
  U.Button(f,"Copy confirmed rank links for bot",24,-565,845,function()self.verifyExport:SetText(self:VerificationExport());self.verifyExport:SetFocus();self.verifyExport:HighlightText(0,-1)end)
  U.Label(f,"Native guild permissions may require an authorized click. Discord roles alone cannot change WoW guild ranks, repairs or server bank permissions. The bot grants its Dedicated Member role only after the reviewed confirmation handoff.",24,-612,845,50)
 end
 self.verifyFrame:Show();self:Refresh()
end
function W:Refresh()
 if not self.frame or not self.frame:IsShown()then return end
 if not A:Allowed()then A:ShowDenied();return end
 local d=self:DB();local jobs={};for _,j in pairs(d.jobs)do jobs[#jobs+1]=j end;table.sort(jobs,function(a,b)return a.id>b.id end)
 self.page=math.min(self.page or 1,math.max(1,math.ceil(#jobs/5)));self.visible={}
 for i,b in ipairs(self.rows)do local j=jobs[(self.page-1)*5+i];self.visible[i]=j and j.id;b:SetText(j and (j.profession.." · "..j.title.." · "..j.status.." · "..money(j.reward))or "No posting");b:SetEnabled(j~=nil)end
 local j=self.selected and d.jobs[self.selected]
 if j then
  local deposit,withdraw=0,0;for _,e in ipairs(d.evidence[j.id]or {})do if e.kind=="deposit"then deposit=deposit+e.quantity else withdraw=withdraw+e.quantity end end
  self.detail:SetText(j.title.."\nOwner: "..j.owner.." · "..j.status.." · Assigned: "..(j.assignee or "nobody").."\n"..j.kind.." · Item "..j.item.." x"..j.quantity.." · Bank tab "..j.tab.." · Reward "..money(j.reward).."\nObserved deposits "..deposit.." / withdrawals "..withdraw..". Officer review required.\n"..(d.pending[j.id]and d.pending[j.id].status or ""))
 else self.detail:SetText("Select a job. Profession categories include gathering, cooking, First Aid, fishing, all craftsmanship, specializations and mercenary/service work. Client-specific professions are planning labels; the addon cannot grant recipes or skills.")end
 local activity=self:SummonStats(GetUnitName("player",true))
 self.status:SetText(self.notice or ("Summons today: "..activity.summons.." / guild recipients: "..activity.guildies..". ").."Only Dedicated Member or higher in Tranquility can use the toolkit. Deposits must match the assigned job; withdrawals are flagged for review. Watchdog evidence exists only while an authorized client can access bank logs.")
 if self.auditText then local lines={};for i=math.max(1,#d.audit-2),#d.audit do local e=d.audit[i];lines[#lines+1]=e.kind.." · "..e.who.." · "..e.detail end;self.auditText:SetText(table.concat(lines,"\n"))end
 if self.verificationDetail then local codes={};for code in pairs(d.verification)do codes[#codes+1]=code end;table.sort(codes);self.verifyIndex=((self.verifyIndex or 1)-1)%math.max(1,#codes)+1;self.verifyCode=codes[self.verifyIndex];local r=self.verifyCode and d.verification[self.verifyCode];self.verificationDetail:SetText(r and (r.name.."\nDiscord account ID: "..r.discord.."\n"..r.status.."\nExpires: "..tostring(r.expires))or "No imported verification requests. The external bot must be configured locally first.")end
end
