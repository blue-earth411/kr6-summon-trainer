-- Local KR4 assets and native KR6 definitions, routed through the game's sound mixer.
local M={}
local S=require('sound_db')
local specs
local prefix='TrainerKR4_'
local failures={}
function M.key(key)return prefix..key end
local function source(file,path)
 if S.sources[file] then return true end
 local ok,value=pcall(love.audio.newSource,path,'static')
 if ok and value then
  S.sources[file]={value};S.source_uses[file]=1;return true
 end
 if not failures[file] then failures[file]=true;print('[KR6Trainer AUDIO] load failed '..path..': '..tostring(value))end
 return false
end
local function ensure(key)
 if not S.sounds or not S.sources or not love.audio then return false end
 specs=specs or assert(love.filesystem.load('kr6_summon_public/vengeance/kr4_audio/sounds.lua'))()
 local def=specs[key];if not def then return false end
 local id=M.key(key);S.sounds[id]=def;S.sound_extras[id]=S.sound_extras[id] or {}
 for _,file in ipairs(def.files)do if not source(file,'kr6_summon_public/vengeance/kr4_audio/'..file)then return false end end
 return true
end
function M.prepare()
 if not S.sounds or not S.sources or not love.audio then return end
 specs=specs or assert(love.filesystem.load('kr6_summon_public/vengeance/kr4_audio/sounds.lua'))()
 for key in pairs(specs)do ensure(key)end
end
function M.play(key,options)
 if ensure(key)then S:queue(M.key(key),options)end
end
function M.start_loop(key,owner)
 if not ensure(key)then return end
 local id=M.key(key)..'_'..owner
 S.sounds[id]=S.sounds[M.key(key)];S.sound_extras[id]=S.sound_extras[id] or {}
 S:queue(id,{delay=.25});return id
end
function M.stop(id)
 if id and S.stop then S:stop(id)end
end
function M.cast(kind,name)
 if kind=='captain' and name=='special' then
  M.play('linirea_banner_bearer_cry',{delay=.2});M.play('linirea_elite_footman_improve')
 elseif kind=='magus' and name=='shoot' then M.play('linirea_arcane_magus_attack_cast')
 elseif kind=='magus' and name=='teleport' then M.play('linirea_arcane_magus_teleportspell')
 elseif kind=='valkyrie' and name=='summon' then M.play('barbarians_valkyrie_summon',{delay=.2})
 elseif kind=='sorcerer' and name=='special' then M.play('linirea_high_sorcerer_sheepspell')
 elseif kind=='djinni' and name=='polimorph' then M.play('kr4_enemies_sandstorm_dijinni_polymorph_units',{delay=.5})
 elseif kind=='falconer' and name=='spawnEagle' then M.play('kr4_enemies_sandstorm_falconeer_bird',{delay=.2})
 elseif kind=='mystic' and name=='heal' then M.play('kr4_enemies_sandstorm_sand_mysthic_heal')
 elseif kind=='geomancer'and name=='toStone'then M.play('dwarves_geomancer_transform')
 elseif kind=='ice_witch'and name=='summon'then M.play('barbarians_ice_witch_summon',{delay=.54})
 elseif kind=='nomad'and name=='shadowOut'then M.play('kr4_enemies_sandstorm_nomad_dodge')end
end
return M
