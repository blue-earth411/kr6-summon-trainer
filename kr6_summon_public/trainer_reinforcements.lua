-- Permanent trainer squad, using the native soldier rally and blocking logic.
local M={}
local E=require('entity_db')
local U=require('utils')
local SU=require('script_utils')
local GR=require('grid_db')
local A=require('klove.animation_db')
local I=require('klove.image_db')
local group_name='trainer_reinforcements'
local animations=assert(love.filesystem.load('kr6_summon_public/'..group_name..'/animations.lua'))()
local offsets={{0,-12},{0,12}}

function M.load_assets()
 require('kr6_summon_public.trainer_audio').prepare_native()
 if not I.db_images[group_name] or not I.db_atlas.trainer_reinforcement_1_0001 then
  I.atlas_uses[group_name..'-0.500000']=nil
  I:load_atlas(.5,'kr6_summon_public/'..group_name,group_name,false)
 end
 for name,animation in pairs(animations)do A.db[name]=animation end
 assert(I.db_atlas.trainer_reinforcement_4_0001 and I.db_atlas.trainer_reinforcement_javelin)
end

local function valid(e,p)
 return GR:cell_is_only(p.x,p.y,e.nav_grid.valid_terrains_dest or e.nav_grid.valid_terrains)
end

local function entry_plan(e,p)
 if not valid(e,p)then return end
 for _,length in ipairs({34,22,12})do
  for _,f in ipairs({{x=1,y=0},{x=-1,y=0},{x=0,y=1},{x=0,y=-1},
    {x=.8,y=.6},{x=-.8,y=.6},{x=.8,y=-.6},{x=-.8,y=-.6}})do
   for _,width in ipairs({1,.65,.4})do
    local goals,starts={},{}
    local clear=true
    for i,o in ipairs(offsets)do
     local q={x=p.x-f.y*o[2]*width,y=p.y+f.x*o[2]*width}
     for step=0,math.ceil(length/5)do
      local d=length*step/math.ceil(length/5)
      if not valid(e,{x=q.x-f.x*d,y=q.y-f.y*d})then clear=false;break end
     end
     if not clear then break end
     goals[i]=q
     starts[i]={x=q.x-f.x*length,y=q.y-f.y*length}
    end
    if clear then return {goals=goals,starts=starts,forward=f,length=length} end
   end
  end
 end
end

local function spiked_hit(this,store,hit)
 local attacker=store.entities[hit.source_id]
 if attacker and attacker.enemy and attacker.health and not hit._linirea_reflected then
  local hits=store._linirea_spiked_hits or {}
  store._linirea_spiked_hits=hits
  hits[#hits+1]={incoming=hit,source=this.id,attacker=attacker.id}
 end
 return true
end

-- on_damage runs before mitigation. Process the resolved hit at the next health tick.
function M.flush_spikes(store)
 local hits=store._linirea_spiked_hits
 if not hits then return end
 store._linirea_spiked_hits=nil
 for _,hit in ipairs(hits)do
  local target=store.entities[hit.attacker]
  local taken=hit.incoming.damage_applied or 0
  if taken>0 and target and target.enemy and not target.health.dead then
   local reflected=E:create_entity('damage')
   reflected.source_id=hit.source
   reflected.target_id=hit.attacker
   reflected.damage_type=DAMAGE_TRUE
   reflected.value=taken*.1
   reflected._linirea_reflected=true
   table.insert(store.damage_queue,reflected)
  end
 end
end

local function create(def,store,variant,native)
 local e=require('kr6_summon_public.trainer_public_spear').create()
 e.health.hp,e.health.hp_max=110,110
 e.health.armor,e.health.magic_armor=.3,0
 e.health.on_damage=spiked_hit
 e.regen.health=15
 -- Track hits in the native component, but schedule the out-of-combat ticks here.
 e.regen.cooldown=math.huge
 e.regen.last_hit_standoff_time=native.regen.last_hit_standoff_time
 e.motion.max_speed=native.motion.max_speed
 e.soldier.melee_slot_offset=native.soldier.melee_slot_offset
 e.melee.range=native.melee.range
 local melee=e.melee.attacks[1]
 melee.damage_min,melee.damage_max=6,10
 melee.hit_time,melee.cooldown,melee.animation=.3,1,'attack'
 e.melee.cooldown=1
 local shot={range=165,range_min=27,cooldown=1.4,ts=-math.huge,action_time=15/FPS,
  animation_start='throw',projectile_frame='trainer_reinforcement_javelin',
  projectile_origin={x=16,y=22},projectile_arc=24,
  proyectile={damage_min=24,damage_max=40,release_sound='Sound_ArrowRelease2'}}
 e._shots={shot}
 e._ranged_display_attack={damage_min=24,damage_max=40,damage_type=DAMAGE_PHYSICAL}
 e._display_attack=e._ranged_display_attack
 local sprite=e.render.sprites[1]
 sprite.prefix='trainer_reinforcement_'..variant
 sprite.angles=native.render.sprites[1].angles
 sprite.anchor={x=.5,y=12/92}
 e.info.portrait=sprite.prefix..'_portrait'
 e.info.i18n_key='TRAINER_LINIREA_REINFORCEMENT'
 for _,messages in pairs(require('i18n').msgs or {})do
  messages.TRAINER_LINIREA_REINFORCEMENT_NAME=def.name
 end
 e.health_bar.offset.y=32
 e.ui.click_rect={pos={x=-11,y=-3},size={x=22,y=32}}
 e.unit.hit_offset={x=0,y=14}
 e.unit.head_offset={x=0,y=25}
 e.unit.mod_offset={x=0,y=15}
 return e
end

local function enter(e,length)
 local base_update=e.main_script.update
 e.main_script.update=function(this,st,script)
  local ts=st.tick_ts
  local duration=length/this.motion.max_speed
  local sprite=this.render.sprites[1]
  -- The native rally drives the same walk animation for entry and player orders.
  local rally=coroutine.create(SU.y_soldier_new_rally)
  this.nav_rally.new=true
  while not this._trainer_deleted do
   local ok,err=coroutine.resume(rally,st,this)
   if not ok then error(err)end
   if coroutine.status(rally)=='dead'then break end
   sprite.alpha=math.floor(255*math.min(1,.42+(st.tick_ts-ts)/duration*2))
   coroutine.yield()
  end
  if this._trainer_deleted then return end
  sprite.alpha=255
  this._linirea_entering=nil
  U.animation_start(this,'idle',nil,st.tick_ts,true)
  local combat=coroutine.create(base_update)
  local next_heal=st.tick_ts+this.regen.last_hit_standoff_time
  repeat
   if this.soldier.target_id or sprite.name=='attack' or sprite.name=='throw' then
    this.regen.last_hit_ts=st.tick_ts
   elseif not this.health.dead then
    next_heal=math.max(next_heal,this.regen.last_hit_ts+this.regen.last_hit_standoff_time)
    if st.tick_ts>=next_heal-1e-7 and this.health.hp<this.health.hp_max then
     this.health.hp=math.min(this.health.hp_max,this.health.hp+this.regen.health)
     next_heal=st.tick_ts+1
    end
   end
   local ok,err=coroutine.resume(combat,this,st,script)
   if not ok then error(err)end
   if coroutine.status(combat)~='dead'then coroutine.yield()end
  until coroutine.status(combat)=='dead' or this._trainer_deleted
 end
 e._linirea_entering=true
end

function M.prepare(def,store,p)
 local native=assert(E:create_entity('soldier_reinforcement_base'))
 local first=math.random(4)
 local second=math.random(3)
 if second>=first then second=second+1 end
 local e=create(def,store,first,native)
 local plan=entry_plan(e,p)
 if not plan then return end
 M.load_assets()
 local group={members={e,create(def,store,second,native)},forward=plan.forward,goals=plan.goals,
  offsets=offsets,reinforcements=true}
 for i,member in ipairs(group.members)do
  local goal=plan.goals[i]
  member._legion_group=group
  member._legion_group_slot=i
  member._kr6_trainer=true
  member._trainer_kind='linirea_reinforcements'
  member.pos=plan.starts[i]
  member.nav_rally.pos={x=goal.x,y=goal.y}
  member.nav_rally.center={x=goal.x,y=goal.y}
  member.nav_rally.new=false
  member.nav_rally.delay_min,member.nav_rally.delay_max=nil,nil
  member.nav_grid.ignore_waypoints=true
  member.render.sprites[1].flip_x=plan.forward.x<0
  enter(member,plan.length)
 end
 return group
end

function M.play_arrival()
 require('kr6_summon_public.trainer_audio').play('ReinforcementTaunt')
end

return M
