local CHANGELOG_VERSION = "8.0.0"
local POPUP_WIDTH = 600
local POPUP_MIN_HEIGHT = 440
local POPUP_MAX_HEIGHT = 650
local CONTENT_WIDTH = POPUP_WIDTH - 30

local CHANGES = {
"|cffffd166*  Classic Era is now officially supported as its own addon build.|r",
"|cff72bce8*|r  Reworked the settings window with cleaner spacing, alignment, sizing, grouping, and visual hierarchy.",
"|cff72bce8*|r  Improved sidebar navigation, page headers, scrollbars, sub-tabs, and active/hover feedback.",
"|cff72bce8*|r  Standardized checkboxes, sliders, dropdowns, color controls, reset buttons, and editable value fields.",
"|cff72bce8*|r  Added larger checkbox click targets, clearer input focus, selected dropdown highlighting, and tab overflow handling.",
"|cff72bce8*|r  Restored the Target of Target and Focus HP text outline, draw order, and configured text shadow.",
"|cff72bce8*|r  Shared UI updates now remain consistent across Retail, TBC, and Classic Era builds.",
"|cff72bce8*|r  Fixed the Shaman class bar: Elemental tracks Maelstrom with a value, and Enhancement tracks Maelstrom Weapon stacks.",
"|cff72bce8*|r  Mana bar now sits flush at the bottom of the player frame as a thin strip.",
"|cff72bce8*|r  Health and mana values display inside the frame - HP right, mana left.",
"|cff72bce8*|r  Cleaner defaults for the cast bar, power bar, power text, text sizing, and frame positioning.",
"|cffff6666*  NOTE: This build may reset your profile due to the number of layout and settings changes. Use at your own risk.|r",
}

local function CreateChangelogFrame()
    local frame = CreateFrame("Frame", "MMF_ChangelogPopup", UIParent)
    frame:SetSize(POPUP_WIDTH, POPUP_MIN_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.06, 0.08, 0.97)

    local titleBG = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    titleBG:SetPoint("TOPLEFT", 1, -1)
    titleBG:SetPoint("TOPRIGHT", -1, -1)
    titleBG:SetHeight(28)
    titleBG:SetColorTexture(0.07, 0.09, 0.12, 1)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    title:SetPoint("TOPLEFT", 12, -8)
    title:SetTextColor(0.90, 0.72, 0.22, 1)
    title:SetText("Matt's Minimal Frames  |cffffffff- v" .. CHANGELOG_VERSION .. "|r")

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -6, -3)
    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTex:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "")
    closeTex:SetAllPoints()
    closeTex:SetJustifyH("CENTER")
    closeTex:SetTextColor(0.5, 0.5, 0.5)
    closeTex:SetText("X")
    closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(0.5, 0.5, 0.5) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetSize(POPUP_WIDTH - 20, 1)
    divider:SetPoint("TOPLEFT", 10, -30)
    divider:SetColorTexture(0.14, 0.16, 0.20, 1)

    local y = -44
    for _, line in ipairs(CHANGES) do
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        text:SetPoint("TOPLEFT", 14, y)
        text:SetWidth(CONTENT_WIDTH)
        text:SetJustifyH("LEFT")
        text:SetTextColor(0.78, 0.80, 0.84)
        text:SetText(line)
        y = y - math.max(26, (text:GetStringHeight() or 0) + 10)
    end

    -- Keep the expanded release notes above the fixed footer controls.
    frame:SetHeight(math.max(POPUP_MIN_HEIGHT, math.min(POPUP_MAX_HEIGHT, math.abs(y) + 54)))

    local divider2 = frame:CreateTexture(nil, "ARTWORK")
    divider2:SetSize(POPUP_WIDTH - 20, 1)
    divider2:SetPoint("BOTTOMLEFT", 10, 34)
    divider2:SetColorTexture(0.14, 0.16, 0.20, 1)

    local check = CreateFrame("CheckButton", nil, frame)
    check:SetSize(14, 14)
    check:SetPoint("BOTTOMLEFT", 12, 12)
    local checkBG = check:CreateTexture(nil, "BACKGROUND")
    checkBG:SetAllPoints()
    checkBG:SetColorTexture(0.1, 0.1, 0.12, 1)
    local checkBorder = check:CreateTexture(nil, "BORDER")
    checkBorder:SetPoint("TOPLEFT", -1, 1)
    checkBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    checkBorder:SetColorTexture(0.3, 0.3, 0.35, 1)
    local checkMark = check:CreateFontString(nil, "OVERLAY")
    checkMark:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    checkMark:SetAllPoints()
    checkMark:SetJustifyH("CENTER")
    checkMark:SetTextColor(0.9, 0.72, 0.22, 1)
    checkMark:SetText("")
    check:SetScript("OnClick", function(self)
        local checked = not self.mmfChecked
        self.mmfChecked = checked
        checkMark:SetText(checked and "+" or "")
        if checked and MattMinimalFramesDB then
            MattMinimalFramesDB.changelogSeenVersion = CHANGELOG_VERSION
            frame:Hide()
        end
    end)

    local checkLabel = frame:CreateFontString(nil, "OVERLAY")
    checkLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    checkLabel:SetPoint("LEFT", check, "RIGHT", 6, 0)
    checkLabel:SetTextColor(0.55, 0.57, 0.62)
    checkLabel:SetText("Don't show this again")

    return frame
end

local _frame

function MMF_TryShowChangelog()
    if not MattMinimalFramesDB then
        print("|cffff9900MMF Changelog:|r DB not ready")
        return
    end
    if MattMinimalFramesDB.changelogSeenVersion == CHANGELOG_VERSION then
        return
    end
    if not _frame then
        _frame = CreateChangelogFrame()
    end
    if _frame then
        _frame:Show()
    else
        print("|cffff9900MMF Changelog:|r frame failed to create")
    end
end
