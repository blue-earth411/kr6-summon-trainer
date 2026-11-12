local E = require("entity_db")
local SU = require("script_utils")
local U = require("utils")
local Audio = require("kr6_summon_public.trainer_audio")
local bit = require("bit")
local soldier = require("scripts").soldier_barrack
local M = {}

local function targetable(unit)
    return unit and unit.enemy and unit.health and not unit.health.dead and unit.health.hp > 0
        and unit.vis and bit.band(unit.vis.bans, F_RANGED) == 0
        and bit.band(unit.vis.flags, F_FRIEND) == 0
end

local function distance_squared(a, b)
    return (a.x - b.x)^2 + (a.y - b.y)^2
end

local function interrupted(unit, store)
    return unit._trainer_deleted or unit.health.dead or unit.unit.is_stunned
        or unit.nav_rally.new or SU.soldier_pick_melee_target(store, unit) ~= nil
end

local function launch(unit, store, target, shot)
    local spear = E:create_entity("fx")
    E:add_comps(spear, "main_script")
    local facing = unit.render.sprites[1].flip_x and -1 or 1
    local origin = {x=unit.pos.x + facing * shot.projectile_origin.x, y=unit.pos.y + shot.projectile_origin.y}
    spear.pos = {x=origin.x, y=origin.y}
    local sprite = spear.render.sprites[1]
    sprite.name, sprite.animated, sprite.prefix = shot.projectile_frame, false, nil
    sprite.anchor = {x=.5, y=.5}
    local impact = {x=target.pos.x, y=target.pos.y + (target.unit.hit_offset.y or 0)}
    local flight = math.max(.12, math.sqrt(distance_squared(origin, impact)) / 325)
    local dx, dy = impact.x-origin.x, impact.y-origin.y
    local arc = shot.projectile_arc
    sprite.r = math.atan2(dy + 4 * arc, dx)
    spear.main_script.update = function(projectile, s)
        local start = s.tick_ts
        while s.tick_ts - start < flight do
            local phase = (s.tick_ts - start) / flight
            projectile.pos.x = origin.x + dx * phase
            projectile.pos.y = origin.y + dy * phase + 4 * arc * phase * (1 - phase)
            sprite.r = math.atan2(dy + 4 * arc * (1 - 2 * phase), dx)
            coroutine.yield()
        end
        if targetable(target) and s.entities[target.id] == target then
            local hit = E:create_entity("damage")
            hit.source_id, hit.target_id = unit.id, target.id
            hit.damage_type = DAMAGE_PHYSICAL
            hit.value = math.random(shot.proyectile.damage_min, shot.proyectile.damage_max)
            table.insert(s.damage_queue, hit)
        end
        table.insert(s.pending_removals, projectile)
    end
    table.insert(store.pending_inserts, spear)
    Audio.play(shot.proyectile.release_sound)
end

local function try_throw(unit, store)
    if interrupted(unit, store) then return end
    local shot = unit._shots[1]
    if store.tick_ts - shot.ts < shot.cooldown then return end
    local target, nearest
    for _, enemy in pairs(store.entities) do
        if targetable(enemy) and enemy.pos then
            local distance = distance_squared(unit.pos, enemy.pos)
            if distance >= shot.range_min^2 and distance <= shot.range^2
                and (not nearest or distance < nearest or distance == nearest and enemy.id < target.id) then
                target, nearest = enemy, distance
            end
        end
    end
    if not target then return end
    shot.ts = store.tick_ts
    U.animation_start(unit, "throw", target.pos.x < unit.pos.x, shot.ts, false)
    while store.tick_ts - shot.ts < shot.action_time - 1e-7 do
        if interrupted(unit, store) then break end
        coroutine.yield()
    end
    if not interrupted(unit, store) and targetable(target)
        and distance_squared(unit.pos, target.pos) <= shot.range^2 then
        launch(unit, store, target, shot)
        while not interrupted(unit, store) and not U.animation_finished(unit) do
            coroutine.yield()
        end
    end
    U.animation_start(unit, "idle", nil, store.tick_ts, true)
end

function M.create()
    local unit = E:create_entity("soldier_paladin")
    unit.powers, unit.timed_actions, unit.ranged, unit.auras = nil, nil, nil, nil
    unit.dodge, unit.cloak = nil, nil
    local attack = unit.melee.attacks[1]
    attack.damage_type, attack.hit_times, attack.pop, attack.sound = DAMAGE_PHYSICAL, nil, nil, "MeleeSword"
    unit.melee.attacks, unit.melee.order = {attack}, {1}
    unit.nav_rally.requires_node_nearby = false
    unit.render.sprites[1].angles = {walk={"running"}}
    unit.ui.can_click, unit.ui.can_select = true, true
    unit.info.random_name_format = nil
    unit.info.fn = function(entity)
        return {type=STATS_TYPE_SOLDIER, hp=entity.health.hp, hp_max=entity.health.hp_max,
            damage_min=24, damage_max=40, damage_type=DAMAGE_PHYSICAL,
            armor=entity.health.armor, magic_armor=0, respawn=entity.health.dead_lifetime}
    end
    unit.main_script.insert = function(entity, store)
        local bans = entity.vis.bans
        local result = soldier.insert(entity, store)
        entity.vis.bans = bans
        return result
    end
    unit.main_script.remove = soldier.remove
    unit.main_script.update = function(entity, store)
        local native = coroutine.create(soldier.update)
        while not entity._trainer_deleted and coroutine.status(native) ~= "dead" do
            local name = entity.render.sprites[1].name
            if name == "idle" or name == "idleBlock" then
                try_throw(entity, store)
            end
            if entity._trainer_deleted then return end
            local ok, err = coroutine.resume(native, entity, store, entity.main_script)
            if not ok then error(err) end
            if coroutine.status(native) ~= "dead" then coroutine.yield() end
        end
    end
    return unit
end

return M
