local T=_G.Tranquility
local A=_G.TranquilityAccess
local W={prefix="TQWORK1",queue={},bankOpen=false};T.work=W
W.professions={"Alchemy","Blacksmithing","Armorsmithing","Weaponsmithing","Leatherworking","Tailoring","Enchanting","Engineering","Mining","Herbalism","Skinning","Cooking","First Aid","Fishing","Jewelcrafting","Inscription","Archaeology","Mercenary","Dungeon escort","PvP defense","Scouting","Loot Goblin","Custom"}
local function now()return GetServerTime()end
local function me()return GetUnitName("player",true)end
local function clean(s,n)return type(s)=="string"and #s>0 and #s<=n and not s:find("[%c|]")end
local function int(v,low,high)local n=tonumber(v);return n and n==n and n%1==0 and n>=low and n<=high and n end
function W:DB()
 TranquilityDB=type(TranquilityDB)=="table"and TranquilityDB or {};TranquilityDB.work=type(TranquilityDB.work)=='table'and TranquilityDB.work or {jobs={},audit={},bank={},evidence={},paid={},pending={},verification={}}
 local d=TranquilityDB.work;TranquilityDB.security=type(TranquilityDB.security)=='table'and TranquilityDB.security or {adminRanks={},bans={},payoutRanks={}}
 for _,k in ipairs({"jobs","audit","bank","evidence","paid","pending","verification"})do if type(d[k])~='table'then d[k]={}end end
 local s=TranquilityDB.security;for _,k in ipairs({'adminRanks','bans','payoutRanks'})do if type(s[k])~='table'then s[k]={}end end
 return d,s
end
function W:Log(kind,who,detail)
 local d=self:DB();d.audit[#d.audit+1]={at=now(),kind=kind,who=who or me(),detail=detail or ""}
 while #d.audit>2000 do table.remove(d.audit,1)end
end
function W:Notice(text)self.notice=text;if self.Refresh then self:Refresh()end end
function W:Send(parts)
 if not A:Native()or #self.queue>=100 then return false end
 local text=table.concat(parts,"|");if #text>240 then return false end
 self.queue[#self.queue+1]=text;return true
end
function W:SendWhisper(parts,target)
 if not A:Native()or #self.queue>=100 then return false end;local text=table.concat(parts,"|");if #text>240 then return false end
 self.queue[#self.queue+1]={text=text,target=target};return true
end
function W:ID()
 local d=self:DB();d.serial=(d.serial or 0)+1
 local hash=0;for i=1,#me()do hash=(hash*33+me():byte(i))%2147483647 end
 return now().."-"..hash.."-"..d.serial
end
function W:Publish(job)
 self:Send({"J1",job.id,job.profession,job.title,tostring(job.item),tostring(job.quantity),tostring(job.tab),tostring(job.reward),tostring(job.deadline),tostring(job.rev),job.kind})
 self:Send({"S1",job.id,job.status,job.assignee or "-",tostring(job.rev),tostring(job.claimedAt or 0),tostring(job.paidAt or 0)})
end
function W:Create(profession,title,item,quantity,tab,reward,days,kind)
 if not A:Allowed()or not A:Admin()or not clean(title,60)then return false end
 local known=false;for _,p in ipairs(self.professions)do if p==profession then known=true end end
 item,quantity,tab,reward,days=int(item,0,9999999),int(quantity,1,1000000),int(tab,1,8),int(reward,0,100000000),int(days,1,30)
 if not known or not item or not quantity or not tab or not reward or not days or (kind~="ITEM"and kind~="SERVICE")or kind=="ITEM"and item==0 then return false end
 local d=self:DB();local n=0;for _ in pairs(d.jobs)do n=n+1 end;if n>=200 then self:Notice("Archive completed jobs before posting more (200 maximum).");return false end
 local j={id=self:ID(),owner=me(),profession=profession,title=title,item=item,quantity=quantity,tab=tab,reward=reward,deadline=now()+days*86400,kind=kind,status="OPEN",rev=now()}
 d.jobs[j.id]=j;self:Log("JOB_CREATED",me(),j.id);self:Publish(j);self:Notice("Job posted. Claims require its posting officer online; rewards remain manual.");return j.id
end
function W:Claim(id)
 if not A:Require()then return false end
 local d=self:DB();local j=d.jobs[id]
 if not j or j.status~="OPEN"or j.deadline<now()then return false end
 if not self:Send({"C1",id})then self:Notice("Network queue full; claim was not sent. Retry shortly.");return false end
 d.pending[id]={at=now(),status="Claim requested; awaiting posting officer"};self:Notice("Claim requested. Wait for assignment before producing/depositing goods.");return true
end
function W:Submit(id)
 if not A:Require()then return false end
 local d=self:DB();local j=d.jobs[id]
 if not j or A:Key(j.assignee)~=A:Key(me())or (j.status~="CLAIMED"and j.status~="FLAGGED")then return false end
 if not self:Send({"D1",id})then self:Notice("Network queue full; delivery report was not sent. Retry shortly.");return false end
 self:Notice("Delivery reported, not proven. The posting officer reviews matching bank evidence or service completion.");return true
end
function W:Owned(j)return j and A:Admin()and A:Key(j.owner)==A:Key(me())end
function W:Review(id,approve)
 local d=self:DB();local j=d.jobs[id]
 if not self:Owned(j)or (j.status~="REVIEW"and j.status~="FLAGGED"and j.status~="CLAIMED")then return false end
 if approve and j.kind=="ITEM"then
  local deposited,withdrawn=0,0
  for _,e in ipairs(d.evidence[id]or {})do if e.kind=="deposit"then deposited=deposited+e.quantity else withdrawn=withdrawn+e.quantity end end
  if deposited-withdrawn<j.quantity then self:Notice("Not enough observed net deposits. Missing/ambiguous logs never establish delivery; inspect the bank and request clarification.");return false end
 end
 j.status=approve and "APPROVED"or "FLAGGED";j.rev=math.max(now(),j.rev+1)
 self:Log(approve and "DELIVERY_APPROVED"or "REVIEW_FLAGGED",j.assignee,id);self:Publish(j);self:Notice("Review saved. Approval does not transfer gold.");return true
end
function W:DailyLimit(who)
 local _,s=self:DB();local member=A:Member(who);return member and s.payoutRanks[member.rank:lower()]or 0
end
function W:PaidToday(who)
 local d=self:DB();local day=math.floor(now()/86400);local amount=0
 for _,p in pairs(d.paid)do if A:Key(p.who)==A:Key(who)and math.floor(p.at/86400)==day then amount=amount+p.amount end end
 return amount
end
function W:ConfirmPaid(id)
 local d=self:DB();local j=d.jobs[id]
 if not self:Owned(j)or j.status~="APPROVED"or d.paid[id]then return false end
 local limit=self:DailyLimit(j.assignee)
 if j.reward>0 and (limit==0 or self:PaidToday(j.assignee)+j.reward>limit)then self:Notice("Rank payout cap is unset or reached. Configure the exact five ranks first. Native guild-bank limits remain separate.");return false end
 d.paid[id]={who=j.assignee,amount=j.reward,at=now(),officer=me()};j.paidAt=now();j.status="PAID";j.rev=math.max(now(),j.rev+1)
 self:Log("OFFICER_CONFIRMED_PAID",j.assignee,id.." / "..j.reward.." copper");self:Publish(j);self:Notice("Manual payout recorded. No money was sent by this addon.");return true
end
function W:SetPayouts(rows,adminRanks)
 local _,s=self:DB();local own=A:Member(me());if not own or own.index~=0 or type(rows)~="table"or #rows~=5 then return false end
 local result={};local count=0
 for _,r in ipairs(rows)do local amount=int(r.amount,0,100000000);if not clean(r.rank,40)or not amount or result[r.rank:lower()]then return false end;result[r.rank:lower()]=amount;count=count+1 end
 if count~=5 then return false end
 if type(adminRanks)~="string"or #adminRanks>160 then return false end
 local admins={};for rank in adminRanks:gmatch("[^,]+")do rank=rank:match("^%s*(.-)%s*$");if not clean(rank,40)then return false end;admins[rank:lower()]=true end
 s.payoutRanks=result;s.adminRanks=admins;s.rev=math.max(now(),(s.rev or 0)+1)
 local parts={"CFG1",tostring(s.rev)};for _,r in ipairs(rows)do parts[#parts+1]=r.rank;parts[#parts+1]=tostring(r.amount)end
 -- Separate rows stay within addon packet limits.
 for rank,amount in pairs(result)do self:Send({"PAY1",rank,tostring(amount),tostring(s.rev)})end
 self:Send({"ADM1",adminRanks or "-",tostring(s.rev)})
 self:Log("PAYOUT_POLICY_SAVED",me(),"Five native rank names; no guild-bank permissions changed");return true
end
function W:Suspend(who,on,reason)
 if not A:Admin()or not clean(who,100)or not clean(reason,70)then return false end
 local member=A:Member(who);if not member or member.index==0 then return false end
 local _,s=self:DB();local old=s.bans[A:Key(who)]or {};local rev=math.max(now(),(old.rev or 0)+1)
 s.bans[A:Key(who)]={blocked=on==true,reason=reason,by=me(),rev=rev};self:Send({"BAN1",who,on and "1"or "0",tostring(rev),reason});self:Log(on and "ACCESS_SUSPENDED"or "ACCESS_RESTORED",who,reason);A:Refresh();return true
end
function W:ObserveBank(tab,rows)
 if not A:Allowed()or not A:Admin()or not self.bankOpen or not int(tab,1,8)or type(rows)~="table"then return false end
 local d=self:DB();d.bank[tab]=d.bank[tab]or {};local baseline=not self.bankBaselined or not self.bankBaselined[tab]
 local signatures=0;for _ in pairs(d.bank[tab])do signatures=signatures+1 end
 if signatures>=2000 then d.bank[tab]={};baseline=true;self:Log("BANK_BASELINE_RENEWED",me(),"Signature retention cap; no retroactive credit")end
 self.bankBaselined=self.bankBaselined or {};local counts={}
 for _,r in ipairs(rows)do
  if (r.kind=="deposit"or r.kind=="withdraw"or r.kind=="move")and clean(r.name,100)and int(r.item,1,9999999)and int(r.quantity,1,1000000)then
   local sig=table.concat({r.kind,A:Key(r.name),r.item,r.quantity,tab,r.toTab or 0},":");counts[sig]=(counts[sig]or 0)+1
   local previous=d.bank[tab][sig]or 0
   if counts[sig]>previous then
    d.bank[tab][sig]=counts[sig]
    if not baseline then
     local jobs={};for _,j in pairs(d.jobs)do jobs[#jobs+1]=j end;table.sort(jobs,function(a,b)if (a.claimedAt or 0)~=(b.claimedAt or 0)then return (a.claimedAt or 0)<(b.claimedAt or 0)end;return a.id<b.id end)
     local remaining=r.quantity
     for _,j in ipairs(jobs)do local id=j.id
     if self:Owned(j)and A:Key(j.assignee)==A:Key(r.name)and j.item==r.item and j.tab==tab and j.claimedAt and (j.status=="CLAIMED"or j.status=="REVIEW"or j.status=="APPROVED"or j.status=="PAID")then
      d.evidence[id]=d.evidence[id]or {};local allocated=r.quantity
      if r.kind=="deposit"then
       local net=0;for _,e in ipairs(d.evidence[id])do net=net+(e.kind=="deposit"and e.quantity or -e.quantity)end
       allocated=math.min(remaining,math.max(0,j.quantity-net));remaining=remaining-allocated
      end
      if allocated>0 then
      local e={kind=r.kind,quantity=allocated,at=now(),tab=tab,observer=me(),note="Observed new log content; no unique bank transaction ID"};table.insert(d.evidence[id],e)
      while #d.evidence[id]>100 do table.remove(d.evidence[id],1)end
      self:Log("BANK_"..r.kind:upper(),r.name,id.." item "..r.item.." x"..r.quantity)
      if r.kind~="deposit"then j.status="FLAGGED";j.rev=math.max(now(),j.rev+1);self:Publish(j);self:Notice("Watchdog flag: "..r.name.." withdrew/moved a matching item. Review context before suspension; no automatic ban or guilt finding.")end
      end
     end
    end end
   end
  end
 end
 self.bankBaselined[tab]=true;return true
end
function W:ScanBank(tab)
 if not self.bankOpen or not A:Admin()or not GetNumGuildBankTransactions or not GetGuildBankTransaction then self:Notice("Open an accessible guild bank log as an authorized officer. Unavailable bank APIs cannot verify delivery.");return false end
 local n=A:Read(GetNumGuildBankTransactions,tab);if not int(n,0,200)then return false end
 local rows={}
 for i=1,n do
  local ok,kind,name,link,quantity,from,to=pcall(GetGuildBankTransaction,tab,i)
  kind,name,link,quantity,from,to=A:Public(kind),A:Public(name),A:Public(link),A:Public(quantity),A:Public(from),A:Public(to)
  if ok and type(link)=="string"then rows[#rows+1]={kind=kind,name=name,item=tonumber(link:match("item:(%d+)")),quantity=quantity,fromTab=from,toTab=to}end
 end
 return self:ObserveBank(tab,rows)
end
local states={OPEN=true,CLAIMED=true,REVIEW=true,APPROVED=true,PAID=true,FLAGGED=true,CANCELLED=true}
function W:Receive(text,sender,channel)
 if channel~="GUILD"or not A:Native()or not clean(sender,100)or type(text)~="string"or #text>240 or text:find("[%c]")then return end
 local p={};for v in (text.."|"):gmatch("(.-)|")do p[#p+1]=v end
 local d,s=self:DB();local actor=A:Member(sender)
 if p[1]=="BAN1"then
  local rev=int(p[4],0,9999999999);if #p~=5 or not A:Admin(sender)or not clean(p[2],100)or (p[3]~="0"and p[3]~="1")or not rev or rev>now()+60 or not clean(p[5],70)then return end
  local target=A:Member(p[2]);if not target or target.index==0 then return end
  local old=s.bans[A:Key(p[2])];if old and old.rev>=rev then return end
  s.bans[A:Key(p[2])]={blocked=p[3]=="1",reason=p[5],by=sender,rev=rev};self:Log("ACCESS_POLICY",p[2],p[5]);A:Refresh();return
 elseif p[1]=="PAY1"or p[1]=="ADM1"then
  if not actor or actor.index~=0 then return end
  if p[1]=="PAY1"and #p==4 and clean(p[2],40)and int(p[3],0,100000000)and int(p[4],0,9999999999)then
   local rev=tonumber(p[4]);if rev<(s.rev or 0)or rev>now()+60 then return end
   if rev>(s.rev or 0)then s.payoutRanks={};s.rev=rev end;s.payoutRanks[p[2]:lower()]=tonumber(p[3])
  elseif p[1]=="ADM1"and #p==3 and #p[2]<=170 and int(p[3],0,9999999999)and tonumber(p[3])>=(s.rev or 0)and tonumber(p[3])<=now()+60 then
   s.adminRanks={};if p[2]~="-"then for rank in p[2]:gmatch("[^,]+")do s.adminRanks[rank:match("^%s*(.-)%s*$"):lower()]=true end end
  end;return
 elseif p[1]=="V1"then if self.ReceiveVerification then self:ReceiveVerification(p,sender)end;return end
 if not A:Allowed()then return end
 if p[1]=="J1"then
  if #p~=11 or not A:Admin(sender)or not p[2]:match("^[%d%-]+$")or #p[2]>50 or not clean(p[3],32)or not clean(p[4],60)or not int(p[5],0,9999999)or not int(p[6],1,1000000)or not int(p[7],1,8)or not int(p[8],0,100000000)or not int(p[9],0,9999999999)or not int(p[10],0,9999999999)or (p[11]~="ITEM"and p[11]~="SERVICE")or tonumber(p[10])>now()+60 or tonumber(p[9])>now()+31*86400 then return end
  local old=d.jobs[p[2]];if old and (A:Key(old.owner)~=A:Key(sender)or old.rev>=tonumber(p[10]))then return end
  local count=0;for _ in pairs(d.jobs)do count=count+1 end;if not old and count>=200 then return end
  d.jobs[p[2]]={id=p[2],owner=sender,profession=p[3],title=p[4],item=tonumber(p[5]),quantity=tonumber(p[6]),tab=tonumber(p[7]),reward=tonumber(p[8]),deadline=tonumber(p[9]),rev=tonumber(p[10]),kind=p[11],status=old and old.status or "OPEN",assignee=old and old.assignee,claimedAt=old and old.claimedAt,paidAt=old and old.paidAt}
 elseif p[1]=="C1"or p[1]=="D1"then
  local j=d.jobs[p[2]];if #p~=2 or not self:Owned(j)or not A:Dedicated(sender)then return end
  if p[1]=="C1"and j.status=="OPEN"and j.deadline>=now()then j.assignee=sender;j.status="CLAIMED";j.claimedAt=now();j.rev=math.max(now(),j.rev+1);self:Log("JOB_CLAIMED",sender,j.id);self:Publish(j)
  elseif p[1]=="D1"and A:Key(j.assignee)==A:Key(sender)and (j.status=="CLAIMED"or j.status=="FLAGGED")then j.status="REVIEW";j.rev=math.max(now(),j.rev+1);self:Publish(j)end
 elseif p[1]=="S1"then
  local j=d.jobs[p[2]];if #p~=7 or not j or A:Key(j.owner)~=A:Key(sender)or not A:Admin(sender)or not states[p[3]]or not int(p[5],0,9999999999)or tonumber(p[5])<j.rev or tonumber(p[5])>now()+60 or not int(p[6],0,9999999999)or not int(p[7],0,9999999999)then return end
  if p[4]~="-"and not A:Member(p[4])then return end
  j.status=p[3];j.assignee=p[4]~="-"and p[4]or nil;j.rev=tonumber(p[5]);j.claimedAt=tonumber(p[6]);j.paidAt=tonumber(p[7])
  if d.pending[j.id]then d.pending[j.id].status=j.assignee and (A:Key(j.assignee)==A:Key(me())and "Assigned to you"or "Assigned to "..j.assignee)or j.status end
  if j.status=="PAID"and not d.paid[j.id]then d.paid[j.id]={who=j.assignee,amount=j.reward,at=j.paidAt,officer=sender}end
 elseif p[1]=="Q1"and #p==1 and A:Admin()then
  if now()-(self.replied or 0)<30 then return end;self.replied=now();for _,j in pairs(d.jobs)do if self:Owned(j)and #self.queue<80 then self:Publish(j)end end
 end
 if self.Refresh then self:Refresh()end
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"CHAT_MSG_ADDON","GUILDBANKFRAME_OPENED","GUILDBANKFRAME_CLOSED","GUILDBANKLOG_UPDATE"})do pcall(frame.RegisterEvent,frame,event)end
frame:SetScript("OnEvent",function(_,event,...)
 if event=="CHAT_MSG_ADDON"then local prefix,text,channel,sender=...;if prefix==W.prefix then W:Receive(text,sender,channel)end
 elseif event=="GUILDBANKFRAME_OPENED"then W.bankOpen=true;W.bankBaselined={}
 elseif event=="GUILDBANKFRAME_CLOSED"then W.bankOpen=false
 elseif W.bankOpen and W.scanTab then W:ScanBank(W.scanTab)end
end)
local elapsed=0;frame:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
 if W.CheckPromotions then W:CheckPromotions()end
 local packet=table.remove(W.queue,1);local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
 if packet and send and A:Native()then if type(packet)=="table"then pcall(send,W.prefix,packet.text,"WHISPER",packet.target)else pcall(send,W.prefix,packet,"GUILD")end end
end)
local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix;if register then pcall(register,W.prefix)end
