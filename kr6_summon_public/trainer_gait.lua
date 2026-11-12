-- Distance-driven walking phase; other animation clocks remain native.
local M={}
M.profiles={legion_captain={frames=20,stride=21.6},elite_longbow={frames=18,stride=37.44}}
function M.update(e,s,kind)
 local r=e.render.sprites[1];local p=M.profiles[kind];local g=e._trainer_gait
 if not g then g={x=e.pos.x,y=e.pos.y,phase=0};e._trainer_gait=g end
 local dx,dy=e.pos.x-g.x,e.pos.y-g.y;g.x=e.pos.x;g.y=e.pos.y
 if r.name=='running'and not e.health.dead then
  if not g.walking then g.walking=true;g.phase=0;g.saved_fps=r.fps end
  local moved=math.sqrt(dx*dx+dy*dy)
  -- A blink changes position without taking a stride; it must not spin the feet.
  local maximum=math.max(4,(e.motion.max_speed or 0)*(s.tick_length or 1/30)*4+4)
  if moved<=maximum then g.phase=(g.phase+moved/p.stride*p.frames)%p.frames end
  r.fps=30;r.ts=s.tick_ts-g.phase/30
 else
  if g.walking then r.fps=g.saved_fps end
  g.walking=false;g.phase=0
 end
end
return M
