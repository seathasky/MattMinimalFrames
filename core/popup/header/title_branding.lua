function MMF_GetPopupHeaderBranding(config)
    config = config or {}
    local compat = config.compat or (_G.MMF_Compat or {})

    if compat.IsTBC then
        return {
            titleText = "|cffffffffMatt's Minimal Frames ",
            suffixText = "TBC EDITION",
            suffixColor = { 0.2, 0.9, 0.4 },
        }
    end

    return {
        titleText = "|cffffffffMatt's Minimal Frames ",
        suffixText = "MIDNIGHT EDITION",
        suffixColor = { 0.6, 0.4, 0.9 },
    }
end
