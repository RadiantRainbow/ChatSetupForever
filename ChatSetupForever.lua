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

StaticPopupDialogs["CHATSETUP_PROMPT"] = {
    text = "Set up default chat options for this character?\n\nA 'Spam' window will be created and General will only show LocalDefense.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = ApplyChatSetup,
    OnCancel = function()
        DB.prompted = true
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

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
        StaticPopup_Show("CHATSETUP_PROMPT")
    end
end)
