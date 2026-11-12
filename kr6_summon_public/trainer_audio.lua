local S = require("sound_db")
local M = {}

local function prepare(id)
    local definition = S.sounds and S.sounds[id]
    if not definition or not S.sources or not love.audio then return false end
    local path = S.files_path or "_assets/kr6-desktop/sounds/files"
    for _, file in ipairs(definition.files or {}) do
        if not S.sources[file] then
            local ok, sound = pcall(love.audio.newSource, path .. "/" .. file, "static")
            if not ok or not sound then return false end
            S.sources[file] = {sound}
            S.source_uses[file] = 1
        end
    end
    S.sound_extras[id] = S.sound_extras[id] or {}
    return true
end

function M.play(id)
    if prepare(id) then S:queue(id) end
end

function M.prepare_group(prefix)
    for id in pairs(S.sounds or {}) do
        if id:sub(1,#prefix)==prefix then prepare(id) end
    end
end

function M.prepare_native()
    for _, id in ipairs({"MeleeSword", "TowerPaladinsKr1HealingCast",
                         "TowerBarbariansKr1AxeSound", "Sound_ArrowRelease2"}) do
        prepare(id)
    end
end

return M
