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
-- Retired gateway packets must never prompt for a code or change guild ranks.
local receive=W.Receive
function W:Receive(text,sender,channel)
 if type(text)=='string'and (text:match('^VAULT1|')or text:match('^VPROOF1|')or text:match('^VOPEN1|')or text:match('^JCODE1|'))then return end
 return receive(self,text,sender,channel)
end