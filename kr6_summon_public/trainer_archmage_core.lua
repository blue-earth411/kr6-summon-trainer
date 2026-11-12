-- Standalone Archmage: native Genesis effects and custom art, without Vengeance assets.
local M={}
local E=require('entity_db')
local U=require('utils')
local SU=require('script_utils')
local A=require('klove.animation_db')
local I=require('klove.image_db')
local GR=require('grid_db')
local P=require('path_db')
local bit=require('bit')
local native=require('scripts').soldier_barrack
local Sound=require('kr6_summon_public.trainer_audio')
local Audio={prepare=Sound.prepare_native,key=function()return 'MeleeSword'end}
function Audio.play(id)Sound.play(id:find('teleport') and 'TowerArcaneKr1TeleportCast' or 'TowerArcaneKr1RayCast')end
function Audio.cast(kind,name)Sound.play(name=='attack' and 'MeleeSword' or name=='teleport' and 'TowerArcaneKr1TeleportCast' or 'TowerArcaneKr1RayCast')end


local legion_archer_damage={min=10,max=13}
local animations={}
local function clone(v)
 if type(v)~='table' then return v end
 local r={};for k,x in pairs(v)do r[k]=clone(x)end;return r
end
local function distance(a,b)return (a.x-b.x)^2+(a.y-b.y)^2 end
local function alive(e)return e and not e._trainer_deleted and e.health and not e.health.dead and e.health.hp>0 end
local function enemy(e)
 return alive(e) and e.enemy and not e.soldier and not e._kr6_trainer and e.vis and
  bit.band(e.vis.bans,F_RANGED)==0 and bit.band(e.vis.flags,F_FRIEND)==0
end
local function friend(e)return alive(e) and e.soldier and not e.enemy end
local function targets(store,p,range,test)
 local r={};for _,e in pairs(store.entities)do
  if e.pos and test(e) and distance(p,e.pos)<=range*range then r[#r+1]=e end
 end
 table.sort(r,function(a,b)
  local da,db=distance(p,a.pos),distance(p,b.pos)
  return da==db and a.id<b.id or da<db
 end)
 return r
end
M.is_enemy=enemy;M.is_friend=friend;M.targets=targets
local function teleport_fx_template()
 local name='trainer_public_arcane_portal'
 local t=E.entities[name]or E:register_t(name,'fx')
 E:add_comps(t,'main_script')
 local r=t.render.sprites[1]
 r.prefix='trainer_public_arcane_decal';r.name='run';r.loop=false;r.anchor={x=.5,y=.5}
 r.size_names=nil;r.size_scales=nil
 t.main_script.update=function(e,s)
  local start=s.tick_ts
  while s.tick_ts-start<23/FPS do coroutine.yield()end
  table.insert(s.pending_removals,e)
 end
end
function M.load_assets()
 require('kr6_summon_public.trainer_native_units').load_assets('mage_kr1')
 local function alias(name,native)
  local a=table.deepclone(assert(A.db[native],native));a.fps=a.fps or FPS
  A.db[name]=a;animations[name]=a
 end
 alias('trainer_public_arcane_decal_run','fx_teleport_arcane_small')
 alias('trainer_public_arcane_shoot_decal_run','aura_teleport_arcane')
 alias('trainer_public_arcane_projectile_hit_run','fx_ray_arcane_end_run')
 local native=A.db.fx_ray_arcane_end_run
 local f=assert(I.db_atlas[native.prefix..'_'..string.format('%04d',native.from)])
 I.db_atlas.trainer_public_arcane_mage_projectile=f
 I.db_atlas.trainer_public_arcane_0001=assert(I.db_atlas.arcane_wizard_tower_KR1_lvl4_arcane_0001)
 teleport_fx_template()
end
local function queue_insert(store,e)
 if simulation and simulation.store==store then simulation:queue_insert_entity(e)
 else
  if e.main_script and e.main_script.queue then e.main_script.queue(e,store,true)end
  table.insert(store.pending_inserts,e)
 end
end
local function track_spawn(e,store)
 if KR6_TRAINER and KR6_TRAINER.track_summon then KR6_TRAINER.track_summon(e,store)end
end
local function damage(store,source,target,lo,hi,kind)
 if not enemy(target) then return end
 local d=E:create_entity('damage')
 d.source_id=source.id;d.target_id=target.id;d.value=math.random(lo,hi);d.damage_type=kind
 if source._trainer_kind=='arcane_sage' or source._arcane_illusion then d.value=d.value*source.unit.damage_factor end
 table.insert(store.damage_queue,d)
end
local function delayed(store,delay,fn)
 local e=E:create_entity('modifier');e.modifier=nil
 e.main_script.update=function(c,s)
  local ts=s.tick_ts;while s.tick_ts-ts<delay do coroutine.yield()end
  fn(s);table.insert(s.pending_removals,c)
 end
 queue_insert(store,e)
 return e
end
local function cast(this,store,name,hit_time,effect,interrupted,animation_scale)
 local start=store.tick_ts
 local sprite=this.render.sprites[1];local old_fps=sprite.fps
 if animation_scale then sprite.fps=FPS/animation_scale end
 U.animation_start(this,name,nil,start,false)
 Audio.cast(this._trainer_kind,name)
 while store.tick_ts-start<hit_time do
  if this.health.dead or this.unit.is_stunned or this.nav_rally.new or
   (interrupted and interrupted()) then
   U.animation_start(this,'idle',nil,store.tick_ts,true)
   sprite.fps=old_fps
   return false
  end
  if this._trainer_kind=='arcane_sage' or this._arcane_illusion then require('kr6_summon_public.trainer_magus').pose(this,store)end
  coroutine.yield()
 end
 if this.health.dead or this.unit.is_stunned or this.nav_rally.new or
  (interrupted and interrupted()) then
  U.animation_start(this,'idle',nil,store.tick_ts,true)
  sprite.fps=old_fps
  return false
 end
 effect()
 while not U.animation_finished(this) do
  if this.health.dead or this.unit.is_stunned or this.nav_rally.new or
   (interrupted and interrupted()) then
   U.animation_start(this,'idle',nil,store.tick_ts,true)
   break
  end
  if this._trainer_kind=='arcane_sage' or this._arcane_illusion then require('kr6_summon_public.trainer_magus').pose(this,store)end
  coroutine.yield()
 end
 sprite.fps=old_fps
 return true
end
local function has_melee_target(this,store)
 -- Use the same eligibility, rally radius and existing blocker checks as native soldiers.
 return this.melee and SU.soldier_pick_melee_target(store,this)~=nil
end
local function effect(store,pos,prefix,name)
 local e=E:create_entity('fx')
 if not e then return end
 E:add_comps(e,'main_script')
 e.pos=clone(pos);e.render.sprites[1].prefix='trainer_public_'..prefix
 e.render.sprites[1].name=name;e.render.sprites[1].anchor={x=.5,y=.166}
 e.render.sprites[1].ts=store.tick_ts;e.render.sprites[1].loop=false
 e.main_script.update=function(f,s)
  local animation=animations['trainer_public_'..prefix..'_'..name]
  local duration=(animation.to-animation.from+1)/FPS
  local ts=s.tick_ts
  while s.tick_ts-ts<duration do coroutine.yield()end
  table.insert(s.pending_removals,f)
 end
 table.insert(store.pending_inserts,e)
end
function M.rain(this,store,p)
 local controller=E:create_entity('modifier')
 controller.modifier=nil
 controller.main_script.update=function(c,s)
  for i=1,5 do
   local dst={x=p.x+math.random(-50,50),y=p.y+math.random(-12,12)}
   local projectile=E:create_entity('fx')
   E:add_comps(projectile,'main_script')
   projectile.pos={x=dst.x+50,y=dst.y+120}
   local sprite=projectile.render.sprites[1]
   sprite.animated=false;sprite.name='trainer_public_arcane_mage_projectile';sprite.prefix=nil
   sprite.anchor={x=.5,y=.5};sprite.r=-math.atan2(120,50)
   projectile.main_script.update=function(e,st)
    local ts=st.tick_ts
    while st.tick_ts-ts<.3 do
     local f=(st.tick_ts-ts)/.3
     e.pos.x=dst.x+50*(1-f);e.pos.y=dst.y+120*(1-f)
     coroutine.yield()
    end
    for _,t in ipairs(targets(st,dst,60,enemy))do damage(st,this,t,14,21,DAMAGE_MAGICAL)end
    Audio.play('linirea_arcane_magus_attack_impacts')
    effect(st,dst,'arcane_projectile_hit','run')
    table.insert(st.pending_removals,e)
   end
   table.insert(s.pending_inserts,projectile)
   local ts=s.tick_ts;while s.tick_ts-ts<.06 do coroutine.yield()end
  end
  table.insert(s.pending_removals,c)
 end
 table.insert(store.pending_inserts,controller)
end
local function can_teleport(t)
 local n=t.nav_path
 local native_modifier=E.entities.mod_teleport_arcane.modifier
 return enemy(t)and not t.health.ignore_damage and not t._kr4_polymorph and n and n.pi and n.spi and n.ni and
  (n.ni>1 or(n.prev_pis and #n.prev_pis>0))and bit.band(t.vis.flags,F_BOSS)==0 and
  U.flags_pass(t.vis,native_modifier)and P:is_node_valid(n.pi,n.ni)
end
function M.teleport(this,store)
 if not alive(this)then return 0 end
 local cfg=this._teleport
 if store.tick_ts-this._teleport_ts<cfg.cooldown then return 0 end
 local count=0
 for _,t in ipairs(targets(store,this.pos,cfg.range,can_teleport))do
  if count>=cfg.count then break end
  local m=E:create_entity('mod_teleport_arcane')
  m.modifier.source_id=this.id;m.modifier.target_id=t.id
  m.modifier.use_mod_offset=false
  m.nodes_offset_min=-cfg.nodes;m.nodes_offset_max=-cfg.nodes;m.nodes_offset_inc=nil
  m.max_times_applied=nil;m.nodeslimit=1
  m.fx_start='trainer_public_arcane_portal';m.fx_end=m.fx_start
  queue_insert(store,m);count=count+1
 end
 if count>0 then this._teleport_ts=store.tick_ts;Audio.play('linirea_arcane_magus_teleport')end
 return count
end
-- The only combat spell allowed while the Archmage is in melee is enemy
-- knockback teleport. Ally advancement and every other skill stay excluded.
function M.melee_teleport(this,store)
 if this._trainer_kind~='arcane_sage' or not this._teleport or
  store.tick_ts-this._teleport_ts<this._teleport.cooldown or
  not targets(store,this.pos,this._teleport.range,can_teleport)[1]then return false end
 return cast(this,store,'teleport',.433,function()M.teleport(this,store)end)
end
-- Rally coordinates are world distances; native paths average six units per node.
function M.ally_teleport_min_distance(this)
 return this._teleport.nodes*(P.average_node_dist or 6)
end
local function allied_destination_valid(t,p,store)
 local types=t.nav_grid and(t.nav_grid.valid_terrains_dest or t.nav_grid.valid_terrains)
 if t._ice_surface_walker then
  
  if types then types=bit.band(types,bit.bnot(TERRAIN_NOWALK))end
 end
 return not types or GR:cell_is_only(p.x,p.y,types)
end
-- Match the native desktop selection paths: heroes and freely rallied reinforcements.
-- Barracks soldiers have selectable info panels too, so selection alone is insufficient.
function M.is_player_movable(t)
 if not t.ui or not t.ui.can_click or not t.ui.can_select then return false end
 return t._kr6_trainer or(t.hero and(not t.hero.stage_hero or t.hero.stage_hero_w_portrait))or
  (t.reinforcement and t.nav_grid)or false
end
local function teleport_members(t,store)
 if t._legion_group then return require('kr6_summon_public.trainer_public_formation').members(t._legion_group,store)end
 local id=t.reinforcement and t.reinforcement.squad_id
 if id~=nil then
  local result={}
  for _,e in pairs(store.entities)do
   if alive(e)and not e.enemy and e.reinforcement and e.reinforcement.squad_id==id then result[#result+1]=e end
  end
  table.sort(result,function(a,b)return a.id<b.id end)
  return result
 end
 return {t}
end
local function teleport_group_key(t)
 if t._legion_group then return t._legion_group end
 local id=t.reinforcement and t.reinforcement.squad_id
 return id~=nil and('reinforcement:'..tostring(id))or t
end
local function allied_move_goal(t,this,store)
 if t==this or not alive(t)or store.entities[t.id]~=t or t.enemy or not M.is_player_movable(t)or
  not t.nav_rally or not t.nav_rally.pos or not t.motion or
  (t.unit and t.unit.is_stunned)or not t.pos or distance(this.pos,t.pos)>this._teleport.range^2 then return end
 local r,m=t.nav_rally,t.motion
 local sprite=t.render and t.render.sprites and t.render.sprites[1]
 local walking=sprite and type(sprite.name)=='string'and(sprite.name:find('walk')or sprite.name:find('run'))
 if not(r.new or(m.arrived==false and walking))or distance(t.pos,r.pos)<=1 then return end
 if not allied_destination_valid(t,r.pos,store)then return end
 return r.pos
end
local function allied_plan(t,this,store)
 local members=teleport_members(t,store)
 if #members==0 then return end
 local plan={members={},group=t._legion_group,reinforcement_squad_id=t.reinforcement and t.reinforcement.squad_id}
 local from,to={x=0,y=0},{x=0,y=0}
 for _,e in ipairs(members)do
  local p=allied_move_goal(e,this,store);if not p then return end
  plan.members[#plan.members+1]={entity=e,goal=clone(p)}
  from.x=from.x+e.pos.x/#members;from.y=from.y+e.pos.y/#members
  to.x=to.x+p.x/#members;to.y=to.y+p.y/#members
 end
 if distance(from,to)<=M.ally_teleport_min_distance(this)^2 then return end
 return plan
end
function M.allied_teleport_plans(this,store)
 if not alive(this)or not this._teleport then return {}end
 local result,seen,used={},{},0
 for _,t in ipairs(targets(store,this.pos,this._teleport.range,function(e)
  return allied_move_goal(e,this,store)~=nil
 end))do
  local key=teleport_group_key(t)
  if not seen[key]then
   seen[key]=true
   local p=allied_plan(t,this,store)
   if p and used+#p.members<=this._teleport.count then
    result[#result+1]=p;used=used+#p.members
   end
  end
 end
 return result
end
local function portal(store,p)
 local fx=E:create_entity('trainer_public_arcane_portal');fx.pos=clone(p)
 fx.render.sprites[1].ts=store.tick_ts;queue_insert(store,fx)
end
function M.teleport_allies(this,store,plans)
 if not alive(this)or(this.unit and this.unit.is_stunned)or this.nav_rally.new or
  store.tick_ts-this._teleport_ts<this._teleport.cooldown then return 0 end
 local moved,seen=0,{}
 for _,plan in ipairs(plans or M.allied_teleport_plans(this,store))do
  local valid=moved+#plan.members<=this._teleport.count
  if plan.group or plan.reinforcement_squad_id~=nil then
   local current=teleport_members(plan.members[1].entity,store)
   if(plan.group and plan.group.cancelled)or #current~=#plan.members then valid=false end
  end
  for _,order in ipairs(plan.members)do
   local e=order.entity;local p=allied_move_goal(e,this,store)
   if seen[e]or not p or distance(p,order.goal)>.0001 or e._legion_group~=plan.group or
    (e.reinforcement and e.reinforcement.squad_id)~=plan.reinforcement_squad_id then valid=false end
  end
  if valid then
   -- The whole squad is validated before any member is moved.
   for _,order in ipairs(plan.members)do
    local e,p=order.entity,order.goal
    portal(store,e.pos);U.unblock_target(store,e)
    e.pos.x=p.x;e.pos.y=p.y
    e.motion.dest=clone(p);e.motion.arrived=true;e.motion.speed={x=0,y=0};e.motion.forced_waypoint=nil
    if e.nav_grid then e.nav_grid.waypoints={}end
    -- Interrupt the existing native rally wait, letting it restore its own bans/immunity.
    -- Its next rally sees the requested destination already reached; no script reset.
    e.nav_rally.new=true
    portal(store,p);seen[e]=true;moved=moved+1
   end
  end
 end
 if moved>0 then this._teleport_ts=store.tick_ts;Audio.play('linirea_arcane_magus_teleport')end
 return moved
end

local sheep_health={armor=0,magic_armor=0,poison_armor=0,spiked_armor=0,immune_to=0,
 damage_factor=1,damage_factor_magical=1,ignore_damage=false}
local function special(this,store)
 local kind=this._trainer_kind;local now=store.tick_ts
 if this._arcane_illusion then
  if has_melee_target(this,store)then return false end
  if now-this._skill_ts>=3 then
   local list=targets(store,this.pos,this._attack_range,enemy)
   if list[1]then
    this._skill_ts=now;local p=clone(list[1].pos)
    return cast(this,store,'shoot',.3,function()M.rain(this,store,p)end)
   end
  end
  return false
 end

  if has_melee_target(this,store) then
   if kind=='arcane_sage'then return M.melee_teleport(this,store)end
   return false
  end
  if kind=='arcane_sage' then
   local upgraded=require('kr6_summon_public.trainer_magus').special(this,store,cast)
   if upgraded~=nil then return upgraded end
  end
  local interrupted=function()return has_melee_target(this,store)end
  if now-this._teleport_ts>=this._teleport.cooldown then
   local plans=M.allied_teleport_plans(this,store)
   if #plans>0 then
    return cast(this,store,'teleport',.433,function()M.teleport_allies(this,store,plans)end,interrupted)
   elseif targets(store,this.pos,this._teleport.range,can_teleport)[1]then
    return cast(this,store,'teleport',.433,function()M.teleport(this,store)end,interrupted)
   end
  end
  if kind=='arcane_sage' then
   local fired=require('kr6_summon_public.trainer_magus').normal_attack(this,store,cast)
   if fired~=nil then return fired end
  end
  if now-this._skill_ts>=3 then
   local list=targets(store,this.pos,this._attack_range,enemy)
   if list[1] then
    this._skill_ts=now;local p=clone(list[1].pos)
    return cast(this,store,'shoot',.3,function()M.rain(this,store,p)end,interrupted)
   end
  end

 return false
end
function M.create(kind,def,store)
 M.load_assets()
 local e=E:create_entity('soldier_paladin')
 e.powers=nil;e.timed_actions=nil;e.ranged=nil;e.auras=nil;e.dodge=nil;e.cloak=nil
 e.enemy=nil;e.nav_path=nil;e.track_kills=nil;e.track_damage=nil
 e._trainer_kind=kind;e._kr6_trainer=true
 e.health.hp_max=kind=='magus' and 540 or 742;e.health.hp=e.health.hp_max
 e.health.armor=0;e.health.magic_armor=kind=='magus' and .8 or .95
 e.motion.max_speed=33;e.regen.health=14
 e.info.random_name_format=nil;e.info.i18n_key='TRAINER_PUBLIC_'..kind:upper()
 e.info.fn=function(t)
  local a=t._display_attack
  return {type=STATS_TYPE_SOLDIER,hp=t.health.hp,hp_max=t.health.hp_max,
   damage_min=a.damage_min*t.unit.damage_factor,damage_max=a.damage_max*t.unit.damage_factor,
   damage_type=DAMAGE_MAGICAL,armor=t.health.armor,magic_armor=t.health.magic_armor,respawn=t.health.dead_lifetime}
 end
 local melee=clone(e.melee.attacks[1]);e.melee.attacks={melee};e.melee.range=60
 melee.damage_min=12;melee.damage_max=18;melee.cooldown=1;melee.hit_time=.3
 melee.damage_type=DAMAGE_PHYSICAL;melee.sound='MeleeSword';melee.pop=nil
 e._attack_range=210;e._teleport={count=4,cooldown=15,nodes=25,range=210}
 e._display_attack={damage_min=14,damage_max=21,damage_type=DAMAGE_MAGICAL}
 e._skill_ts=store.tick_ts;e._teleport_ts=store.tick_ts-15
 e.render.sprites[1].angles={walk={'walk','walkUp','walkDown'}}
 if kind=='arcane_sage'then require('kr6_summon_public.trainer_magus').setup(e,store)end
 e.main_script.update=function(this,st,script)
  local co=coroutine.create(native.update)
  while coroutine.status(co)~='dead'do
   if this._trainer_deleted then return end
   if this._sage_blink_goal and alive(this) and not this.unit.is_stunned then
    require('kr6_summon_public.trainer_magus').self_blink(this,st,cast)
   end
   local name=this.render.sprites[1].name
   if kind=='arcane_sage' and alive(this) and not this.unit.is_stunned and not this.nav_rally.new and
    name~='idle' and name~='idleBlock' and has_melee_target(this,st)then
    if M.melee_teleport(this,st)then
     co=coroutine.create(native.update);U.animation_start(this,'idle',nil,st.tick_ts,true)
    end
   end
   if not this.health.dead and not this.unit.is_stunned and not this.nav_rally.new and
    (name=='idle' or name=='idleBlock')then special(this,st)end
   local ok,err=coroutine.resume(co,this,st,script);if not ok then error(err)end
   if kind=='arcane_sage'then require('kr6_summon_public.trainer_magus').pose(this,st)end
   if coroutine.status(co)~='dead'then coroutine.yield()end
  end
 end
 return e
end
return M
