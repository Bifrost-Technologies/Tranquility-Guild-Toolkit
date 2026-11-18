local n=0;local function check(v,s)assert(v,s);n=n+1 end
local w={};setmetatable(w,{__index=function()return function()end end});function w:SetScript(k,v)self[k]=v end;function w:CreateFontString()return self end
CreateFrame=function()return setmetatable({},{__index=w})end;UIParent={};UISpecialFrames={};SlashCmdList={}
local clock=100000;GetServerTime=function()return clock end;GetUnitName=function()return 'Officer-Realm'end;GetNormalizedRealmName=function()return 'Realm'end
local rank,index='Guild Master',0;GetGuildInfo=function()return 'Tranquility',rank,index end
local ranks={'Guild Master','Officer','Dedicated Member','Member','Recruit'}
GuildControlGetNumRanks=function()return #ranks end;GuildControlGetRankName=function(i)return ranks[i]end
local memberRank='Dedicated Member';local memberIndex=2
GetNumGuildMembers=function()return 2 end;GetGuildRosterInfo=function(i)if i==1 then return 'Officer-Realm','Guild Master',0,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,'guid-officer' end;return 'Worker-Realm',memberRank,memberIndex,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,'guid-worker'end
UnitGUID=function()return 'guid-officer'end
Tranquility={modules={}};TranquilityDB={security={vaultUnlocked={character="officer-realm",guid="guid-officer",confirmed=true}}};assert(loadfile('guild/Tranquility/Access.lua'))();local a=TranquilityAccess;a:RefreshRoster()
check(a:Allowed(),'GM allowed');rank,index='Member',3;check(not a:Allowed(),'Member denied');rank,index='Recruit',4;check(not a:Allowed(),'Lower rank denied');rank,index='Dedicated Member',2;check(a:Allowed(),'Dedicated allowed');rank,index='Officer',1;check(a:Allowed(),'Higher rank allowed');rank,index='Guild Master',0
check(a:Member('Worker-Realm').guid=='guid-worker','Native GUID parsed correctly')
for _,f in ipairs({'WorkBoard','Verification','WorkUI','Contracts','ContractUI'})do assert(loadfile('guild/Tranquility/'..f..'.lua'))()end
local b=Tranquility.work;local id=b:Create('Fishing','Fish for bank',123,10,1,10000,7,'ITEM');check(id,'Officer posts job')
b:Receive('C1|'..id,'Worker-Realm','WHISPER');check(not b:DB().jobs[id].assignee,'Whisper cannot claim');b:Receive('C1|'..id,'Worker-Realm','GUILD');check(b:DB().jobs[id].assignee=='Worker-Realm','Native guild sender claims')
b.bankOpen=true;b:ObserveBank(1,{});local rows={{kind='deposit',name='Worker-Realm',item=123,quantity=10}};b:ObserveBank(1,rows);b:ObserveBank(1,rows);check(#b:DB().evidence[id]==1,'Repeated log not double credited');check(b:Review(id,true),'Observed full deposit approves');check(not b:ConfirmPaid(id),'Unconfigured payout fails closed')
local _,policy=b:DB();policy.payoutRanks['dedicated member']=10000;check(b:ConfirmPaid(id),'Manual confirmation within cap');check(not b:ConfirmPaid(id),'Cannot pay same order twice')
rows[#rows+1]={kind='withdraw',name='Worker-Realm',item=123,quantity=10};b:ObserveBank(1,rows);check(b:DB().jobs[id].status=='FLAGGED','Post-payout withdrawal flagged');check(not policy.bans[a:Key('Worker-Realm')],'No automatic guilt or ban')
local code=string.rep('a',32);memberRank,memberIndex='Member',3;a:RefreshRoster();check(b:ImportVerification('VREQ|'..code..'|Worker-Realm|123456789|100600')==1,'Bound expiring request imported');b:ReceiveVerification({'V1',code},'Officer-Realm');check(b:DB().verification[code].status=='Awaiting native character proof','Other character cannot claim code');b:ReceiveVerification({'V1',code},'Worker-Realm');check(b:DB().verification[code].status=='Native character confirmed; review promotion','Correct native sender proves character')
C_GuildInfo=nil;check(b:PromoteVerified(code),'Native UI fallback pending');b:CheckPromotions();check(b:VerificationExport()=='','No rank confirmation before actual promotion');memberRank,memberIndex='Dedicated Member',2;a:RefreshRoster();b:CheckPromotions();check(b:VerificationExport():match('^VACK|'),'Actual native rank yields confirmation')
memberRank,memberIndex='Dedicated Member',2;a:RefreshRoster()
check(b:AssignJobRole('Worker-Realm','Mercenaries',true),'Officer assigns mercenary role')
local contract=b:CreateContract('MERC','Guard the summoning circle',50000,7);check(contract,'Dedicated player can post contract')
b:Receive('P3|'..contract..'|ACCEPT','Worker-Realm','GUILD');check(b:Contracts()[contract].participants['Worker-Realm']=='ACCEPTED','Assigned mercenary accepts contract')
b:Receive('P3|'..contract..'|REPORT','Worker-Realm','GUILD');check(b:ReviewContract(contract,'Worker-Realm',false),'Requester reviews service');check(b:ReviewContract(contract,'Worker-Realm',true),'Manual payment recorded');check(not b:ReviewContract(contract,'Worker-Realm',true),'Contract cannot be paid twice')
check(b:PayrollAward('Worker-Realm','Mercenaries',5,'Guarded summoning circle'),'Role daily award approved');check(not b:PayrollAward('Worker-Realm','Mercenaries',5,'Duplicate'),'Daily role award cannot duplicate');check(not b:PayrollAward('Worker-Realm','Mercenaries',10,'Too much'),'Payroll bounds enforced')
b:Receive('SUMCOUNT1|0|999|1','Worker-Realm','GUILD');check(not b:DB().summonReports,'Stale summon reports rejected')
b:Receive('SUMCOUNT1|1|1|2','Worker-Realm','GUILD');check(not b:DB().summonReports,'Guild count cannot exceed total')
print('PASS: '..n..' security and guild work assertions')
