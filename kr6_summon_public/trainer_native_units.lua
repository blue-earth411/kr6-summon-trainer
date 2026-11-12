local E=require('entity_db')
local U=require('utils')
local SU=require('script_utils')
local I=require('klove.image_db')
local A=require('klove.animation_db')
local EXO=require('exoskeleton')
local barrack=require('scripts').soldier_barrack
local Audio=require('kr6_summon_public.trainer_audio')
local band=require('bit').band
local M={}

local asset_root='_assets/kr6-desktop/images/fullhd_bc3'
local reference_scale=768/1080
local miner_walk_distance=60
local miner_tunnel_speed_factor=0.7
local sound_groups={knights='TowerKnightsOrder',wildcat='TowerWildcatHuntresses',miners='TowerGoldProspectors',
    crossbows='TowerCursedCrossbows',alchemist='TowerAlchemistShack',sunray_master='TowerMinorElementals'}
local function copy_pos(point) return {x=point.x,y=point.y} end
local function load_assets(group,options)
    options=options or {}
    local atlas_name=options.atlas or 'go_towers_'..group
    local atlas=assert(love.filesystem.load(asset_root..'/'..atlas_name..'.lua'))()
    local animations={}
    if options.animations~=false then
        local dir=KR_PATH_GAME..'/data/animations/'..atlas_name
        animations=assert(love.filesystem.load(dir..'/tower_'..group..'.lua'))()
    end
    for name,frame in pairs(atlas) do
        local current=I.db_atlas[name]
        if not current or not I.db_images[current.atlas] then
            local key='trainer_native_'..group..'_'..frame.a_name
            if not I.db_images[key] then
                local _,image,w,h=I:load_image_file(frame.a_name,asset_root)
                assert(image,'Missing native unit texture '..frame.a_name)
                I.db_images[key]={image,w,h}
            end
            frame.atlas=key;frame.group='trainer_native_'..group;frame.ref_scale=reference_scale
            local q,s=frame.f_quad,frame.a_size
            frame.quad=love.graphics.newQuad(q[1],q[2],q[3],q[4],s[1],s[2])
            I.db_atlas[name]=frame
        else
            frame=current
        end
        for _,alias in ipairs(frame.alias or {}) do I.db_atlas[alias]=frame end
    end
    for name,animation in pairs(animations.animations or animations) do
        if not A.db[name] then A.db[name]=animation end
    end
    if not A.db.stun_small_loop then
        local mods=assert(love.filesystem.load(KR_PATH_GAME..'/data/animations/go_towers/tower_mods.lua'))()
        for name,animation in pairs(mods.animations or mods) do
            if not A.db[name] then A.db[name]=animation end
        end
    end
    if group=='miners' and not A.db.unit_lvl_4Def_buriedOut then
        EXO:load({'unit_lvl_4Def','emerging_blastDef','emerging_blast_floorDef','emerging_blast_backDef','hitDef'},
            'trainer_native_miners','go_towers_miners')
    end
    if options.exos and (not A.db.sigil_lvl3Def_loop or not EXO.exos or not EXO.exos.sigil_lvl3Def) then
        EXO:load(options.exos,'trainer_native_'..group,atlas_name)
    end
end
M.load_assets=load_assets

local function queue(store,entity)
    if simulation and simulation.store==store then
        simulation:queue_insert_entity(entity)
    else
        table.insert(store.pending_inserts,entity)
    end
end

local function remove(store,entity)
    if simulation and simulation.store==store then
        simulation:queue_remove_entity(entity)
    else
        table.insert(store.pending_removals,entity)
    end
end

local function sound(key)
    if key then Audio.play(key) end
end

local function resume(co,entity,store,script)
    local ok,err=coroutine.resume(co,entity,store,script)
    if not ok then error(err) end
    return coroutine.status(co)~='dead'
end

local function emergence(miner,store)
    local skill=miner.powers.skill_b
    local aura=E:create_entity(skill.auras[skill.level])
    aura.pos=copy_pos(miner.pos);aura.aura.source_id=miner.id;aura.aura.ts=store.tick_ts
    aura.render=nil -- The three original decals supply the exoskeleton visuals.
    aura.main_script.update=function(this,active_store)
        local hit=this.aura
        for _,enemy in pairs(active_store.entities) do
            if enemy.enemy and enemy.unit and enemy.health and not enemy.health.dead and enemy.vis
                and band(enemy.vis.flags,hit.vis_bans)==0 and band(enemy.vis.bans,hit.vis_flags)==0
                and U.is_inside_ellipse(enemy.pos,this.pos,hit.radius) then
                local damage=E:create_entity('damage')
                damage.source_id=miner.id;damage.target_id=enemy.id
                damage.damage_type=hit.damage_type;damage.value=math.random(hit.damage_min,hit.damage_max)
                table.insert(active_store.damage_queue,damage)
                local stun=E:create_entity(hit.mod)
                stun.modifier.level=skill.level
                stun.modifier.duration=stun.modifier.duration[skill.level]
                stun.modifier.source_id=miner.id;stun.modifier.target_id=enemy.id
                stun.modifier.ts=active_store.tick_ts
                queue(active_store,stun)
            end
        end
        remove(active_store,this)
    end
    queue(store,aura)
    for _,name in ipairs(skill.visuals) do
        local visual=E:create_entity(name)
        visual.pos=copy_pos(miner.pos);visual.render.sprites[1].ts=store.tick_ts
        queue(store,visual)
    end
end

local function miner_update(miner,store,script)
    local combat=coroutine.create(barrack.update)
    local entry=true
    while true do
        if not miner.health.dead and (entry or miner._public_tunnel_goal) then
            U.unblock_target(store,miner)
            local bans=miner.vis._bans or miner.vis.bans
            miner.vis._bans=nil;miner.vis.bans=F_ALL
            miner._in_transit=true
            if not entry then U.y_animation_play(miner,miner.bury_in_anim,nil,store.tick_ts,1,1) end
            entry=false
            while miner._public_tunnel_goal and not miner.health.dead do
                local goal=miner._public_tunnel_goal
                local origin=copy_pos(miner.pos)
                local start=store.tick_ts
                local duration=miner.tunneling_time/miner_tunnel_speed_factor
                local animation,flip=U.animation_name_facing_point(miner,'bury',goal)
                U.animation_start(miner,animation,flip,start,true,1)
                while not miner.health.dead and miner._public_tunnel_goal==goal do
                    local fraction=math.min(1,(store.tick_ts-start)/duration)
                    miner.pos.x=origin.x+(goal.x-origin.x)*fraction
                    miner.pos.y=origin.y+(goal.y-origin.y)*fraction
                    if fraction==1 then miner._public_tunnel_goal=nil;break end
                    coroutine.yield()
                end
            end
            miner.vis.bans=bans;miner._in_transit=nil
            if not miner.health.dead then
                miner.nav_rally.pos=copy_pos(miner.pos);miner.nav_rally.center=copy_pos(miner.pos)
                miner.nav_rally.new=false;miner.motion.arrived=true
                emergence(miner,store)
                U.y_animation_play(miner,miner.bury_out_anim,nil,store.tick_ts,1,1)
                combat=coroutine.create(barrack.update)
            end
        end
        if not resume(combat,miner,store,script) then return end
        coroutine.yield()
    end
end

function M.move_miner(miner,point)
    local dx,dy=point.x-miner.pos.x,point.y-miner.pos.y
    if not miner._in_transit and dx*dx+dy*dy<=miner_walk_distance*miner_walk_distance then
        miner._public_tunnel_goal=nil
        return false
    end
    U.unblock_target(game.store,miner)
    miner._public_tunnel_goal={x=point.x,y=point.y}
    miner.motion.forced_waypoint=nil
    miner.nav_rally.new=false
    return true
end

local function summon_update(entry,seconds)
    return function(unit,store,script)
        local until_ts=seconds and store.tick_ts+seconds
        if seconds then
            unit.reinforcement.ts=store.tick_ts
            -- These standalone units leave through their native death cels.
            unit.reinforcement.fade=false
        end
        sound(unit.sound_events.raise)
        for _,animation in ipairs(entry) do U.y_animation_play(unit,animation,nil,store.tick_ts,1,1) end
        local combat=coroutine.create(barrack.update)
        while true do
            if until_ts and (store.tick_ts>=until_ts or unit.health.dead) then
                if not unit.health.dead then unit.health.death_ts=store.tick_ts end
                unit.health.hp=0;unit.health.dead=true;unit.vis.bans=F_ALL
                unit.ui.can_click=false;unit.health_bar.hidden=true
                U.unblock_target(store,unit)
                SU.remove_modifiers(store,unit)
                sound(unit.sound_remove_1)
                U.y_animation_play(unit,unit.animation_death or 'death',nil,store.tick_ts,1,1)
                remove(store,unit)
                return
            end
            if not resume(combat,unit,store,script) then return end
            coroutine.yield()
        end
    end
end

local function wildcat_ultimate(unit)
    local original=unit.main_script.update
    local on_remove=unit.main_script.remove
    local tower=E:create_entity('tower_wildcat_lvl4')
    local action=tower.timed_attacks.list[1]
    -- The native arrow volley stores its cooldown on the parent tower. Give
    -- this soldier a private context only while its coroutine is executing.
    local context={tower={damage_factor=1}}
    unit.soldier.tower_id=tower.id
    unit.main_script.update=function(this,store,script)
        local combat=coroutine.create(original)
        local next_cast=store.tick_ts+action.cooldown
        local controller
        while true do
            if not this.health.dead and not this.unit.is_stunned and not this.nav_rally.new and store.tick_ts>=next_cast then
                local enemy=U.find_foremost_enemy(store.entities,this.pos,0,action.range,nil,F_RANGED,F_FLYING)
                if enemy and not enemy.health.dead then
                    if not controller then
                        controller=E:create_entity(action.controller)
                        controller.source_id=this.id;controller.info_tower={tower={}}
                        this._public_ultimate_controller=controller
                        queue(store,controller)
                    end
                    controller.pos=copy_pos(this.pos)
                    controller.info_tower.tower.damage_factor=this.unit.damage_factor
                    controller.enemy=enemy;controller.cast_ult=true
                    next_cast=store.tick_ts+action.cooldown
                end
            end
            store.entities[tower.id]=context
            local ok,err=coroutine.resume(combat,this,store,script)
            store.entities[tower.id]=nil
            if not ok then error(err) end
            if coroutine.status(combat)=='dead' then return end
            coroutine.yield()
        end
    end
    unit.main_script.remove=function(this,store,script)
        if this._public_ultimate_controller then remove(store,this._public_ultimate_controller) end
        return on_remove(this,store,script)
    end
end

function M.create(def)
    if def.group then
        load_assets(def.group)
        Audio.prepare_group(sound_groups[def.group])
    end
    local unit=E:create_entity(def.entity)
    if not unit.nav_grid then E:add_comps(unit,'nav_grid') end
    for _,power in pairs(unit.powers or {}) do power.level=power.max_level end
    if def.entity=='soldier_knights_lvl4' then
        unit.powers.ultimate.active=true
    elseif def.entity=='soldier_wildcat_lvl4' then
        unit.powers.ultimate.active=true
        wildcat_ultimate(unit)
    elseif def.entity=='soldier_miners_lvl4' then
        unit.main_script.update=miner_update
        unit.main_script.remove=barrack.remove
    elseif def.entity=='soldier_crossbows_ult' then
        unit.melee.attacks[1].mod='mod_crossbows_skill_b_lvl3'
        unit.main_script.insert=barrack.insert;unit.main_script.remove=barrack.remove
        unit.main_script.update=summon_update({'in_armor','in_spectre'},unit.reinforcement.duration)
    elseif def.entity=='soldier_alchemist_skill_b_lvl3' then
        unit.main_script.insert=barrack.insert;unit.main_script.remove=barrack.remove
        unit.main_script.update=summon_update({'pecs','pecs'},unit.reinforcement.duration)
    elseif def.entity=='soldier_sunray_master_lvl3' then
        unit.main_script.update=summon_update({'raise'})
    end
    Audio.prepare_native()
    return unit
end

return M
