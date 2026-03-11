function MMF_CreateProfilesPage(popup, parent, accentColor)
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"

    local function NormalizeProfileName(name)
        if type(name) ~= "string" then return "" end
        return name:gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function BuildProfileOptions(names)
        local out = {}
        for _, profileName in ipairs(names or {}) do
            out[#out + 1] = { value = profileName, label = profileName }
        end
        return out
    end

    local function BuildDeleteProfileNames(allNames, activeName)
        local out = {}
        for _, profileName in ipairs(allNames or {}) do
            if profileName ~= "Default" and profileName ~= activeName then
                out[#out + 1] = profileName
            end
        end
        return out
    end

    local function NameExists(name, names)
        if type(name) ~= "string" or name == "" then
            return false
        end
        for _, profileName in ipairs(names or {}) do
            if profileName == name then
                return true
            end
        end
        return false
    end

    local profileNames = MMF_GetProfileNames and MMF_GetProfileNames() or { "Default" }
    local selectedProfileName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
    local deleteTargetName
    local deleteProfileNames = {}
    local profileDropdown
    local deleteDropdown
    local SetProfileFeedback
    local RefreshProfilesUI

    local profilesTitle = parent:CreateFontString(nil, "OVERLAY")
    profilesTitle:SetFont(fontPath, 12, "")
    profilesTitle:SetPoint("TOPLEFT", 12, -12)
    profilesTitle:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
    profilesTitle:SetText("PROFILES")

    local profilesSubtext = parent:CreateFontString(nil, "OVERLAY")
    profilesSubtext:SetFont(fontPath, 10, "")
    profilesSubtext:SetPoint("TOPLEFT", 12, -32)
    profilesSubtext:SetTextColor(0.65, 0.65, 0.7)
    profilesSubtext:SetText("Switch instantly, create default/copy profiles, then manage old profiles below.")

    local activeProfileLabel = parent:CreateFontString(nil, "OVERLAY")
    activeProfileLabel:SetFont(fontPath, 10, "")
    activeProfileLabel:SetPoint("TOPLEFT", 12, -60)
    activeProfileLabel:SetTextColor(0.8, 0.8, 0.8)
    activeProfileLabel:SetText("Active Profile")

    local activeProfileValue = parent:CreateFontString(nil, "OVERLAY")
    activeProfileValue:SetFont(fontPath, 10, "")
    activeProfileValue:SetPoint("LEFT", activeProfileLabel, "RIGHT", 10, 0)
    activeProfileValue:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
    activeProfileValue:SetText("")

    local profileFeedback = parent:CreateFontString(nil, "OVERLAY")
    profileFeedback:SetFont(fontPath, 10, "")
    profileFeedback:SetPoint("TOPLEFT", 12, -272)
    profileFeedback:SetWidth(300)
    profileFeedback:SetJustifyH("LEFT")
    profileFeedback:SetText("")

    SetProfileFeedback = function(msg, isError)
        if isError then
            profileFeedback:SetTextColor(1, 0.35, 0.35)
        else
            profileFeedback:SetTextColor(0.6, 0.9, 0.6)
        end
        profileFeedback:SetText(msg or "")
    end

    profileDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accentColor,
        fontPath = fontPath,
        x = 12,
        y = -84,
        width = 300,
        labelWidth = 62,
        buttonOffset = 64,
        buttonWidth = 220,
        visibleRows = 8,
        label = "Profile",
        options = BuildProfileOptions(profileNames),
        getValue = function()
            return selectedProfileName
        end,
        onSelect = function(value)
            selectedProfileName = value
            local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
            if value == activeName then
                return
            end
            if MMF_SwitchProfile and MMF_SwitchProfile(value) then
                SetProfileFeedback("Switched profile: " .. value, false)
                RefreshProfilesUI()
            else
                SetProfileFeedback("Could not switch profile.", true)
            end
        end,
    })

    local createProfileLabel = parent:CreateFontString(nil, "OVERLAY")
    createProfileLabel:SetFont(fontPath, 10, "")
    createProfileLabel:SetPoint("TOPLEFT", 12, -118)
    createProfileLabel:SetTextColor(0.8, 0.8, 0.8)
    createProfileLabel:SetText("New Profile")
    createProfileLabel:SetWidth(72)
    createProfileLabel:SetJustifyH("LEFT")

    local createProfileInputBG = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    createProfileInputBG:SetSize(220, 20)
    createProfileInputBG:SetPoint("TOPLEFT", 76, -116)
    createProfileInputBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    createProfileInputBG:SetBackdropColor(0.06, 0.06, 0.08, 1)
    createProfileInputBG:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local createProfileInput = CreateFrame("EditBox", nil, createProfileInputBG)
    createProfileInput:SetAllPoints(createProfileInputBG)
    createProfileInput:SetAutoFocus(false)
    createProfileInput:SetFont(fontPath, 10, "")
    createProfileInput:SetJustifyH("LEFT")
    createProfileInput:SetJustifyV("MIDDLE")
    createProfileInput:SetTextInsets(6, 6, 0, 0)
    createProfileInput:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
    createProfileInput:SetMaxLetters(24)

    createProfileInputBG:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.6)
    end)
    createProfileInputBG:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    local dividerProfiles = parent:CreateTexture(nil, "ARTWORK")
    dividerProfiles:SetSize(300, 1)
    dividerProfiles:SetPoint("TOPLEFT", 12, -182)
    dividerProfiles:SetColorTexture(0.12, 0.12, 0.15, 1)

    local createProfileBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    createProfileBtn:SetSize(108, 22)
    createProfileBtn:SetPoint("TOPLEFT", 76, -148)
    createProfileBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    createProfileBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    createProfileBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local createProfileBtnText = createProfileBtn:CreateFontString(nil, "OVERLAY")
    createProfileBtnText:SetFont(fontPath, 10, "")
    createProfileBtnText:SetPoint("CENTER")
    createProfileBtnText:SetText("Create Default")
    createProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    createProfileBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        createProfileBtnText:SetTextColor(1, 1, 1)
    end)
    createProfileBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        createProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)

    local copyProfileBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    copyProfileBtn:SetSize(108, 22)
    copyProfileBtn:SetPoint("TOPLEFT", 188, -148)
    copyProfileBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    copyProfileBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    copyProfileBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local copyProfileBtnText = copyProfileBtn:CreateFontString(nil, "OVERLAY")
    copyProfileBtnText:SetFont(fontPath, 10, "")
    copyProfileBtnText:SetPoint("CENTER")
    copyProfileBtnText:SetText("Copy Active")
    copyProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    copyProfileBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        copyProfileBtnText:SetTextColor(1, 1, 1)
    end)
    copyProfileBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        copyProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)

    local deleteSectionTitle = parent:CreateFontString(nil, "OVERLAY")
    deleteSectionTitle:SetFont(fontPath, 10, "")
    deleteSectionTitle:SetPoint("TOPLEFT", 12, -194)
    deleteSectionTitle:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
    deleteSectionTitle:SetText("DELETE / RESET")

    deleteDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accentColor,
        fontPath = fontPath,
        x = 12,
        y = -212,
        width = 300,
        labelWidth = 62,
        buttonOffset = 64,
        buttonWidth = 220,
        visibleRows = 6,
        label = "Profile",
        placeholderText = "Select profile...",
        optionsProvider = function()
            local all = MMF_GetProfileNames and MMF_GetProfileNames() or { "Default" }
            local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
            deleteProfileNames = BuildDeleteProfileNames(all, activeName)
            if #deleteProfileNames == 0 then
                SetProfileFeedback("No deletable profiles available.", true)
            end
            return BuildProfileOptions(deleteProfileNames)
        end,
        onSelect = function(value)
            deleteTargetName = value
        end,
    })

    local deleteProfileBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    deleteProfileBtn:SetSize(120, 22)
    deleteProfileBtn:SetPoint("TOPLEFT", 64, -240)
    deleteProfileBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    deleteProfileBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    deleteProfileBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local deleteProfileBtnText = deleteProfileBtn:CreateFontString(nil, "OVERLAY")
    deleteProfileBtnText:SetFont(fontPath, 10, "")
    deleteProfileBtnText:SetPoint("CENTER")
    deleteProfileBtnText:SetText("Delete Profile")
    deleteProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    deleteProfileBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        deleteProfileBtnText:SetTextColor(1, 0.4, 0.4)
    end)
    deleteProfileBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        deleteProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)

    local resetActiveProfileBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    resetActiveProfileBtn:SetSize(120, 22)
    resetActiveProfileBtn:SetPoint("TOPLEFT", 192, -240)
    resetActiveProfileBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    resetActiveProfileBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    resetActiveProfileBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local resetActiveProfileBtnText = resetActiveProfileBtn:CreateFontString(nil, "OVERLAY")
    resetActiveProfileBtnText:SetFont(fontPath, 10, "")
    resetActiveProfileBtnText:SetPoint("CENTER")
    resetActiveProfileBtnText:SetText("Reset Current")
    resetActiveProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    resetActiveProfileBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        resetActiveProfileBtnText:SetTextColor(1, 1, 1)
    end)
    resetActiveProfileBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        resetActiveProfileBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)

    local function CreateProfileFromInput(copyFrom, feedbackText)
        local name = NormalizeProfileName(createProfileInput:GetText())
        if name == "" then
            SetProfileFeedback("Enter a profile name.", true)
            return
        end

        local ok, err = MMF_CreateProfile and MMF_CreateProfile(name, copyFrom)
        if not ok then
            SetProfileFeedback(err or "Could not create profile.", true)
            return
        end

        selectedProfileName = name
        createProfileInput:SetText("")
        if MMF_SwitchProfile and MMF_SwitchProfile(name) then
            RefreshProfilesUI()
            SetProfileFeedback((feedbackText or "Created profile") .. ": " .. name, false)
        else
            RefreshProfilesUI()
            SetProfileFeedback("Created profile, but could not switch.", true)
        end
    end

    RefreshProfilesUI = function()
        profileNames = MMF_GetProfileNames and MMF_GetProfileNames() or { "Default" }
        local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"

        if not NameExists(selectedProfileName, profileNames) then
            selectedProfileName = activeName
        end
        if not NameExists(selectedProfileName, profileNames) then
            selectedProfileName = profileNames[1] or "Default"
        end

        activeProfileValue:SetText(activeName)
        profileDropdown.SetOptions(BuildProfileOptions(profileNames))
        profileDropdown.SetSelectedValue(selectedProfileName)

        deleteProfileNames = BuildDeleteProfileNames(profileNames, activeName)
        if not NameExists(deleteTargetName, deleteProfileNames) then
            deleteTargetName = deleteProfileNames[1]
        end
        deleteDropdown.SetOptions(BuildProfileOptions(deleteProfileNames))
        deleteDropdown.SetSelectedValue(deleteTargetName)
    end

    createProfileBtn:SetScript("OnClick", function()
        CreateProfileFromInput(false, "Created default profile")
    end)

    copyProfileBtn:SetScript("OnClick", function()
        local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
        CreateProfileFromInput(activeName, "Copied active profile")
    end)

    createProfileInput:SetScript("OnEnterPressed", function()
        createProfileBtn:Click()
        createProfileInput:ClearFocus()
    end)
    createProfileInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    deleteProfileBtn:SetScript("OnClick", function()
        if not deleteTargetName then
            SetProfileFeedback("Select a profile to delete.", true)
            return
        end

        local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
        if deleteTargetName == "Default" then
            SetProfileFeedback("Default profile cannot be deleted.", true)
            return
        end
        if deleteTargetName == activeName then
            SetProfileFeedback("Switch away from this profile before deleting.", true)
            return
        end

        local profileToDelete = deleteTargetName
        _G.MMF_OnConfirmProfileDelete = function()
            if MMF_DeleteProfile and MMF_DeleteProfile(profileToDelete) then
                SetProfileFeedback("Deleted profile: " .. profileToDelete, false)
                deleteTargetName = nil
                RefreshProfilesUI()
            else
                SetProfileFeedback("Could not delete profile.", true)
            end
        end
        StaticPopup_Show("MMF_DELETE_PROFILE_WARNING", profileToDelete)
    end)

    resetActiveProfileBtn:SetScript("OnClick", function()
        local activeName = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
        _G.MMF_OnConfirmProfileReset = function()
            if MMF_ResetActiveProfile and MMF_ResetActiveProfile() then
                SetProfileFeedback("Reset profile: " .. activeName, false)
                RefreshProfilesUI()
                return
            end
            if MMF_ResetProfile and MMF_ResetProfile(activeName) then
                SetProfileFeedback("Reset profile: " .. activeName, false)
                RefreshProfilesUI()
            else
                SetProfileFeedback("Could not reset profile.", true)
            end
        end
        StaticPopup_Show("MMF_RESET_PROFILE_WARNING", activeName)
    end)

    RefreshProfilesUI()

    return {
        profileSelectList = profileDropdown.list,
        deleteProfileSelectList = deleteDropdown.list,
    }
end
