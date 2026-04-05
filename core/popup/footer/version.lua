local function GetAddonVersionText()
    local version

    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata("MattMinimalFrames", "Version")
    end

    if (not version or version == "") and GetAddOnMetadata then
        version = GetAddOnMetadata("MattMinimalFrames", "Version")
    end

    if type(version) ~= "string" or version == "" then
        version = "?.?.?"
    end

    if not version:match("^v") then
        version = "v" .. version
    end

    return version
end

function MMF_GetPopupFooterVersionText()
    return "|cFFFFE27A" .. GetAddonVersionText() .. "|r|cFFE7ECF3  |  |r|cFFFFFFFFJoin the community Discord.|r"
end
