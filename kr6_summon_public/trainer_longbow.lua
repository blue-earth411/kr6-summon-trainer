-- User-approved original Elite Longbowman, with native allied movement and health rules.
local M={}
local E=require('entity_db');local U=require('utils');local SU=require('script_utils');local bit=require('bit')
local I=require('klove.image_db');local A=require('klove.animation_db');local S=require('sound_db')
local native=require('scripts').soldier_barrack
local Gait=require('kr6_summon_public.trainer_gait')
local path='kr6_summon_public/trainer_longbow/';local prefix='trainer_longbow'
local animations=assert(love.filesystem.load(path..'animations.lua'))()
local function clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
local function alive(e)return e and e.health and e.health.hp and e.health.hp>0 and not e.health.dead and not e._trainer_deleted end
local function hostile(e)
 return alive(e) and e.enemy and not e.soldier and not e.hero and e.vis
  and bit.band(e.vis.flags,F_FRIEND)==0
end
local function enemy(e)
 return hostile(e) and bit.band(e.vis.bans,F_RANGED)==0
end
local function dist(a,b)return(a.x-b.x)^2+(a.y-b.y)^2 end
local function queue(st,e)table.insert(st.pending_inserts,e)end
local function sound(key)if S.sounds and S.sounds[key]then S:queue(key)end end
local function point(t)local o=t.unit and t.unit.hit_offset or{};return{x=t.pos.x+(o.x or 0),y=t.pos.y+(o.y or 0)}end
local function nearest(st,p,range,seen)
 local best,d
 for _,e in pairs(st.entities)do if enemy(e)and not(seen and seen[e.id])then
  local n=dist(p,e.pos);if n<=range^2 and(not d or n<d or(n==d and e.id<best.id))then best,d=e,n end
 end end
 return best
end
function M.load_assets()
 local image=I.db_images and I.db_images.trainer_longbow
 if not image or not image[1]or not I.db_atlas[prefix..'_portrait']then
  I.atlas_uses['trainer_longbow-0.500000']=nil;I:load_atlas(.5,'kr6_summon_public/trainer_longbow','trainer_longbow',false)
 end
 for n,a in pairs(animations)do A.db[n]=a end
 assert(I.db_atlas[prefix..'_0001']and I.db_atlas[prefix..'_gold_arrow'],'Elite longbowman textures unavailable')
 require('kr6_summon_public.trainer_audio').prepare_native()
end
function M.fire(this,st,target,special)
 if not enemy(target)then return false end
 local e=E:create_entity('arrow');local b=e.bullet;local r=e.render.sprites[1]
 e.pos={x=this.pos.x+(target.pos.x<this.pos.x and -8 or 8),y=this.pos.y+18}
 b.source_id=this.id;b.target_id=target.id;b.level=0;b.damage_type=DAMAGE_PHYSICAL
 b.damage_min=special and 25 or 16;b.damage_max=special and 35 or 24;b.damage_factor=this.unit.damage_factor
 b.damage_inc=0;b.reduce_armor=special and .25 or 0;b.reduce_magic_armor=0;b.damage_radius=0;b.mod=nil;b.mods=nil
 b.damage_flags=0;b.damage_bans=0;b.vis_flags=0;b.vis_bans=0
 r.prefix=nil;r.name=prefix..(special and'_gold_arrow'or'_arrow');r.animated=false;r.anchor={x=.5,y=.5};r.scale={x=special and 1.35 or 1,y=special and 1.35 or 1};r.hidden=false
 -- Short, fading golden afterimages share the projectile entity and never deal damage.
 local history={}
 if special then
  r.draw_order=10
  for i=1,4 do
   local tail=E:clone_c('sprite');tail.name=r.name;tail.prefix=nil;tail.animated=false
   tail.anchor={x=.5,y=.5};tail.scale={x=.82-i*.09,y=.62-i*.07}
   tail.alpha=145-i*25;tail.draw_order=10-i;tail.z=r.z;tail.hidden=true
   e.render.sprites[#e.render.sprites+1]=tail
  end
 end
 e.sound_events.insert=nil;e.sound_events.hit=nil
 e._longbow_special=special;e._longbow_seen={};e._longbow_hits=0
 e.main_script.insert=function()return true end
 e.main_script.update=function(projectile,store)
  local victim=store.entities[projectile.bullet.target_id]
  while enemy(victim)do
   local origin=clone(projectile.pos);local ts=store.tick_ts
   local length=math.sqrt(dist(origin,point(victim)))
   local flight=special and math.max(.16,math.min(.95,length/350))or math.max(.1,math.min(.65,length/430))
   local hitpoint
   repeat
    if not enemy(victim)then table.insert(store.pending_removals,projectile);return end
    local t=math.min(1,(store.tick_ts-ts)/flight);local endpoint=point(victim)
    local x=origin.x+(endpoint.x-origin.x)*t;local y=origin.y+(endpoint.y-origin.y)*t+math.sin(math.pi*t)*(special and 5 or 18)
    if dist(projectile.pos,{x=x,y=y})>.001 then r.r=math.atan2(y-projectile.pos.y,x-projectile.pos.x)end
    projectile.pos.x,projectile.pos.y=x,y;hitpoint=endpoint
    if special then
     history[#history+1]={ts=store.tick_ts,x=x,y=y,r=r.r}
     while #history>1 and store.tick_ts-history[1].ts>.24 do table.remove(history,1)end
     for i=1,4 do
      local sample
      for j=#history,1,-1 do if history[j].ts<=store.tick_ts-i*.04+1e-7 then sample=history[j];break end end
      local tail=projectile.render.sprites[i+1];tail.hidden=not sample
      if sample then tail.offset.x=sample.x-x;tail.offset.y=sample.y-y;tail.r=sample.r end
     end
    end
    if t>=1 then break end
    coroutine.yield()
   until false
   -- Damage is emitted only at real arrow contact, using KR6's normal armor and dodge rules.
   if SU.unit_dodges(store,victim,true)then break end
   local d=SU.create_bullet_damage(projectile.bullet,victim.id,projectile.bullet.source_id)
   table.insert(store.damage_queue,d);projectile._longbow_seen[victim.id]=true;projectile._longbow_hits=projectile._longbow_hits+1
   if not special or projectile._longbow_hits>=4 then break end
   victim=nearest(store,victim.pos,90,projectile._longbow_seen)
   if not victim then break end
   projectile.bullet.target_id=victim.id
  end
  table.insert(store.pending_removals,projectile)
 end
 sound('Sound_ArrowRelease2');queue(st,e);return true
end
local function cancelled(this)return not alive(this)or this.unit.is_stunned or this.nav_rally.new end
local function wait(this,st,start,duration,test)
 while st.tick_ts-start<duration do if cancelled(this)or(test and not test())then return false end;coroutine.yield()end
 return not cancelled(this)and(not test or test())
end
local function reset(this,st)if alive(this)then U.animation_start(this,'idle',nil,st.tick_ts,true)end end
function M.ranged(this,st)
 if cancelled(this)or SU.soldier_pick_melee_target(st,this)then return false end
 local target=nearest(st,this.pos,this._longbow_shot.range);if not target then return false end
 local skill=this._longbow_ricochet;local special=st.tick_ts-skill.ts>=skill.cooldown
 local shot=this._longbow_shot;if not special and st.tick_ts-shot.ts<shot.cooldown then return false end
 local start=st.tick_ts;local windup=special and 1.0 or 8/30
 local test=function()return not SU.soldier_pick_melee_target(st,this)and enemy(target)and dist(this.pos,target.pos)<=shot.range^2 end
 this.render.sprites[1].flip_x=target.pos.x<this.pos.x;U.animation_start(this,special and'ricochet'or'shoot',nil,start,false)
 if not wait(this,st,start,windup,test)then reset(this,st);return false end
 if M.fire(this,st,target,special)then shot.ts=start;if special then skill.ts=start end end
 wait(this,st,start,special and 1.3 or 20/30,function()return not SU.soldier_pick_melee_target(st,this)end)
 reset(this,st);return true
end
local function melee_enemy(this,target)
 local attack=this.melee.attacks[1]
 return hostile(target) and bit.band(attack.vis_flags,target.vis.bans)==0
  and bit.band(attack.vis_bans,target.vis.flags)==0
end
local function combo_target(this,st)
 local target=st.entities[this.soldier.target_id]
 if melee_enemy(this,target) and this.motion.arrived and dist(this.pos,target.pos)<=80^2 then
  return target
 end
end
local function combo(this,st,target)
 local start=st.tick_ts
 this.render.sprites[1].flip_x=target.pos.x<this.pos.x
 U.animation_start(this,'combo',nil,start,false)
 local same=function()return combo_target(this,st)==target end
 for hit,time in ipairs({6/30,18/30,30/30})do
  if not wait(this,st,start,time,same)then reset(this,st);return end
  local d=E:create_entity('damage');d.source_id=this.id;d.target_id=target.id;d.damage_type=DAMAGE_PHYSICAL;d.value=math.random(6,8)*this.unit.damage_factor
  table.insert(st.damage_queue,d)
  local bleed=E:create_entity('mod_connor_skill_a_bleed');bleed.modifier.source_id=this.id;bleed.modifier.target_id=target.id;bleed.modifier.duration=4;queue(st,bleed)
  sound('MeleeSword')
  if hit==1 then this._longbow_combo.ts=start;this.melee.attacks[1].ts=st.tick_ts end
 end
 wait(this,st,start,1.2,same);reset(this,st)
end

-- The native melee action returns only after the current attack finishes.
-- Its sprite may still be named "attack" while choosing the next action.
local native_melee=SU.y_soldier_melee_block_and_attacks
SU.y_soldier_melee_block_and_attacks=function(store,this)
 local skill=this._longbow_combo
 if not skill or cancelled(this) or store.tick_ts-skill.ts<skill.cooldown-1e-7 then
  return native_melee(store,this)
 end

 local target=SU.soldier_pick_melee_target(store,this)
 if not melee_enemy(this,target) then return native_melee(store,this) end
 if SU.soldier_move_to_slot_step(store,this,target) then return true end
 if combo_target(this,store)~=target then return native_melee(store,this) end

 combo(this,store,target)
 return true
end
function M.create(def,st)
 local e=E:create_entity('soldier_paladin');e.powers=nil;e.timed_actions=nil;e.auras=nil;e.dodge=nil;e.ranged=nil
 e.health.hp_max=280;e.health.hp=280;e.health.armor=.6;e.health.magic_armor=0;e.regen.health=6
 e.motion.max_speed=46.8;e.nav_rally.requires_node_nearby=false;e.nav_rally.immune_to=0
 e.unit.hit_offset={x=0,y=15};e.unit.mod_offset={x=0,y=14};e.unit.head_offset={x=0,y=27}
 e.ui.click_rect={pos={x=-14,y=-2},size={x=28,y=37}};e.health_bar.offset={x=0,y=37}
 local r=e.render.sprites[1];r.prefix=prefix;r.name='idle';r.anchor={x=.5,y=.3};r.scale={x=1,y=1};r.angles={walk={'running'}}
 local a=e.melee.attacks[1];e.melee.attacks={a};e.melee.order={1};e.melee.range=60;e.melee.cooldown=1.4;e.melee.arrived_slot_animation='idle'
 a.animation='attack';a.damage_min=10;a.damage_max=20;a.damage_type=DAMAGE_PHYSICAL;a.cooldown=1.4;a.hit_time=16/30;a.hit_times=nil;a.sound='MeleeSword';a.pop=nil
 e._longbow_shot={range=200,cooldown=.9,ts=st.tick_ts-.9,damage_min=16,damage_max=24}
 e._longbow_ricochet={cooldown=10,ts=st.tick_ts-10,range=200,bounce_range=90,max_bounces=3}
 e._longbow_combo={cooldown=10,ts=st.tick_ts-10}
 e.info.random_name_format=nil;e.info.i18n_key='TRAINER_ELITE_LONGBOW';e.info.portrait=prefix..'_portrait'
 for _,messages in pairs(require('i18n').msgs or{})do messages.TRAINER_ELITE_LONGBOW_NAME=def.name end
 e.info.fn=function(t)return{type=STATS_TYPE_SOLDIER,hp=t.health.hp,hp_max=t.health.hp_max,damage_min=16*t.unit.damage_factor,damage_max=24*t.unit.damage_factor,damage_type=DAMAGE_PHYSICAL,armor=t.health.armor,magic_armor=t.health.magic_armor,respawn=t.health.dead_lifetime}end
 e.main_script.insert=function(this,store)local bans=this.vis.bans;local ok=native.insert(this,store);this.vis.bans=bans;return ok end
 e.main_script.remove=native.remove
 e.main_script.update=function(this,store)
  local co=coroutine.create(native.update)
  while not this._trainer_deleted and coroutine.status(co)~='dead'do
   Gait.update(this,store,'elite_longbow')
   local name=this.render.sprites[1].name
   if not cancelled(this)and(name=='idle'or name=='idleBlock')then
    M.ranged(this,store)
   end
   local ok,err=coroutine.resume(co,this,store,this.main_script);if not ok then error(err)end
   Gait.update(this,store,'elite_longbow')
   if coroutine.status(co)~='dead'then coroutine.yield()end
  end
 end
 return e
end
return M

