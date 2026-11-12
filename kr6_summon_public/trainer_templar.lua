-- Native stage 08 swordsman, with manual rally movement independent of the boss controller.
local M={}
local E=require('entity_db')
local U=require('utils')
local I=require('klove.image_db')
local A=require('klove.animation_db')
local native=require('scripts').soldier_barrack
local SU=require('script_utils')
local animations
local function get_animations()
 if not animations then
  local chunk=assert(love.filesystem.load(KR_PATH_GAME..'/data/animations/go_stage08/stage_08_templars.lua'))
  local data=chunk();animations=data.animations or data
 end
 return animations
end
local prefix='trainer_public_'
local group='trainer_public_templar'
local texture_path='_assets/kr6-desktop/images/fullhd_bc3'

local function attach_frame(key,frame,atlas,scale)
 local f={}
 for k,v in pairs(frame)do f[k]=v end
 f.atlas=atlas;f.group=group;f.ref_scale=scale
 f.quad=love.graphics.newQuad(f.f_quad[1],f.f_quad[2],f.f_quad[3],f.f_quad[4],f.a_size[1],f.a_size[2])
 I.db_atlas[key]=f
end

function M.load_assets()
 local body=I.db_atlas[prefix..'templars_templar_0001']
 local grail=I.db_atlas.trainer_templar_grail_icon
 if not body or not grail or not I.db_images[body.atlas] or not I.db_images[grail.atlas] then
  local frames=assert(love.filesystem.load(texture_path..'/go_stage08.lua'))()
  local names={}
  for name,frame in pairs(frames)do
   names[name]=frame
   for _,alias in ipairs(frame.alias or {})do names[alias]=frame end
  end
  for name,frame in pairs(names)do
   if name:find('^templars_templar_') or name:find('^templars_hit_templar_') then
    local atlas=prefix..frame.a_name
    if not I.db_images[atlas] then
     local _,image,w,h=I:load_image_file(frame.a_name,texture_path)
     assert(image,'Missing Genesis Templar texture '..frame.a_name)
     I.db_images[atlas]={image,w,h}
    end
    attach_frame(prefix..name,frame,atlas,768/1080)
   end
  end
  local image=love.graphics.newImage('kr6_summon_public/grail.png')
  local w,h=image:getDimensions()
  I.db_images[group..'_grail']={image,w,h}
  attach_frame('trainer_templar_grail_icon',{f_quad={0,0,w,h},a_size={w,h},size={w,h},trim={0,0,0,0}},group..'_grail',768/1080)
 end
 for name,animation in pairs(get_animations())do
  if name:find('^templars_templar_') or name:find('^templars_hit_templar_')then
   local local_animation={}
   for k,v in pairs(animation)do local_animation[k]=v end
   local_animation.prefix=prefix..animation.prefix
   local_animation.group=group
   A.db[prefix..name]=local_animation
   if name:find('^templars_hit_templar_') and not A.db[name] then A.db[name]=local_animation end
  end
 end
 A.db[prefix..'templars_templar_running']=A.db[prefix..'templars_templar_walk']
 A.db[prefix..'templars_templar_grail_raise']={prefix=prefix..'templars_templar',frames={140,140,134,132,128,124,120,118,116,114,112,110,109,108,107,1,1,1},group=group}
end

-- One roll for each death. A failed roll proceeds through the native corpse lifecycle.
function M.try_revive(this,store)
 if this._trainer_deleted or not this.health.dead or math.random()>=.2 then return false end
 local h=this.health;local saved_ignore=h.ignore_damage
 SU.remove_modifiers(store,this);U.unblock_target(store,this)
 h.dead=false;h.hp=math.floor(h.hp_max*.6+.5);h.ignore_damage=true
 h.death_ts=0;h.death_finished_ts=nil;h.delete_after=nil;h.last_damage_types=0
 this._grail_reviving=true;this._grail_revive_count=(this._grail_revive_count or 0)+1
 this.health_bar.hidden=false
 local r=this.render.sprites[1];local fx=this.render.sprites[2]
 r.alpha=255;r.hidden=false;r.time_offset=0;r.fps=30
 local start=store.tick_ts;this._grail_start=start
 U.animation_start(this,'grail_raise',nil,start,false)
 while store.tick_ts-start<.6-1e-7 do
  if this._trainer_deleted then return false end
  local t=math.max(0,math.min(1,(store.tick_ts-start)/.6))
  fx.hidden=false;fx.alpha=math.floor(235*math.min(1,t*6+.35)*math.min(1,(1-t)*5))
  local scale=.86+.14*math.sin(math.pi*t);fx.scale={x=scale,y=scale};fx.offset.y=3*t
  coroutine.yield()
 end
 if this._trainer_deleted then return false end
 fx.hidden=true;h.ignore_damage=saved_ignore or false;this._grail_reviving=nil
 r.fps=nil;U.animation_start(this,'idle',nil,store.tick_ts,true)
 print('[KR6Trainer GRAIL] id='..this.id..' hp='..h.hp..'/'..h.hp_max..' revive='..this._grail_revive_count)
 return true
end
local function update(this,store)
 local co=coroutine.create(native.update);local death_checked=false
 while not this._trainer_deleted and coroutine.status(co)~='dead'do
  if this.health.dead and not death_checked then
   death_checked=true
   if M.try_revive(this,store)then death_checked=false;co=coroutine.create(native.update)end
  end
  if this._trainer_deleted then return end
  local ok,err=coroutine.resume(co,this,store,this.main_script);if not ok then error(err)end
  if coroutine.status(co)~='dead'then coroutine.yield()end
 end
end
function M.create(def)
 local e=assert(E:create_entity('soldier_stage_08_templar_swordsman'))
 E:add_comps(e,'nav_grid')
 e.main_script.insert=native.insert;e.main_script.update=update;e.main_script.remove=native.remove
 e.health.hp_max=300;e.health.hp=300;e.health.armor=.31;e.health.magic_armor=0
 e.melee.attacks[1].damage_min=20;e.melee.attacks[1].damage_max=30
 e.melee.attacks[2].damage_min=30;e.melee.attacks[2].damage_max=40
 local fx=E:clone_c('sprite');fx.name='trainer_templar_grail_icon';fx.prefix=nil;fx.animated=false
 fx.anchor={x=.5,y=.82};fx.offset={x=0,y=0};fx.hidden=true;fx.z=e.render.sprites[1].z;fx.draw_order=.5
 e.render.sprites[2]=fx
 e.nav_rally.requires_node_nearby=false
 e.nav_rally.immune_to=0
 e.render.sprites[1].prefix=prefix..'templars_templar'
 e.render.sprites[1].angles={walk={'running'}}
 e.melee.order=U.attack_order(e.melee.attacks)
 e.info.random_name_format=nil;e.info.i18n_key='TRAINER_TEMPLAR'
 for _,messages in pairs(require('i18n').msgs or {})do messages.TRAINER_TEMPLAR_NAME=def.name end
 return e
end
return M
