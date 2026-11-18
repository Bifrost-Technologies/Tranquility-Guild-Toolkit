local T=_G.Tranquility
local function whole(value,low,high)
    value=tonumber(value)
    return value and value==value and value%1==0 and value>=low and value<=high and value or nil
end
function T:RecruitSettings()
    TranquilityDB=type(TranquilityDB)=="table" and TranquilityDB or {}
    local settings=type(TranquilityDB.recruitment)=="table" and TranquilityDB.recruitment or {}
    TranquilityDB.recruitment=settings
    settings.normal=whole(settings.normal,1,30) or 4
    settings.slow=whole(settings.slow,settings.normal,60) or math.max(10,settings.normal)
    settings.window=whole(settings.window,10,600) or 120
    settings.batch=whole(settings.batch,1,50) or 50
    return settings
end
function T:SaveRecruitSettings(normal,slow,window,batch)
    normal=whole(normal,1,30);slow=whole(slow,1,60);window=whole(window,10,600);batch=whole(batch,1,50)
    if not normal or not slow or slow<normal or not window or not batch then return false end
    local settings=self:RecruitSettings()
    settings.normal,settings.slow,settings.window,settings.batch=normal,slow,window,batch
    if self.recruitment and self.recruitment.Refresh then self.recruitment:Refresh() end
    return true
end
function T:ShowRecruitSettings()
    if not TranquilityAccess or not TranquilityAccess:Require()then return end
    local UI=self.featureUI
    if not self.settingsFrame then
        local f=UI.Panel("TranquilityGlobalSettings","TRANQUILITY / GLOBAL SETTINGS",760,440)
        self.settingsFrame=f;self.settingsFields={}
        UI.Label(f,"Recruitment uses one manually searched WHO result per batch. Every invite is copied and sent by you.\nThese settings pace preparing invite commands; they cannot control or confirm chat submissions.",22,-58,710,48)
        local fields={{"normal","Normal invite-command interval (1-30 seconds)"},{"slow","Warning interval (normal-60 seconds)"},{"window","Warning cooldown window (10-600 seconds)"},{"batch","Eligible players per batch (1-50)"}}
        for i,field in ipairs(fields) do
            local y=-123-(i-1)*44
            UI.Label(f,field[2],22,y-6,535,27)
            local box=UI.Edit(f,"",585,y,110);box:SetNumeric(true);self.settingsFields[field[1]]=box
        end
        UI.Button(f,"Save",22,-321,125,function()
            local fields=self.settingsFields
            if self:SaveRecruitSettings(fields.normal:GetText(),fields.slow:GetText(),fields.window:GetText(),fields.batch:GetText()) then
                for _,box in pairs(fields) do box:ClearFocus() end
                self.settingsStatus:SetText("Saved globally. Changes apply to command preparation; no messages or invites were sent.")
            else self.settingsStatus:SetText("Enter whole numbers in the shown ranges. Warning interval must be at least the normal interval.") end
        end)
        UI.Button(f,"Defaults",164,-321,125,function()
            self:SaveRecruitSettings(4,10,120,50);self:ShowRecruitSettings()
        end)
        self.settingsStatus=UI.Label(f,"",22,-371,710,48)
    end
    local settings=self:RecruitSettings()
    for key,box in pairs(self.settingsFields) do box:SetText(tostring(settings[key])) end
    self.settingsStatus:SetText("Default: 4 seconds normally; 10 seconds for 120 seconds after a relevant rate warning. Repeated warnings extend the window.")
    self.settingsFrame:Show()
end
