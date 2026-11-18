local A=TranquilityAccess
local function now()return GetServerTime()end
local function me()return GetUnitName('player',true)end
A.discordURL='https://discord.gg/CMjbSRYt6'
A.joinCode='3781'
function A:VaultSettings()
 TranquilityDB=TranquilityDB or {};TranquilityDB.security=TranquilityDB.security or {};return TranquilityDB.security
end
function A:FinishReveal()
 self:VaultSettings().vaultRevealed=true;self.vaultRevealed=true;self.vaultReveal=nil
 self.vaultWords:SetAlpha(1);self.vaultWords:SetText('Join our Discord to enter the guild toolkit')
 self.vaultControls:Show();self.vaultControls:SetAlpha(1);self.discordBox:Show();self.vaultHint:SetText('Join Discord → complete initiation → get your four-digit code → Enter Guild.')
end
function A:UnlockVault(authority)
 if not self:RankAllowed()or type(self:Read(UnitGUID,'player'))~='string'then return false end
 TranquilityDB=TranquilityDB or {};TranquilityDB.security=TranquilityDB.security or {}
 TranquilityDB.security.vaultUnlocked={character=self:Key(me()),guid=self:Read(UnitGUID,'player'),confirmed=true,at=now(),authority=authority}
 if self.frame then self.frame:Hide()end;self:Refresh();return true
end
function A:SubmitVault(pin)
 if not self:Native()then self.vaultStatus:SetText('Join the Tranquility guild first. A code cannot grant access outside the guild.');return false end
 local settings=self:VaultSettings();local ban=settings.bans and settings.bans[self:Key(me())];if ban and ban.blocked then self.vaultStatus:SetText('Toolkit access is suspended. Contact a guild officer.');return false end
 if type(pin)~='string'or not pin:match('^%d%d%d%d$')then self.vaultStatus:SetText('Enter the four-digit code issued for this character.');return false end
 if self.masterPin and pin==self.masterPin then if self:VaultSettings().vaultRevealed then self:FinishReveal()end
 local _,index=self:Native();if index==0 then self.masterPin=nil;return self:UnlockVault(me())end end
 local db=TranquilityDB;local p=db and db.security and db.security.pendingVault
 if pin==self.joinCode then
  if now()-(self.joinAttempt or 0)<10 then return false end;self.joinAttempt=now()
  local T=_G.Tranquility;if not T or not T.work then return false end
  local nonce='';for i=1,32 do nonce=nonce..('%x'):format(math.random(0,15))end
  settings.pendingVault={challenge=nonce,pin=pin,expires=now()+600,shared=true}
  self.vaultStatus:SetText('Code accepted. Waiting for an online authorized officer to promote you to Dedicated Member. Keep playing; you can close this window.')
  return T.work:Send({'JCODE1',nonce,pin})
 end
 if not p or p.expires<now()or pin~=p.pin then self.vaultStatus:SetText('No matching active code. Request verification from the guild bot and your officer.');return false end
 if now()-(p.lastAttempt or 0)<5 then return false end;p.lastAttempt=now()
 local T=_G.Tranquility;if not T or not T.work then self.vaultStatus:SetText('Enable the Tranquility core addon to complete verification.');return false end
 self.vaultStatus:SetText('Code submitted. Waiting for the officer and native Dedicated Member rank.');return T.work:SendWhisper({'VPROOF1',p.challenge,pin},p.officer)
end
function A:ShowVault()
 self:HideTools();self:VaultSettings().vaultClosed=false
 if not self.vaultBuilt then
  self.vaultBuilt=true
  local f=CreateFrame('Frame','TranquilityVault',UIParent,'BackdropTemplate');self.frame=f;f:SetSize(670,480);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true)
  if GetScreenWidth and GetScreenHeight and f.SetScale then f:SetScale(math.min(1,(GetScreenWidth()-32)/670,(GetScreenHeight()-32)/480))end
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=22,insets={left=7,right=7,top=7,bottom=7}});f:SetBackdropColor(.025,.035,.055,1)
  self.vaultClose=CreateFrame('Button',nil,f,'UIPanelCloseButton');self.vaultClose:SetPoint('TOPRIGHT',-5,-5);self.vaultClose:SetScript('OnClick',function()f:Hide()end)
  table.insert(UISpecialFrames,'TranquilityVault')
  f:SetScript('OnHide',function()self:VaultSettings().vaultClosed=true;if self.vaultInput then self.vaultInput:ClearFocus()end end)
  local function label(text,y,width,height,font)local t=f:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight');t:SetPoint('TOP',0,y);t:SetSize(width,height);t:SetText(text);return t end
  label('T R A N Q U I L I T Y',-28,600,28,'GameFontNormalLarge'):SetTextColor(.79,.68,.43)
  label('G U I L D   V A U L T',-64,600,22):SetTextColor(.47,.55,.67)
  local door=CreateFrame('Frame',nil,f,'BackdropTemplate');door:SetSize(586,200);door:SetPoint('TOP',0,-104);door:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});door:SetBackdropColor(.07,.085,.11,1)
  local seam=door:CreateTexture(nil,'ARTWORK');seam:SetSize(1,166);seam:SetPoint('CENTER');seam:SetColorTexture(.3,.35,.42,.5)
  self.vaultWords=label('',-123,540,64,'QuestFont');self.vaultWords:SetTextColor(.63,.8,1);if self.vaultWords.SetFont then pcall(self.vaultWords.SetFont,self.vaultWords,'Fonts\\MORPHEUS.TTF',22)end
  local discord=CreateFrame('EditBox',nil,f,'InputBoxTemplate');self.discordBox=discord;discord:SetSize(440,26);discord:SetPoint('TOP',0,-184);discord:SetAutoFocus(false);discord:SetText(self.discordURL);discord:SetScript('OnEditFocusGained',function(box)box:SetText(self.discordURL);box:HighlightText()end);discord:SetScript('OnEscapePressed',function()f:Hide()end);discord:Hide()
  local panel=CreateFrame('Frame',nil,f);self.vaultControls=panel;panel:SetSize(520,96);panel:SetPoint('TOP',0,-222);panel:Hide()
  for i=1,6 do local slot=CreateFrame('Frame',nil,panel,'BackdropTemplate');slot:SetSize(45,42);slot:SetPoint('TOPLEFT',89+(i-1)*48,0);slot:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=8});slot:SetBackdropColor(.025,.04,.07,1)end
  local input=CreateFrame('EditBox',nil,panel);self.vaultInput=input;input:SetSize(278,38);input:SetPoint('TOPLEFT',92,-2);input:SetAutoFocus(false);input:SetMaxLetters(4);input:SetNumeric(true);if input.SetFontObject then input:SetFontObject('GameFontNormalLarge')end;if input.SetJustifyH then input:SetJustifyH('CENTER')end
  input:SetScript('OnEnterPressed',function(box)self:SubmitVault(box:GetText());box:ClearFocus()end);input:SetScript('OnEscapePressed',function(box)box:ClearFocus();f:Hide()end)
  local enter=CreateFrame('Button',nil,panel,'UIPanelButtonTemplate');enter:SetSize(280,28);enter:SetPoint('TOP',0,-56);enter:SetText('Enter Guild');enter:SetScript('OnClick',function()self:SubmitVault(input:GetText())end)
  self.vaultStatus=label(self.denial,-326,586,74);self.vaultStatus:SetTextColor(.72,.76,.83)
  local hint=label('Double-click the sealed door to reveal how to join. You may close this window anytime.',-418,590,32);self.vaultHint=hint;hint:SetTextColor(.44,.52,.65)
  local function click()local clock=GetTime and GetTime()or now();if not self.vaultRevealed and self.vaultReveal==nil and self.vaultClick and clock-self.vaultClick<=.6 then self:VaultSettings().vaultRevealed=true;self.vaultReveal=0;self.vaultControls:Hide();self.vaultWords:SetText('');self.vaultRevealed=false end;self.vaultClick=clock end
  door:EnableMouse(true);door:SetScript('OnMouseDown',click);f:SetScript('OnMouseDown',click)
  f:SetScript('OnUpdate',function(_,dt)
   if self.vaultReveal==nil or self.vaultRevealed then return end;self.vaultReveal=self.vaultReveal+math.min(dt,.1)
   local phrase='i solemnly swear that i am to no good';local written=#phrase/16
   self.vaultWords:SetText(phrase:sub(1,math.min(#phrase,math.floor(self.vaultReveal*16))))
   if self.vaultReveal>written+1 then self.vaultWords:SetAlpha(math.max(0,1-(self.vaultReveal-written-1)))end
   if self.vaultReveal>=written+2 then self:FinishReveal()end
  end)
 end
 local _,index=self:Native()
 if index==0 and not self:Allowed()then self.masterPin=self.masterPin or tostring(math.random(1000,9999));self.vaultStatus:SetText('Guild Master bootstrap: enter '..self.masterPin..' to initialize your officer vault. Native guild authority is required.')
 elseif self:RankAllowed()then self.vaultStatus:SetText('Guild rank confirmed. Join Discord, complete initiation and enter the four-digit code from the bot.')
 elseif self:Native()then self.vaultStatus:SetText('Welcome, guildmate. Join Discord, complete initiation and enter the bot code. An authorized officer will promote you to Dedicated Member.')
 else self.vaultStatus:SetText(self.denial)end
 self.frame:Show();return false
end
