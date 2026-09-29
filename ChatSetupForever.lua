local addonName = "ChatSetupForever"

local DB
local setupFrame = CreateFrame("Frame")
local promptShown = false

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
    setupFrame:SetScript("OnUpdate", nil)

    if not HasChannels() then
        local elapsed = 0
        setupFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.5 then
                elapsed = 0
                if HasChannels() then
                    ApplyChatSetup()
                end
            end
        end)
        return
    end

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
    end

    DB.prompted = true
end

local function CreatePromptDialog()
    local f = CreateFrame("Frame", "ChatSetupForeverPrompt", UIParent)
    f:SetWidth(360)
    f:SetHeight(140)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:SetMovable(false)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture(0, 0, 0, 0.85)

    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
    border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(256)
    header:SetHeight(64)
    header:SetPoint("TOP", f, "TOP", 0, 18)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("Chat Setup")

    local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", f, "TOP", 0, -20)
    text:SetWidth(320)
    text:SetJustifyH("CENTER")
    text:SetText("Set up default chat options for this character?\n\nA 'Spam' window will be created and General will only show LocalDefense.")

    local yes = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    yes:SetWidth(80)
    yes:SetHeight(22)
    yes:SetPoint("BOTTOM", f, "BOTTOM", -50, 15)
    yes:SetText("Yes")
    yes:SetScript("OnClick", function()
        ApplyChatSetup()
        f:Hide()
    end)

    local no = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    no:SetWidth(80)
    no:SetHeight(22)
    no:SetPoint("BOTTOM", f, "BOTTOM", 50, 15)
    no:SetText("No")
    no:SetScript("OnClick", function()
        DB.prompted = true
        f:Hide()
    end)

    return f
end

setupFrame:RegisterEvent("PLAYER_LOGIN")
setupFrame:SetScript("OnEvent", function()
    if not ChatSetupForeverDB then
        ChatSetupForeverDB = {}
    end
    DB = ChatSetupForeverDB
    if DB.prompted == nil then
        DB.prompted = false
    end

    if not DB.prompted and not promptShown then
        promptShown = true
        local dialog = CreatePromptDialog()
        dialog:Show()
    end
end)
