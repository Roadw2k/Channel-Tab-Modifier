local ADDON_NAME = ...
local DEFAULT_MAX_CHAT_WINDOWS = 10

local CTM = CreateFrame("Frame")
local settingsFrame
local minimapButton
local rows = {}
local installedHooks = {}
local originalTabColors = {}

local COLORS = {
    background = {0.035, 0.045, 0.065, 0.98},
    panel = {0.065, 0.08, 0.115, 0.96},
    panelHover = {0.09, 0.11, 0.155, 1},
    border = {0.18, 0.22, 0.31, 1},
    accent = {0.19, 0.72, 0.92, 1},
    accentHover = {0.28, 0.82, 1, 1},
    text = {0.92, 0.95, 1, 1},
    muted = {0.55, 0.61, 0.71, 1},
    danger = {0.93, 0.39, 0.42, 1},
}

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(borderColor or COLORS.border))
end

local function SetChatIcon(texture)
    local atlasName = "communities-icon-chat"
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName) then
        texture:SetAtlas(atlasName, false)
    else
        texture:SetTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
        texture:SetTexCoord(0, 1, 0, 1)
    end
    texture:SetVertexColor(unpack(COLORS.accent))
end

local function GetMaxChatWindows()
    return NUM_CHAT_WINDOWS or DEFAULT_MAX_CHAT_WINDOWS
end

local function GetOriginalName(index)
    if type(GetChatWindowInfo) ~= "function" then
        return nil
    end

    local name = GetChatWindowInfo(index)
    if type(name) == "string" and name ~= "" then
        return name
    end
end

local function GetTab(index)
    return _G["ChatFrame" .. index .. "Tab"]
end

local function ResizeTabToLabel(tab, label)
    local padding = tab.sizePadding or 0
    if type(PanelTemplates_TabResize) == "function" then
        PanelTemplates_TabResize(tab, padding)
        tab.textWidth = label:GetWidth()
    else
        local sidePadding = 20
        tab:SetWidth(label:GetStringWidth() + sidePadding + padding)
        tab.textWidth = label:GetStringWidth()
    end
end

local function CopyColor(color)
    if not color then
        return nil
    end
    return {r = color.r, g = color.g, b = color.b, a = color.a or 1}
end

local function RememberOriginalTabColor(originalName, tab)
    if originalTabColors[originalName] == nil then
        originalTabColors[originalName] = tab.selectedColorTable and CopyColor(tab.selectedColorTable) or false
    end
end

local function GetDefaultTabColor(originalName)
    local color = originalTabColors[originalName]
    if color then
        return CopyColor(color)
    end
    if NORMAL_FONT_COLOR then
        return {r = NORMAL_FONT_COLOR.r, g = NORMAL_FONT_COLOR.g, b = NORMAL_FONT_COLOR.b, a = 1}
    end
    return {r = 1, g = 0.82, b = 0, a = 1}
end

local function ApplyCustomTabAppearance(tab, label, color)
    if not color then
        return
    end

    if label then
        label:SetTextColor(color.r, color.g, color.b, 1)
    end

    for _, regionName in ipairs({
        "ActiveLeft", "ActiveMiddle", "ActiveRight",
        "HighlightLeft", "HighlightMiddle", "HighlightRight", "glow",
    }) do
        local region = tab[regionName]
        if region then
            region:SetVertexColor(color.r, color.g, color.b, 1)
        end
    end

    local opacity = color.a or 1
    tab.mouseOverAlpha = opacity
    tab.noMouseAlpha = opacity
    tab:SetAlpha(opacity)
end

local function GetSavedTab(index, originalName)
    local savedTab = CTMDB.tabs and CTMDB.tabs[index]
    if savedTab and savedTab.originalName == originalName then
        return savedTab
    end
end

local function ApplyTabColor(index, originalName, tab, label)
    RememberOriginalTabColor(originalName, tab)

    local savedTab = GetSavedTab(index, originalName)
    local customColor = (savedTab and savedTab.color) or (CTMDB.colors and CTMDB.colors[originalName])
    local originalColor = originalTabColors[originalName]
    tab.selectedColorTable = customColor and CopyColor(customColor) or (originalColor and CopyColor(originalColor) or nil)

    local chatFrame = _G["ChatFrame" .. index]
    local isSelected = not chatFrame or not chatFrame.isDocked
    if chatFrame and chatFrame.isDocked and type(FCFDock_GetSelectedWindow) == "function" and GENERAL_CHAT_DOCK then
        isSelected = chatFrame == FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    end

    if type(FCFTab_UpdateColors) == "function" then
        FCFTab_UpdateColors(tab, isSelected)
        if customColor then
            ApplyCustomTabAppearance(tab, label, customColor)
        elseif chatFrame and type(FCFTab_UpdateAlpha) == "function" then
            FCFTab_UpdateAlpha(chatFrame)
        end
    elseif label then
        local color = customColor or GetDefaultTabColor(originalName)
        label:SetTextColor(color.r, color.g, color.b, 1)
        if customColor then
            tab:SetAlpha(color.a or 1)
        end
    end
end

function CTM:ApplyNames()
    if not CTMDB then
        return
    end

    for index = 1, GetMaxChatWindows() do
        local originalName = GetOriginalName(index)
        local tab = GetTab(index)
        if originalName and tab then
            local savedTab = GetSavedTab(index, originalName)
            local customName = (savedTab and savedTab.name) or CTMDB.names[originalName]
            local displayName = customName and customName ~= "" and customName or originalName
            local label = tab.Text or tab:GetFontString()
            if label and label:GetText() ~= displayName then
                tab:SetText(displayName)
                ResizeTabToLabel(tab, label)
            end
            ApplyTabColor(index, originalName, tab, label)
        end
    end
end

local function StyleButton(button, accent)
    SetBackdrop(button, accent and COLORS.accent or COLORS.panel, accent and COLORS.accent or COLORS.border)
    button:SetScript("OnEnter", function(self)
        local color = accent and COLORS.accentHover or COLORS.panelHover
        self:SetBackdropColor(unpack(color))
        self:SetBackdropBorderColor(unpack(accent and COLORS.accentHover or COLORS.accent))
    end)
    button:SetScript("OnLeave", function(self)
        local color = accent and COLORS.accent or COLORS.panel
        self:SetBackdropColor(unpack(color))
        self:SetBackdropBorderColor(unpack(accent and COLORS.accent or COLORS.border))
    end)
end

local function CreateTextButton(parent, text, width, height, accent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    StyleButton(button, accent)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(unpack(accent and {0.02, 0.08, 0.11, 1} or COLORS.text))
    button.Label = label
    return button
end

local function HideRows()
    for _, row in ipairs(rows) do
        row:Hide()
    end
    wipe(rows)
end

local function UpdateEmptyState(frame, count)
    if count == 0 then
        frame.EmptyState:Show()
    else
        frame.EmptyState:Hide()
    end
end

local function UpdateRowColorSwatch(row)
    local color = row.Color or row.DefaultColor
    row.ColorSwatch:SetColorTexture(color.r, color.g, color.b, color.a or 1)
end

local function PersistRow(row)
    if not CTMDB or not row.OriginalName or not row.Index then
        return
    end

    local customName = strtrim(row.EditBox:GetText() or "")
    if customName == "" or customName == row.OriginalName then
        customName = nil
        CTMDB.names[row.OriginalName] = nil
    else
        CTMDB.names[row.OriginalName] = customName
    end

    local color = CopyColor(row.Color)
    CTMDB.colors[row.OriginalName] = color
    CTMDB.tabs[row.Index] = {
        originalName = row.OriginalName,
        name = customName,
        color = CopyColor(color),
    }
end

local function SetRowColor(row, color)
    row.Color = CopyColor(color)
    UpdateRowColorSwatch(row)
end

local function OpenRowColorPicker(row)
    local startingColor = CopyColor(row.Color or row.DefaultColor)
    local previousCustomColor = CopyColor(row.Color)

    local function UpdateColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local alpha = ColorPickerFrame:GetColorAlpha() or 1
        SetRowColor(row, {r = r, g = g, b = b, a = alpha})
    end

    local function CancelColor()
        SetRowColor(row, previousCustomColor)
    end

    local info = {
        r = startingColor.r,
        g = startingColor.g,
        b = startingColor.b,
        opacity = startingColor.a or 1,
        hasOpacity = true,
        swatchFunc = UpdateColor,
        cancelFunc = CancelColor,
    }

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = startingColor.a or 1
        ColorPickerFrame.func = UpdateColor
        ColorPickerFrame.opacityFunc = UpdateColor
        ColorPickerFrame.cancelFunc = CancelColor
        ColorPickerFrame:SetColorRGB(startingColor.r, startingColor.g, startingColor.b)
        ColorPickerFrame:Show()
    end
end

local function PopulateSettings()
    if not settingsFrame then
        return
    end

    HideRows()
    local count = 0

    for index = 1, GetMaxChatWindows() do
        local originalName = GetOriginalName(index)
        if originalName then
            count = count + 1
            local row = CreateFrame("Frame", nil, settingsFrame.ScrollChild, "BackdropTemplate")
            row:SetPoint("TOPLEFT", 0, -((count - 1) * 68))
            row:SetPoint("TOPRIGHT", -4, -((count - 1) * 68))
            row:SetHeight(58)
            SetBackdrop(row, COLORS.panel, COLORS.border)

            local number = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            number:SetPoint("LEFT", 14, 5)
            number:SetText(index)
            number:SetTextColor(unpack(COLORS.accent))
            number:SetWidth(22)

            local original = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            original:SetPoint("TOPLEFT", number, "TOPRIGHT", 9, 1)
            original:SetText("Original: " .. originalName)
            original:SetTextColor(unpack(COLORS.muted))

            local editBox = CreateFrame("EditBox", nil, row, "BackdropTemplate")
            editBox:SetPoint("BOTTOMLEFT", number, "BOTTOMRIGHT", 9, -1)
            editBox:SetPoint("RIGHT", -137, 0)
            editBox:SetHeight(27)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(40)
            editBox:SetFontObject("GameFontHighlight")
            editBox:SetTextInsets(9, 9, 0, 0)
            SetBackdrop(editBox, COLORS.background, COLORS.border)
            local savedTab = GetSavedTab(index, originalName)
            editBox:SetText((savedTab and savedTab.name) or CTMDB.names[originalName] or originalName)
            editBox:SetCursorPosition(0)
            editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
            editBox:SetScript("OnEditFocusGained", function(self)
                self:SetBackdropBorderColor(unpack(COLORS.accent))
                self:HighlightText()
            end)
            editBox:SetScript("OnEditFocusLost", function(self)
                self:SetBackdropBorderColor(unpack(COLORS.border))
                self:HighlightText(0, 0)
            end)

            local restore = CreateTextButton(row, "Restore", 72, 27, false)
            restore:SetPoint("RIGHT", -10, -11)

            local colorButton = CreateFrame("Button", nil, row, "BackdropTemplate")
            colorButton:SetSize(30, 27)
            colorButton:SetPoint("RIGHT", restore, "LEFT", -8, 0)
            SetBackdrop(colorButton, COLORS.background, COLORS.border)

            local colorSwatch = colorButton:CreateTexture(nil, "ARTWORK")
            colorSwatch:SetPoint("TOPLEFT", 5, -5)
            colorSwatch:SetPoint("BOTTOMRIGHT", -5, 5)

            local colorLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            colorLabel:SetPoint("BOTTOM", colorButton, "TOP", 0, 2)
            colorLabel:SetText("Color")
            colorLabel:SetTextColor(unpack(COLORS.muted))

            row.Index = index
            row.OriginalName = originalName
            row.EditBox = editBox
            row.DefaultColor = GetDefaultTabColor(originalName)
            row.Color = CopyColor((savedTab and savedTab.color) or CTMDB.colors[originalName])
            row.ColorSwatch = colorSwatch
            UpdateRowColorSwatch(row)

            colorButton:SetScript("OnClick", function() OpenRowColorPicker(row) end)
            colorButton:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(unpack(COLORS.accent))
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Tab color", unpack(COLORS.accent))
                GameTooltip:AddLine("Choose a custom color and overall tab opacity.", 1, 1, 1)
                GameTooltip:AddLine("Use 100% opacity for maximum readability.", 0.7, 0.75, 0.82)
                GameTooltip:Show()
            end)
            colorButton:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(unpack(COLORS.border))
                GameTooltip:Hide()
            end)

            restore:SetScript("OnClick", function()
                editBox:SetText(originalName)
                editBox:ClearFocus()
                SetRowColor(row, nil)
            end)

            rows[#rows + 1] = row
        end
    end

    settingsFrame.ScrollChild:SetHeight(math.max(1, count * 68 - 10))
    settingsFrame.Count:SetText(count .. (count == 1 and " chat tab found" or " chat tabs found"))
    UpdateEmptyState(settingsFrame, count)
end

local function SaveSettings()
    if not CTMDB then
        return false
    end

    for _, row in ipairs(rows) do
        PersistRow(row)
    end

    CTM:ApplyNames()
    if settingsFrame then
        settingsFrame.Status:SetText("Changes saved")
        settingsFrame.Status:SetTextColor(0.36, 0.86, 0.58, 1)
    end
    return true
end

local function CreateSettingsFrame()
    local frame = CreateFrame("Frame", "CTMSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(570, 570)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function(self)
        self.Status:SetText("Edit the label and color shown on each chat tab.")
        self.Status:SetTextColor(unpack(COLORS.muted))
        PopulateSettings()
    end)
    SetBackdrop(frame, COLORS.background, COLORS.border)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetColorTexture(unpack(COLORS.accent))
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(3)

    local iconBadge = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    iconBadge:SetSize(42, 42)
    iconBadge:SetPoint("TOPLEFT", 22, -16)
    SetBackdrop(iconBadge, COLORS.panel, COLORS.border)

    local headerIcon = iconBadge:CreateTexture(nil, "ARTWORK")
    headerIcon:SetPoint("TOPLEFT", 7, -7)
    headerIcon:SetPoint("BOTTOMRIGHT", -7, 7)
    SetChatIcon(headerIcon)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", iconBadge, "TOPRIGHT", 12, -3)
    title:SetText("Channel Tab Modifier")
    title:SetTextColor(unpack(COLORS.text))

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Personalize your chat tab labels and colors")
    subtitle:SetTextColor(unpack(COLORS.muted))

    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("TOPRIGHT", -55, -29)
    count:SetTextColor(unpack(COLORS.muted))
    frame.Count = count

    local close = CreateTextButton(frame, "×", 30, 30, false)
    close:SetPoint("TOPRIGHT", -14, -15)
    close.Label:SetFontObject("GameFontNormalLarge")
    close:SetScript("OnClick", function() frame:Hide() end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(unpack(COLORS.border))
    divider:SetPoint("TOPLEFT", 20, -73)
    divider:SetPoint("TOPRIGHT", -20, -73)
    divider:SetHeight(1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 22, -88)
    scrollFrame:SetPoint("BOTTOMRIGHT", -39, 82)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(505)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.ScrollChild = scrollChild

    local emptyState = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyState:SetPoint("TOP", 0, -45)
    emptyState:SetText("No chat tabs were found.\nCreate a chat window, then reopen this panel.")
    emptyState:SetTextColor(unpack(COLORS.muted))
    emptyState:SetJustifyH("CENTER")
    frame.EmptyState = emptyState

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 24, 28)
    status:SetTextColor(unpack(COLORS.muted))
    frame.Status = status

    local save = CreateTextButton(frame, "Save changes", 124, 34, true)
    save:SetPoint("BOTTOMRIGHT", -22, 20)
    save:SetScript("OnClick", function()
        if SaveSettings() then
            print("|cff31b8ebCTM:|r Chat tab settings saved.")
            frame:Hide()
        end
    end)

    local resetAll = CreateTextButton(frame, "Restore all", 104, 34, false)
    resetAll:SetPoint("RIGHT", save, "LEFT", -10, 0)
    resetAll:SetScript("OnClick", function()
        for _, row in ipairs(rows) do
            row.EditBox:SetText(row.OriginalName)
            SetRowColor(row, nil)
        end
        frame.Status:SetText("Original labels and colors restored. Click Save changes to apply.")
        frame.Status:SetTextColor(unpack(COLORS.muted))
    end)

    frame:Hide()
    settingsFrame = frame
    tinsert(UISpecialFrames, frame:GetName())
end

local function PositionMinimapButton()
    if not minimapButton or not CTMDB then
        return
    end

    local angle = math.rad(CTMDB.minimapAngle or 225)
    local minimapRadius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2
    local radius = minimapRadius + (minimapButton:GetWidth() / 2) - 2
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CursorAngle()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local centerX, centerY = Minimap:GetCenter()
    local x, y = cursorX - centerX, cursorY - centerY
    local radians

    if math.atan2 then
        radians = math.atan2(y, x)
    elseif x > 0 then
        radians = math.atan(y / x)
    elseif x < 0 and y >= 0 then
        radians = math.atan(y / x) + math.pi
    elseif x < 0 then
        radians = math.atan(y / x) - math.pi
    elseif y > 0 then
        radians = math.pi / 2
    else
        radians = -math.pi / 2
    end

    return math.deg(radians)
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "CTMMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    background:SetVertexColor(unpack(COLORS.background))

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    SetChatIcon(icon)
    button.Icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER", 10, -10)
    button.Border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetSize(32, 32)
    highlight:SetPoint("CENTER")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            CTM:ApplyNames()
            print("|cff31b8ebCTM:|r Chat tab settings refreshed.")
        else
            if settingsFrame:IsShown() then
                settingsFrame:Hide()
            else
                settingsFrame:Show()
            end
        end
    end)
    button:SetScript("OnEnter", function(self)
        self.Icon:SetVertexColor(unpack(COLORS.accentHover))
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Channel Tab Modifier", unpack(COLORS.accent))
        GameTooltip:AddLine("Left-click to open settings.", 1, 1, 1)
        GameTooltip:AddLine("Right-click to refresh tab labels.", 0.7, 0.75, 0.82)
        GameTooltip:AddLine("Drag to reposition.", 0.7, 0.75, 0.82)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.Icon:SetVertexColor(unpack(COLORS.accent))
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            CTMDB.minimapAngle = CursorAngle()
            PositionMinimapButton()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton = button
    PositionMinimapButton()
end

local function InstallHooks()
    local function RefreshAfterBlizzardUpdate()
        CTM:ApplyNames()
    end

    for _, functionName in ipairs({"FCF_SetWindowName", "FCF_OpenNewWindow", "FCF_DockFrame", "FCF_DockUpdate"}) do
        if not installedHooks[functionName] and type(_G[functionName]) == "function" then
            hooksecurefunc(functionName, RefreshAfterBlizzardUpdate)
            installedHooks[functionName] = true
        end
    end
end

function CTM:ToggleSettings()
    if not settingsFrame then
        return
    end
    settingsFrame:SetShown(not settingsFrame:IsShown())
end

local function InitializeDatabase()
    CTMDB = CTMDB or {}
    CTMDB.names = CTMDB.names or {}
    CTMDB.colors = CTMDB.colors or {}
    CTMDB.tabs = CTMDB.tabs or {}
    if CTMDB.minimapAngle == nil then
        CTMDB.minimapAngle = 225
    end
end

CTM:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        InitializeDatabase()
        CreateSettingsFrame()
        CreateMinimapButton()
        InstallHooks()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        InstallHooks()
        self:ApplyNames()
    elseif event == "PLAYER_ENTERING_WORLD" then
        InstallHooks()
        self:ApplyNames()
    end
end)

CTM:RegisterEvent("ADDON_LOADED")
CTM:RegisterEvent("PLAYER_LOGIN")
CTM:RegisterEvent("PLAYER_ENTERING_WORLD")

SLASH_CHANNELTABMODIFIER1 = "/ctm"
SLASH_CHANNELTABMODIFIER2 = "/channelnames"
SlashCmdList.CHANNELTABMODIFIER = function(message)
    message = strtrim(message or ""):lower()
    if message == "refresh" then
        CTM:ApplyNames()
        print("|cff31b8ebCTM:|r Chat tab settings refreshed.")
    elseif message == "reset" then
        wipe(CTMDB.names)
        wipe(CTMDB.colors)
        wipe(CTMDB.tabs)
        CTM:ApplyNames()
        if settingsFrame and settingsFrame:IsShown() then
            PopulateSettings()
        end
        print("|cff31b8ebCTM:|r All custom tab labels and colors were removed.")
    else
        CTM:ToggleSettings()
    end
end
