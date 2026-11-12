import json,plistlib,shutil,hashlib
from pathlib import Path
import sys
root=Path(sys.argv[1])
data=plistlib.loads((root/'KR4/Sounds/sounds.plist').read_bytes())
definitions={}
def walk(x):
 if not isinstance(x,dict):return
 for k,v in x.items():
  if isinstance(v,dict) and ('file' in v or isinstance(v.get('sounds'),list)):definitions[k]=v
  else:walk(v)
walk(data)
keys=['group_generic_combat','common_enemie_dead','group_arrow_release_sound','group_arrow_hit_sound','axe_release_sound',
 'linirea_banner_bearer_cry','linirea_elite_footman_improve','linirea_arcane_magus_attack_cast','linirea_arcane_magus_attack_impacts',
 'linirea_arcane_magus_teleport','linirea_arcane_magus_teleportspell','linirea_musketeer_shot','linirea_knight_rider_charge_loopstart',
 'linirea_knight_rider_charge_loop','linirea_knight_rider_charge_loopend','dwarves_mechadwarf_impact','dwarves_mechadwarf_death',
 'dwarves_tinbeard_gunman_shootgun','barbarians_valkyrie_summon','kr4_enemies_sandstorm_assassin_instakill',
 'kr4_enemies_sandstorm_nomad_dodge','kr4_enemies_sandstorm_dijinni_polymorph_units',
 'linirea_high_sorcerer_hit','linirea_high_sorcerer_sheepbleat','linirea_high_sorcerer_sheepspell',
 'kr4_enemies_sandstorm_falconeer_bird','group_sandstorm_eagle_ambient','group_sandstorm_eagle_death',
 'group_sandstorm_camel_rider_death','group_sandstorm_mysthic_attack',
 'kr4_enemies_sandstorm_sand_mysthic_heal','kr4_enemies_sandstorm_sand_mysthic_death',
 'dwarves_geomancer_transform','barbarians_ice_witch_summon','barbarians_apex_shard_spawn',
 'barbarians_frost_giant_attack','barbarians_frost_giant_death',
 'dwarves_sulfur_alchemist_death','dwarves_sulfur_alchemist_acid','dwarves_sulfur_alchemist_hit',
 'kr4_enemies_sandstorm_nomad_spawn','kr4_enemies_sandstorm_elephant_death','group_sandstorm_elephant_ambient']
files={p.stem:p for p in (root/'KR4_PC/Sounds/Fx').rglob('*.ogg')}
out=Path(sys.argv[2])
def lua(v):
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,bool):return 'true' if v else 'false'
 return str(v)
spec={};origins={}
for key in keys:
 d=definitions[key];sources=[]
 for single in d.get('sounds',[key]):
  source=files[definitions[single]['file']];shutil.copy2(source,out/source.name);sources.append(source.name)
  origins[source.name]={'source':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
 gain=d.get('volume',definitions[d['sounds'][0]].get('volume',1) if 'sounds' in d else 1)
 if 'volume_min' in d:gain=[d['volume_min'],d['volume_max']]
 group='BULLETS' if d.get('profile')=='bullet' else 'DEATH' if d.get('profile')=='death' else 'SFX'
 if key=='group_generic_combat':group='SWORDS'
 spec[key]={'files':sources,'source_group':group,'gain':gain,'loop':d.get('loop',False),'mode':'random' if len(sources)>1 else 'sequence','ignore':d.get('delay_time',.08)}
(out/'sounds.lua').write_text('return '+lua(spec)+'\n',encoding='utf8')
print('Imported',len(spec),'original KR4 sound definitions;',len(origins),'unaltered Ogg files')
