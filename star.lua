local Star = {
  x,
  y,
  radius,
  brightness,
  color,

  generateStars = function(self, nbStars)
    local _stars = {}

    for i=1,nbStars do

      local _x = math.random(0, WIDTH)
      local _y = math.random(0, HEIGHT)

      local _star = self:new(_x, _y)
      table.insert(_stars,_star)
    end

    return _stars
  end,

  new = function(self, x, y)
    local _star = {}

    setmetatable(_star, self)
    self.__index = self

    _star.x = x or math.random(0, love.graphics.getWidth())
    _star.y = y or math.random(0, love.graphics.getHeight())
    _star.radius = math.random(1, 2)
    _star.brightness = {}
    _star.brightness.value = math.random(0, 100)/100
    _star.brightness.direction = math.random(0, 1)

    return _star
  end,

  update = function(self,dt)
    if self.brightness.direction == 0 then
      -- On augmente la luminosité
      self.brightness.value = self.brightness.value + 0.35 * dt
      -- Si la luminonité atteint sont seuil max, alors changer le seuil
      if self.brightness.value >= 1 then
        self.brightness.value = 1
        self.brightness.direction = 1
      end
    elseif self.brightness.direction == 1 then
      -- On diminue la luminosité
      self.brightness.value = self.brightness.value - 0.35 * dt
      -- Si la luminonité atteint sont seuil min, alors changer le seuil
      if self.brightness.value <= 0 then
        self.brightness.value = 0
        self.brightness.direction = 0
      end
    end
  end,

  draw = function(self)

    love.graphics.push()

    love.graphics.setColor(1,1,1,self.brightness.value)

    --love.graphics.setColor(1, 1, 1, self.brightness.value)
    love.graphics.circle('fill', self.x, self.y, self.radius, 64)

    love.graphics.pop()
  end

}

return Star
