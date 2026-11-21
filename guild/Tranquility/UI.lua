local TG = _G.Tranquility
local UI = {}
TG.featureUI = UI
function UI.Label(parent, text, x, y, width, height)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT", x, y); f:SetSize(width, height or 22)
    f:SetJustifyH("LEFT"); f:SetJustifyV("TOP"); f:SetText(text)
    return f
end
function UI.Button(parent, text, x, y, width, action)
    local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    f:SetPoint("TOPLEFT", x, y); f:SetSize(width, 26); f:SetText(text)
    f:SetScript("OnClick", action)
    f:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    f:GetNormalTexture():SetVertexColor(.06,.24,.36,1)
    f:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    f:GetPushedTexture():SetVertexColor(.08,.36,.48,1)
    return f
end
function UI.Edit(parent, text, x, y, width)
    local f = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    f:SetPoint("TOPLEFT", x, y); f:SetSize(width, 26); f:SetAutoFocus(false)
    f:SetMaxLetters(255); f:SetText(text)
    f:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    return f
end
function UI.Panel(name, title, width, height)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(width, height);if GetScreenWidth and GetScreenHeight and f.SetScale then f:SetScale(math.min(1,(GetScreenWidth()-40)/width,(GetScreenHeight()-40)/height))end; f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    f:SetBackdropColor(0.035, 0.045, 0.065, 0.98)
    local heading=UI.Label(f, title, 22, -20, width - 80, 26)
    if name:lower():find("auction",1,true) then heading:SetTextColor(.25,.75,.45) else heading:SetTextColor(.3,.72,1) end
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5); close:SetScript("OnClick", function() f:Hide() end)
    table.insert(UISpecialFrames, name)
    f:Hide()
    return f
end
function UI.ScrollText(parent, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, y); scroll:SetSize(width, height)
    local child = CreateFrame("Frame", nil, scroll); child:SetSize(width - 12, height)
    scroll:SetScrollChild(child)
    local text = UI.Label(child, "", 0, 0, width - 18, height)
    return function(content)
        text:SetText(content)
        local size = math.max(height, text:GetStringHeight() + 20)
        text:SetHeight(size); child:SetHeight(size)
    end
end
