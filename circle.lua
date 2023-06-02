local Vec = require('vec')

---@class Circle
local Circle = {
  c = Vec.new(0, 0),
  r = 1,
  m = 1.0,
  vel = 0,
  acc = Vec.new(0, 0),
  tdie = 5.0,
  tborn = 0.0,
  points = 10.0,
  color = {1, 1, 1},
  shotgun = false,
  p1 = Vec.new(0, 0),
  p2 = Vec.new(0, 0),
  p3 = Vec.new(0, 0),
  p4 = Vec.new(0, 0),
  time = 0,
}

function Circle:new(x, y, r, v, td, tb, bonus, color_, shotg)
  local newobj = { 
    c = Vec.new(x, y),
    r = r,
    m = 45.0/r,
    vel =  Vec.new(v * math.random(50, 75), v * math.random(50, 75)),
    tdie = td,
    tborn = tb,
    points = bonus,
    color = color_,
    shotgun = shotg or false,
    p1 = Vec.new(x, y),
    p2 = Vec.new(x+200, y),
    p3 = Vec.new(x+40, y+240),
    p4 = Vec.new(x+240, y+240),
  }
  self.__index = self
  return setmetatable(newobj, self)
end

return Circle