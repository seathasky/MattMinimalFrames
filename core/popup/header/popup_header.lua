function MMF_CreatePopupHeader(popup, config)
    config = config or {}

    local popupWidth = config.popupWidth
    local POPUP_LAYOUT = config.popupLayout or {}
    local ACCENT_COLOR = config.accentColor or { 0.6, 0.4, 0.9 }
    local TITLE_WALLPAPER_ALPHA = config.titleWallpaperAlpha or 0.03
    local Compat = config.compat or (_G.MMF_Compat or {})
    local SetAspectCropTexCoords = config.setAspectCropTexCoords or MMF_SetAspectCropTexCoords
    local ApplyPopupScale = config.applyPopupScale or function() end
    local IsUISoundsEnabled = config.isUISoundsEnabled or MMF_IsPopupUISoundsEnabled or function() return true end
    local headerConstants = (MMF_GetPopupHeaderConstants and MMF_GetPopupHeaderConstants()) or {}
    local headerControlLayout = (MMF_GetPopupHeaderControlLayout and MMF_GetPopupHeaderControlLayout()) or {}
    local headerBranding = (MMF_GetPopupHeaderBranding and MMF_GetPopupHeaderBranding({ compat = Compat })) or {}
    local titleBarShell = MMF_CreatePopupHeaderTitleBarShell({
        popup = popup,
        popupWidth = popupWidth,
        popupLayout = POPUP_LAYOUT,
        accentColor = ACCENT_COLOR,
        titleWallpaperAlpha = TITLE_WALLPAPER_ALPHA,
        setAspectCropTexCoords = SetAspectCropTexCoords,
        headerBranding = headerBranding,
    })
    local titleBar = titleBarShell.titleBar
    local closeX = titleBarShell.closeX
    local UpdateTitleWallpaperCrop = titleBarShell.UpdateTitleWallpaperCrop
    
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        
        local titleControlFactories = MMF_CreatePopupHeaderTitleControlFactories({
            titleBar = titleBar,
            accentColor = ACCENT_COLOR,
            fontPath = headerConstants.titleControlFont or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf",
        })
        local EnsureTitleControlFont = titleControlFactories.EnsureTitleControlFont
        local CreateTitleCheckbox = titleControlFactories.CreateTitleCheckbox
        local CreateTitleButton = titleControlFactories.CreateTitleButton
    
        local controlRefs = {
            lockFramesContainer = nil,
            editModeContainer = nil,
            testModeContainer = nil,
            lockFramesButton = nil,
            editModeButton = nil,
            testModeCheckbox = nil,
        }
        local modeController = MMF_CreatePopupHeaderModeController({
            refs = controlRefs,
            titleBar = titleBar,
            accentColor = ACCENT_COLOR,
            ensureTitleControlFont = EnsureTitleControlFont,
            refreshPopupWidgetTree = MMF_RefreshPopupWidgetTree,
        })

        local headerActions = MMF_CreatePopupHeaderActions({
            popup = popup,
            accentColor = ACCENT_COLOR,
            modeController = modeController,
        })

        controlRefs.editModeContainer, controlRefs.editModeButton = CreateTitleButton(
            closeX,
            headerControlLayout.editButtonOffsetX or -276,
            "Edit Mode",
            headerActions.OnEditModeClick,
            headerConstants.editButtonWidth or 92
        )
        modeController.SetEditModeButtonState(MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true)
        if controlRefs.editModeButton then
            MMF_AttachPopupSideTooltip(controlRefs.editModeButton, "Edit Mode", headerConstants.editTooltipLines or {})
        end

        controlRefs.testModeContainer, controlRefs.testModeCheckbox = CreateTitleCheckbox(
            controlRefs.editModeContainer,
            headerControlLayout.testCheckboxOffsetX or -8,
            "Test Mode",
            modeController.IsGlobalTestModeEnabled(),
            headerActions.OnTestModeToggle
        )
        if controlRefs.testModeContainer then
            controlRefs.testModeContainer:SetWidth(headerConstants.testContainerWidth or 96)
            controlRefs.testModeContainer:EnableMouse(true)
            MMF_AttachPopupSideTooltip(controlRefs.testModeContainer, "Test Mode", headerConstants.testTooltipLines or {})
        end
        modeController.SetTestModeCheckboxState(modeController.IsGlobalTestModeEnabled())
    
        controlRefs.lockFramesContainer, controlRefs.lockFramesButton = CreateTitleButton(
            closeX,
            headerControlLayout.lockButtonOffsetX or -136,
            "Frames Unlocked",
            headerActions.OnLockFramesClick,
            headerConstants.lockButtonWidth or 128
        )
        if controlRefs.lockFramesButton then
            MMF_AttachPopupSideTooltip(controlRefs.lockFramesButton, "Frame Lock", headerConstants.lockTooltipLines or {})
        end
    
        modeController.SyncTitleLockCheckboxState()
        popup.MMFRefreshTitleBarControls = modeController.ApplyInitialTitleBarState
    
        popup:HookScript("OnShow", function()
            modeController.ApplyInitialTitleBarState()
        end)
    
        modeController.ApplyInitialTitleBarState()
    
        MMF_CreatePopupHeaderGUIScaleControl(titleBar, closeX, popup, ACCENT_COLOR, ApplyPopupScale)

    return {
        titleBar = titleBar,
        UpdateTitleWallpaperCrop = UpdateTitleWallpaperCrop,
        ApplyInitialTitleBarState = modeController.ApplyInitialTitleBarState,
    }
end
