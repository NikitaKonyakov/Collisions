local Circle = require('circle')
local Vec = require('vec')

---
---@param circleA Circle
---@param circleB Circle
local function circleCircle(circleA, circleB)
  local dir = circleA.c - circleB.c --[[@as Vec]]
  return dir:length() < (circleA.r + circleB.r)
end

---@param circleA Circle
---@param circleB Circle
local function staticCircleResolution(circleA, circleB)
  local dir = circleA.c - circleB.c --[[@as Vec]]
  local overlap = (dir:length() - circleA.r - circleB.r) / 2.0
  local mov = dir:norm() * overlap --[[@as Vec]]
  circleA.c.x = circleA.c.x - mov.x
  circleA.c.y = circleA.c.y - mov.y

  circleB.c.x = circleB.c.x + mov.x
  circleB.c.y = circleB.c.y + mov.y
end

---@param circle Circle
---@param point Vec
local function circlePoint(circle, point)
  local dir = circle.c - point
  return dir:length() < circle.r
end

local combo = 0.0
local shotcount = 0
local curt = 0
local t = 0
local score = 0.0
local selected = nil
local circles = {}
local timetoplay = 30.0
local mainFont = love.graphics.newFont("KingsRegular.ttf", 20)
local background_image = love.graphics.newImage("background.jpg")
local gameover_image = love.graphics.newImage("gameover_background.jpg")

local function randomvalue()
  local theta = math.random()*2*math.pi
  local r = math.random() + math.random()
  if r >= 1 then
      r = 2 - r
  end
  return r * math.cos(theta), r * math.sin(theta)
end

local function lerp(a, b, tt)
  return a * (1 - tt) + b * tt
end

local function lerp2d (p1, p2, tt)
  local x = lerp(p1.x, p2.x, tt)
  local y = lerp(p1.y, p2.y, tt)
  return Vec.new(x, y)
end

local function cuadBezier(p1, p2, p3, p4, tt)
  local a = lerp2d(p1, p2, tt)
  local b = lerp2d(p2, p3, tt)
  local c = lerp2d(p3, p4, tt)
  local aa = lerp2d(a, b, tt)
  local bb = lerp2d(b, c, tt)
  local aaa = lerp2d(aa, bb, tt)
  return aaa
end

function love.load()
  love.graphics.setFont(mainFont)
  local music = love.audio.newSource("backgroundmusic.mp3", "stream")
  love.audio.setVolume(0.1)
  love.audio.play(music)
  for i = 1, 15, 1 do
    local x = math.random() * love.graphics.getWidth()
    local y = math.random() * love.graphics.getHeight()
    local bonus = 1.0
    local v = 0
    table.insert(circles, Circle:new(x, y, math.random(15, 35), v, math.random(1, 5), love.timer.getTime(), bonus))
  end
end

local function timetodie()
  for _, circle in ipairs(circles) do
    if (love.timer.getTime() - circle.tborn) > circle.tdie then
      table.remove(circles, _)
    end
  end
end

local shotgun_ = false

function  love.mousepressed(x, y, button)
  
  if button == 1 then
    local mousePos = Vec.new(x, y)
    local pressed = true
    if shotgun_ then
      for i = 1, 10, 1 do
        local xx,yy= randomvalue()
        local xy = Vec.new(x + xx*100, y + yy*100)
        for _,circle in ipairs(circles) do
          if circlePoint(circle, xy) then
            timetoplay = timetoplay + circle.points/5.0
            if (circle.points > 0) then
              score = score + circle.points
            else score = score + circle.points
              combo = 0.0
            end 
            pressed = false
            table.remove(circles, _)
            shotgun_ = false
          end
        end
      end
    end
    for _, circle in ipairs(circles) do 
      if circlePoint(circle, mousePos) then
        if ((curt - t) <= 4) then
          if (shotcount == 10) then
            shotcount = 1
            t = curt
            combo = combo + 1.5
            score = combo * score
          end
        else 
          combo = 0
          shotcount = 1
          t = curt
        end
        if circle.shotgun then
          shotgun_ = true
        end
        timetoplay = timetoplay + circle.points/50.0
        score = score + circle.points
        if (circle.points > 0) then
          shotcount = shotcount + 1
        else
          shotcount = 0
          combo = 0.0
        end 
        table.remove(circles, _)
        pressed = false
      end
    end
    if pressed then
      combo = 0.0
    end
  end
end
local curentTime = love.timer.getTime()
function love.update(dt)
curt = curt + dt

  timetodie()
  if (love.timer.getTime() - curentTime) > 1 then
    for i = 1, 3, 1 do
      local x = math.random() * love.graphics.getWidth()
      local y = math.random() * love.graphics.getHeight()
      local bonus = 1.0
      local v = 0
      local bcolor = {1, 1, 1}
      local shotg = false
      local q = math.random(12)
      if (q < 4) then
        bonus = 2.0
        v = 1
        bcolor = {1, 1, 0}
      end
      if (q == 4 or q == 5) then
        bonus = 2.0
        v = 1
        bcolor = {0, 1, 1}
        shotg = true
      end
      if (q == 6) then
        bonus = -10.0
        bcolor = {1, 0, 0}
      end
      table.insert(circles, Circle:new(x, y, math.random(15, 45), v, math.random(3, 5), love.timer.getTime(), bonus, bcolor, shotg))
    end
    curentTime = love.timer.getTime()
  end

  for _, circle in ipairs(circles) do
    circle.acc = circle.vel * -0.5 -- эмуляция трения
    if (circle.vel:length() > 0) then
     if (circle.time < 1)  then
        circle.time = circle.time + dt 
        circle.c = cuadBezier(circle.p1, circle.p2, circle.p3, circle.p4, circle.time)
     else
        circle.vel = circle.vel + circle.acc * dt
        circle.c = circle.c + circle.vel * dt
      end
    end
    if circle.vel:length() < 0.1 then
      circle.vel = Vec(0, 0)
    end

    if circle.c.x < 0 then
      circle.c.x = love.graphics.getWidth() + circle.c.x
    end
    if circle.c.y < 0 then
      circle.c.y = love.graphics.getHeight() + circle.c.y
    end
    if circle.c.x > love.graphics.getWidth() then
      circle.c.x = circle.c.x - love.graphics.getWidth()
    end
    if circle.c.y > love.graphics.getHeight() then
      circle.c.y = circle.c.y - love.graphics.getHeight()
    end
  end

  local collisions = {}

  for i = 1, #circles, 1 do
    for j = i + 1, #circles, 1 do
      local ci = circles[i]
      local cj = circles[j]
      if circleCircle(ci, cj) then
        table.insert(collisions, { ci, cj })
        staticCircleResolution(ci, cj)
      end
    end
  end

  for _, col in ipairs(collisions) do
    ---@see https://www.vobarian.com/collisions/2dcollisions2.pdf

    local a, b = unpack(col)
    local dir = b.c - a.c
    local dist = dir:length()

    local normal = dir:norm()
    local tangent = Vec(-normal.y, normal.x)

    local dpNormA = a.vel:dot(normal)
    local dpNormB = b.vel:dot(normal)

    local dpTangA = a.vel:dot(tangent)
    local dpTangB = b.vel:dot(tangent)

    -- сохранение импульса
    local p1 = (dpNormA * (a.m - b.m) + 2 * b.m * dpNormB) / (a.m + b.m)
    local p2 = (dpNormB * (b.m - a.m) + 2 * a.m * dpNormA) / (a.m + b.m)

    a.vel = tangent * dpTangA + normal * p1
    b.vel = tangent * dpTangB + normal * p2
  end
  if love.keyboard.isDown('escape') then
    love.event.quit()
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(background_image)
  local text = "Score: "..math.floor(score)
  local text2 = "Combo: "..math.floor(combo * 100)/100
  local text3 = "Time:"..math.floor((timetoplay-love.timer.getTime()) * 100)/100
  love.graphics.setColor(1, 1, 0)
  love.graphics.print(text, 10, 10)
  love.graphics.print(text2, 10, 25)
  love.graphics.print(text3, 10, 40)
  for _, circle in ipairs(circles) do
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle('line', circle.c.x, circle.c.y, circle.r)
    love.graphics.setColor(circle.color)
    love.graphics.circle('fill', circle.c.x, circle.c.y, circle.r)
  end
  if (love.timer.getTime() > timetoplay) then
    love.graphics.clear()
    love.graphics.setNewFont("KingsRegular.ttf", 100)
    local textg = "Your score "..math.floor(score)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(gameover_image)
    love.graphics.setColor(1, 0.3, 0)
    love.graphics.printf("Game Over", 0, 200, 800, "center")
    love.graphics.printf(textg, 0, 300, 800, "center")
    --[[if love.keyboard.isDown('tab') then
      love.graphics.clear()
      love.graphics.setNewFont("KingsRegular.ttf", 20)
      local i = 1
      for _, stat in ipairs(statistic) do
        local texts = i..stat
        i = i + 1
        love.graphics.print(texts, 100, _*20)
      end
    end]]--
  end
end