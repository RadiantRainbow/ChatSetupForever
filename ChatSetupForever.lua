local addonName, ns = ...

local DB
local setupFrame = CreateFrame("Frame")
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

-- Message groups matching the "Other" tab options requested for the Loot tab
local LOOT_MESSAGE_GROUPS = {
    "COMBAT_XP_GAIN",        -- Experience
    "COMBAT_HONOR_GAIN",     -- Honor
    "COMBAT_FACTION_CHANGE", -- Reputation
    "SKILL",                 -- Skill-ups
    "LOOT",                  -- Item Loot
    "CURRENCY",              -- Currency
    "MONEY",                 -- Money Loot
}

local function RemoveAllChannelsFromFrame(frame)
    local channels = {GetChannelList()}
    local i = 1
    while i <= #channels do
        local name = channels[i + 1]
        i = i + 3

        if type(name) == "string" and name ~= "" then
            frame:RemoveChannel(name)
        end
    end
end

local function ConfigureLootWindow(frame)
    -- Uncheck everything in the "Chat" / "Other" left tabs
    ChatFrame_RemoveAllMessageGroups(frame)

    -- Remove any joined global channels
    RemoveAllChannelsFromFrame(frame)

    -- Enable only the requested "Other" groups
    for _, group in ipairs(LOOT_MESSAGE_GROUPS) do
        ChatFrame_AddMessageGroup(frame, group)
    end
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

    -- Spam tab: all channels except LocalDefense
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
            i = i + 3

            if type(name) == "string" and name ~= "" then
                if not string.find(name, "LocalDefense") then
                    ChatFrame1:RemoveChannel(name)
                end
                spamFrame:AddChannel(name)
            end
        end
    else
        Debug("Failed to create Spam window.")
    end

    -- Loot tab: only Experience/Honor/Reputation/Skill-ups/Item Loot/Currency/Money Loot
    local lootFrame = GetChatFrameByName("Loot")
    if not lootFrame then
        FCF_OpenNewWindow("Loot")
        lootFrame = GetChatFrameByName("Loot")
    end

    if lootFrame then
        ConfigureLootWindow(lootFrame)
        -- Removed: do NOT hide LOOT_MESSAGE_GROUPS from General
        Debug("Loot window configured.")
    else
        Debug("Failed to create Loot window.")
    end

    Debug("Setup complete.")
end

local function MarkPrompted()
    DB.prompted = true
end

local function CreateConfirmDialog()
    local dialog = _G["ChatSetupForeverPrompt"]
    if dialog then
        dialog:Show()
        return
    end

    dialog = CreateFrame("Frame", "ChatSetupForeverPrompt", UIParent, "BackdropTemplate")
    dialog:SetSize(360, 150)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(100)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    local text = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", dialog, "TOP", 0, -20)
    text:SetWidth(320)
    text:SetJustifyH("CENTER")
    text:SetText("Set up default chat options for this character?\n\nA 'Spam' window will be created, a 'Loot' window for loot/rep/xp/etc., and General will show LocalDefense plus loot/rep/xp/etc.")

    local yes = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    yes:SetSize(80, 22)
    yes:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 40, 20)
    yes:SetText("Yes")
    yes:SetScript("OnClick", function()
        ApplyChatSetup()
        MarkPrompted()
        dialog:Hide()
    end)

    local no = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    no:SetSize(80, 22)
    no:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -40, 20)
    no:SetText("No")
    no:SetScript("OnClick", function()
        MarkPrompted()
        dialog:Hide()
    end)

    dialog:Show()
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
        if DB and not DB.prompted then
            Debug("Showing prompt...")
            CreateConfirmDialog()
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
        Debug("Reset. Prompt will show on next login or /chatsetup show.")
    elseif msg == "show" then
        Debug("Showing prompt...")
        CreateConfirmDialog()
    else
        Debug("Usage: /chatsetup show | /chatsetup reset")
    end
end
