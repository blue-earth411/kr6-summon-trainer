import plistlib,re,json,math
from pathlib import Path
from PIL import Image
import sys
root=Path(sys.argv[1])
base=root/'KR4'
out=Path(sys.argv[2])
units=plistlib.loads((base/'Settings/units_settings.plist').read_bytes())
choices={'captain':('linirea','banner_bearer','linirea_banner_soldier',675),
 'magus':('linirea','arcane_magus','arcane_magus',742),
 'shield':('linirea','tower_shield_knight','tower_shield_knight',1350),
 'djinni':('sandstorm','djini','djini',1822),
 'assassin':('sandstorm','assassin','assasin',675),
 'footman':('linirea','elite_footman','linirea_soldier',364),
 'musketeer':('linirea','musketeer','musketeer',243),
 'archer':('sandstorm','legion_archer','legion_archer',189),
 'cavalry':('linirea','knight_rider','knight_rider',297),
 'dismounted':('linirea','paladin','paladin',1012),
 'huntress':('barbarians','northern_huntress','northern_huntress',162),
 'ranger':('linirea','elven_warrior','elven_warrior',405),
 'wildling':('barbarians','northern_wildling','northern_wildling',168),
 'legionnaire':('sandstorm','legionnaire','legionnaire',378),
 'mecha':('dwarves','mechadwarf','mechadwarf',1620),
 'gunman':('dwarves','tinbeard_gunman','tinbeard_gunman',162),
 'valkyrie':('barbarians','valkyrie','valkyrie',540),
 'warhammer':('dwarves','warhammer_guard','warhammer_guard',94),
 'draugr':('barbarians','draugr','draugr',202),
 'sorcerer':('linirea','high_sorcerer','high_sorcerer',2362),
 'falconer':('sandstorm','falconeer','falconeer',486),
 'camel':('sandstorm','camel_rider','camel_rider',553),
 'mystic':('sandstorm','sand_mysthic','sand_mysthic',742),
 'eagle':('sandstorm','desert_eagle','desert_eagle',60),
 'geomancer':('dwarves','stonebeard_geomancer','stonebeard_geomancer',675),
 'ice_witch':('barbarians','ice_witch','ice_witch',337),
 'alchemist':('dwarves','sulfur_alchemist','sulfur_alchemist',216),
 'frost_giant':('barbarians','frost_giant','frost_giant',1890),
 'shard':('barbarians','apex_shard','apex_shard',108),
 'nomad':('sandstorm','legion_nomad','nomad',364),
 'elephant':('sandstorm','elephant_lancer','war_elephant_archers',3780)}
def lua(v):
 if isinstance(v,dict):return '{'+','.join('['+lua(str(k))+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,(list,tuple)):return '{'+','.join(map(lua,v))+'}'
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,bool):return 'true' if v else 'false'
 if v is None:return 'nil'
 return str(v)
animfiles={p.name:p for p in (base/'Animations').rglob('*.plist')}
anims={};need=set();loaded=set()
def addanim(filename):
 if filename in loaded:return
 loaded.add(filename)
 d=plistlib.loads(animfiles[filename].read_bytes())
 for inc in d.get('includes',{}):addanim(inc)
 for k,a in d.get('animations',{}).items():
  prefix=a['prefix'];f=a['fromIndex'];t=a['toIndex']
  if 'layerStart' in a:
   assert a['layerStart']==a['layerEnd']==1
   prefix+='1'
  anims['trainer_kr4_'+k]={'prefix':'trainer_kr4_'+prefix,'from':f,'to':t,'fps':30,'group':'kr4_allied'}
  need.update(f'{prefix}_{i:04d}.png' for i in range(f,t+1))
def add_effects(value):
 if isinstance(value,dict):
  for key,v in value.items():
   if key=='animations_file' and v in animfiles:addanim(v)
   elif key=='fixed_frame':need.add(v)
   elif key=='single_frame':need.add(v)
   else:add_effects(v)
 elif isinstance(value,list):
  for v in value:add_effects(v)
spec={}
for kind,(group,name,prefix,hp) in choices.items():
 d=units[group][name]
 addanim(d['animations']['animations_file']);add_effects(d['skills'])
 if kind=='sorcerer':addanim('high_sorcerer_sheep_animations.plist')
 portrait=d['info']['display_bottom_image'];need.add(portrait)
 need.add(d['shadow']['sprite'])
 spec[kind]={'source':d,'prefix':prefix,'hp':hp,'portrait':'trainer_kr4_'+portrait[:-4]}
 if kind=='elephant':
  spec[kind]['rider']=units['sandstorm']['elephant_lancer_unit']
  spec[kind]['mount']=units['sandstorm']['elephant_lancer_mount']
  add_effects(spec[kind]['rider']['skills'])
 # Soldier movement requests running; enemy movement uses walk.
 anims['trainer_kr4_'+prefix+'_running']=anims['trainer_kr4_'+prefix+'_walk'].copy()
 anims['trainer_kr4_'+prefix+'_raise']=anims['trainer_kr4_'+prefix+'_idle'].copy()
 if kind=='captain':anims['trainer_kr4_'+prefix+'_attack']=anims['trainer_kr4_'+prefix+'_attackSword'].copy()
 if kind=='djinni':anims['trainer_kr4_'+prefix+'_attack']=anims['trainer_kr4_'+prefix+'_polimorph'].copy()
 if kind=='dismounted':anims['trainer_kr4_'+prefix+'_attack']=anims['trainer_kr4_'+prefix+'_specialAttack1'].copy()
 if kind=='falconer':
  for key,value in list(anims.items()):
   if key.startswith('trainer_kr4_falconeer_'):
    anims[key.replace('trainer_kr4_falconeer_','trainer_kr4_falconeer_alone_',1)]=value.copy()
  for name,source in [('idle','aloneIdle'),('running','aloneWalk'),('death','aloneDeath')]:
   anims['trainer_kr4_falconeer_alone_'+name]=anims['trainer_kr4_falconeer_'+source].copy()
# Custom attack reuses original elephant step frames; runtime adds a coordinated body/rider lunge.
anims['trainer_kr4_war_elephant_archers_attack']={'prefix':'trainer_kr4_war_elephant_archers','from':1,'to':30,'fps':30,'group':'kr4_allied','frames':[1, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 34, 32, 30, 28, 26, 24, 20, 16, 12, 8, 4, 1]}
anims['trainer_kr4_desert_sheep_death']=anims['trainer_kr4_desert_sheep_idle'].copy()
anims['trainer_kr4_desert_sheep_running']=anims['trainer_kr4_desert_sheep_walk'].copy()
# Arcane projectile is a single sprite in the original game.
need.add('arcane_mage_projectile.png')
frames={};atlases={}
for assets in [base/'Sprites/HD',root/'KR4_PC/Sprites/HD']:
 for p in assets.rglob('*.plist'):
  d=plistlib.loads(p.read_bytes())
  if 'frames' not in d:continue
  for key,v in d['frames'].items():
   found=[n for n in [key]+v.get('aliases',[]) if n in need and n not in frames]
   if not found:continue
   tex=p.with_suffix('.png')
   if not tex.exists():continue
   if tex not in atlases:atlases[tex]=Image.open(tex).convert('RGBA')
   x,y,w,h=map(int,re.findall(r'-?\d+',v['textureRect']))
   sw,sh=map(int,re.findall(r'-?\d+',v['spriteSize']))
   if v.get('textureRotated'):w,h=h,w
   crop=atlases[tex].crop((x,y,x+w,y+h))
   if v.get('textureRotated'):crop=crop.transpose(Image.Transpose.ROTATE_90)
   assert crop.size==(sw,sh),(key,crop.size,(sw,sh))
   W,H=map(int,re.findall(r'-?\d+',v['spriteSourceSize']))
   ox,oy=map(float,re.findall(r'-?\d+(?:\.\d+)?',v['spriteOffset']))
   left=round((W-sw)/2+ox);top=round((H-sh)/2-oy)
   assert left>=0 and top>=0,(key,left,top)
   for name in found:frames[name]=(crop,[W,H],[left,top,W-sw-left,H-sh-top])
missing=sorted(need-frames.keys())
assert not missing,missing
width=4096;x=y=row=page=0;placements=[]
for name,(im,size,trim) in sorted(frames.items(),key=lambda kv:-kv[1][0].height):
 w,h=im.size
 if x+w+2>width:x=0;y+=row+2;row=0
 if y+h+2>8192:page+=1;x=y=row=0
 placements.append((name,im,size,trim,x,y,page));x+=w+2;row=max(row,h)
meta={};sizes={}
for number in range(page+1):
 entries=[v for v in placements if v[-1]==number]
 height=math.ceil(max(v[5]+v[1].height+2 for v in entries)/4)*4
 assert height<=8192
 filename='kr4_allied.png' if number==0 else f'kr4_allied_{number+1}.png'
 atlas=Image.new('RGBA',(width,height));sizes[filename]=[width,height]
 for name,im,size,trim,x,y,_ in entries:
  atlas.paste(im,(x,y));meta['trainer_kr4_'+name[:-4]]={'a_name':filename,'a_size':[width,height],
   'f_quad':[x,y,im.width,im.height],'size':size,'trim':trim,'alias':[]}
 atlas.save(out/filename)
(out/'atlas_sizes.lua').write_text('return '+lua(sizes),encoding='utf8')
(out/'atlas_sizes.json').write_text(json.dumps(sizes),encoding='utf8')
(out/'kr4_allied.lua').write_text('return '+lua(meta),encoding='utf8')
(out/'animations.lua').write_text('return '+lua(anims),encoding='utf8')
(out/'spec.lua').write_text('return '+lua(spec),encoding='utf8')
(out/'source_units.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2),encoding='utf8')
print('Imported',len(frames),'original HD frames;',len(anims),'animations;',sizes)

