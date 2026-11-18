local T=Tranquility;local A=TranquilityAccess
local D={prefix='TQDEF1',records={},aggregates={},units={},pins={},ttl=20};T.defense=D
local function now()return GetServerTime()end
local function me()return GetUnitName('player',true)end
local function pub(v)return A:Public(v)end
local function number(v,lo,hi)v=pub(v);return type(v)=='number'and v==v and v>=lo and v<=hi and v end
local function integer(v,lo,hi)local n=tonumber(v);return n and number(n,lo,hi)and n%1==0 and n end
local function call(fn,...)if type(fn)~='function'then return end;local ok,a,b,c,d=pcall(fn,...);if ok then return pub(a),pub(b),pub(c),pub(d)end end
local function vector(v)if not v or not v.GetXY then return end;local x,y=call(v.GetXY,v);if number(x,-1000000,1000000)and number(y,-1000000,1000000)then return x,y end end
function D:Settings()
 TranquilityDB=TranquilityDB or {};TranquilityDB.defense=TranquilityDB.defense or {enabled=false,share=false,fallback=true,friendly=false};return TranquilityDB.defense
end
function D:Hash(s)
 local a,b=5381,97;for i=1,#s do a=(a*33+s:byte(i))%4294967296;b=(b*65599+s:byte(i))%4294967296 end
 return ('%04x%04x%04x%04x'):format(math.floor(a/65536),a%65536,math.floor(b/65536),b%65536)
end
function D:OwnPosition()
 local api=C_Map;if not api then return end
 local map=call(api.GetBestMapForUnit,'player');if not number(map,1,999999)then return end
 local pos=call(api.GetPlayerMapPosition,map,'player');local x,y=vector(pos)
 if number(x,0,1)and number(y,0,1)then return {map=map,x=x,y=y,vector=pos}end
end
function D:Calibrate(own)
 if not UnitPosition or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos or not CreateVector2D then return end
 local continent,world=call(C_Map.GetWorldPosFromMapPos,own.map,own.vector);local wx,wy=vector(world)
 local x,y,_,instance=call(UnitPosition,'player')
 if not number(continent,0,999999)or not number(wx,-1000000,1000000)or not number(wy,-1000000,1000000)or not number(x,-1000000,1000000)or not number(y,-1000000,1000000)or instance~=continent then return end
 local direct=(x-wx)^2+(y-wy)^2;local swapped=(y-wx)^2+(x-wy)^2
 if math.min(direct,swapped)>25 then return end
 return {continent=continent,swap=swapped<direct,x=x,y=y,map=own.map}
end
function D:ExactPosition(unit,calibration)
 if not calibration then return end
 local x,y,_,instance=call(UnitPosition,unit)
 if not number(x,-1000000,1000000)or not number(y,-1000000,1000000)or instance~=calibration.continent or(x-calibration.x)^2+(y-calibration.y)^2>2500^2 then return end
 local a,b=x,y;if calibration.swap then a,b=y,x end
 local v=call(CreateVector2D,a,b);if not v then return end
 local map,pos=call(C_Map.GetMapPosFromWorldPos,calibration.continent,v,calibration.map);local px,py=vector(pos)
 if map==calibration.map and number(px,0,1)and number(py,0,1)then return px,py end
end
function D:Put(id,map,x,y,faction,at,mode,source)
 local old=self.records[id];if old and (old.at>at or old.mode=='E'and mode=='P'and now()-old.at<10)then return end
 local count=0;for _ in pairs(self.records)do count=count+1 end;if not old and count>=512 then return end
 self.records[id]={id=id,map=map,x=x,y=y,faction=faction,at=at,mode=mode,source=source}
end
function D:SeedUnits()
 local plates=call(C_NamePlate and C_NamePlate.GetNamePlates);if type(plates)~='table'then return end
 local n=0;for _,plate in ipairs(plates)do if n>=80 then break end
  if not plate.IsForbidden or call(plate.IsForbidden,plate)==false then local unit=pub(plate.namePlateUnitToken);if type(unit)=='string'and unit:match('^nameplate%d+$')then self.units[unit]=true;n=n+1 end end
 end
end
function D:Scan()
 self:Prune()
 local settings=self:Settings();if not A:Allowed()or not settings.enabled then return end
 self.localSamples={};self.own=nil
 if now()-(self.seedAt or 0)>=5 then self.seedAt=now();self:SeedUnits()end
 local own=self:OwnPosition();if not own then self.diagnostic='Player map position unavailable; no sightings fabricated.';return end
 local calibration=self:Calibrate(own);local candidates={};for unit in pairs(self.units)do candidates[#candidates+1]=unit end;candidates[#candidates+1]='target';candidates[#candidates+1]='mouseover'
 local list,seen={},{};local total={H=0,A=0};local anonymous={H=0,A=0};local exact,approx,restricted=0,0,0
 for _,unit in ipairs(candidates)do
  if call(UnitIsPlayer,unit)==true and (not UnitIsVisible or call(UnitIsVisible,unit)==true)and call(UnitIsDeadOrGhost,unit)~=true then
   local faction=call(UnitFactionGroup,unit);local myFaction=call(UnitFactionGroup,'player')
   local f=faction=='Horde'and 'H'or faction=='Alliance'and 'A'
   if f and (faction~=myFaction or settings.friendly)then
    local guid=call(UnitGUID,unit);local name=call(GetUnitName,unit,true);local id
    if type(name)=='string'and #name>0 and #name<=100 and not name:find('[%c|]')then id='n'..self:Hash(A:Key(name))elseif type(guid)=='string'and #guid<=100 then id='g'..self:Hash(guid)end
    if not id and not unit:match('^nameplate%d+$')and next(self.units)then id=false end
    if id~=false and(not id or not seen[id])then
     if id then seen[id]=true end;total[f]=total[f]+1
     local x,y=self:ExactPosition(unit,calibration);local mode='E'
     if x then exact=exact+1 elseif settings.fallback then x,y,mode=own.x,own.y,'P';approx=approx+1 else restricted=restricted+1 end
     if x and id then local r={id=id,map=own.map,x=x,y=y,faction=f,at=now(),mode=mode,source=me()};self:Put(id,r.map,x,y,f,r.at,mode,me());list[#list+1]=r
     elseif x then anonymous[f]=anonymous[f]+1 end
    end
   else restricted=restricted+1 end
  end
 end
 for _,f in ipairs({'H','A'})do local key=A:Key(me())..':'..f;if anonymous[f]>0 and settings.fallback then self.aggregates[key]={map=own.map,x=own.x,y=own.y,faction=f,count=total[f],at=now(),source=me()}
  else self.aggregates[key]=nil end end
 table.sort(list,function(a,b)return a.id<b.id end);self.localSamples=list;self.own=own;self.localTotal=total;self.localAnonymous=anonymous
 self.diagnostic=('Exact public positions: %d · Scout approximations: %d · Restricted/unavailable: %d'):format(exact,approx,restricted)
end
function D:Prune()
 for id,r in pairs(self.records)do if now()-r.at>=self.ttl then self.records[id]=nil end end
 for id,r in pairs(self.aggregates)do if now()-r.at>=self.ttl then self.aggregates[id]=nil end end
end
function D:Publish()
 local s=self:Settings();if not s.enabled or not s.share or not A:Allowed()or not self.transport or not self.own then return end
 local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage;if not send then return end
 local list=self.localSamples or {};local fields={};self.cursor=self.cursor or 1
 for _=1,math.min(3,#list)do if self.cursor>#list then self.cursor=1 end;local r=list[self.cursor];self.cursor=self.cursor+1
  fields[#fields+1]=table.concat({r.id,math.floor(r.x*10000+.5),math.floor(r.y*10000+.5),r.faction,r.mode},',')
 end
 local realm=GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName();local text
 self.publishCycle=(self.publishCycle or 0)+1
 if self.publishCycle%3==0 then
  self.aggregateFaction=self.aggregateFaction=='H'and 'A'or 'H';local f=self.aggregateFaction;local r=self.aggregates[A:Key(me())..':'..f]
  text=table.concat({'A1',realm,self.own.map,now(),f,math.floor(self.own.x*10000+.5),math.floor(self.own.y*10000+.5),r and r.count or 0},'|')
 elseif #fields>0 then text=table.concat({'D1',realm,self.own.map,now(),table.concat(fields,';')},'|')end
 if text and #text<=240 then pcall(send,self.prefix,text,'GUILD')end
end
function D:Receive(text,sender,channel)
 text,sender,channel=pub(text),pub(sender),pub(channel)
 local settings=self:Settings();if not settings.enabled or not A:Allowed()or channel~='GUILD'or not A:Dedicated(sender)or type(text)~='string'or #text>240 or text:find('[%c]')then return end
 local fields={};for p in(text..'|'):gmatch('(.-)|')do fields[#fields+1]=p end
 local realm=GetNormalizedRealmName and GetNormalizedRealmName()or GetRealmName();local map,at=integer(fields[3],1,999999),integer(fields[4],0,9999999999)
 if fields[2]~=realm or not map or not at or at>now()+3 or now()-at>=self.ttl then return end
 self.rate=self.rate or {};local key=A:Key(sender);local rate=self.rate[key];if not rate or now()-rate.at>=1 then rate={at=now(),n=0};self.rate[key]=rate end;rate.n=rate.n+1;if rate.n>3 then return end
 if fields[1]=='D1'and #fields==5 then
  local parsed={};for row in fields[5]:gmatch('[^;]+')do
   local id,x,y,f,mode=row:match('^([ng][a-f0-9]+),(%d+),(%d+),([HA]),([EP])$');x,y=integer(x,0,10000),integer(y,0,10000)
   if not id or #id~=17 or not x or not y or #parsed>=3 then return end;parsed[#parsed+1]={id=id,x=x/10000,y=y/10000,f=f,mode=mode}
  end
  for _,r in ipairs(parsed)do self:Put(r.id,map,r.x,r.y,r.f,at,r.mode,sender)end
 elseif fields[1]=='A1'and #fields==8 then
  local f=fields[5];local x,y,n=integer(fields[6],0,10000),integer(fields[7],0,10000),integer(fields[8],0,100)
  if(f~='H'and f~='A')or not x or not y or not n then return end
  local id=key..':'..f;local old=self.aggregates[id];if old and old.at>at then return end
  local count=0;for _ in pairs(self.aggregates)do count=count+1 end;if not old and count>=256 then return end
  self.aggregates[id]=n>0 and {map=map,x=x/10000,y=y/10000,count=n,faction=f,at=at,source=sender}or nil
 end
end
function D:Project(r,map)
 if r.map==map then return r.x,r.y end
 local a,b,c,d=call(C_Map and C_Map.GetMapRectOnMap,r.map,map)
 if number(a,0,1)and number(b,0,1)and number(c,0,1)and number(d,0,1)and b>a and d>c then return a+r.x*(b-a),c+r.y*(d-c)end
end
function D:Cells(map)
 self:Prune();local cells={};local w,h=call(C_Map and C_Map.GetMapWorldSize,map);w=number(w,100,100000)or 5000;h=number(h,100,100000)or w
 local gx,gy=math.max(.008,math.min(.05,200/w)),math.max(.008,math.min(.05,200/h))
 local function cell(r)
  local x,y=self:Project(r,map);if not x or not number(x,0,1)or not number(y,0,1)then return end
  if not self:Settings().friendly and r.faction==(call(UnitFactionGroup,'player')=='Horde'and 'H'or 'A')then return end
  local key=r.faction..':'..math.floor(x/gx)..':'..math.floor(y/gy);local c=cells[key]
  if not c then c={x=x,y=y,faction=r.faction,n=0,g=0,count=0,at=r.at,approx=false};cells[key]=c end
  c.at=math.max(c.at,r.at);return c
 end
 for id,r in pairs(self.records)do local c=cell(r);if c then if id:sub(1,1)=='n' then c.n=c.n+1 else c.g=c.g+1 end;c.approx=c.approx or r.mode=='P'end end
 for _,r in pairs(self.aggregates)do local c=cell(r);if c then c.count=math.max(c.count,r.count);c.approx=true end end
 local list={};for _,c in pairs(cells)do c.count=math.max(c.count,c.n,c.g);c.alpha=math.min(1,math.max(0,1-(now()-c.at)/self.ttl));list[#list+1]=c end
 table.sort(list,function(a,b)return a.count>b.count end);return list,w,h
end
function D:Stop()
 self.records={};self.aggregates={};self.units={};self.localSamples={};self.own=nil;self.rate={};if self.frame then self.frame:Hide()end
 for _,pin in ipairs(self.pins)do pin:Hide()end
end
local events=CreateFrame('Frame')
for _,event in ipairs({'NAME_PLATE_UNIT_ADDED','NAME_PLATE_UNIT_REMOVED','CHAT_MSG_ADDON','PLAYER_ENTERING_WORLD'})do pcall(events.RegisterEvent,events,event)end
local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix;if register then local ok,result=pcall(register,D.prefix);D.transport=ok and result~=false end
events:SetScript('OnEvent',function(_,event,...)
 if event=='CHAT_MSG_ADDON'then local prefix,text,channel,sender=...;if prefix==D.prefix then D:Receive(text,sender,channel)end;return end
 if not A:Allowed()or not D:Settings().enabled then return end
 local unit=pub(...);if event=='NAME_PLATE_UNIT_ADDED'and type(unit)=='string'and unit:match('^nameplate%d+$')then local n=0;for _ in pairs(D.units)do n=n+1 end;if n<80 then D.units[unit]=true end
 elseif event=='NAME_PLATE_UNIT_REMOVED'and type(unit)=='string'then D.units[unit]=nil
 elseif event=='PLAYER_ENTERING_WORLD'then D:Stop()end
end)
local elapsed=0;events:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
 if not A:Allowed()or not D:Settings().enabled then if next(D.records)or next(D.aggregates)then D:Stop()end;return end
 D:Scan();D:Publish();if D.Render then D:Render()end;if D.Refresh then D:Refresh()end
end)
