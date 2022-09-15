local Projectile = {

  position,
  speed,
  orientation,

  new = function(self, position, speed, orientation)

    local _projectile = {}

    setmetatable(_projectile, self)
    self.__index = self

    _projectile.position = position
    _projectile.speed = speed
    _projectile.orientation = orientation

    return _projectile

  end,

  update = function(self, dt)
    -- On traite la vitesse
    local _speed = Vector:new(self.speed.norm, self.speed.angle) -- on adapte la vitesse à DT
    _speed:multiply(dt) -- on adapte la vitesse à DT
    self.position = self.position:add(_speed)

    -- Si le projectile sort de l'écran, on le supprime
    if self.position.x < 0 or self.position.x > WIDTH or self.position.y < 0 or self.position.y > HEIGHT then

    end

  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.setColor(0, 1, 0.5, 1)
    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.rotate(self.orientation)
    love.graphics.setLineWidth(5)
    love.graphics.line(0, 0, 15, 0)
    love.graphics.pop()
  end

}

return Projectile
