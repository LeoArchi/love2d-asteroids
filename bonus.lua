local Bonus = {

  position,
  radius,
  type,

  new = function(self, type)

    local _bonus = {}

    setmetatable(_bonus, self)
    self.__index = self

    local _x = math.random(0, WIDTH)
    local _y = math.random(0, HEIGHT)

    _bonus.radius = 20
    _bonus.position = Vector:newByCoordinates(_x, _y)
    _bonus.type = type

    return _bonus

  end,

  draw = function(self)
    love.graphics.push()

    if self.type == 'life' then
      love.graphics.setColor(235/255, 64/255, 52/255, 1)
    elseif self.type == 'ammo' then
      love.graphics.setColor(0, 1, 0.5, 1)
    end


    love.graphics.circle('fill', self.position.x, self.position.y, self.radius, 32)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle('line', self.position.x, self.position.y, self.radius, 32)

    love.graphics.pop()
  end

}


return Bonus
