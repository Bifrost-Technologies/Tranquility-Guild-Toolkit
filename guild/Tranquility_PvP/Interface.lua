local T=Tranquility;local D=T.defense;local A=TranquilityAccess
local function now()return GetServerTime()end
function D:Color(faction,count)
 local hostile=faction~=(A:Read(UnitFactionGroup,'player')=='Horde'and 'H'or 'A')
 if not hostile then if count>=15 then return .1,.85,.35 elseif count>=5 then return .1,.7,.65 else return .2,.55,1 end end
 if count>=25 then return .65,.04,.08 elseif count>=15 then return .95,.12,.08 elseif count>=5 then return 1,.45,.05 else return 1,.85,.12 end
end
function D:Render()
 local map=WorldMapFrame
 if not A:Allowed()or not self:Settings().enabled or not map or not map.IsShown or not map:IsShown()or not map.GetCanvas or map.IsForbidden and map:IsForbidden()then for _,pin in ipairs(self.pins)do pin:Hide()end;return end
 local canvas=map:GetCanvas();if not canvas or canvas.IsForbidden and canvas:IsForbidden()then return end
 local id=map:GetMapID();local cells,w,h=self:Cells(id);local width,height=canvas:GetWidth(),canvas:GetHeight()
 if type(width)~='number'or type(height)~='number'or width<=0 or height<=0 then return end
 for i=1,math.min(50,#cells)do
  local c=cells[i];local pin=self.pins[i]
  if not pin then
   pin=CreateFrame('Frame',nil,canvas);self.pins[i]=pin;pin:EnableMouse(true);if pin.SetMouseClickEnabled then pin:SetMouseClickEnabled(false)end
   pin.fill=pin:CreateTexture(nil,'BACKGROUND');pin.fill:SetAllPoints();pin.fill:SetColorTexture(1,1,1,1)
   if pin.CreateMaskTexture and pin.fill.AddMaskTexture then local mask=pin:CreateMaskTexture(nil,'BACKGROUND');mask:SetAllPoints();mask:SetTexture('Interface\\CHARACTERFRAME\\TempPortraitAlphaMask');pin.fill:AddMaskTexture(mask)end
   pin.text=pin:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');pin.text:SetPoint('CENTER');pin.text:SetTextColor(1,1,1)
   pin:SetScript('OnEnter',function(frame)
    if not GameTooltip or not frame.cell then return end;local r=frame.cell;GameTooltip:SetOwner(frame,'ANCHOR_RIGHT');GameTooltip:SetText((r.faction=='H'and 'Horde'or 'Alliance')..': '..r.count..(r.approx and ' seen near scouts (approximate)'or ' recently seen at public coordinates'))
    GameTooltip:AddLine((now()-r.at)..'s old · fades completely in 20s',1,1,1);GameTooltip:AddLine('Overlapping scout totals use a conservative maximum. Different layers may overlap; no server-wide radar.',.75,.8,.9,true);GameTooltip:Show()
   end);pin:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  end
  pin:SetParent(canvas);pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',c.x*width,-c.y*height)
  local radius=c.approx and 140 or 90;pin:SetSize(math.max(22,math.min(180,2*radius/w*width)),math.max(22,math.min(180,2*radius/h*height)))
  local r,g,b=self:Color(c.faction,c.count);pin.fill:SetVertexColor(r,g,b,.36);pin:SetAlpha(c.alpha);pin.text:SetText((c.approx and '~'or '')..c.count);pin.cell=c;pin:Show()
 end
 for i=math.min(50,#cells)+1,#self.pins do self.pins[i]:Hide()end
end
function D:Refresh()
 if not self.frame or not self.frame:IsShown()then return end
 if not A:Allowed()then self:Stop();return end
 local settings=self:Settings();local own=self:OwnPosition();local cells=own and self:Cells(own.map)or {};local lines={}
 for i=1,math.min(8,#cells)do local c=cells[i];lines[#lines+1]=(c.faction=='H'and 'Horde'or 'Alliance')..' · '..c.count..(c.approx and ' approximate'or ' observed')..' · '..('%.1f, %.1f'):format(c.x*100,c.y*100)..' · '..(now()-c.at)..'s old'end
 self.summary:SetText(#lines>0 and table.concat(lines,'\n')or 'No recent sightings on your map. This does not establish that the area is safe.')
 self.diagnostics:SetText((settings.enabled and 'SCOUTING ACTIVE'or 'SCOUTING OFF')..' · '..(self.transport and 'Guild transport available'or 'Guild transport unavailable')..'\n'..(self.diagnostic or 'Enable scouting to test public APIs on this client.')..'\nExact coordinates first · Reports expire in 20 seconds · Layer is not independently verified')
 for key,box in pairs(self.options or {})do box:SetChecked(settings[key]==true)end
 if self.alertDetail then local danger=self.Danger and self:Danger()or {};local rows={};for i=1,math.min(6,#danger)do local item=danger[i];rows[#rows+1]=item.cell.count..' observed · about '..math.floor(item.distance)..' yards · '..(now()-item.cell.at)..'s old'..(item.cell.approx and ' · approximate'or '')end;self.alertDetail:SetText(#rows>0 and table.concat(rows,'\n')or 'No fresh concentration meets your current distance/count threshold. Guild reports may come from another layer.')end
end
function D:Page(name)
 self.page=name
 for title,view in pairs(self.pages)do if title==name then view:Show()else view:Hide()end end
 for title,button in pairs(self.tabs)do button:SetEnabled(title~=name)end
 self:Refresh()
end
function D:Show()
 if not A:Require()then return end
 if not self.frame then
  local U=T.featureUI;local f=U.Panel('TranquilityPvP','TRANQUILITY / PVP COMMAND CENTER',940,760);self.frame=f
  U.Label(f,'Guild reconnaissance · Fresh observations, short-lived heatmaps and approaching-danger warnings',24,-62,890,32)
  self.pages={};self.tabs={};self.options={}
  for i,name in ipairs({'Radar','Heatmap','Danger alerts','Settings'})do
   local key=name;self.tabs[key]=U.Button(f,key,24+(i-1)*230,-106,200,function()self:Page(key)end)
   local view=CreateFrame('Frame',nil,f);view:SetPoint('TOPLEFT',24,-154);view:SetSize(890,540);self.pages[key]=view
  end
  local function checkbox(parent,key,text,y)
   local box=CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate');self.options[key]=box;box:SetSize(26,26);box:SetPoint('TOPLEFT',0,y);U.Label(parent,text,36,y-5,845)
   box:SetScript('OnClick',function(b)self:Settings()[key]=b:GetChecked()==true;if key=='enabled'then if b:GetChecked()then self:SeedUnits()else self:Stop();self.frame:Show()end end;if self.CheckAlerts then self:CheckAlerts()end;self:Refresh()end)
  end
  local radar=self.pages.Radar
  self.diagnostics=U.Label(radar,'',0,0,880,90);self.summary=U.Label(radar,'',0,-116,880,290)
  U.Button(radar,'Start / stop scouting',0,-450,420,function()local settings=self:Settings();settings.enabled=not settings.enabled;if settings.enabled then self:SeedUnits()else self:Stop();self.frame:Show()end;self:Refresh()end)
  U.Button(radar,'Scouting configuration',450,-450,420,function()self:Page('Settings')end)
  local heatmap=self.pages.Heatmap
  U.Label(heatmap,'WORLD MAP / DENSITY OVERLAY',0,0,875,32)
  U.Label(heatmap,'Yellow 1–4 · Orange 5–14 · Red 15–24 · Dark red 25+\nOptional friendlies: blue → teal → green\n\n~ means scout-centered or uncertain density. Every observation fades out after 20 seconds unless renewed. Distinct public identities are deduplicated; anonymous overlapping scout pools use a conservative maximum.\n\nHover map circles for age and uncertainty. Public map coordinates are preferred; unavailable/secret enemy positions never become invented exact locations. Sightings do not reveal every player on a layer and do not produce through-wall models.',0,-54,875,290)
  U.Button(heatmap,'Open world map',0,-390,420,function()if WorldMapFrame then WorldMapFrame:Show();local own=self:OwnPosition();if own and WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(own.map)end;self:Render()end end)
  U.Button(heatmap,'Clear local observations',450,-390,420,function()self:Stop();self:SeedUnits();self.frame:Show();self:Refresh()end)
  local alerts=self.pages['Danger alerts'];checkbox(alerts,'alerts','Show a warning when fresh enemy concentrations are within range',0);checkbox(alerts,'sound','Optional alert sound (at most once per 30 seconds)',44)
  U.Label(alerts,'Minimum observed enemies',0,-112,270);self.alertCount=U.Edit(alerts,tostring(self:Settings().alertCount or 5),300,-104,120)
  U.Label(alerts,'Warning distance in yards',450,-112,270);self.alertRange=U.Edit(alerts,tostring(self:Settings().alertRange or 300),730,-104,130)
  U.Button(alerts,'Save alert thresholds',0,-160,870,function()local count,range=tonumber(self.alertCount:GetText()),tonumber(self.alertRange:GetText());if not count or count%1~=0 or count<1 or count>100 or not range or range%1~=0 or range<50 or range>1000 then self.alertDetail:SetText('Use 1–100 enemies and 50–1,000 yards.');return end;local settings=self:Settings();settings.alertCount=count;settings.alertRange=range;self:CheckAlerts();self:Refresh()end)
  self.alertDetail=U.Label(alerts,'',0,-224,870,228)
  U.Label(alerts,'Distances are estimates based on map observations, not a wallhack. Alerts use reports no older than 15 seconds; layer/context may be unverified. No recent alert does not guarantee safety.',0,-466,870,60)
  local settings=self.pages.Settings
  checkbox(settings,'enabled','Enable scouting and world-map overlay',0);checkbox(settings,'share','Share sightings with admitted guild scouts',48);checkbox(settings,'fallback','Allow scout-centered fallback only when exact coordinates are unavailable',96);checkbox(settings,'friendly','Observe and show friendlies as well as enemies',144)
  U.Label(settings,'Exact-only mode: turn the fallback option off.\n\nScouting and sharing start off. Only permitted nameplate, target and mouseover data is sampled. Private/secret values and forbidden frames are skipped. The module cannot query all nearby/layer players, track hidden units globally, or draw enemy skeletons through geometry.\n\nRaw observations stay in memory and expire quickly. Disabling this PvP sub-addon also removes the collector and alerts; the rest of the guild toolkit remains separate.',0,-218,870,240)
  U.Label(f,'/tranq pvp · Enable Tranquility: PvP in AddOns · Requires Tranquility guild membership',24,-716,890,28)
 end
 self.frame:Show();self:Page(self.page or 'Radar')
end
