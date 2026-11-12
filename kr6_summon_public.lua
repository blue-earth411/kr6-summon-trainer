-- Steam launch option: -custom_script kr6_summon_public
custom_script = {}

function custom_script:init()
    if _G.KR6_TRAINER then
        print("[Summon Trainer] Another trainer is already active.")
        return
    end
    local ok, err = pcall(function()
        require("kr6_summon_public.trainer_public_panel").install()
    end)
    if not ok then
        print("[Summon Trainer] Startup failed: " .. tostring(err))
        return
    end
    print("[Summon Trainer] v1.3 loaded.")
end

return custom_script
