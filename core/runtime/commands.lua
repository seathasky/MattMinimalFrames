local commandsRegistered = false

function MMF_RegisterSlashCommands()
    if commandsRegistered then
        return
    end

    SLASH_MATTMINIMALFRAMES1 = "/mmf"
    SlashCmdList["MATTMINIMALFRAMES"] = function()
        if MMF_ShowWelcomePopup then
            MMF_ShowWelcomePopup(true)
        end
    end

    SLASH_MMFRELOAD1 = "/rl"
    SlashCmdList["MMFRELOAD"] = ReloadUI

    commandsRegistered = true
end

MMF_RegisterSlashCommands()
