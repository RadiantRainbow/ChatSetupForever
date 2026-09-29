local addonName, ns = ...

local DB
local setupFrame = CreateFrame("Frame")
local promptShown = false
local channelWaitTicker

local function Debug(msg)
    print("|cFF00FF00[ChatSetupForever]|r " .. tostring(msg))
end

local function GetChatFrameByName(name)
    for i = 1, NUM_CHAT_WINDOWS do
        if GetChatWindowInfo(i) == name then
            return _G["ChatFrame"..i]
        end
    end
    return nil
end

local function HasChannels()
    local list = {GetChannelList()}
    return #list > 0
end

local function ApplyChatSetup()
    if channelWaitTicker then
        channelWaitTicker:Cancel()
        channelWaitTicker = nil
    end

    if not HasChannels() then
        Debug("Waiting for channels...")
        channelWaitTicker = C_Timer.NewTicker(0.5, function()
            if HasChannels() then
                channelWaitTicker:Cancel()
                channelWaitTicker = nil
                ApplyChatSetup()
            end
        end)
        return
    end

    Debug("Applying chat setup...")

    local spamFrame = GetChatFrameByName("Spam")
    if not spamFrame then
        FCF_OpenNewWindow("Spam")
        spamFrame = GetChatFrameByName("Spam")
    end

    if spamFrame then
        local channels = {GetChannelList()}
        local i = 1
        while i <= #channels do
            local id = channels[i]
            local name = channels[i + 1]
            i = i + 2

            if name and name ~= "" then
                if not string.find(name, "LocalDefense") then
                    ChatFrame_RemoveChannel(ChatFrame1, name)
                end
                ChatFrame_AddChannel(spamFrame, name)
            end
        end
        Debug("Setup complete.")
    else
        Debug("Failed to create Spam window.")
    end
end

local function CreatePromptDialog()
    local existing = _G["ChatSetupForeverPrompt"]
    if existing then
        existing:Show()
        existing:Raise()
        Debug("Reusing existing dialog.")
        return existing
    end

    local f = CreateFrame("Frame", "ChatSetupForeverPrompt", UIParent, "BackdropTemplate")
    f:SetSize(360, 150)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(200)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)

    tinsert(UISpecialFrames, f:GetName())

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText("Chat Setup")

    local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", f, "TOP", 0, -35)
    text:SetWidth(320)
    text:SetJustifyH("CENTER")
    text:SetText("Set up default chat options for this character?\n\nA 'Spam' window will be created and General will only show LocalDefense.")

    local yes = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    yes:SetSize(80, 22)
    yes:SetPoint("BOTTOM", f, "BOTTOM", -50, 16)
    yes:SetText("Yes")
    yes:SetScript("OnClick", function()
        ApplyChatSetup()
        f:Hide()
    end)

    local no = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    no:SetSize(80, 22)
    no:SetPoint("BOTTOM", f, "BOTTOM", 50, 16)
    no:SetText("No")
    no:SetScript("OnClick", function()
        f:Hide()
    end)

    f:SetScript("OnHide", function()
        DB.prompted = true
    end)

    f:Show()

    return f
end

local function ShowPrompt()
    if promptShown then
        Debug("Prompt already shown this session.")
        return
    end
    promptShown = true
    Debug("Showing prompt...")
    local dialog = CreatePromptDialog()
    dialog:Show()
    dialog:Raise()

    C_Timer.After(0, function()
        Debug("Dialog IsShown: " .. tostring(dialog:IsShown()))
        Debug("Dialog IsVisible: " .. tostring(dialog:IsVisible()))
        Debug("Dialog parent: " .. tostring(dialog:GetParent()))
        Debug("Dialog parent visible: " .. tostring(dialog:GetParent() and dialog:GetParent():IsVisible()))
        Debug("Dialog alpha: " .. tostring(dialog:GetAlpha()))
        Debug("Dialog scale: " .. tostring(dialog:GetEffectiveScale()))
        local left, bottom, width, height = dialog:GetRect()
        Debug("Dialog rect: " .. (left or "nil") .. ", " .. (bottom or "nil") .. ", " .. (width or "nil") .. ", " .. (height or "nil"))
    end)
end

setupFrame:RegisterEvent("ADDON_LOADED")
setupFrame:RegisterEvent("PLAYER_LOGIN")
setupFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not ChatSetupForeverDB then
            ChatSetupForeverDB = {}
        end
        DB = ChatSetupForeverDB
        if DB.prompted == nil then
            DB.prompted = false
        end
        Debug("Loaded. prompted=" .. tostring(DB.prompted))
    elseif event == "PLAYER_LOGIN" then
        if DB and not DB.prompted and not promptShown then
            ShowPrompt()
        else
            Debug("Skipping prompt. prompted=" .. tostring(DB and DB.prompted))
        end
    end
end)

SLASH_CHATSETUPFOREVER1 = "/chatsetup"
SlashCmdList["CHATSETUPFOREVER"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "reset" then
        DB.prompted = false
        promptShown = false
        Debug("Reset. Prompt will show on next login or /chatsetup show.")
    elseif msg == "show" then
        promptShown = false
        ShowPrompt()
    else
        Debug("Usage: /chatsetup show | /chatsetup reset")
    end
end
