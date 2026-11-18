local L=TranquilityLFG
function L:Armor(p)
 if p.class=="MAGE"or p.class=="WARLOCK"or p.class=="PRIEST"then return "CLOTH"end
 if p.class=="WARRIOR"or p.class=="PALADIN"then return p.level>=40 and "PLATE"or "MAIL"end
 if p.class=="HUNTER"or p.class=="SHAMAN"then return p.level>=40 and "MAIL"or "LEATHER"end
 if p.class=="ROGUE"or p.class=="DRUID"then return "LEATHER"end
 return "UNKNOWN"
end
function L:LootIntent(p,role)
 if p.loot and p.loot~="AUTO"then return p.loot end
 if role=="HEALER"then return "HEAL"end
 if role=="TANK"then return "DEFENSE"end
 if p.class=="MAGE"or p.class=="WARLOCK"or p.class=="PRIEST"then return "SPELL"end
 if p.class=="PALADIN"or p.class=="WARRIOR"then return "STRENGTH"end
 return "AGILITY"
end
function L:LootConflict(a,ar,b,br)
 local aa,ba=self:Armor(a),self:Armor(b);local ai,bi=self:LootIntent(a,ar),self:LootIntent(b,br)
 local overlap=0
 if aa==ba then overlap=ai==bi and 10 or ((ai=="HEAL"and bi=="SPELL")or (ai=="SPELL"and bi=="HEAL"))and 4 or 1 end
 if ai==bi then overlap=overlap+2 end -- weapons/jewelry can overlap across armor classes
 local wants={};for id in pairs(a.wants or {})do if b.wants and b.wants[id]then wants[#wants+1]=id;overlap=overlap+20 end end
 return overlap,aa==ba,wants
end
function L:PartyProfiles()
 local list={self:OwnProfile()};local seen={[self:Key(self:Me())]=true}
 local total=self:Read(GetNumGroupMembers)or 0;local raid=self:Read(IsInRaid)==true
 for i=1,math.min(total,40)do
  local name=self:Read(GetUnitName,(raid and "raid"or "party")..i,true)
  if name and not seen[self:Key(name)]then
   local p=self.profiles[self:Key(name)]
   if not p or self:Clock()-p.at>150 then return nil,"A current party member has no fresh role/loot profile: "..name end
   list[#list+1]=p;seen[self:Key(name)]=true
  end
 end
 return list
end
function L:LootWarning(candidate,role)
 local party,why=self:PartyProfiles();if not party then return why end
 local sameArmor,compete,items=0,0,{}
 for _,p in ipairs(party)do local score,same,wants=self:LootConflict(p,p.assignedRole or p.roles:match("^[^,]+"),candidate,role or candidate.roles:match("^[^,]+"));if same then sameArmor=sameArmor+1 end;if score>=4 then compete=compete+1 end;for _,id in ipairs(wants)do items[#items+1]=tostring(id)end end
 if sameArmor>0 or compete>0 then return "Loot advisory: "..sameArmor.." current member(s) share "..self:Armor(candidate).." armor; "..compete.." may share stat/role or item needs. Different roles reduce overlap. Invite remains your choice."..(#items>0 and " Shared wishlist: "..table.concat(items,",")or "")end
end
function L:DungeonLoot(activity)
 local out={};local T=_G.Tranquility
 if T and T.db and T.db.loot and T.db.loot.items then
  for id,item in pairs(T.db.loot.items)do
   for _,source in pairs(item.sources or {})do
    if type(source)=="table"and type(source.instance)=="string"and source.instance:lower()==activity:lower()then out[#out+1]={id=id,name=item.name or tostring(id),source="Observed journal; availability not guaranteed"};break end
   end
  end
 end
 table.sort(out,function(a,b)return tonumber(a.id)<tonumber(b.id)end);return out
end
function L:Eligible(p,leader)
 if not p or not p.available or not p.ready or p.mode~=self.mode or self:Clock()-p.at>120 or p.level<1 or not self.rolesByClass[p.class]then return false end
 if p.level<self.options.minLevel and not (self.options.carry and self:Key(p.name)==self:Key(leader.name)and p.level>=self.options.entryLevel)then return false end
 if p.level>self.options.maxLevel then return false end
 if self.mode~="DUNGEON"then
  if p.ranked~=self.options.ranked or p.bracket~=(self.mode=="ARENA"and tonumber((self.activities[1]or "2v2"):match("^(%d)v%d$"))or self.options.bracket)then return false end
  if self.options.ranked and (self.options.minRating or 0)>0 and p.rating<(self.options.minRating or 0)then return false end
 end
 return true
end
function L:BuildPlan()
 self:Settings();local leader=self:OwnProfile()
 if not self.rolesByClass[leader.class]then return nil,"Your native class profile is unavailable. Refresh before forming."end
 if not self.active or self.active.mode~=self.mode or not leader.leader or not self:CanLead()then return nil,"Queue this page with the green leader flag, and be solo or the actual party leader."end
 if self.mode~="DUNGEON"and (self.active.ranked~=self.options.ranked or self.active.bracket~=tonumber(self.size and self.size:GetText()or self.active.size))then return nil,"Queue again to apply the selected casual/ranked category and team bracket."end
 if self.options.carry and (self.mode~="DUNGEON"or leader.level>=self.options.minLevel or leader.level<self.options.entryLevel)then return nil,"Only the lower-level leader can be the carry."end
 local party,why=self:PartyProfiles();if not party then return nil,why end
 local size=self.active.size;if #party>size then return nil,"Current group is larger than this listing."end
 local candidates,fixed={},{}
 for _,p in ipairs(party)do fixed[self:Key(p.name)]=true end
 for _,e in ipairs(self:List())do
  local p=self.profiles[self:Key(e.name)]
  local match=false;for a in e.activity:gmatch("[^;]+")do for b in self.active.activity:gmatch("[^;]+")do if a:lower()==b:lower()then match=true end end end
  if match and p and not fixed[self:Key(p.name)]and self:Eligible(p,leader)and not (self.inviteCooldown and self.inviteCooldown[self:Key(p.name)]and self.inviteCooldown[self:Key(p.name)]>self:Clock())then candidates[#candidates+1]=p end
 end
 table.sort(candidates,function(a,b)return a.name<b.name end)
 if #candidates>60 then
  local counts,shortlist,selected={},{},{}
  for _,p in ipairs(candidates)do local k=p.class..":"..p.roles;counts[k]=(counts[k]or 0)+1;if counts[k]<=6 and #shortlist<60 then shortlist[#shortlist+1]=p;selected[self:Key(p.name)]=true end end
  for _,p in ipairs(candidates)do if #shortlist<60 and not selected[self:Key(p.name)]then shortlist[#shortlist+1]=p end end
  candidates=shortlist
 end
 -- Bounded beam search assigns flexible roles while minimizing shared loot, not a fixed class recipe.
 local tanks=self.mode=="DUNGEON"and 1 or self.options.tanks or 0
 local heals=self.mode=="DUNGEON"and 1 or self.options.healers or self.mode=="ARENA"and 1 or math.max(1,math.floor(size/5))
 if tanks+heals>size then return nil,"Tank/healer targets exceed team size."end
 local need={TANK=tanks,HEALER=heals,DPS=size-tanks-heals}
 local beam={{members={},used={},counts={TANK=0,HEALER=0,DPS=0},score=0,key=""}}
 for slot=1,size do
  local choices=slot<=#party and {party[slot]}or candidates;local nextBeam={}
  for _,state in ipairs(beam)do
   for _,p in ipairs(choices)do if not state.used[self:Key(p.name)]then
    if slot>#party or p.level>0 and p.level<=self.options.maxLevel and (p.level>=self.options.minLevel or self.options.carry and self:Key(p.name)==self:Key(leader.name)and p.level>=self.options.entryLevel)then
     for _,role in ipairs({"TANK","HEALER","DPS"})do if self:HasRole(p,role)and state.counts[role]<need[role]then
      local s={members={},used={},counts={},score=state.score,key=state.key..p.name..role}
      for k,v in pairs(state.used)do s.used[k]=v end;for k,v in pairs(state.counts)do s.counts[k]=v end
      for _,m in ipairs(state.members)do s.members[#s.members+1]=m;if self.options.diversity then s.score=s.score+self:LootConflict(m.profile,m.role,p,role)end end
      s.members[#s.members+1]={profile=p,role=role,existing=fixed[self:Key(p.name)]==true};s.used[self:Key(p.name)]=true;s.counts[role]=s.counts[role]+1
      nextBeam[#nextBeam+1]=s
     end end
    end
   end end
  end
  table.sort(nextBeam,function(a,b)if a.score~=b.score then return a.score<b.score end;return a.key<b.key end)
  local width=size<=5 and 48 or size<=10 and 16 or size<=15 and 8 or 1
  beam={};for i=1,math.min(width,#nextBeam)do beam[i]=nextBeam[i]end
  if #beam==0 then return nil,"Not enough fresh READY players with the required roles, activity and level/rank filters. Directory availability alone is not queue readiness."end
 end
 local best=beam[1];best.at=self:Clock();best.mode=self.mode;best.activity=self.active.activity;best.size=size;best.leader=self:Key(self:Me());return best
end
local invite=L.Invite
function L:Invite(who,confirmed)
 local p=self.profiles[self:Key(who)];self:Settings()
 if not self:CanLead()or not self.db.leader then self:Notify("Volunteer with the green leader flag and be solo or the actual party leader to invite.");return false end
 if p and (not p.available or self:Clock()-p.at>150)then return false end
 if p and p.available and self:Clock()-p.at<=150 and not self.entries[self:Key(who)]then
  -- Available directory members may receive a deliberate invite without falsely queueing them.
  local api=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
  local warning=self:LootWarning(p)
  if warning and not confirmed then self.pendingInvite=who;self:Notify(warning.." Click Confirm invite to proceed.");return false end
  if api then local ok,result=pcall(api,who);if ok and result~=false then self:Notify("Invite attempted; the available member has not promised readiness.");return true end end
  self:Notify("Invite unavailable; use the native invite control.");return false
 end
 if p and not confirmed then local warning=self:LootWarning(p);if warning then self.pendingInvite=who;self:Notify(warning.." Click Confirm invite to proceed.");return false end end
 return invite(self,who)
end
function L:StartForming()
 local plan,why=self:BuildPlan();if not plan then self:Notify(why);return false end
 self.plan=plan;self.options.auto=true;self.formAt=0;self.pendingMember=nil;self:Notify("Leader-controlled formation started. One invitation at a time; acceptance is never assumed.");return true
end
function L:StopForming(reason)self:Settings();self.options.auto=false;self.pendingMember=nil;self:Notify(reason or "Automatic formation paused.")end
function L:FormTick()
 if not self.options.auto then return end
 if not self:Allowed()or not self:CanLead()or not self.db.leader or not self.active then self:StopForming("Formation stopped: leadership, guild membership or ready listing changed.");return end
 if self:Read(InCombatLockdown)==true then return end
 local party=self:PartyProfiles();if not party then self:StopForming("Refresh the profiles of current party members before continuing.");return end
 local inGroup={};for _,p in ipairs(party)do inGroup[self:Key(p.name)]=true end
 self.inviteCooldown=self.inviteCooldown or {}
 if self.pendingMember then
  if inGroup[self:Key(self.pendingMember)]then self.pendingMember=nil
  elseif self:Clock()-(self.inviteAt or 0)<25 then return
  else self.inviteCooldown[self:Key(self.pendingMember)]=self:Clock()+300;self.pendingMember=nil end
 end
 if #party>=self.active.size then self:StopForming("Group filled. Verify the group, loot rules and native activity queue together.");return end
 if self:Clock()-(self.formAt or 0)<3 then return end;self.formAt=self:Clock()
 local plan,why=self:BuildPlan();if not plan then self:StopForming(why);return end;self.plan=plan
 for _,m in ipairs(plan.members)do if not inGroup[self:Key(m.profile.name)]then
  local ok=self:Invite(m.profile.name,true)
  if not ok then self:StopForming("Native invitation failed or was blocked. Review permissions; no automatic retry.");return end
  self.pendingMember=m.profile.name;self.inviteAt=self:Clock();return
 end end
end
