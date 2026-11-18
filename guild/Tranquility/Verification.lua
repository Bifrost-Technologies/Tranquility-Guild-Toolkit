local T=_G.Tranquility;local W=T.work;local A=_G.TranquilityAccess
local function now()return GetServerTime()end
local function me()return GetUnitName("player",true)end
function W:ImportVerification(text)
 if not A:Admin()or type(text)~="string"or #text>16000 then return false end
 local d=self:DB();local count=0
 for line in text:gmatch("[^\r\n]+")do
  local code,name,discord,expires=line:match("^VREQ|([a-f0-9]+)|([^|]+)|(%d+)|(%d+)$")
  expires=tonumber(expires)
  if code and #code==32 and #name<=100 and #discord<=24 and expires and expires>now()and expires<=now()+1200 then
   local member=A:Member(name)
   local total=0;for _ in pairs(d.verification)do total=total+1 end
   if member and (d.verification[code]or total<100)then
    local old=d.verification[code]
    if not old then d.verification[code]={code=code,name=member.name,guid=member.guid,discord=discord,expires=expires,status="Awaiting native character proof"};count=count+1 end
   end
  end
 end
 self:Log("VERIFICATION_REQUESTS_IMPORTED",me(),tostring(count));self:Notice("Imported "..count.." bot challenges. Characters submit /tranq verify <code>; promotion still needs an officer click.");return count
end
function W:SubmitVerification(code)
 if not A:Native()or type(code)~="string"or not code:match("^[a-f0-9]+$")or #code~=32 or now()-(self.verifySent or 0)<30 then return false end
 self.verifySent=now();return self:Send({"V1",code})
end
function W:ReceiveVerification(p,sender)
 if #p~=2 or #p[2]~=32 or not p[2]:match("^[a-f0-9]+$")or not A:Admin()then return end
 local d=self:DB();local request=d.verification[p[2]];local member=A:Member(sender)
 if not request or not member or request.expires<now()or request.status~="Awaiting native character proof"or A:Key(request.name)~=A:Key(sender)or request.guid and request.guid~=member.guid then return end
 request.status="Native character confirmed; review promotion";request.claimedAt=now();request.claimedBy=member.name
 self:Log("CHARACTER_PROOF_RECEIVED",sender,"Discord member link pending officer review");self:Notice("Character proof received for "..sender..". Review its Dedicated Member promotion.")
end
function W:PromoteVerified(code)
 local d=self:DB();local request=d.verification[code]
 if not A:Admin()or not request or request.expires<now()or request.status~="Native character confirmed; review promotion"then return false end
 A:RefreshRoster();local member=A:Member(request.name);local rankOrder=A.threshold and A.threshold+1
 if not member or not member.guid or not rankOrder then self:Notice("Native guild roster GUID or Dedicated Member rank is unavailable. Refresh the guild roster; no promotion attempted.");return false end
 local api=C_GuildInfo
 if not api or not api.SetGuildRankOrder then self:Notice("Use the native guild roster to assign Dedicated Member, then refresh. The addon will observe the actual rank.");request.status="Awaiting native rank confirmation";return true end
 if api.IsGuildRankAssignmentAllowed then local allowed=A:Read(api.IsGuildRankAssignmentAllowed,member.guid,rankOrder);if allowed~=true then self:Notice("Native guild permissions do not permit this rank assignment.");return false end end
 local ok,result=pcall(api.SetGuildRankOrder,member.guid,rankOrder)
 if not ok or result==false then self:Notice("Native promotion was blocked. Use normal guild controls; no bypass or automatic retry.");return false end
 request.status="Awaiting native rank confirmation";self:Log("PROMOTION_REQUESTED",member.name,"Dedicated Member; repairs follow native rank settings");return true
end
function W:CheckPromotions()
 if not A:Admin()then return end
 local d=self:DB()
 for code,r in pairs(d.verification)do
  if r.status=="Awaiting native rank confirmation"then
   local member=A:Member(r.name)
   if member and A:Dedicated(member.name)and (not r.guid or r.guid==member.guid)then
    r.status="Guild rank confirmed";r.confirmedAt=GetServerTime();self:Log("DEDICATED_RANK_CONFIRMED",member.name,"Linked Discord account; no bank permissions rewritten")
   end
  elseif r.expires<now()and r.status~="Guild rank confirmed"then d.verification[code]=nil end
 end
end
function W:VerificationExport()
 if not A:Admin()then return ""end
 self:CheckPromotions();local d=self:DB();local lines={}
 for code,r in pairs(d.verification)do if r.status=="Guild rank confirmed"and r.discord~="0"then lines[#lines+1]=table.concat({"VACK",code,r.name,r.discord,tostring(r.confirmedAt)},"|")end end
 return table.concat(lines,"\n")
end
function W:IssueVault(code)
 if not A:Allowed()or not A:Admin()then return false end;local d=self:DB();local r=d.verification[code]
 if not r or r.expires<now()or r.status=='Guild rank confirmed'then return false end
 local member=A:Member(r.name);if not member or not member.guid then self:Notice('Refresh the native roster before issuing a character-bound vault code.');return false end
 r.guid=member.guid;r.pin=tostring(math.random(1000,9999));r.pinAttempts=0
 if not self:SendWhisper({'VAULT1',code,r.pin,tostring(r.expires)},member.name)then return false end
 local send=SendChatMessage or C_ChatInfo and C_ChatInfo.SendChatMessage
 if send then pcall(send,'Tranquility vault code: '..r.pin..'. Double-click the sealed vault door and enter this four-digit code. Expires in ten minutes or less. Never share it.','WHISPER',nil,member.name)end
 self:Log('VAULT_CODE_ISSUED',member.name,'Character-bound expiring challenge; code omitted from audit');self:Notice('Vault code sent in-game to '..member.name..'.');return true
end
local receiveVault=W.Receive
function W:Receive(text,sender,channel)
 if type(text)=='string'and(text:match('^VAULT1|')or text:match('^VPROOF1|')or text:match('^VOPEN1|'))then
  if channel~='WHISPER'or not A:Native()or type(sender)~='string'or #sender>100 or #text>240 or text:find('[%c]')then return end
  local p={};for v in(text..'|'):gmatch('(.-)|')do p[#p+1]=v end
  local d,s=self:DB()
  if p[1]=='VAULT1'then
   local expires=tonumber(p[4]);if #p~=4 or not A:Admin(sender)or #p[2]~=32 or not p[2]:match('^[a-f0-9]+$')or not p[3]:match('^%d%d%d%d$')or not expires or expires%1~=0 or expires<=now()or expires>now()+1200 then return end
   s.pendingVault={challenge=p[2],pin=p[3],officer=sender,expires=expires};if s.vaultClosed then return end;A:ShowVault();A.vaultStatus:SetText('Your officer sent a four-digit vault code in-game. Reveal the inscription and enter it.');return
  elseif p[1]=='VPROOF1'then
   if #p~=3 or not A:Allowed()or not A:Admin()then return end;local r=d.verification[p[2]];local member=A:Member(sender)
   if not r or not member or r.expires<now()or r.status~='Awaiting native character proof'or A:Key(r.name)~=A:Key(sender)or r.guid~=member.guid or not r.pin or(r.pinAttempts or 0)>=5 then return end
   r.pinAttempts=(r.pinAttempts or 0)+1;if r.pin~=p[3]then return end
   self:ReceiveVerification({'V1',p[2]},sender);r.vaultProof=true
   if A:Dedicated(sender)then r.status='Awaiting native rank confirmation';self:CheckPromotions()else self:Notice(sender..' proved their vault code. Review and click Request native promotion.');if self.Refresh then self:Refresh()end end;return
  elseif p[1]=='VOPEN1'then
   local pending=s.pendingVault;if #p~=2 or not pending or pending.challenge~=p[2]or pending.expires<now()or (not pending.shared and A:Key(sender)~=A:Key(pending.officer))or not A:Admin(sender)then return end
   if not A:RankAllowed()then s.vaultApproval={officer=sender,challenge=p[2],expires=pending.expires};return end
   s.pendingVault=nil;s.vaultApproval=nil;A:UnlockVault(sender);return
  end
 end
 return receiveVault(self,text,sender,channel)
end
local checkPromotions=W.CheckPromotions
function W:CheckPromotions()
 local d,s=self:DB();local approval=s.vaultApproval
 if approval and approval.expires>=now()and A:RankAllowed()then s.pendingVault=nil;s.vaultApproval=nil;A:UnlockVault(approval.officer)end
 checkPromotions(self)
 if not A:Admin()then return end
 for code,r in pairs(d.verification)do
  if r.status=='Guild rank confirmed'and r.vaultProof and not r.vaultSent then r.vaultSent=self:SendWhisper({'VOPEN1',code},r.name)end
 end
end
-- Transitional Discord initiation code: membership is authoritative; this shared code is not a secret.
local receiveInitiation=W.Receive
function W:Receive(text,sender,channel)
 if type(text)=='string'and text:match('^JCODE1|')then
  if channel~='GUILD'or not A:Allowed()or not A:Admin()or type(sender)~='string'or #sender>100 or #text>100 then return end
  local challenge,pin=text:match('^JCODE1|([a-f0-9]+)|(%d%d%d%d)$')
  A:RefreshRoster();local member=A:Member(sender);local d,s=self:DB();local ban=s.bans[A:Key(sender)]
  if not challenge or #challenge~=32 or pin~=A.joinCode or not member or not member.guid or ban and ban.blocked then return end
  d.initiationTimes=d.initiationTimes or {};local key=A:Key(sender)
  if now()-(d.initiationTimes[key]or 0)<10 then return end;d.initiationTimes[key]=now()
  local count=0;for _ in pairs(d.verification)do count=count+1 end;if count>=100 and not d.verification[challenge]then return end
  d.verification[challenge]={code=challenge,name=member.name,guid=member.guid,discord='0',expires=now()+600,status='Native character confirmed; review promotion',vaultProof=true,shared=true}
  self:Log('DISCORD_INITIATION_CODE_ACCEPTED',member.name,'Guild membership checked; native Dedicated Member promotion requested')
  if A:Dedicated(sender)then d.verification[challenge].status='Awaiting native rank confirmation';self:CheckPromotions()else self:PromoteVerified(challenge)end
  return
 end
 return receiveInitiation(self,text,sender,channel)
end
