local T=Tranquility;local W=T.work;local A=TranquilityAccess
local function now()return GetServerTime()end
local function me()return GetUnitName('player',true)end
local function clean(s,n)return type(s)=='string'and #s>0 and #s<=n and not s:find('[%c|]')end
local function number(s,max)local n=tonumber(s);return n and n%1==0 and n>=0 and n<=max and n end
W.payrollRoles={Guide={min=10000,max=10000},Summoner={min=50000,max=50000},Professions={min=50000,max=150000},Mercenaries={min=50000,max=50000},['Loot Goblin']={min=50000,max=250000}}
function W:Contracts()local d=self:DB();d.contracts=d.contracts or {};return d.contracts end
function W:PublishContract(c)
 self:Send({'P1',c.id,c.category,c.title,tostring(c.reward),tostring(c.deadline),c.closed and '1'or '0',tostring(c.rev)})
 for who,status in pairs(c.participants)do self:Send({'P2',c.id,who,status,tostring(c.rev)})end
end
function W:CreateContract(category,title,reward,days)
 if not A:Require()or (category~='GUIDE'and category~='MERC')or not clean(title,80)or not number(reward,100000000)or not number(days,30)or days<1 then return false end
 local contracts=self:Contracts();local count=0;for _ in pairs(contracts)do count=count+1 end;if count>=100 then return false end
 local c={id=self:ID(),owner=me(),category=category,title=title,reward=tonumber(reward),deadline=now()+days*86400,participants={},rev=now()};contracts[c.id]=c;self:PublishContract(c);self:Log('PLAYER_CONTRACT_POSTED',me(),c.id);self:Notice('Player-funded contract posted. Price is per accepted participant; no escrow or automatic gold transfer.');return c.id
end
function W:ContractAction(id,action)
 if not A:Require()then return false end;local c=self:Contracts()[id];if not c then return false end
 if action=='ACCEPT'or action=='REPORT'then return self:Send({'P3',id,action})end
 if A:Key(c.owner)~=A:Key(me())then return false end
 if action=='CLOSE'then c.closed=true;c.rev=math.max(now(),c.rev+1);self:PublishContract(c);return true end
end
function W:ReviewContract(id,who,paid)
 local c=self:Contracts()[id];if not A:Allowed()or not c or A:Key(c.owner)~=A:Key(me())or c.participants[who]~='REVIEW'and not(paid and c.participants[who]=='APPROVED')then return false end
 c.participants[who]=paid and 'PAID'or 'APPROVED';c.rev=math.max(now(),c.rev+1);self:PublishContract(c);self:Log(paid and 'CONTRACT_MANUALLY_PAID'or 'CONTRACT_APPROVED',who,id);return true
end
local receive=W.Receive
function W:Receive(text,sender,channel)
 if type(text)=="string"and text:sub(1,5)=="ROLE1"then
  if channel~="GUILD"or not A:Allowed()or not A:Admin(sender)or #text>240 then return end
  local who,role,on,rev=text:match("^ROLE1|([^|]+)|([^|]+)|([01])|(%d+)$");rev=tonumber(rev)
  if not who or not A:Dedicated(who)or not self.payrollRoles[role]or not rev or rev>now()+60 then return end
  local _,policy=self:DB();policy.jobRoles=policy.jobRoles or {};policy.roleRevisions=policy.roleRevisions or {};local key=A:Key(who)..":"..role
  if rev<=(policy.roleRevisions[key]or 0)then return end;policy.roleRevisions[key]=rev;local k=A:Key(who);policy.jobRoles[k]=policy.jobRoles[k]or {};policy.jobRoles[k][role]=on=="1"and true or nil;return
 end
 if type(text)=='string'and text:sub(1,1)=='P'and text:match('^P[123]|')then
  if channel~='GUILD'or not A:Allowed()or not A:Dedicated(sender)or #text>240 or text:find('[%c]')then return end
  local p={};for v in(text..'|'):gmatch('(.-)|')do p[#p+1]=v end;local contracts=self:Contracts();local c=contracts[p[2]]
  if p[1]=='P1'then
   if #p~=8 or not clean(p[2],50)or not p[2]:match('^[%d%-]+$')or not({GUIDE=true,MERC=true})[p[3]]or not clean(p[4],80)or not number(p[5],100000000)or not number(p[6],9999999999)or tonumber(p[6])>now()+31*86400 or not number(p[8],9999999999)or tonumber(p[8])>now()+60 or(p[7]~='0'and p[7]~='1')then return end
   if c and (A:Key(c.owner)~=A:Key(sender)or c.rev>tonumber(p[8]))then return end
   local count=0;for _ in pairs(contracts)do count=count+1 end;if not c and count>=100 then return end
   contracts[p[2]]={id=p[2],owner=sender,category=p[3],title=p[4],reward=tonumber(p[5]),deadline=tonumber(p[6]),closed=p[7]=='1',rev=tonumber(p[8]),participants=c and c.participants or {}}
  elseif p[1]=='P2'then
   if #p~=5 or not c or A:Key(c.owner)~=A:Key(sender)or not A:Dedicated(p[3])or not({ACCEPTED=true,REVIEW=true,APPROVED=true,PAID=true})[p[4]]or not number(p[5],9999999999)or tonumber(p[5])<c.rev or tonumber(p[5])>now()+60 then return end
   local count=0;for _ in pairs(c.participants)do count=count+1 end;if count>=40 and not c.participants[p[3]]then return end
   c.participants[p[3]]=p[4];c.rev=tonumber(p[5])
  elseif p[1]=='P3'then
   if #p~=3 or not c or A:Key(c.owner)~=A:Key(me())then return end
   if p[3]=='ACCEPT'and not c.closed and c.deadline>=now()and not c.participants[sender]then
    local count=0;for _ in pairs(c.participants)do count=count+1 end;if count>=(c.category=='MERC'and 40 or 1)then return end
    local _,policy=self:DB();local roles=policy.jobRoles and policy.jobRoles[A:Key(sender)]or {};local native=A:Member(sender)
    local required=c.category=='MERC'and 'Mercenaries'or 'Guide'
    if not roles[required]and not(native and native.rank==required)then return end
    c.participants[sender]='ACCEPTED';c.rev=math.max(now(),c.rev+1);self:PublishContract(c)
   elseif p[3]=='REPORT'and c.participants[sender]=='ACCEPTED'then c.participants[sender]='REVIEW';c.rev=math.max(now(),c.rev+1);self:PublishContract(c)end
  end
  if self.RefreshContracts then self:RefreshContracts()end;return
 end
 receive(self,text,sender,channel)
 if text=='Q1'and channel=='GUILD'and A:Allowed()and A:Dedicated(sender)and now()-(self.contractReplyAt or 0)>=30 then self.contractReplyAt=now();for _,c in pairs(self:Contracts())do if A:Key(c.owner)==A:Key(me())and #self.queue<75 then self:PublishContract(c)end end end
end
function W:AssignJobRole(who,role,on)
 if not A:Admin()or not A:Dedicated(who)or not self.payrollRoles[role]then return false end
 local _,p=self:DB();p.jobRoles=p.jobRoles or {};local k=A:Key(who);p.jobRoles[k]=p.jobRoles[k]or {};p.jobRoles[k][role]=on and true or nil
 p.roleRevisions=p.roleRevisions or {};local revision=math.max(now(),(p.roleRevisions[k..':'..role]or 0)+1);p.roleRevisions[k..':'..role]=revision;self:Send({'ROLE1',who,role,on and '1'or '0',tostring(revision)})
 self:Log('JOB_ROLE_POLICY',who,role..' '..(on and 'assigned'or 'removed'));return true
end
function W:SummonStats(who)
 local out={summons=0,guildies=0,day=math.floor(now()/86400)};local U=_G.Uber
 if not U or not U.db then return out end
 local seen={};for _,e in ipairs(U.db.delivery or {})do
  if(e.kind=='DELIVERY_CORROBORATED'or e.kind=='PARTY_TRAVEL_CORROBORATED')and e.spellID and (e.spellID==698 or e.spellID==7720)and math.floor((e.at or 0)/86400)==out.day and A:Key(e.source)==A:Key(who)then
   local key=(e.castID or e.order or '')..':'..A:Key(e.subject);if not seen[key]then seen[key]=true;out.summons=out.summons+1;if A:Member(e.subject)then out.guildies=out.guildies+1 end end
  end
 end;out.qualified=out.summons>1;return out
end
function W:PayrollAward(who,role,gold,reason)
 if not A:Admin()or not A:Dedicated(who)or not self.payrollRoles[role]or not clean(reason,100)then return false end
 local amount=tonumber(gold);if not amount or amount~=amount or amount%1~=0 then return false end;amount=amount*10000
 local bounds=self.payrollRoles[role];if amount<bounds.min or amount>bounds.max then return false end
 local d,p=self:DB();local native=A:Member(who);local assigned=p.jobRoles and p.jobRoles[A:Key(who)]or {}
 if not assigned[role]and not(native and native.rank==role)then return false end
 if role=='Summoner'and not self:SummonStats(who).qualified then self:Notice('Summoner needs more than one corroborated summon today on this observing client. Missing evidence requires review; rank is never automatically revoked.');return false end
 d.payroll=d.payroll or {};local key=math.floor(now()/86400)..':'..A:Key(who)..':'..role;if d.payroll[key]then return false end
 d.payroll[key]={who=who,role=role,amount=amount,at=now(),reason=reason,officer=me(),status='APPROVED_NOT_PAID'};self:Log('PAYROLL_APPROVED',who,role..' '..amount..' copper / '..reason);return true
end
function W:TelemetryExport()
 if not A:Admin()then return ''end
 local value=self.bankOpen and A:Read(GetGuildBankMoney);local L=_G.TranquilityLFG;local groups=0
 if L and L.Allowed and L:Allowed()then for _,p in pairs(L.profiles or {})do if p.ready and p.leader and now()-(p.at or 0)<=150 then groups=groups+1 end end end
 return table.concat({'TQSTATUS1',tostring(now()),type(value)=='number'and tostring(value)or '-',tostring(groups)},'|')
end
function W:LootBuybackQuote(item,quantity)
 if not A:Admin()then return nil end;item,quantity=tonumber(item),tonumber(quantity);if not item or not quantity or quantity<1 or quantity%1~=0 then return nil end
 local auction=T.auction;local snapshot=auction and auction.snapshots and auction.snapshots[item]
 if not snapshot or now()-snapshot.at>900 or snapshot.at>now()+60 then self:Notice('Observe a fresh per-unit AH price in Auctions first (within 15 minutes). No invented market price.');return nil end
 local info=C_Item and C_Item.GetItemInfo or GetItemInfo;if not info then return nil end
 local values={pcall(info,item)};local quality=A:Public(values[4]);if not values[1]or type(quality)~='number'or quality<2 or quality>4 then self:Notice('Load item data first. Buyback targets uncommon, rare and epic items.');return nil end
 local amount=math.floor(snapshot.price*quantity*2+.5);if amount>100000000 then return nil end
 self:Log('LOOT_BUYBACK_QUOTED',me(),item..' x'..quantity..' / twice observed AH asking price / '..amount..' copper');return amount
end
-- Other providers' guild activity is explicitly reported, never treated as server-certified proof.
local statsReceive=W.Receive
function W:Receive(text,sender,channel)
 if type(text)=='string'and text:match('^SUMCOUNT1|')then
  if channel~='GUILD'or not A:Allowed()or not A:Dedicated(sender)or #text>100 then return end
  local day,total,guilds=text:match('^SUMCOUNT1|(%d+)|(%d+)|(%d+)$');day,total,guilds=tonumber(day),tonumber(total),tonumber(guilds)
  if not day or day~=math.floor(now()/86400)or total>5000 or guilds>total then return end
  local d=self:DB();d.summonReports=d.summonReports or {};d.summonReports[A:Key(sender)]={day=day,summons=total,guildies=guilds,at=now(),reported=true};return
 end
 return statsReceive(self,text,sender,channel)
end
local U=_G.Uber
if U and U.Evidence then
 local evidence=U.Evidence
 function U:Evidence(kind,...)
  local event=evidence(self,kind,...)
  if kind=='DELIVERY_CORROBORATED'or kind=='PARTY_TRAVEL_CORROBORATED'then W.statsDirty=true end
  return event
 end
end
local statsFrame=CreateFrame('Frame');local elapsed=0
statsFrame:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<5 then return end;elapsed=0
 if not W.statsDirty or not A:Allowed()then return end;W.statsDirty=false;local stats=W:SummonStats(me());W:Send({'SUMCOUNT1',tostring(stats.day),tostring(stats.summons),tostring(stats.guildies)})
end)
