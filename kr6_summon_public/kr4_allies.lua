-- Original KR4 artwork, converted locally. Combat runs through KR6 allied soldier systems.
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
local Audio=require('kr6_summon_public.trainer_kr4_audio')
local spec=assert(love.filesystem.load('kr6_summon_public/vengeance/kr4_import/spec.lua'))()
local legion_archer_damage={min=10,max=13}
local animations=assert(love.filesystem.load('kr6_summon_public/vengeance/kr4_import/animations.lua'))()
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
 local name='trainer_kr4_magus_portal'
 local t=E.entities[name]or E:register_t(name,'fx')
 E:add_comps(t,'main_script')
 local r=t.render.sprites[1]
 r.prefix='trainer_kr4_arcane_magus_decal';r.name='run';r.loop=false;r.anchor={x=.5,y=.5}
 r.size_names=nil;r.size_scales=nil
 t.main_script.update=function(e,s)
  local start=s.tick_ts
  while s.tick_ts-start<23/FPS do coroutine.yield()end
  table.insert(s.pending_removals,e)
 end
end
function M.load_assets()
 local ready=true
 for _,s in pairs(spec)do
  local a=assert(animations['trainer_kr4_'..s.prefix..'_idle'])
  local frame=I.db_atlas[a.prefix..'_'..string.format('%04d',a.from)]
  if not frame then ready=false;break end
 end
 local pages=assert(love.filesystem.load('kr6_summon_public/vengeance/kr4_import/atlas_sizes.lua'))()
 for name in pairs(pages)do
  local image=I.db_images and I.db_images[name:gsub('%.png$','')]
  if not image or not image[1] then ready=false;break end
 end
 if not ready then
  I.atlas_uses['kr4_allied-0.500000']=nil
  I:load_atlas(.5,'kr6_summon_public/vengeance/kr4_import','kr4_allied',false)
 end
 for name,a in pairs(animations)do A.db[name]=a end
 teleport_fx_template()
 assert(I.db_atlas.trainer_kr4_arcane_magus_0001,'KR4 atlas load failed')
 for _,s in pairs(spec)do
  local a=animations['trainer_kr4_'..s.prefix..'_idle']
  assert(I.db_atlas[a.prefix..'_'..string.format('%04d',a.from)],'KR4 troop atlas load failed: '..s.prefix)
 end
 for name in pairs(pages)do
  local image=I.db_images and I.db_images[name:gsub('%.png$','')]
  assert(image and image[1],'KR4 atlas page load failed: '..name)
 end
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
 e.pos=clone(pos);e.render.sprites[1].prefix='trainer_kr4_'..prefix
 e.render.sprites[1].name=name;e.render.sprites[1].anchor={x=.5,y=.166}
 e.render.sprites[1].ts=store.tick_ts;e.render.sprites[1].loop=false
 e.main_script.update=function(f,s)
  local animation=animations['trainer_kr4_'..prefix..'_'..name]
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
   sprite.animated=false;sprite.name='trainer_kr4_arcane_mage_projectile';sprite.prefix=nil
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
    effect(st,dst,'arcane_magus_projectile_hit','run')
    table.insert(st.pending_removals,e)
   end
   table.insert(s.pending_inserts,projectile)
   local ts=s.tick_ts;while s.tick_ts-ts<.06 do coroutine.yield()end
  end
  table.insert(s.pending_removals,c)
 end
 table.insert(store.pending_inserts,controller)
end
function M.shoot(this,store,target,attack)
 if this._trainer_kind=='ice_witch' or this._trainer_kind=='alchemist' then return M.new_projectile(this,store,target,attack,false)end
 if this._trainer_kind=='mystic' then return M.mystic_ray(this,store,target,attack)end
 Audio.play(attack.proyectile.release_sound)
 local src={x=this.pos.x,y=this.pos.y+17}
 if attack.projectile_origin then
  local hand=attack.projectile_origin
  src={x=this.pos.x+(this.render.sprites[1].flip_x and -hand.x or hand.x),y=this.pos.y+hand.y}
 end
 if attack._sprite then
  local off=this.render.sprites[attack._sprite].offset
  src={x=this.pos.x+off.x,y=this.pos.y+off.y+14}
 end
 local dst=clone(target.pos);dst.y=dst.y+(target.unit.hit_offset and target.unit.hit_offset.y or 0)
 local duration=math.min(1.8,math.max(.12,math.sqrt(distance(src,dst))/325))
 if attack.projectile_frame or this._trainer_kind=='archer' or this._trainer_kind=='huntress' or this._trainer_kind=='ranger' or this._trainer_kind=='gunman' or this._trainer_kind=='nomad' or this._trainer_kind=='elephant' then
  local e=E:create_entity('fx');E:add_comps(e,'main_script')
  e.pos=clone(src)
  local r=e.render.sprites[1];r.animated=false;r.prefix=nil
  local projectile=attack.proyectile
  r.name=attack.projectile_frame or ((this._trainer_kind=='archer'or this._trainer_kind=='elephant') and 'trainer_kr4_legion_archer_arrow_0001' or
   this._trainer_kind=='gunman' and 'trainer_kr4_tinbeard_gunman_proyectile_0001' or
   'trainer_kr4_'..assert(projectile.animations.fixed_frame):gsub('%.png$',''))
  r.anchor={x=.5,y=.5}
  local arc=attack.projectile_arc or 60
  if attack.projectile_arc then r.r=math.atan2(dst.y-src.y+4*arc,dst.x-src.x)end
  e.main_script.update=function(p,s)
   local ts=s.tick_ts
   while s.tick_ts-ts<duration do
    local f=(s.tick_ts-ts)/duration
    local x=src.x+(dst.x-src.x)*f;local y=src.y+(dst.y-src.y)*f+arc*4*f*(1-f)
    if attack.projectile_arc then
     r.r=math.atan2(dst.y-src.y+4*arc*(1-2*f),dst.x-src.x)
    else
     r.r=this._trainer_kind=='huntress' and f*math.pi*8 or math.atan2(y-p.pos.y,x-p.pos.x)
    end
    p.pos.x=x;p.pos.y=y
    coroutine.yield()
   end
   if enemy(target) then
    damage(s,this,target,attack.proyectile.damage_min,attack.proyectile.damage_max,DAMAGE_PHYSICAL)
    local hit=projectile.hit and projectile.hit.init_sound
    if hit then Audio.play(hit.id)end
   end
   if this._trainer_kind=='gunman' then effect(s,dst,'tinbeard_gunman_proyectile','hit')end
   table.insert(s.pending_removals,p)
  end
  table.insert(store.pending_inserts,e)
 else
  -- Original KR4 rifle bullets are instantaneous-looking; the muzzle smoke is the original asset.
  effect(store,src,'musketeer_smoke','run')
  delayed(store,duration,function(s)
   if enemy(target) then damage(s,this,target,attack.proyectile.damage_min,attack.proyectile.damage_max,DAMAGE_PHYSICAL)end
  end)
 end
end
-- Native KR4 rays use the original animation stretched between cast and hit positions.
local function ray(store,src,dst,prefix,duration)
 local e=E:create_entity('fx');E:add_comps(e,'main_script');e.pos=clone(src)
 local r=e.render.sprites[1];r.prefix='trainer_kr4_'..prefix;r.name=prefix=='sand_mysthic_ray' and 'travel' or 'run'
 r.anchor={x=0,y=.5};r.ts=store.tick_ts;r.loop=false
 r.r=math.atan2(dst.y-src.y,dst.x-src.x)
 local a=assert(animations[r.prefix..'_'..r.name])
 local frame=assert(I.db_atlas[a.prefix..'_'..string.format('%04d',a.from)])
 r.scale={x=math.sqrt(distance(src,dst))/(frame.size[1]*.5),y=1}
 e.main_script.update=function(f,s)
  local ts=s.tick_ts;while s.tick_ts-ts<duration do coroutine.yield()end
  table.insert(s.pending_removals,f)
 end
 queue_insert(store,e)
end
function M.mystic_ray(this,store,target,attack)
 local projectile=attack.proyectile
 local off=this.render.sprites[1].flip_x and attack.shoot_position_flipped or attack.shoot_position
 local src={x=this.pos.x+off.x,y=this.pos.y+off.y}
 local dst={x=target.pos.x,y=target.pos.y+(target.unit.hit_offset.y or 0)}
 local impact=clone(target.pos)
 Audio.play(projectile.travel_sound)
 ray(store,src,dst,'sand_mysthic_ray',projectile.duration)
 delayed(store,projectile.hit_time,function(s)
  for _,t in ipairs(targets(s,impact,projectile.damage_area,enemy))do
   damage(s,this,t,projectile.damage_min,projectile.damage_max,DAMAGE_MAGICAL)
  end
  effect(s,dst,'sand_mysthic_ray_explosion','run')
 end)
end
function M.freeze(this,store,target)
 if not enemy(target)or bit.band(target.vis.flags,F_BOSS)~=0 then return false end
 local mod=E:create_entity('mod_stun')
 mod.modifier.source_id=this.id;mod.modifier.target_id=target.id;mod.modifier.duration=1
 mod.modifier.animation_phases=false;mod.modifier.use_mod_offset=false;mod.pos=clone(target.pos)
 local r=mod.render.sprites[1];r.prefix='trainer_kr4_freeze';r.name='start';r.animated=true
 r.size_names=nil;r.size_anchors=nil;r.anchor={x=.5,y=.19};r.offset={x=0,y=0};r.ts=store.tick_ts
 local native_insert=mod.main_script.insert
 mod.main_script.insert=function(e,s)
  if not enemy(s.entities[e.modifier.target_id])then return false end
  local ok=native_insert(e,s);if ok then e.render.sprites[1].name='start';e.render.sprites[1].ts=s.tick_ts end;return ok
 end
 mod.main_script.update=function(e,s)
  while alive(target)and s.entities[target.id]==target and s.tick_ts-e.modifier.ts<1 do
   e.pos=clone(target.pos)
   if s.tick_ts-e.modifier.ts>=8/FPS and e.render.sprites[1].name~='idle'then U.animation_start(e,'idle',nil,s.tick_ts,true)end
   coroutine.yield()
  end
  if s.entities[target.id]==target then effect(s,target.pos,'freeze','end')end
  table.insert(s.pending_removals,e)
 end
 queue_insert(store,mod);return true
end
local dwarf_kinds={warhammer=true,gunman=true,geomancer=true,alchemist=true}
local function healable(this,t)
 return friend(t)and t~=this and dwarf_kinds[t._trainer_kind]and t.health.hp<t.health.hp_max
end
function M.alchemist_heal(this,store,pos,projectile)
 for _,t in ipairs(targets(store,pos,projectile.damage_area,function(t)return healable(this,t)end))do
  t.health.hp=math.min(t.health.hp_max,t.health.hp+t.health.hp_max*projectile.healing_percentage)
  if not t._alchemist_hot then
   local m=E:create_entity('modifier');m.modifier=nil;m.pos=clone(t.pos)
   t._alchemist_hot=m
   local cfg=projectile.modifier
   m.main_script.update=function(e,s)
    local start=s.tick_ts;local next_tick=start+cfg.tick_time
    while alive(t)and s.entities[t.id]==t and s.tick_ts-start<=cfg.duration+1e-6 do
     if s.tick_ts+1e-6>=next_tick then
      t.health.hp=math.min(t.health.hp_max,t.health.hp+cfg.healing_points_tick);next_tick=next_tick+cfg.tick_time
     end
     coroutine.yield()
    end
    if t._alchemist_hot==e then t._alchemist_hot=nil end
    table.insert(s.pending_removals,e)
   end
   m.main_script.remove=function(e)if t._alchemist_hot==e then t._alchemist_hot=nil end;return true end
   queue_insert(store,m);effect(store,t.pos,'sulfur_alchemist_heal_fx','run')
  end
 end
end
function M.new_projectile(this,store,target,attack,healing)
 local cfg=attack.proyectile;Audio.play(cfg.release_sound)
 local e=E:create_entity('fx');E:add_comps(e,'main_script')
 local off=this.render.sprites[1].flip_x and attack.shoot_position_flipped or attack.shoot_position
 local src={x=this.pos.x+off.x,y=this.pos.y+off.y};e.pos=clone(src)
 local dst={x=target.pos.x,y=target.pos.y+(healing and 0 or target.unit.hit_offset.y)}
 local r=e.render.sprites[1];r.anchor={x=.5,y=.5};r.ts=store.tick_ts
 if this._trainer_kind=='ice_witch'then r.prefix='trainer_kr4_ice_witch_bolt';r.name='travel'
 else r.prefix=nil;r.animated=false;r.name='trainer_kr4_'..cfg.animations.fixed_frame:gsub('%.png$','')end
 e.main_script.update=function(p,s)
  local start=s.tick_ts
  if this._trainer_kind=='ice_witch'then
   while enemy(target)and s.tick_ts-start<2 do
    dst={x=target.pos.x,y=target.pos.y+target.unit.hit_offset.y}
    local dx,dy=dst.x-p.pos.x,dst.y-p.pos.y;local len=math.sqrt(dx*dx+dy*dy)
    if len<=360*s.tick_length then break end
    p.pos.x=p.pos.x+dx/len*360*s.tick_length;p.pos.y=p.pos.y+dy/len*360*s.tick_length;r.r=math.atan2(dy,dx)
    coroutine.yield()
   end
   if enemy(target)and distance(p.pos,dst)<(360*s.tick_length+1)^2 then
    damage(s,this,target,cfg.damage_min,cfg.damage_max,DAMAGE_MAGICAL)
    effect(s,dst,'ice_witch_bolt','hit')
    if math.random()<cfg.modifier.chance then M.freeze(this,s,target)end
   end
  else
   local duration=.7333333333
   while s.tick_ts-start<duration do
    local f=(s.tick_ts-start)/duration;p.pos.x=src.x+(dst.x-src.x)*f;p.pos.y=src.y+(dst.y-src.y)*f+65*4*f*(1-f)
    r.r=f*math.pi*4;coroutine.yield()
   end
   if healing then
    M.alchemist_heal(this,s,dst,cfg);effect(s,dst,'sulfur_alchemist_projectile_heal_hit','run');Audio.play('dwarves_sulfur_alchemist_acid')
   elseif enemy(target)then
    damage(s,this,target,cfg.damage_min,cfg.damage_max,DAMAGE_PHYSICAL)
    effect(s,target.pos,'sulfur_alchemist_projectile_hit','run');Audio.play('dwarves_sulfur_alchemist_hit')
   end
  end
  table.insert(s.pending_removals,p)
 end
 queue_insert(store,e);return true
end
-- The screenshot lake is painted scenery, separate from native sliding terrain.
local visual_ice_lake=assert(love.filesystem.load('kr6_summon_public/ice_lake.lua'))()
function M.is_visual_ice(pos,store)
 if store.level_idx~=10 then return false end
 local map=visual_ice_lake
 local x=math.floor((pos.x-map.ox)/map.step)
 local row=map.rows[math.floor((map.top-pos.y)/map.step)+1]
 if x<0 or x>=map.width or not row then return false end
 -- Native open puddles are holes rather than ice.
 for _,p in ipairs({{x=177,y=380},{x=424,y=396},{x=614,y=232}})do
  if U.is_inside_ellipse(pos,p,25)then return false end
 end
 for i=1,#row,2 do if x>=row[i]and x<=row[i+1]then return true end end
 return false
end
function M.on_shard_ice(this,store)
 if GR.cell_is and GR:cell_is(this.pos.x,this.pos.y,TERRAIN_ICE)then return true end
 if M.is_visual_ice(this.pos,store)then return true end
 -- Use precisely the extra ice auras that the native troll pathfinder can slide on.
 local cfg=E.entities.mod_movement_terrain_troll_pathfinder
 for _,name in ipairs(cfg and cfg.auras_to_consider_terrain or {})do
  for _,a in pairs(store.entities)do
   if a.template_name==name and a.aura and not a._trainer_deleted and
    store.tick_ts-(a.aura.ts or 0)<(a.aura.duration or math.huge)and
    U.is_inside_ellipse(this.pos,a.pos,a.aura.radius)then return true end
  end
 end
 return false
end
function M.shard_count(this,store)
 local seen={};local count=0
 local function add(e)
  if e._shard_owner_id==this.id and alive(e)and not seen[e.id]then seen[e.id]=true;count=count+1 end
 end
 for _,e in pairs(store.entities)do add(e)end
 for _,e in ipairs(store.pending_inserts or {})do add(e)end
 return count
end
function M.can_spawn_shard(this,store)
 return alive(this)and(M.on_shard_ice(this,store)or M.shard_count(this,store)<3)
end
function M.spawn_shard(this,store)
 if not M.can_spawn_shard(this,store)then return false end
 local e=M.create('shard',{name='冰晶'},store)
 e._shard_owner_id=this.id
 e.pos={x=this.pos.x+20,y=this.pos.y};e.nav_rally.pos=clone(e.pos);e.nav_rally.center=clone(e.pos);e.nav_rally.new=false
 e._kr6_trainer=true;e._trainer_kind='shard';e.nav_rally.delay_min=nil;e.nav_rally.delay_max=nil;e.nav_grid.ignore_waypoints=true
 queue_insert(store,e);track_spawn(e,store);Audio.play('barbarians_apex_shard_spawn');return e
end
function M.stone_form(this,active)
 if this._stone==active then return end
 local ratio=this.health.hp/this.health.hp_max
 this._stone=active;this.health.hp_max=active and this._stone_hp*3.3 or this._stone_hp
 this.health.hp=this.health.hp_max*ratio
 this.melee.arrived_slot_animation=active and 'idleBlock'or'idle'
end
function M.heal(this,store,target)
 if not alive(this) or not friend(target) or target==this or target._trainer_kind=='mystic' or
  distance(this.pos,target.pos)>this._heal.range^2 or target.health.hp>=target.health.hp_max*.9 then return false end
 local src={x=this.pos.x,y=this.pos.y+30};local dst={x=target.pos.x,y=target.pos.y+15}
 target.health.hp=math.min(target.health.hp_max,target.health.hp+this._heal.modifier.healing_points)
 ray(store,src,dst,'sand_mysthic_healing',.65)
 effect(store,target.pos,'sand_mysthic_healing_modifier','run')
 return true
end
function M.spawn_eagle(this,store)
 if not alive(this) or this._eagle_sent then return false end
 this._eagle_sent=true
 local e=M.create('eagle',{name='沙漠鹰'},store)
 e._owner=this;e.pos=clone(this.pos);e.nav_rally.pos=clone(e.pos);e.nav_rally.center=clone(e.pos)
 e.nav_rally.new=false;e._kr6_trainer=true;e._trainer_kind='eagle'
 this._eagle=e;queue_insert(store,e);track_spawn(e,store)
 this.render.sprites[1].prefix='trainer_kr4_falconeer_alone'
 return true
end
function M.eagle_update(this,store)
 local attack_ts=store.tick_ts-3;local ambient_ts=store.tick_ts-7
 while not this._trainer_deleted do
  if this.health.dead then
   U.animation_start(this,'death',nil,store.tick_ts,false)
   Audio.play('group_sandstorm_eagle_death')
   while not U.animation_finished(this)do coroutine.yield()end
   table.insert(store.pending_removals,this);return
  end
  if this._owner and this._owner._trainer_deleted then
   this._trainer_deleted=true;table.insert(store.pending_removals,this);return
  end
  if not this.unit.is_stunned then
   if store.tick_ts-ambient_ts>=7 then Audio.play('group_sandstorm_eagle_ambient');ambient_ts=store.tick_ts end
   local target=not this.nav_rally.new and targets(store,(alive(this._owner) and this._owner.pos or this.nav_rally.center),470,function(t)
    return enemy(t) and bit.band(t.vis.flags,F_FLYING)==0
   end)[1]
   local dst=target and target.pos or this.nav_rally.pos
   local dist=math.sqrt(distance(this.pos,dst))
   if target and dist<=20 and store.tick_ts-attack_ts>=3 then
    this.render.sprites[1].flip_x=target.pos.x<this.pos.x
    cast(this,store,'attack',.16,function()
     if distance(this.pos,target.pos)<=40^2 then damage(store,this,target,7,9,DAMAGE_PHYSICAL)end
    end)
    attack_ts=store.tick_ts
   elseif dist>(target and 20 or 2) then
    local step=math.min(dist,this.motion.max_speed*store.tick_length)
    this.pos.x=this.pos.x+(dst.x-this.pos.x)/dist*step
    this.pos.y=this.pos.y+(dst.y-this.pos.y)/dist*step
    this.render.sprites[1].flip_x=dst.x<this.pos.x
    if this.render.sprites[1].name~='running' then U.animation_start(this,'running',nil,store.tick_ts,true)end
   else
    this.nav_rally.new=false;this.motion.arrived=true
    if this.render.sprites[1].name~='idle' then U.animation_start(this,'idle',nil,store.tick_ts,true)end
   end
  end
  coroutine.yield()
 end
 table.insert(store.pending_removals,this)
end
function M.promote(this,store,target)
 if not friend(target) or target.hero or target._kr6_trainer or target._kr4_promoted then return false end
 target._kr4_promoted=true
 -- KR6 ordinary barracks soldiers stand in for KR4 recruits. Preserve their tower and controls.
 local old=target.health.hp_max;local new=math.floor(old*1.5)
 target.health.hp_max=new;target.health.hp=math.min(new,target.health.hp+new-old)
 target.unit.damage_factor=target.unit.damage_factor*1.5
 effect(store,target.pos,'arcane_magus_projectile_hit','run')
 return true
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
  m.fx_start='trainer_kr4_magus_portal';m.fx_end=m.fx_start
  queue_insert(store,m);count=count+1
 end
 if count>0 then this._teleport_ts=store.tick_ts;Audio.play('linirea_arcane_magus_teleport')end
 return count
end
-- Rally coordinates are world distances; native paths average six units per node.
function M.ally_teleport_min_distance(this)
 return this._teleport.nodes*(P.average_node_dist or 6)
end
local function allied_destination_valid(t,p,store)
 local types=t.nav_grid and(t.nav_grid.valid_terrains_dest or t.nav_grid.valid_terrains)
 if t._ice_surface_walker then
  if M.is_visual_ice(p,store)then return true end
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
 local fx=E:create_entity('trainer_kr4_magus_portal');fx.pos=clone(p)
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
local sheep_components={'regen','dodge','auras','death_spawns'}
local function neutralize_sheep(t)
 for k,v in pairs(sheep_health)do t.health[k]=v end
 for _,k in ipairs(sheep_components)do t[k]=nil end
end
local function pause_sheep_aura(m,a)
 if not a.aura or a.aura.source_id~=m._target.id or not a.main_script or not a.main_script.update then return end
 if m._auras[a.id]or(not a.main_script.co and a.main_script.runs==0)then return end
 local script=a.main_script
 local co=script.co
 if not co then co=coroutine.create(script.update);script.runs=math.max(0,(script.runs or 1)-1)end
 local record={entity=a,script=script,co=co,hidden={}}
 if a.render then for i,r in ipairs(a.render.sprites)do record.hidden[i]=r.hidden;r.hidden=true end end
 record.paused=coroutine.create(function()while m._target._kr4_polymorph==m do coroutine.yield()end end)
 script.co=record.paused;m._auras[a.id]=record
end
local function restore_polymorph(m,store)
 local t=m._target
 if t and t._kr4_polymorph==m then
  -- A sheep killed during the effect has no native death explosion, spawn or resurrection.
  -- KR6 still handles health and rewards; only the special death coroutine is bypassed.
  if not alive(t)then
   t._kr4_polymorph=nil;SU.stun_dec(t)
   for _,record in pairs(m._auras)do table.insert(store.pending_removals,record.entity)end
   if t.health_bar then t.health_bar.hidden=true end
   if t.ui then t.ui.can_click=false;t.ui.can_select=false end
   local script=t.main_script
   if script then script.co=coroutine.create(function(e,s)
    U.animation_start(e,'death',nil,s.tick_ts,false)
    local ts=s.tick_ts;while s.tick_ts-ts<.5 do coroutine.yield()end
    table.insert(s.pending_removals,e)
   end)end
   return true
  end
  for k in pairs(sheep_health)do t.health[k]=m._health[k]end
  t.health.on_damage=m._health.on_damage
  for _,k in ipairs(sheep_components)do t[k]=m._components[k]end
  for _,record in pairs(m._auras)do
   local a=record.entity
   if record.script.co==record.paused then
    record.script.co=record.co
    if a.render then for i,r in ipairs(a.render.sprites)do r.hidden=record.hidden[i]end end
   end
  end
  t.render.sprites=m._sprites;t._kr4_polymorph=nil;SU.stun_dec(t)
  t.vis.flags=bit.bor(bit.band(t.vis.flags,bit.bnot(F_FLYING)),m._flying)
  t.vis.bans=bit.bor(bit.band(t.vis.bans,bit.bnot(F_BLOCK)),m._block_ban)
  t.unit.hit_offset=m._hit_offset;t.unit.mod_offset=m._mod_offset
  if t.health_bar then t.health_bar.offset=m._health_bar_offset end
  if t.ui then t.ui.click_rect=m._click_rect end
  if m._script and m._script.co==m._paused_co then m._script.co=m._native_co end
  if not t.health.dead then U.animation_start(t,'idle',nil,store.tick_ts,true)end
 end
 return true
end
local function can_polymorph(t)
 return enemy(t) and not t._kr4_polymorph and not t.hero and not t.unit.ignore_stun and
  not t.health.ignore_damage and not t._stone_form_pushed_bans and
  not (t.stone_form and t.render.sprites[1].prefix==t.stone_form.anim_prefix) and
  bit.band(t.vis.flags,F_BOSS)==0
end
function M.polymorph(this,store,target)
 local range=this._attack_range or 250
 if not alive(this) or not can_polymorph(target) or
  distance(this.pos,target.pos)>range*range or
  (this._polymorph_last_ts and store.tick_ts-this._polymorph_last_ts<20-1e-6) then return false end
 local m=E:create_entity('modifier')
 m.modifier.target_id=target.id;m.modifier.source_id=this.id
 m.modifier.type='trainer_djinni_polymorph';m.modifier.duration=13
 m.modifier.vis_flags=F_MOD;m.modifier.vis_bans=F_BOSS
 m.main_script.insert=function(e,s)
  local t=s.entities[e.modifier.target_id]
  local source=s.entities[e.modifier.source_id]
  if not alive(source) or not can_polymorph(t) or distance(source.pos,t.pos)>range*range then return false end
  e._target=t;e._sprites=t.render.sprites;e._start=s.tick_ts
  e._health={on_damage=t.health.on_damage};e._components={};e._auras={}
  for k in pairs(sheep_health)do e._health[k]=t.health[k]end
  for _,k in ipairs(sheep_components)do e._components[k]=t[k]end
  neutralize_sheep(t)
  t.health.on_damage=function(v)neutralize_sheep(v);return true end
  t._kr4_polymorph=e;SU.stun_inc(t)
  for _,a in pairs(s.entities)do pause_sheep_aura(e,a)end
  for _,a in ipairs(s.pending_inserts)do pause_sheep_aura(e,a)end
  e._flying=bit.band(t.vis.flags,F_FLYING);e._block_ban=bit.band(t.vis.bans,F_BLOCK)
  t.vis.flags=bit.band(t.vis.flags,bit.bnot(F_FLYING));t.vis.bans=bit.band(t.vis.bans,bit.bnot(F_BLOCK))
  e._hit_offset=t.unit.hit_offset;e._mod_offset=t.unit.mod_offset
  t.unit.hit_offset={x=0,y=12};t.unit.mod_offset={x=0,y=10}
  if t.health_bar then e._health_bar_offset=t.health_bar.offset;t.health_bar.offset={x=0,y=30}end
  if t.ui then e._click_rect=t.ui.click_rect;t.ui.click_rect={pos={x=-12,y=0},size={x=24,y=28}}end
  -- Pause the actual native coroutine, including mid-animation stone-form logic, without restarting it.
  local script=t.main_script
  if script and script.update then
   e._script=script;e._native_co=script.co
   if not e._native_co then
    e._native_co=coroutine.create(script.update);script.runs=math.max(0,(script.runs or 1)-1)
   end
   e._paused_co=coroutine.create(function(_,s)
    while t._kr4_polymorph==e and alive(t) do neutralize_sheep(t);coroutine.yield()end
    restore_polymorph(e,s)
   end)
   script.co=e._paused_co
  end
  local sprite=clone(t.render.sprites[1])
  sprite.prefix=this._trainer_kind=='sorcerer' and 'trainer_kr4_high_sorcerer_sheep' or 'trainer_kr4_desert_sheep'
  sprite.name='idle';sprite.angles=nil
  sprite.anchor={x=.5,y=.17};sprite.offset={x=0,y=0};sprite.ts=s.tick_ts;sprite.loop=true
  t.render.sprites={sprite}
  for _,ally in pairs(s.entities)do
   if ally.soldier and ally.soldier.target_id==t.id then U.unblock_target(s,ally)end
  end
  return true
 end
 m.main_script.remove=restore_polymorph
 m.main_script.update=function(e,s)
  while s.entities[e.modifier.target_id]==e._target and alive(e._target) and
   s.tick_ts<e._start+e.modifier.duration do
   neutralize_sheep(e._target)
   for _,a in pairs(s.entities)do pause_sheep_aura(e,a)end
   for _,a in ipairs(s.pending_inserts)do pause_sheep_aura(e,a)end
   coroutine.yield()
  end
  restore_polymorph(e,s);table.insert(s.pending_removals,e)
 end
 table.insert(store.pending_inserts,m)
 this._polymorph_last_ts=store.tick_ts
 return true
end
function M.shadow_jump(this,store)
 local t=SU.soldier_pick_melee_target(store,this)
 if not t or not enemy(t)or store.tick_ts-this._jump_ts<this._jump.cooldown then return false end
 local dx,dy=this.pos.x-t.pos.x,this.pos.y-t.pos.y
 local length=math.sqrt(dx*dx+dy*dy)
 if length<1 then dx,dy,length=this.render.sprites[1].flip_x and 1 or -1,0,1 end
 local p={x=t.pos.x+dx/length*120,y=t.pos.y+dy/length*120}
 if not GR:cell_is_only(p.x,p.y,this.nav_grid.valid_terrains_dest or this.nav_grid.valid_terrains)then return false end
 local jumped=cast(this,store,this._jump.animation_start,this._jump.action_time,function()
  U.unblock_target(store,this)
  this.pos=clone(p);this.nav_rally.pos=clone(p);this.nav_rally.center=clone(p)
  this.motion.dest=clone(p);this.motion.forced_waypoint=nil;this.motion.arrived=true
  this._jump_ts=store.tick_ts
 end)
 if jumped then cast(this,store,this._jump.animation_end,0,function()end)end
 return jumped
end
-- Original step frames plus a smooth, mirrored lunge create a melee animation without new atlas pages.
-- All mounted parts use the same transform around the elephant's sprite anchor.
local elephant_pose_keys={
 {t=0,x=0,y=0,r=0,sx=1,sy=1},
 {t=.20,x=-5,y=0,r=.035,sx=.98,sy=1.02},
 {t=.36,x=-7,y=2,r=.055,sx=.98,sy=1.03},
 {t=.50,x=10,y=-2,r=-.055,sx=1.04,sy=.96},
 {t=.62,x=7,y=-1,r=-.025,sx=1.02,sy=.98},
 {t=.82,x=-1,y=0,r=.01,sx=1,sy=1},
 {t=1,x=0,y=0,r=0,sx=1,sy=1}
}
function M.elephant_pose(this,store)
 local body=this.render.sprites[1]
 local t=store.tick_ts-body.ts
 local pose={x=0,y=0,r=0,sx=1,sy=1}
 if alive(this)and not this.unit.is_stunned and not this.nav_rally.new and body.name=='attack'and t>=0 and t<1 then
  for i=2,#elephant_pose_keys do
   local b=elephant_pose_keys[i];local a=elephant_pose_keys[i-1]
   if t<=b.t then
    local f=(t-a.t)/(b.t-a.t);f=f*f*(3-2*f)
    for _,k in ipairs({'x','y','r','sx','sy'})do pose[k]=a[k]+(b[k]-a[k])*f end
    break
   end
  end
  if t>=.5 and this._elephant_impact_ts~=body.ts then
   this._elephant_impact_ts=body.ts
   if enemy(store.entities[this.soldier.target_id])then Audio.play('dwarves_mechadwarf_impact')end
  end
 end
 local sign=body.flip_x and -1 or 1
 local angle=pose.r*sign;local c,s=math.cos(angle),math.sin(angle)
 body.offset={x=pose.x*sign,y=pose.y};body.r=angle;body.scale={x=pose.sx,y=pose.sy}
 for i,part in ipairs(this._elephant_parts)do
  local r=this.render.sprites[i+1]
  if r.name~='range'then r.flip_x=body.flip_x end
  local p=body.flip_x and part.position_flipped or part.position
  local px,py=(p.x-60)*pose.sx,(p.y-10)*pose.sy
  r.offset={x=body.offset.x+px*c-py*s,y=body.offset.y+px*s+py*c}
  r.r=angle;r.scale={x=pose.sx,y=pose.sy}
 end
end
-- Riders are rendered on the elephant and shoot independently of its native melee coroutine.
-- They have no separate faction, hit box, lifetime or selectable entity to leak across restarts.
function M.elephant_riders(this,store)
 local dead=not alive(this)
 local flip=this.render.sprites[1].flip_x
 for i,part in ipairs(this._elephant_parts)do
  local r=this.render.sprites[i+1]
  r.hidden=dead;r.flip_x=flip
  local p=flip and part.position_flipped or part.position
  r.offset={x=p.x-60,y=p.y-10}
 end
 M.elephant_pose(this,store)
 for _,shot in ipairs(this._rider_shots)do
  local r=this.render.sprites[shot._sprite]
  local target=shot.target_id and store.entities[shot.target_id]
  if dead or this.unit.is_stunned then shot.target_id=nil;r.name='idle';r.loop=true
  elseif shot.target_id then
   if not enemy(target)or distance(this.pos,target.pos)>shot.range^2 or distance(this.pos,target.pos)<shot.range_min^2 then
    shot.target_id=nil;r.name='idle';r.loop=true
   else
    r.flip_x=target.pos.x<this.pos.x
    if not shot.fired and store.tick_ts-r.ts>=shot.action_time then
     M.shoot(this,store,target,shot);shot.fired=true
    end
    if store.tick_ts-r.ts>=23/FPS then shot.target_id=nil;r.name='idle';r.loop=true end
   end
  elseif store.tick_ts-shot.ts>=shot.cooldown then
   local t=targets(store,this.pos,shot.range,function(t)return enemy(t)and distance(this.pos,t.pos)>=shot.range_min^2 end)[1]
   if t then
    shot.ts=store.tick_ts;shot.cooldown=1+math.random()*.3;shot.target_id=t.id;shot.fired=false
    r.name='range';r.ts=store.tick_ts;r.loop=false
    r.flip_x=t.pos.x<this.pos.x
   end
  end
 end
 if not dead and this.render.sprites[1].name=='running'and store.tick_ts-this._ambient_ts>=6 then
  this._ambient_ts=store.tick_ts;Audio.play('group_sandstorm_elephant_ambient')
 end
end
local function special(this,store)
 local kind=this._trainer_kind;local now=store.tick_ts
 if kind=='ice_witch'and now-this._spawn_ts>=this._spawner.cooldown and not has_melee_target(this,store)and M.can_spawn_shard(this,store)then
  if targets(store,this.pos,this._shots[1].range,enemy)[1]then
   return cast(this,store,'summon',this._spawner.action_time,function()
    if M.spawn_shard(this,store)then this._spawn_ts=store.tick_ts end
   end,function()return has_melee_target(this,store)end)
  end
 end
 if kind=='alchemist'and now-this._heal_shot.ts>=this._heal_shot.cooldown and not has_melee_target(this,store)then
  local shot=this._heal_shot
  local t=targets(store,this.pos,shot.range,function(t)return healable(this,t)and t.health.hp<=t.health.hp_max*.75 end)[1]
  if t then
   this.render.sprites[1].flip_x=t.pos.x<this.pos.x
   return cast(this,store,shot.animation_start,shot.action_time,function()
    if healable(this,t)and distance(this.pos,t.pos)<=shot.range^2 then
     M.new_projectile(this,store,t,shot,true);shot.ts=store.tick_ts
    end
   end,function()return has_melee_target(this,store)end)
  end
 end
 if kind=='falconer' and not this._eagle_sent and not has_melee_target(this,store) then
  local target=targets(store,this.pos,this._summon_range,enemy)[1]
  if target then return cast(this,store,'spawnEagle',.2,function()
   if enemy(target) and distance(this.pos,target.pos)<=this._summon_range^2 then M.spawn_eagle(this,store)end
  end,function()return has_melee_target(this,store)end)end
 end
 if kind=='mystic' and now-this._heal_ts>=this._heal.cooldown and not has_melee_target(this,store) then
  local list=targets(store,this.pos,this._heal.range,function(t)
   return friend(t) and t~=this and t._trainer_kind~='mystic' and t.health.hp<t.health.hp_max*.9
  end)
  if list[1] then return cast(this,store,'heal',this._heal.action_time,function()
   if M.heal(this,store,list[1])then this._heal_ts=store.tick_ts end
  end,function()return has_melee_target(this,store)end)end
 end
 if kind=='sorcerer' and now-(this._polymorph_last_ts or this._skill_ts)>=20 then
  local list=targets(store,this.pos,this._attack_range,can_polymorph)
  if list[1] then
   this.render.sprites[1].flip_x=list[1].pos.x<this.pos.x
   return cast(this,store,'special',.5,function()
    if M.polymorph(this,store,list[1])then
     Audio.play('linirea_high_sorcerer_sheepbleat')
     effect(store,list[1].pos,'high_sorcerer_smoke','run')
    end
   end)
  end
 elseif kind=='captain' and now-this._skill_ts>=6 and not this.soldier.target_id then
  local list=targets(store,this.pos,220,function(t)
   return friend(t) and not t.hero and not t._kr6_trainer and not t._kr4_promoted
  end)
  if list[1] then
   this._skill_ts=now
   return cast(this,store,'special',.3,function()M.promote(this,store,list[1])end)
  end
 elseif kind=='magus' then
  if has_melee_target(this,store) then return false end
  local interrupted=function()return has_melee_target(this,store)end
  if now-this._teleport_ts>=this._teleport.cooldown then
   local plans=M.allied_teleport_plans(this,store)
   if #plans>0 then
    return cast(this,store,'teleport',.433,function()M.teleport_allies(this,store,plans)end,interrupted)
   elseif targets(store,this.pos,this._teleport.range,can_teleport)[1]then
    return cast(this,store,'teleport',.433,function()M.teleport(this,store)end,interrupted)
   end
  end
  if now-this._skill_ts>=3 then
   local list=targets(store,this.pos,this._attack_range,enemy)
   if list[1] then
    this._skill_ts=now;local p=clone(list[1].pos)
    return cast(this,store,'shoot',.3,function()M.rain(this,store,p)end,interrupted)
   end
  end
 elseif this._shots then
  if has_melee_target(this,store) then return false end
  for _,attack in ipairs(this._shots)do
   if now-attack.ts>=attack.cooldown then
    local list=targets(store,this.pos,attack.range,function(t)
     return enemy(t) and distance(this.pos,t.pos)>=(attack.range_min or 0)^2
    end)
    if list[1] then
     local t=list[1];attack.ts=now
     local name=attack.animation_start
     local ending
     if attack.angle_animation then
      local dx,dy=t.pos.x-this.pos.x,t.pos.y-this.pos.y
      local angle=math.abs(dy)>math.abs(dx)*.75 and (dy>=0 and 'up' or 'down') or 'lateral'
      name=attack.angle_animation[angle].animation_start;ending=attack.angle_animation[angle].animation_end
     end
     this.render.sprites[1].flip_x=t.pos.x<this.pos.x
     local interrupt=function()return has_melee_target(this,store)end
     if attack.animation_first_time and not this._range_ready then
      local prep=animations[this.render.sprites[1].prefix..'_'..attack.animation_first_time]
      if not cast(this,store,attack.animation_first_time,(prep.to-prep.from+1)/FPS,function()end,interrupt) then return false end
      this._range_ready=true
     end
     local fired=cast(this,store,name,attack.action_time,function()
      if enemy(t) and distance(this.pos,t.pos)<=attack.range^2 then
       M.shoot(this,store,t,attack)
       local extra_delay=0
       for _,delay in ipairs(attack.extra_proyectiles or {})do
        extra_delay=extra_delay+delay
        delayed(store,extra_delay,function(s)
         if alive(this) and not this.unit.is_stunned and not this.nav_rally.new and not interrupt() and
          enemy(t) and distance(this.pos,t.pos)<=attack.range^2 then M.shoot(this,s,t,attack)end
        end)
       end
       if attack.animation_loop then U.animation_start(this,attack.animation_loop,nil,store.tick_ts,false)end
       if ending then U.animation_start(this,ending,nil,store.tick_ts,false)end
      end
     end,interrupt,attack.animation_scale)
     if fired and attack.animation_end then cast(this,store,attack.animation_end,0,function()end,interrupt)end
     return fired
    end
   end
  end
 elseif kind=='valkyrie' and now-this._skill_ts>=1 and not has_melee_target(this,store) then
  local list=targets(store,this.pos,200,function(t)
   return t.soldier and not t.enemy and not t.hero and t.health and t.health.dead and
    not t._kr4_revived and (t._trainer_kind=='huntress' or t._trainer_kind=='wildling' or t._trainer_kind=='barbarian')
  end)
  if list[1] then
   this._skill_ts=now
   return cast(this,store,'summon',.4,function()
    for n=1,math.min(3,#list)do M.revive(this,store,list[n])end
   end,function()return has_melee_target(this,store)end)
  end
 elseif kind=='djinni' and now-this._skill_ts>=20 then
  local list=targets(store,this.pos,this._attack_range,function(t)
   return can_polymorph(t)
  end)
  if list[1] then
   this._skill_ts=now
   return cast(this,store,'polimorph',.5,function()
    M.polymorph(this,store,list[1])
   end)
  end
 end
 return false
end
function M.charge(this,store)
 local now=store.tick_ts
 if this.nav_rally.new and not this.health.dead and not this.unit.is_stunned and
  now-this._charge_ts>=4 and distance(this.pos,this.nav_rally.pos)>60*60 then
  this._charge_ts=now;this._charge_until=now+2;this._charge_hits={}
 end
 local active=this._charge_until and now<this._charge_until and not this.health.dead and not this.unit.is_stunned
 if active and not this._charge_audio then
  Audio.play('linirea_knight_rider_charge_loopstart')
  this._charge_audio=Audio.start_loop('linirea_knight_rider_charge_loop',this.id)
 elseif not active and this._charge_audio then
  Audio.stop(this._charge_audio);this._charge_audio=nil
  Audio.play('linirea_knight_rider_charge_loopend')
 end
 this.motion.max_speed=this._walk_speed*(active and 2 or 1)
 this.render.sprites[1].angles.walk={active and 'chargeWalk' or 'running'}
 if active then
  for _,t in ipairs(targets(store,this.pos,50,function(e)
   return enemy(e) and bit.band(e.vis.flags,F_FLYING)==0
  end))do
   if not this._charge_hits[t.id] and this._charge_count<6 then
    this._charge_hits[t.id]=true;this._charge_count=this._charge_count+1
    damage(store,this,t,16,24,DAMAGE_PHYSICAL)
   end
  end
 else this._charge_count=0 end
end
function M.revive(this,store,target)
 if not alive(this) or store.entities[target.id]~=target or not target.health.dead or target._kr4_revived or
  not target.soldier or target.enemy or target.hero or distance(this.pos,target.pos)>200*200 or
  (target._trainer_kind~='huntress' and target._trainer_kind~='wildling' and target._trainer_kind~='barbarian') then return false end
 target._kr4_revived=true
 local e=M.create('draugr',{name='北国亡魂'},store)
 e.pos=clone(target.pos);e.nav_rally.pos=clone(e.pos);e.nav_rally.center=clone(e.pos);e.nav_rally.new=false
 e.nav_rally.delay_min=nil;e.nav_rally.delay_max=nil;e.nav_grid.ignore_waypoints=true
 e._kr6_trainer=true;e._trainer_kind='draugr';e.render.sprites[1].ts=store.tick_ts
 queue_insert(store,e);track_spawn(e,store)
 return true
end
function M.dismount(this,store)
 if this._dismounted or this._trainer_deleted then return end
 this._dismounted=true
 local p=clone(this.pos)
 delayed(store,.37,function(s)
  if this._trainer_deleted then return end
  local kind=this._trainer_kind=='camel' and 'legionnaire' or 'dismounted'
  local e=M.create(kind,{name=kind=='legionnaire' and '军团士兵' or '下马圣骑士'},s)
  e.pos=clone(p);e.nav_rally.pos=clone(p);e.nav_rally.center=clone(p);e.nav_rally.new=false
  e.nav_rally.delay_min=nil;e.nav_rally.delay_max=nil;e.nav_grid.ignore_waypoints=true
  e._kr6_trainer=true;e._trainer_kind=kind
  e.render.sprites[1].ts=s.tick_ts
  queue_insert(s,e);track_spawn(e,s)
 end)
end
function M.create(kind,def,store)
 Audio.prepare()
 local s=assert(spec[kind]);local d=s.source
 -- Start with a native allied paladin to retain the tested grid, rally, selection and faction components.
 local e=E:create_entity('soldier_paladin')
 e.powers=nil;e.timed_actions=nil;e.ranged=nil;e.auras=nil;e.dodge=nil;e.cloak=nil
 e.enemy=nil;e.nav_path=nil;e.track_kills=nil;e.track_damage=nil
 if kind=='ice_witch'or kind=='shard'then
  -- Only their own rally navigation accepts the lake surface; the world grid remains intact.
  e._ice_surface_walker=true
  e.nav_grid.valid_terrains=bit.bor(e.nav_grid.valid_terrains,TERRAIN_NOWALK)
  e.nav_grid.valid_terrains_dest=bit.bor(e.nav_grid.valid_terrains_dest or e.nav_grid.valid_terrains,TERRAIN_NOWALK)
 end
 e.health.hp_max=s.hp;e.health.hp=s.hp
 if kind=='archer'then e.health.hp_max=200;e.health.hp=200
 elseif kind=='warhammer'then e.health.hp_max=math.floor(s.hp*1.3+.5);e.health.hp=e.health.hp_max end
 e.health.armor=d.armor_type==0 and d.armor/100 or 0
 e.health.magic_armor=d.armor_type==1 and d.armor/100 or 0
 e.motion.max_speed=d.speed or d.speed_max;e.regen.health=math.max(5,math.floor(s.hp*.02))
 local key='TRAINER_KR4_'..kind:upper()
 local L=require('i18n')
 for _,messages in pairs(L.msgs or {})do messages[key..'_NAME']=def.name end
 e.info.random_name_format=nil;e.info.i18n_key=key;e.info.portrait=s.portrait
 e.info.fn=function(t)
  local a=t._display_attack or (t.melee and t.melee.attacks[#t.melee.attacks])
  return {type=STATS_TYPE_SOLDIER,hp=t.health.hp,hp_max=t.health.hp_max,
   damage_min=a and a.damage_min*t.unit.damage_factor or 0,
   damage_max=a and a.damage_max*t.unit.damage_factor or 0,
   damage_type=a and a.damage_type or DAMAGE_MAGICAL,
   armor=t.health.armor,magic_armor=t.health.magic_armor,respawn=t.health.dead_lifetime}
 end
 local sprite=e.render.sprites[1]
 sprite.prefix='trainer_kr4_'..s.prefix;sprite.anchor=clone(d.anchor);sprite.name='idle'
 sprite.angles={walk={'running'}}
 e.health_bar.offset={x=0,y=d.life_bar.y}
 e.unit.hit_offset=clone(d.hit_position);e.unit.head_offset=clone(d.head_position)
 e.unit.mod_offset=clone(d.modifier_position)
 e.ui.can_click=true;e.ui.can_select=true
 e.ui.click_rect={pos={x=-14,y=-2},size={x=28,y=d.life_bar.y}}
 local a=clone(e.melee.attacks[1]);e.melee.attacks={a};e.melee.range=60
 for _,skill in ipairs(d.skills)do
  if skill.key=='melee' and (skill.main or not skill.area) then
   a.damage_min=skill.damage_min or skill.damage;a.damage_max=skill.damage_max or skill.damage;a.cooldown=skill.cooldown
   local first=skill.animation_random and skill.animation_random[1]
   a.animation=skill.animation_start or (first and first.animation_start) or 'attack'
   a.hit_time=skill.action_time or (first and first.action_time) or .43
   if skill.extra_hits then
    a.hit_times={a.hit_time};local time=a.hit_time
    for _,delay in ipairs(skill.extra_hits)do time=time+delay;a.hit_times[#a.hit_times+1]=time end
   end
  end
 end
 local melee_factor=(kind=='mystic'or kind=='gunman')and 1.2 or kind=='warhammer'and 1.15 or 1
 a.damage_min=math.floor(a.damage_min*melee_factor+.5);a.damage_max=math.floor(a.damage_max*melee_factor+.5)
 a.damage_type=DAMAGE_PHYSICAL;a.pop=nil;a.sound=Audio.key('group_generic_combat')
 e.sound_events.death=Audio.key(kind=='mecha' and 'dwarves_mechadwarf_death' or
  (kind=='camel' or kind=='mystic' or kind=='eagle' or kind=='alchemist' or kind=='frost_giant' or kind=='elephant') and d.death_sound or 'common_enemie_dead')
 e.sound_events.death_by_explosion=e.sound_events.death
 if kind=='magus' then
  e._attack_range=210
  e._teleport={count=4,cooldown=15,nodes=25,range=e._attack_range}
  e._display_attack={damage_min=14,damage_max=21,damage_type=DAMAGE_MAGICAL}
 elseif kind=='captain' then
  local spear=clone(a);spear.animation='attackSpear';spear.hit_time=.5
  spear.chance=.5;spear.cooldown_group='captain';a.cooldown_group='captain'
  e.melee.attacks={spear,a}
 elseif kind=='shield' then e.melee.arrived_slot_animation='idleBlock'
 elseif kind=='assassin' then
  local kill=clone(a);kill.instakill=true;kill.chance=.15;kill.animation='instakill'
  kill.hit_time=.46;kill.cooldown=.45;kill.vis_bans=bit.bor(kill.vis_bans,F_BOSS)
  kill.sound=Audio.key('kr4_enemies_sandstorm_assassin_instakill')
  kill.cooldown_group='assassin';a.cooldown_group='assassin';e.melee.attacks={kill,a}
  E:add_comps(e,'dodge');e.dodge.chance=.15;e.dodge.animation='dodge'
  e.dodge.sound=Audio.key('kr4_enemies_sandstorm_nomad_dodge')
 elseif kind=='djinni' then
  e.melee=nil;e._attack_range=250
 elseif kind=='sorcerer' then
  e._attack_range=300*.75
  e.ui.click_rect={pos={x=-28,y=-2},size={x=56,y=d.life_bar.y}}
 elseif kind=='musketeer' or kind=='archer' or kind=='huntress' or kind=='ranger' or kind=='gunman' or kind=='mystic' or kind=='ice_witch' or kind=='alchemist' or kind=='nomad' then
  e._shots={}
  for _,skill in ipairs(d.skills)do
   if skill.key=='range_unit' then
    local shot=clone(skill);shot.ts=store.tick_ts
    if kind=='mystic' then
     shot.range=skill.range*.6;shot.cooldown=skill.cooldown*1.2
     shot.proyectile.damage_min=36
     shot.proyectile.damage_max=52
     shot.proyectile.damage_area=skill.proyectile.damage_area*.6
    else
     shot.range=skill.range*.75
    end
    if kind=='archer' and skill.main then
     shot.proyectile.damage_min=legion_archer_damage.min;shot.proyectile.damage_max=legion_archer_damage.max
     shot.range_min=0
     shot.cooldown=skill.cooldown-.1;shot.animation_scale=.6/.7
     shot.action_time=skill.action_time*shot.animation_scale
    end
    if kind=='gunman'then
     shot.proyectile.damage_min=math.floor(skill.proyectile.damage_min*1.2+.5)
     shot.proyectile.damage_max=math.floor(skill.proyectile.damage_max*1.2+.5)
    end
    if kind=='alchemist'and not skill.main then e._heal_shot=shot;shot.range=skill.range
    else e._shots[#e._shots+1]=shot end
    if skill.main then e._display_attack={damage_min=shot.proyectile.damage_min,damage_max=shot.proyectile.damage_max,
     damage_type=(kind=='mystic'or kind=='ice_witch')and DAMAGE_MAGICAL or DAMAGE_PHYSICAL}end
   end
   if skill.key=='heal' then e._heal=clone(skill);e._heal_ts=store.tick_ts-skill.cooldown end
   if skill.key=='spawner'then e._spawner=clone(skill);e._spawn_ts=store.tick_ts-skill.cooldown end
  end
 elseif kind=='falconer' then
  e._summon_range=470*.75
 elseif kind=='cavalry' then
  e._walk_speed=d.speed;e._charge_ts=store.tick_ts-4;e._charge_count=0
 end
 if kind=='geomancer'then e._stone=false;e._stone_hp=s.hp end
 if kind=='frost_giant'then a.sound=Audio.key('barbarians_frost_giant_attack');e.ui.click_rect={pos={x=-26,y=-4},size={x=52,y=68}}end
 if kind=='nomad'then
  for _,skill in ipairs(d.skills)do if skill.key=='shadow_jump'then e._jump=clone(skill)end end
  e._jump_ts=store.tick_ts-e._jump.cooldown
 end
 if kind=='elephant'then
  -- Native single-target melee supplies armor, blocking, damage timing and interruption rules.
  a.animation='attack';a.damage_min=72;a.damage_max=108;a.cooldown=2;a.hit_time=.5
  a.damage_type=DAMAGE_PHYSICAL;a.sound=nil;a.hit_times=nil
  e.melee.attacks={a};e.melee.order={1};e.melee.cooldown=2;e.melee.arrived_slot_animation='idle'
  e.ui.click_rect={pos={x=-34,y=-2},size={x=68,y=70}}
  e.unit.size=UNIT_SIZE_LARGE
  e._elephant_parts=clone(d.units.units);e._rider_shots={};e._ambient_ts=store.tick_ts
  local archer_range
  for _,skill in ipairs(spec.archer.source.skills)do
   if skill.key=='range_unit'and skill.main then archer_range=skill.range*.75 end
  end
  for i,part in ipairs(e._elephant_parts)do
   local rider=part.key=='elephant_lancer_unit'
   local r=clone(sprite);r.prefix='trainer_kr4_'..(rider and 'war_elephant_archer_unit'or'war_elephant_archer_mount')
   r.angles=nil;r.ignore_start=true;r.anchor=clone(rider and s.rider.anchor or {x=.5,y=.5})
   r.name='idle';r.ts=store.tick_ts;r.offset={x=part.position.x-60,y=part.position.y-10}
   e.render.sprites[#e.render.sprites+1]=r
   if rider then
    local shot=clone(s.rider.skills[1]);shot.range=assert(archer_range)*11/10
    shot.proyectile.damage_min=legion_archer_damage.min;shot.proyectile.damage_max=legion_archer_damage.max
    shot.cooldown=shot.cooldown_min;shot.ts=store.tick_ts;shot._sprite=i+1
    e._rider_shots[#e._rider_shots+1]=shot
   end
  end
  e._display_attack=a
  e._ranged_display_attack={damage_min=legion_archer_damage.min,damage_max=legion_archer_damage.max,damage_type=DAMAGE_PHYSICAL}
 end
 -- Area strikes require damage_flags/damage_bans, absent from a basic melee attack.
 -- Clone the native area component so filtering cannot terminate the soldier coroutine.
 for _,skill in ipairs(d.skills)do
  if skill.key=='melee' and skill.area then
   local sweep=E:clone_c('area_attack')
   sweep.animation=skill.animation_start;sweep.hit_time=skill.action_time;sweep.cooldown=skill.cooldown
   sweep.damage_type=DAMAGE_PHYSICAL;sweep.damage_min=skill.damage_min or skill.damage
   sweep.damage_max=skill.damage_max or skill.damage;sweep.damage_radius=skill.area.range
   sweep.count=skill.area.max_units;sweep.hit_offset=clone(skill.area.centerOffset)
   sweep.sound=Audio.key(kind=='sorcerer' and 'linirea_high_sorcerer_hit' or kind=='mecha' and 'dwarves_mechadwarf_impact' or 'group_generic_combat')
   if kind=='sorcerer' then e.melee.attacks={sweep}
   else table.insert(e.melee.attacks,1,sweep)end
  end
 end
 e._skill_ts=store.tick_ts;e._teleport_ts=store.tick_ts
 if kind=='magus'then e._teleport_ts=store.tick_ts-e._teleport.cooldown end
 if kind=='sorcerer' then e._skill_ts=store.tick_ts-20 end
 e.main_script.update=function(this,st,script)
  local co=coroutine.create(native.update)
  if kind=='shard'then cast(this,st,'spawn',71/FPS,function()end)end
  while coroutine.status(co)~='dead' do
   if this._trainer_deleted then return end
   if kind=='elephant'then M.elephant_riders(this,st)end
   if kind=='nomad'and alive(this)and not this.unit.is_stunned and not this.nav_rally.new then
    if M.shadow_jump(this,st)then co=coroutine.create(native.update)end
   end
   if kind=='cavalry' or kind=='camel' then
    if kind=='cavalry' then M.charge(this,st)end
    if this.health.dead then M.dismount(this,st)end
   end
   if kind=='shield' then this.health.armor=this.soldier.target_id and 0 or .9 end
   if kind=='frost_giant'and alive(this)then
    local r=this.render.sprites[1]
    if r.name=='attack'and st.tick_ts-r.ts>=a.hit_time and this._giant_hit_ts~=r.ts then
     this._giant_hit_ts=r.ts;local t=st.entities[this.soldier.target_id]
     if enemy(t)then effect(st,t.pos,'frost_giant_hit','run')end
    end
   end
   if kind=='geomancer'and alive(this)then
    local stone=not this.nav_rally.new and not this.unit.is_stunned and has_melee_target(this,st)
    if stone~=this._stone then
     if not stone and(this.nav_rally.new or this.unit.is_stunned)then M.stone_form(this,false)
     else
      local animation=stone and'toStone'or'toDwarf'
      local duration=stone and 24/FPS or 16/FPS
      cast(this,st,animation,duration,function()M.stone_form(this,stone)end)
     end
     co=coroutine.create(native.update)
    end
   end
   local name=this.render.sprites[1].name
   if not this.health.dead and not this.unit.is_stunned and not this.nav_rally.new and
    (kind=='sorcerer' or name=='idle' or name=='idleBlock') then
    local casted=special(this,st)
    if kind=='sorcerer' and casted then
     -- Discard an interrupted native melee wait; resume from a fresh idle cycle.
     co=coroutine.create(native.update)
     U.animation_start(this,'idle',nil,st.tick_ts,true)
    end
   end
   local ok,err=coroutine.resume(co,this,st,script)
   if not ok then error(err)end
   if kind=='elephant'then M.elephant_pose(this,st)end
   if coroutine.status(co)~='dead' then coroutine.yield()end
  end
 end
 if kind=='eagle' then
  e.melee=nil;e.main_script.update=M.eagle_update;e.regen=nil
  e.nav_rally.immune_to=0
  e.main_script.insert=function(this,st)
   -- Native soldier insertion hides/ protects units until its rally coroutine runs.
   -- The custom flight coroutine must finish that transition itself.
   local bans=bit.bor(this.vis.bans,F_BLOCK)
   if native.insert(this,st)==false then return false end
   this.vis.bans=bans
   return true
  end
  e.vis.flags=bit.bor(e.vis.flags,F_FLYING)
  sprite.offset={x=0,y=40};e.health_bar.offset.y=e.health_bar.offset.y+40
  e.unit.hit_offset.y=e.unit.hit_offset.y+40;e.unit.head_offset.y=e.unit.head_offset.y+40
  e.unit.mod_offset.y=e.unit.mod_offset.y+40
  e.ui.click_rect={pos={x=-16,y=30},size={x=32,y=35}}
  e._display_attack={damage_min=7,damage_max=9,damage_type=DAMAGE_PHYSICAL}
 end
 return e
end
return M
