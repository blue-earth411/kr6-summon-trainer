local E=require('entity_db')
local U=require('utils')
local P=require('path_db')
local GR=require('grid_db')
local A=require('klove.animation_db')
local I=require('klove.image_db')
local bit=require('bit')
local Audio=require('kr6_summon_public.trainer_audio')
local M={}

local sigil_name='trainer_magus_sigil'
local sigil_mod=sigil_name..'_teleport'
local buff_name='trainer_magus_empowerment'
local body='trainer_arcane_sage'
local native_body='arcane_wizard_tower_KR1_lvl4_arcane'
local body_scale=1.1
local body_anchor={x=.5,y=1-120/341}
local function copy(p)return {x=p.x,y=p.y}end
local function dist2(a,b)return (a.x-b.x)^2+(a.y-b.y)^2 end
local function queue(store,e)
    if simulation and simulation.store==store then simulation:queue_insert_entity(e)
    else table.insert(store.pending_inserts,e)end
end
local function remove(store,e)
    if simulation and simulation.store==store then simulation:queue_remove_entity(e)
    else table.insert(store.pending_removals,e)end
end
local function alive(e)
    return e and e.health and not e.health.dead and e.health.hp>0 and not e._trainer_deleted
end
local function enemy(e)
    return alive(e) and e.enemy and not e.soldier and not e._kr6_trainer and e.pos and e.vis
end

local function animations()
    local function span(first,last)
        local frames={}
        for i=first,last,first<=last and 1 or -1 do frames[#frames+1]=i end
        return frames
    end
    local actions={idle={1},raise={1},teleport={},sigil={},empower={}}
    for i=1,30 do actions.teleport[i]=193+math.floor((i-1)*48/29)end
    for i=193,241 do actions.sigil[#actions.sigil+1]=i end
    for i=193,209 do actions.empower[#actions.empower+1]=i end
    for i=208,193,-1 do actions.empower[#actions.empower+1]=i end
    M.motion_profiles={}
    for name,frames in pairs(actions)do
     A.db[body..'_'..name]={prefix=native_body,from=1,to=#frames,frames=frames,fps=FPS}
     local profile={};for i=1,#frames do profile[i]={x=0,y=0}end
     M.motion_profiles[name]=profile
    end
    -- New hand-drawn movement and attack poses; timers and effects remain unchanged.
    local custom=assert(love.filesystem.load('kr6_summon_public/trainer_magus/animations.lua'))()
    local atlas=assert(love.filesystem.load('kr6_summon_public/trainer_magus/atlas.lua'))()
    local key='trainer_arcane_sage_motion'
    if not I.db_images[key] then
        local _,image,w,h=I:load_image_file('motion.png','kr6_summon_public/trainer_magus')
        assert(image,'Missing Archmage motion sprites')
        I.db_images[key]={image,w,h}
    end
    for name,f in pairs(atlas)do
        f.atlas=key;f.group=key;f.ref_scale=768/1080
        local q=f.f_quad
        f.quad=love.graphics.newQuad(q[1],q[2],q[3],q[4],f.a_size[1],f.a_size[2])
        I.db_atlas[name]=f
    end
    for name,a in pairs(custom)do
        A.db[body..'_'..name]=a
        -- The art already contains the gait and cloth movement; don't bob it twice.
        M.motion_profiles[name]=nil
    end
    local badge_key='trainer_arcane_sage_empowered'
    if not I.db_images[badge_key] then
        local _,image,w,h=I:load_image_file('empowered.png','kr6_summon_public/trainer_magus')
        assert(image,'Missing tower empowerment badge')
        I.db_images[badge_key]={image,w,h}
    end
    I.db_atlas[badge_key]={atlas=badge_key,group=badge_key,ref_scale=768/1080,
        a_size={64,40},f_quad={0,0,64,40},size={64,40},trim={0,0,0,0},
        quad=love.graphics.newQuad(0,0,64,40,64,40)}
    A.db[body..'_forge']=table.deepclone(A.db[body..'_arcane_bolt'])
    A.db[body..'_mirrors']=table.deepclone(A.db[body..'_empower'])
    M.motion_profiles.forge=nil;M.motion_profiles.mirrors=nil
    local smoke=assert(love.filesystem.load('kr6_summon_public/trainer_magus/smoke.lua'))()
    local smoke_key='trainer_arcane_illusion_smoke'
    if not I.db_images[smoke_key]then
        local _,image,w,h=I:load_image_file('smoke.png','kr6_summon_public/trainer_magus')
        I.db_images[smoke_key]={assert(image),w,h}
    end
    for name,f in pairs(smoke)do
        f.atlas=smoke_key;f.group=smoke_key;f.ref_scale=768/1080
        local q=f.f_quad
        f.quad=love.graphics.newQuad(q[1],q[2],q[3],q[4],f.a_size[1],f.a_size[2])
        I.db_atlas[name]=f
    end
    A.db[smoke_key..'_run']={prefix=smoke_key,from=1,to=8,fps=12}
    local death=assert(love.filesystem.load('kr6_summon_public/trainer_magus/death.lua'))()
    local death_key='trainer_arcane_sage_death'
    if not I.db_images[death_key]then
        local _,image,w,h=I:load_image_file('death.png','kr6_summon_public/trainer_magus')
        I.db_images[death_key]={assert(image),w,h}
    end
    for name,f in pairs(death)do
        f.atlas=death_key;f.group=death_key;f.ref_scale=768/1080
        local q=f.f_quad
        f.quad=love.graphics.newQuad(q[1],q[2],q[3],q[4],f.a_size[1],f.a_size[2])
        I.db_atlas[name]=f
    end
    local death_frames={}
    for i=1,46 do death_frames[i]=math.min(8,1+math.floor((i-1)*8/46))end
    A.db[body..'_death']={prefix=death_key,from=1,to=46,frames=death_frames,fps=30}
    M.motion_profiles.death=nil
    -- A head-and-shoulders crop of the actual classic KR6 caster, sharing its texture.
    local portrait=table.deepclone(assert(I.db_atlas[native_body..'_0001']))
    local q=portrait.f_quad
    portrait.f_quad={q[1]+3,q[2],27,24};portrait.size={27,24};portrait.trim={0,0,0,0}
    portrait.ref_scale=2 -- 54x48 UI pixels, matching the original KR4 head portrait.
    portrait.quad=love.graphics.newQuad(q[1]+3,q[2],27,24,portrait.a_size[1],portrait.a_size[2])
    I.db_atlas[body..'_portrait']=portrait
end

local function buff_insert(this,store)
    local target=store.entities[this.modifier.target_id]
    if not target or not target.tower or target.pending_removal then return false end
    target.tower.damage_factor=target.tower.damage_factor*this.damage_factor
    this._target=target
    return true
end

local function buff_remove(this,store)
    local target=this._target
    if target and target.tower then
        target.tower.damage_factor=target.tower.damage_factor/this.damage_factor
    end
    this._target=nil
    return true
end

local function buff_update(this,store)
    local m=this.modifier
    while store.tick_ts-m.ts<m.duration do
        local target=store.entities[m.target_id]
        if not target then
            for _,pending in ipairs(store.pending_inserts)do
                if pending.id==m.target_id then target=pending;break end
            end
        end
        if not target or not target.tower or target.pending_removal then break end
        if target~=this._target then
            buff_remove(this,store)
            target.tower.damage_factor=target.tower.damage_factor*this.damage_factor
            this._target=target
        end
        this.pos=copy(target.pos)
        coroutine.yield()
    end
    remove(store,this)
end

local function has_branch(id)
    local up=package.loaded.upgrades
    local levels=up and up.levels and up.levels.power_teleportation_sigil
    return levels and table.contains(levels,id)
end

-- Native Arcane ray tick/remainder behavior, with one multiplier applied after
-- the native integer roll. This is exactly +20%, without rounding the range or
-- multiplying again by the caster's general unit damage factor.
local function normal_ray_damage(this,store)
    local m,dps=this.modifier,this.dps
    local target=store.entities[m.target_id]
    if not target or target.health.dead then remove(store,this);return end
    local raw=math.random(dps.damage_min,dps.damage_max)*1.2
    local extra=math.max(0,raw-target.health.hp)
    local cycles,total=0,m.duration/dps.damage_every
    local tick=math.floor((raw-extra)/total)
    local first=raw-extra-tick*total
    local function hit(value)
        local d=E:create_entity('damage')
        d.source_id=this.id;d.target_id=target.id;d.value=value
        d.damage_type=dps.damage_type;d.pop=dps.pop
        d.pop_chance=dps.pop_chance;d.pop_conds=dps.pop_conds
        table.insert(store.damage_queue,d)
    end
    this.pos=target.pos;dps.ts=store.tick_ts;m.ts=store.tick_ts
    while true do
        target=store.entities[m.target_id]
        if not target or target.health.dead then break end
        if cycles>=total then hit(extra);break end
        if this.render and m.use_mod_offset and target.unit.hit_offset then
            for _,r in ipairs(this.render.sprites)do r.offset=copy(target.unit.hit_offset)end
        end
        if store.tick_ts-dps.ts>=dps.damage_every then
            cycles=cycles+1;dps.ts=dps.ts+dps.damage_every
            hit(tick+(cycles==1 and first or 0))
        end
        coroutine.yield()
    end
    remove(store,this)
end

local function templates()
    -- Clone the native sigil, keeping its teleport, damage, silence and stun handlers.
    -- Mandatory ranks are maxed. Branches follow the player's choices, defaulting to A.
    local mod=E.entities[sigil_mod] or E:register_t(sigil_mod,'mod_teleportation_sigil_teleport')
    mod.instakill_chance=.2;mod.instakill_min_hp=50;mod.second_tp_chance=.3
    mod.mod_slow=has_branch('l2b') and 'mod_power_teleportation_sigil_slow' or nil
    mod.modifier.duration=has_branch('l2b') and 1 or 2
    mod.mod_stun=has_branch('l5b') and 'mod_teleportation_sigil_stun' or nil
    local silence=E.entities[sigil_name..'_silence'] or E:register_t(sigil_name..'_silence','mod_teleportation_sigil_silence')
    silence.render.sprites[1].prefix=nil
    silence.render.sprites[1].name='trainer_public_arcane_0001'
    silence.render.sprites[1].alpha=0
    mod.mod_silence=not has_branch('l5b') and sigil_name..'_silence' or nil
    mod.mod_damage_red=not has_branch('l5b') and 'mod_teleportation_sigil_damage_red' or nil
    local decal=E.entities[sigil_name..'_decal'] or E:register_t(sigil_name..'_decal','decal_teleportation_sigil')
    decal.render.sprites[1].prefix='sigil_lvl3Def'
    local sigil=E:register_t(sigil_name,'aura_teleportation_sigil')
    sigil.mod_teleport=sigil_mod;sigil.portal_decal=decal.template_name
    sigil.max_count=has_branch('l4b') and 6 or 4

    -- Clone the native modifier visuals and cadence; multiply its raw roll once.
    local ray_mod=E.entities.trainer_magus_arcane_ray or E:register_t('trainer_magus_arcane_ray','mod_ray_arcane')
    local base=E.entities.mod_ray_arcane.dps
    ray_mod.dps.damage_min=base.damage_min;ray_mod.dps.damage_max=base.damage_max
    ray_mod.main_script.update=normal_ray_damage
    local buff=E.entities[buff_name] or E:register_t(buff_name,'modifier')
    E:add_comps(buff,'render')
    buff.damage_factor=1.4
    buff.modifier.duration=8;buff.modifier.type=buff_name
    buff.modifier.level=3;buff.modifier.keep_on_tower_upgrade=true
    buff.modifier.use_mod_offset=false
    buff.main_script.insert=buff_insert
    buff.main_script.remove=buff_remove
    buff.main_script.update=buff_update
    local r=buff.render.sprites[1]
    r.prefix=nil;r.name='trainer_arcane_sage_empowered';r.animated=false
    r.anchor={x=.5,y=.5};r.offset={x=0,y=85};r.z=Z_EFFECTS or 3300
    r.scale={x=1,y=1};r.alpha=255
    local ring=table.deepclone(r)
    ring.prefix='trainer_public_arcane_shoot_decal';ring.name='run';ring.animated=true;ring.loop=true
    ring.offset={x=0,y=2};ring.z=Z_DECALS or 1400;ring.scale={x=1.35,y=1.35}
    buff.render.sprites[2]=ring
end

function M.load_assets()
    local loader=require('kr6_summon_public.trainer_native_units')
    loader.load_assets('magus_sigil',{atlas='go_power_teleportation_sigil',animations=false,
        exos={'sigil_lvl1Def','sigil_lvl2Def','sigil_lvl3Def','portal_particlesDef',
            'tp_fx_fuerteDef','fx_instakillDef','tp_desintegration_bigDef','tp_fx_defaultDef',
            'decal_tp_largoDef','desintegration_smallDef'}})
    loader.load_assets('mage_kr1')
    loader.load_assets('forger')
    Audio.prepare_group('TowerArcaneForger')
    require('kr6_summon_public.trainer_archmage_core').load_assets()
    animations()
    Audio.prepare_group('PowersTeleportSigil')
    Audio.prepare_group('TowerArcaneKr1')
end

function M.setup(this,store)
    M.load_assets()
    if not E.entities[sigil_name] then templates()end
    this._sigil={range=this._teleport.range/2,cooldown=30,ts=store.tick_ts-30}
    this._disintegrate={range=this._attack_range,cooldown=22,ts=store.tick_ts}
    this._empower={range=220,cooldown=22,duration=8,damage_factor=1.4,ts=store.tick_ts}
    this._self_blink={min_distance=150}
    this._forge={cooldown=5,ts=store.tick_ts,damage_factor=1.5}
    this._mirrors={cooldown=20,duration=10,ts=store.tick_ts,ids={}}
    this.unit.damage_factor=this.unit.damage_factor*1.2
    local r=this.render.sprites[1]
    r.prefix=body;r.exo=nil;r.anchor=copy(body_anchor)
    r.scale={x=body_scale,y=body_scale};r.offset={x=0,y=0};r.angles={walk={'walk','walkUp','walkDown'}}
    this.health_bar.offset={x=0,y=38}
    this.ui.click_rect={pos={x=-16,y=-2},size={x=32,y=40}}
    this.unit.hit_offset={x=0,y=18};this.unit.head_offset={x=0,y=30}
    this.unit.mod_offset={x=0,y=15}
    this.info.portrait=body..'_portrait'
    this._hand_fx={}
    for i=1,2 do
        local glow=table.deepclone(E:create_entity('fx_ray_start').render.sprites[1])
        glow.hidden=true;glow.ignore_start=true;glow.loop=true;glow.offset={x=0,y=18};glow.z=Z_EFFECTS or 3300
        glow.scale={x=.3,y=.3};glow.anchor={x=.5,y=.5}
        this.render.sprites[#this.render.sprites+1]=glow
        this._hand_fx[i]=glow
    end
    local aura=table.deepclone(E:create_entity('fx').render.sprites[1])
    aura.prefix='trainer_public_arcane_shoot_decal';aura.name='run'
    aura.loop=true;aura.ignore_start=true;aura.hidden=true;aura.alpha=0
    aura.anchor={x=.5,y=.5};aura.offset={x=0,y=1};aura.z=Z_DECALS or 1400
    aura.scale={x=.75,y=.75}
    this.render.sprites[#this.render.sprites+1]=aura
    this._stride_aura=aura

end

function M.request_move(this,p)
    if not alive(this) or not this._self_blink then return false end
    this._sage_blink_goal=nil
    if dist2(this.pos,p)<=this._self_blink.min_distance^2 then return false end
    this._sage_blink_goal=copy(p)
    this.nav_rally.pos=copy(p);this.nav_rally.center=copy(p);this.nav_rally.new=true
    this.motion.forced_waypoint=nil
    return true
end

local function self_blink_fx(store,p)
    local fx=E:create_entity('fx_teleport_arcane')
    fx.pos=copy(p);fx.render.sprites[1].ts=store.tick_ts
    queue(store,fx)
end

function M.self_blink(this,store,cast)
    local goal=this._sage_blink_goal
    if not goal then return false end
    U.unblock_target(store,this)
    this.nav_rally.new=false
    this.render.sprites[1].flip_x=goal.x<this.pos.x
    this.motion.speed={x=0,y=0}
    local moved=false
    cast(this,store,'teleport',.433,function()
        if this._sage_blink_goal~=goal or not GR:cell_is_only(goal.x,goal.y,
            this.nav_grid.valid_terrains_dest or this.nav_grid.valid_terrains)then return end
        self_blink_fx(store,this.pos)
        this.pos.x=goal.x;this.pos.y=goal.y
        this.motion.dest=copy(goal);this.motion.arrived=true;this.motion.speed={x=0,y=0}
        this.motion.forced_waypoint=nil;this.nav_grid.waypoints={}
        this.nav_rally.pos=copy(goal);this.nav_rally.center=copy(goal);this.nav_rally.new=true
        this._sage_blink_goal=nil;moved=true
        self_blink_fx(store,goal);Audio.play('TowerArcaneKr1TeleportCast')
    end,function()return this._sage_blink_goal~=goal or this._trainer_deleted end)
    if this._sage_blink_goal==goal then
        this._sage_blink_goal=nil
        -- Resume the native rally coroutine so it restores its visibility and immunity.
        this.nav_rally.new=true
    end
    return moved
end

function M.pose(this,store)
    local r=this.render.sprites[1]
    r.offset={x=0,y=0};r.r=0;r.alpha=255;r.scale={x=body_scale,y=body_scale}
    local aura=this._stride_aura
    if aura then
        local speed=this.motion.speed or {x=0,y=0}
        local walking=alive(this) and not this.unit.is_stunned and
            (r.name=='walk' or r.name=='walkUp' or r.name=='walkDown' or r.name=='running') and
            (speed.x*speed.x+speed.y*speed.y)>.1
        aura.hidden=not walking
        if walking then
            if not aura._walking then aura.ts=store.tick_ts end
            local fade=math.min(1,math.max(0,store.tick_ts-aura.ts)/.16)
            aura.alpha=math.floor((130+18*math.sin((store.tick_ts-aura.ts)*3))*fade)
        else aura.alpha=0 end
        aura._walking=walking
    end
    local casting=not this.health.dead and not this.unit.is_stunned and
        (r.name=='shoot' or r.name=='attack' or r.name=='arcane_bolt' or r.name=='forge' or r.name=='disintegrate')
    local elapsed=math.max(0,store.tick_ts-r.ts)
    for i,glow in ipairs(this._hand_fx or {})do
        glow.hidden=not casting
        if casting then
            if glow._cast_ts~=r.ts or glow._cast_name~=r.name then
                glow.ts=r.ts;glow._cast_ts=r.ts;glow._cast_name=r.name
            end
            local channel=r.name=='disintegrate'
            local release=channel and 21/FPS or (r.name=='arcane_bolt' or r.name=='forge') and 20/FPS or r.name=='shoot' and .3 or this.melee.attacks[1].hit_time
            local charge=math.min(1,elapsed/math.max(.05,release))
            local flash=math.max(0,1-math.abs(elapsed-release)/.15)
            local sign=r.flip_x and -1 or 1
            local hand_x=(channel and 8 or 11)*sign
            glow.offset={x=hand_x+(i==2 and math.cos(elapsed*18)*3 or 0),
                y=19+(i==2 and math.sin(elapsed*18)*3 or 0)}
            local scale=(i==1 and .22 or .12)+charge*.12+flash*.16
            glow.scale={x=scale,y=scale};glow.alpha=math.floor(160+95*charge)
            glow.r=(i==1 and 1 or -1)*elapsed*3
        end
    end

    if this.health.dead then
        -- The death sprite sheet supplies the KR4-style arcane burst and empty
        -- robe aftermath. Keep it upright and fully visible; no generic tilt/fade.
        r.offset={x=0,y=0};r.r=0;r.alpha=255
        r.scale={x=body_scale,y=body_scale}
    else
        local profile=M.motion_profiles and M.motion_profiles[r.name]
        if profile and #profile>0 then
            local frame=math.floor(math.max(0,store.tick_ts-r.ts)*(r.fps or FPS))
            frame=r.loop and frame%#profile+1 or math.min(#profile,frame+1)
            local pose=profile[frame]
            r.offset.x=pose.x;r.offset.y=pose.y
        end
    end
end

function M.sigil_position(this,store)
    local range=this._sigil.range
    local nearest=P:nearest_nodes(this.pos.x,this.pos.y)[1]
    if not nearest then return end
    local pi,spi,ni=unpack(nearest)
    local wanted=ni-math.ceil(range/(P.average_node_dist or 6))
    if wanted<1 then wanted=1 end
    -- Walk back along the incoming route and choose a valid point within casting range.
    for node=wanted,ni do
        if P:is_node_valid(pi,node)then
            local p=P:node_pos(pi,spi,node)
            if dist2(this.pos,p)<=range*range and dist2(this.pos,p)>16 then return p end
        end
    end
end

function M.sigil_enemy(this,store)
    local sigil=E.entities[sigil_name]
    local filter={vis_flags=F_TELEPORT,vis_bans=sigil.vis_bans}
    local max_times=E.entities[sigil_mod].max_times_applied
    for _,target in pairs(store.entities)do
        if enemy(target) and target.nav_path and U.flags_pass(target.vis,filter) and
            dist2(this.pos,target.pos)<=this._attack_range^2 and
            (not target.enemy.counts or (target.enemy.counts.mod_teleport or 0)<max_times)then
            return target
        end
    end
end

function M.place_sigil(this,store,p)
    local cfg=this._sigil
    if not alive(this) or not M.sigil_enemy(this,store) or dist2(this.pos,p)>cfg.range^2 or
        store.tick_ts-cfg.ts<cfg.cooldown then return false end
    local e=E:create_entity(sigil_name)
    e.pos=copy(p);e._magus_owner_id=this.id
    queue(store,e);cfg.ts=store.tick_ts
    Audio.play('TowerArcaneKr1TeleportCast')
    return e
end

local function normal_ray_eligible(this,target)
    local attack=E.entities.tower_arcane_wizard_kr1.attacks.list[1]
    return enemy(target) and not target.health.ignore_damage and
        dist2(this.pos,target.pos)<=this._attack_range^2 and U.flags_pass(target.vis,attack)
end

function M.normal_targets(this,store)
    local list={}
    for _,target in pairs(store.entities)do
        if normal_ray_eligible(this,target)then list[#list+1]=target end
    end
    table.sort(list,function(a,b)
        local da,db=dist2(this.pos,a.pos),dist2(this.pos,b.pos)
        return da==db and a.id<b.id or da<db
    end)
    return list
end

function M.normal_ray_target(this,store)
    return M.normal_targets(this,store)[1]
end

function M.normal_ray(this,store,target)
    if not alive(this) or not normal_ray_eligible(this,target)then return false end
    local ray=E:create_entity('ray_arcane')
    local sign=this.render.sprites[1].flip_x and -1 or 1
    ray.pos={x=this.pos.x+11*sign,y=this.pos.y+19}
    local b=ray.bullet
    b.from=copy(ray.pos);b.to=copy(target.pos)
    b.source_id=this.id;b.target_id=target.id;b.level=1
    b.mod='trainer_magus_arcane_ray'
    queue(store,ray);this._skill_ts=store.tick_ts
    return ray
end

function M.normal_attack(this,store,cast)
    local list=M.normal_targets(this,store)
    if #list==0 then return false end
    local rain=#list>=2
    local attack=E.entities.tower_arcane_wizard_kr1.attacks.list[1]
    local cooldown=rain and 3 or attack.cooldown
    if store.tick_ts-this._skill_ts<cooldown then return false end
    local start=store.tick_ts
    this.render.sprites[1].flip_x=list[1].pos.x<this.pos.x
    local function same_mode()
        local current=M.normal_targets(this,store)
        return #current>0 and (#current>=2)==rain,current
    end
    local interrupted=function()
        return require('script_utils').soldier_pick_melee_target(store,this)~=nil or not same_mode()
    end
    return cast(this,store,rain and 'shoot' or 'arcane_bolt',rain and .3 or attack.shoot_time,function()
        local valid,current=same_mode()
        if not valid then return end
        local target=current[1]
        this.render.sprites[1].flip_x=target.pos.x<this.pos.x
        if rain then
            require('kr6_summon_public.trainer_archmage_core').rain(this,store,copy(target.pos))
            this._skill_ts=start
        else M.normal_ray(this,store,target)end
    end,interrupted)
end

local function disintegrate_eligible(this,target)
    local attack=E.entities.tower_arcane_wizard_kr1.attacks.list[2]
    return enemy(target) and not target.health.ignore_damage and
        dist2(this.pos,target.pos)<=this._disintegrate.range^2 and U.flags_pass(target.vis,attack)
end

function M.disintegrate_target(this,store)
    local candidates={}
    for _,e in pairs(store.entities)do
        if disintegrate_eligible(this,e)then candidates[#candidates+1]=e end
    end
    table.sort(candidates,function(a,b)
        return a.health.hp==b.health.hp and a.id<b.id or a.health.hp>b.health.hp
    end)
    return candidates[1]
end

function M.disintegrate(this,store,target)
    local cfg=this._disintegrate
    if not alive(this) or not disintegrate_eligible(this,target) or store.tick_ts-cfg.ts<cfg.cooldown then return false end
    local ray=E:create_entity('ray_arcane_disintegrate')
    local sign=this.render.sprites[1].flip_x and -1 or 1
    ray.pos={x=this.pos.x+14*sign,y=this.pos.y+17}
    local b=ray.bullet
    b.from=copy(ray.pos);b.to=copy(target.pos)
    b.source_id=this.id;b.target_id=target.id;b.level=3
    queue(store,ray);cfg.ts=store.tick_ts
    local glow=E:create_entity('fx_ray_start')
    glow.pos=copy(ray.pos);glow.render.sprites[1].ts=store.tick_ts
    E:add_comps(glow,'main_script')
    glow.main_script.update=function(this,active_store)
        local start=active_store.tick_ts
        while active_store.tick_ts-start<ray.ray_duration do coroutine.yield()end
        remove(active_store,this)
    end
    queue(store,glow)
    Audio.play('TowerArcaneKr1DisintegrateCast')
    return ray
end

local function can_empower(this,tower)
    return tower.tower and tower.pos and not tower.pending_removal and
        tower.tower.can_be_mod~=false and type(tower.tower.damage_factor)=='number' and
        (tower.attacks or tower.barrack) and dist2(this.pos,tower.pos)<=this._empower.range^2
end

function M.empower_targets(this,store)
    local list={}
    for _,tower in pairs(store.entities)do
        if can_empower(this,tower)then list[#list+1]=tower end
    end
    return list
end

function M.empower(this,store)
    local cfg=this._empower
    if not alive(this) or store.tick_ts-cfg.ts<cfg.cooldown then return 0 end
    local list=M.empower_targets(this,store)
    for _,tower in ipairs(list)do
        local mod=E:create_entity(buff_name)
        mod.pos=copy(tower.pos);mod.modifier.source_id=this.id;mod.modifier.target_id=tower.id
        queue(store,mod)
    end
    if #list>0 then cfg.ts=store.tick_ts;Audio.play('TowerArcaneKr1TeleportCast')end
    return #list
end

function M.skill_enemy(this,store)
    local best,range=nil,this._attack_range^2
    for _,e in pairs(store.entities)do
        local d=e.pos and dist2(this.pos,e.pos)
        if d and d<=range and enemy(e) and not e.health.ignore_damage and
            U.flags_pass(e.vis,E.entities.tower_forger_lvl4.attacks.list[1])then
            if not best or d<dist2(this.pos,best.pos)then best=e end
        end
    end
    return best
end

function M.forge(this,store,target)
    local cfg=this._forge
    if not cfg or not alive(this) or store.tick_ts-cfg.ts<cfg.cooldown then return false end
    if target~=M.skill_enemy(this,store)then target=M.skill_enemy(this,store)end
    if not target then return false end
    local weapon=E:create_entity('bullet_forger_basic_lvl4')
    local sign=this.render.sprites[1].flip_x and -1 or 1
    weapon.pos={x=this.pos.x,y=this.pos.y+60}
    weapon.suffix=({'a','b','c','d','e','f'})[math.random(1,6)]
    weapon.render.sprites[1].ts=store.tick_ts
    local b=weapon.bullet
    b.from=copy(weapon.pos);b.to=copy(target.pos)
    b.target_id=nil;b.source_id=this.id;b.source_=this;b.level=4
    b.to=copy(weapon.pos)
    weapon._forge_target_id=target.id;weapon._forge_hold=.8
    b.damage_factor=1.5;b.damage_radius=assert(E.entities.bomb_bfg.bullet.damage_radius)
    b.mods={}
    local native_update=weapon.main_script.update
    weapon.main_script.update=function(w,st,script)
        local co=coroutine.create(native_update)
        local start=st.tick_ts
        while coroutine.status(co)~='dead'do
            if not w._forge_released then
                if not alive(st.entities[b.source_id])then remove(st,w);return end
                w.pos.x=this.pos.x;w.pos.y=this.pos.y+60
                if st.tick_ts-start>=w._forge_hold then
                    local foe=st.entities[w._forge_target_id]
                    if not enemy(foe)then foe=M.skill_enemy(this,st)end
                    if not foe then remove(st,w);return end
                    b.from=copy(w.pos);b.to=copy(foe.pos);b.target_id=foe.id
                    w._forge_released=true
                end
            end
            local ok,err=coroutine.resume(co,w,st,script)
            if not ok then error(err)end
            if coroutine.status(co)~='dead'then coroutine.yield()end
        end
    end
    local fx=E:create_entity('fx_bullet_forger_spawn')
    fx.pos=copy(weapon.pos);fx.render.sprites[1].ts=store.tick_ts
    queue(store,fx);queue(store,weapon)
    cfg.ts=store.tick_ts;Audio.play('TowerArcaneForgerBasicAttackCast')
    return weapon
end

local function mirror_positions(this,store)
    local target=M.skill_enemy(this,store)
    if not target then return end
    local dx,dy=target.pos.x-this.pos.x,target.pos.y-this.pos.y
    local len=math.sqrt(dx*dx+dy*dy)
    if len<1 then dx,dy,len=1,0,1 end
    dx,dy=dx/len,dy/len
    local terrain=this.nav_grid.valid_terrains_dest or this.nav_grid.valid_terrains
    for _,distance in ipairs({45,32,22})do
        local points={}
        for _,side in ipairs({-1,1})do
            local p={x=this.pos.x+dx*distance-dy*side*16,y=this.pos.y+dy*distance+dx*side*16}
            local ok=true
            for n=1,5 do
                local x=this.pos.x+(p.x-this.pos.x)*n/5
                local y=this.pos.y+(p.y-this.pos.y)*n/5
                if not GR:cell_is_only(x,y,terrain)then ok=false;break end
            end
            if ok then points[#points+1]=p end
        end
        if #points==2 then return points end
    end
end

function M.mirror_exit(this,store)
    if this._mirror_exit_fx then return end
    this._mirror_exit_fx=true
    U.unblock_target(store,this)
    local fx=E:create_entity('fx');E:add_comps(fx,'main_script')
    fx.pos=copy(this.pos)
    local r=fx.render.sprites[1]
    r.prefix='trainer_arcane_illusion_smoke';r.name='run';r.loop=false;r.ts=store.tick_ts
    r.anchor={x=.5,y=.5};r.offset={x=0,y=18};r.z=Z_EFFECTS or 3300
    r.scale={x=1,y=1}
    fx._mirror_exit=true
    fx.main_script.update=function(e,st)
        local ts=st.tick_ts
        while st.tick_ts-ts<8/12 do coroutine.yield()end
        remove(st,e)
    end
    queue(store,fx)
    return fx
end

function M.mirror_block(this,store)
    local old=store.entities[this.soldier.target_id]
    if not alive(this) or this.unit.is_stunned or this.nav_rally.new then
        U.unblock_target(store,this);return
    end
    if old and enemy(old) and U.is_blocked_valid(store,this) and dist2(this.pos,old.pos)<=50^2 then return old end
    U.unblock_target(store,this)
    local target=U.find_nearest_enemy(store.entities,this.pos,0,35,F_BLOCK,bit.bor(F_FLYING,F_CLIFF),function(e)
        return not e.enemy.max_blockers or #e.enemy.blockers<e.enemy.max_blockers
    end)
    if target then U.block_enemy(store,this,target);return target end
end

function M.spawn_mirrors(this,store)
    local cfg=this._mirrors
    if not cfg or not alive(this) or store.tick_ts-cfg.ts<cfg.cooldown then return false end
    local points=mirror_positions(this,store)
    if not points then return false end
    local active=0
    for _,id in ipairs(cfg.ids)do if alive(store.entities[id])then active=active+1 end end
    if active>0 then return false end
    local units={}
    for _,p in ipairs(points)do
        local e=require('kr6_summon_public.trainer_archmage_core').create('magus',{name=(KR6_TRAINER and KR6_TRAINER.language=='zh-CN')and'奥术法师'or'Arcane Magus'},store)
        M.setup(e,store)
        e._arcane_illusion=true;e._kr6_trainer=true;e._trainer_kind='magus'
        e._mirror_owner=this.id;e._mirror_expire=store.tick_ts+cfg.duration
        e._sigil=nil;e._disintegrate=nil;e._empower=nil;e._forge=nil;e._mirrors=nil
        e._self_blink=nil;e._teleport=nil;e.regen=nil
        e.health.hp_max=this.health.hp_max*.3;e.health.hp=e.health.hp_max
        e.unit.damage_factor=this.unit.damage_factor*.3
        e._skill_ts=store.tick_ts-3;e.info.i18n_key='TRAINER_ARCANE_ILLUSION'
        for _,messages in pairs(require('i18n').msgs or {})do messages.TRAINER_ARCANE_ILLUSION_NAME=(KR6_TRAINER and KR6_TRAINER.language=='zh-CN')and'奥术幻影'or'Arcane Illusion' end
        e.pos=copy(p);e.nav_rally.pos=copy(p);e.nav_rally.center=copy(p);e.nav_rally.new=true
        local update=e.main_script.update
        e.main_script.update=function(illusion,st,script)
            local co=coroutine.create(update)
            while not illusion._trainer_deleted and coroutine.status(co)~='dead' do
                if st.tick_ts>=illusion._mirror_expire or not alive(illusion) or not alive(st.entities[illusion._mirror_owner])then
                    M.mirror_exit(illusion,st)
                    illusion._trainer_deleted=true;remove(st,illusion);return
                end
                M.mirror_block(illusion,st)
                local ok,err=coroutine.resume(co,illusion,st,script)
                if not ok then error(err)end
                M.pose(illusion,st)
                illusion.render.sprites[1].alpha=155
                if coroutine.status(co)~='dead'then coroutine.yield()end
            end
        end
        units[#units+1]=e
    end
    cfg.ids={}
    for _,e in ipairs(units)do
        cfg.ids[#cfg.ids+1]=e.id;queue(store,e)
        if KR6_TRAINER and KR6_TRAINER.track_summon then KR6_TRAINER.track_summon(e,store)end
    end
    cfg.ts=store.tick_ts
    return units
end

function M.special(this,store,cast)
    local now=store.tick_ts
    if this._arcane_illusion then return nil end
    local foe=M.skill_enemy(this,store)
    if foe and this._mirrors and now-this._mirrors.ts>=this._mirrors.cooldown and mirror_positions(this,store)then
        return cast(this,store,'mirrors',13/FPS,function()M.spawn_mirrors(this,store)end)
    end
    if foe and this._forge and now-this._forge.ts>=this._forge.cooldown then
        this.render.sprites[1].flip_x=foe.pos.x<this.pos.x
        return cast(this,store,'forge',20/FPS,function()M.forge(this,store,foe)end)
    end
    local interrupted=function()return require('script_utils').soldier_pick_melee_target(store,this)~=nil end
    if now-this._disintegrate.ts>=this._disintegrate.cooldown then
        local target=M.disintegrate_target(this,store)
        if target then
            this.render.sprites[1].flip_x=target.pos.x<this.pos.x
            return cast(this,store,'disintegrate',21/FPS,function()M.disintegrate(this,store,target)end,interrupted)
        end
    end
    if now-this._empower.ts>=this._empower.cooldown and #M.empower_targets(this,store)>0 then
        local foe=U.find_foremost_enemy(store.entities,this.pos,0,this._empower.range,nil,F_RANGED,F_FRIEND)
        if foe then return cast(this,store,'empower',13/FPS,function()M.empower(this,store)end,interrupted)end
    end
    if now-this._sigil.ts>=this._sigil.cooldown and M.sigil_enemy(this,store)then
        local p=M.sigil_position(this,store)
        if p then
            this.render.sprites[1].flip_x=p.x<this.pos.x
            return cast(this,store,'sigil',.433,function()M.place_sigil(this,store,p)end,interrupted)
        end
    end
end
return M
