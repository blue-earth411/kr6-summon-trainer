local M={}
local GR=require('grid_db')
local U=require('utils')
local formation_scales={1,.8,.6,.45}
local function alive(e)return e and not e._trainer_deleted and e.health and not e.health.dead and e.health.hp>0 end
local function clone(p)return {x=p.x,y=p.y}end
local function present(e,s)
 if s.entities[e.id]==e then return true end
 for _,p in ipairs(s.pending_inserts or {})do if p==e then return true end end
 return false
end
function M.members(g,s)
 local result={}
 for _,e in ipairs(g.members)do if alive(e)and present(e,s)then result[#result+1]=e end end
 return result
end
local function valid(e,p)
 local types=e.nav_grid.valid_terrains_dest or e.nav_grid.valid_terrains
 return not types or GR:cell_is_only(p.x,p.y,types)
end
local function positions(anchor,forward,scale,offsets)
 local f,p=forward,{x=-forward.y,y=forward.x};local a={}
 for i,o in ipairs(offsets or {{18,-17},{18,17},{-14,0}})do
  a[i]={x=anchor.x+scale*(o[1]*f.x+o[2]*p.x),y=anchor.y+scale*(o[1]*f.y+o[2]*p.y)}
 end
 return a
end
function M.move_group(g,s,p)
 local members=M.members(g,s)
 if #members==0 then return false end
 local anchor={x=0,y=0}
 for _,e in ipairs(members)do anchor.x=anchor.x+e.pos.x/#members;anchor.y=anchor.y+e.pos.y/#members end
 local dx,dy=p.x-anchor.x,p.y-anchor.y;local len=math.sqrt(dx*dx+dy*dy)
 local f=len>1 and {x=dx/len,y=dy/len}or g.forward
 local goals
 for _,scale in ipairs(formation_scales)do
  local candidate=positions(p,f,scale,g.offsets);local ok=true
  for _,e in ipairs(members)do if not valid(e,candidate[e._legion_group_slot])then ok=false;break end end
  if ok then goals=candidate;break end
 end
 if not goals then return false end
 g.anchor=clone(p);g.forward=f;g.goals=goals
 for _,e in ipairs(members)do
  U.unblock_target(s,e);e.nav_rally.pos=clone(goals[e._legion_group_slot]);e.nav_rally.center=clone(e.nav_rally.pos)
  e.nav_rally.new=true;e.motion.forced_waypoint=nil
 end
 return true
end
return M
