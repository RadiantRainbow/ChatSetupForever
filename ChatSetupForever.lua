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
end

local function CreatePromptDialog()
    local f = CreateFrame("Frame", "ChatSetupForeverPrompt", UIParent, "BackdropTemplate")
    f:SetSize(360, 150)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:SetMovable(false)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    tinsert(UISpecialFrames, f:GetName())

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(256, 64)
    header:SetPoint("TOP", f, "TOP", 0, 12)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("Chat Setup")

    local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", f, "TOP", 0, -22)
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
