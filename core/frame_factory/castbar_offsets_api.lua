local function Install(castbarOffsets)
    castbarOffsets = castbarOffsets or _G.MMF_FrameFactoryCastbarOffsets or {}

    _G.MMF_ApplyCastBarPosition = castbarOffsets.ApplyCastBarPosition
    _G.MMF_GetCastBarDefaultOffsetForUnit = castbarOffsets.GetCastBarDefaultOffsetForUnit
    _G.MMF_GetCastBarOffsetForUnit = castbarOffsets.GetCastBarOffsetForUnit
    _G.MMF_SetCastBarOffsetForUnit = castbarOffsets.SetCastBarOffsetForUnit
    _G.MMF_ResetCastBarOffsetForUnit = castbarOffsets.ResetCastBarOffsetForUnit
    _G.MMF_IsCastBarOffsetDefaultForUnit = castbarOffsets.IsCastBarOffsetDefaultForUnit
    _G.MMF_SyncCastBarOffsetControlsForUnit = castbarOffsets.UpdateCastBarOffsetControlsForUnit
end

_G.MMF_FrameFactoryCastbarOffsetsAPI = {
    Install = Install,
}
