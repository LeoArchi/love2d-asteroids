local Asteroid = {

  position,
  speed,
  radius,
  orientation,
  radial_speed, -- en radians
  vertices,
  life_level,
  life,
  blink, -- Pour l'effet clignotement

  new = function(self, x, y, angle, radius, life_level)

    local _asteroid = {}

    setmetatable(_asteroid, self)
    self.__index = self

    _asteroid.radius = radius or math.random(50, 100)
    _asteroid.life = 3 -- Il faut trois 'hits' pour casser un astéroide
    _asteroid.life_level = life_level or 3 -- Lorsqu'un astéroide casse, les débris sont de nouveaux astéroides avec un life level égale au niveau du parent -1. A 0, il n'y a plus de débris

    local _x = x or math.random(0 + _asteroid.radius, WIDTH - _asteroid.radius)
    local _y = y or math.random(0 + _asteroid.radius, HEIGHT - _asteroid.radius)

    local _speed

    if _asteroid.life_level == 3 then
      _speed = math.random(100, 120)
    elseif _asteroid.life_level == 2 then
      _speed = math.random(120, 140)
    elseif _asteroid.life_level == 1 then
      _speed = math.random(140, 180)
    end

    local angle = angle or math.random(0, 360)

    _asteroid.position = Vector:newByCoordinates(_x, _y)
    _asteroid.speed = Vector:new(_speed, angle)
    _asteroid.orientation = 0
    _asteroid.radial_speed = math.random(-0.1, 0.1)

    -- On initialise l'effet clignotement
    _asteroid.blink = {
      count = 0,
      isWhite = false,
      isBlinking = false
    }

    -- on calcule les vertices
    _asteroid.vertices = {}
    local _nb_vertices = math.random(15, 20)
    local _subdivition = 2*math.pi / _nb_vertices

    for alpha=0, 2*math.pi - _subdivition, _subdivition do

      local _radius = _asteroid.radius + math.random(-20, 0)

      local _x = _radius * math.cos(alpha)
      local _y = _radius * math.sin(alpha)

      table.insert(_asteroid.vertices, _x)
      table.insert(_asteroid.vertices, _y)
    end

    -- Sécurité permetant de retirer le dernier vertice si il est égal au premier
    local real_nb_vertice = table.length(_asteroid.vertices)
    if _asteroid.vertices[0] == _asteroid.vertices [real_nb_vertice-1] and _asteroid.vertices[1] == _asteroid.vertices [real_nb_vertice] then
      table.remove(_asteroid.vertices, real_nb_vertice-1)
      table.remove(_asteroid.vertices, real_nb_vertice)
    end

    return _asteroid

  end,

  update = function(self, dt)

    -- On traite l'effet de clignotement
    if self.blink.isBlinking and self.blink.count > 0 then

      self.blink.isWhite = not self.blink.isWhite -- On inverse la couleur du clignotement

      if self.blink.isWhite then
        self.blink.count = self.blink.count - 1 -- On décrémente le compteur de clignotement si on est sur une frame blanche
      end

      if self.blink.count == 0 then
        self.blink.isWhite = false -- Dans tout les cas, si le compteur de clignotement atteind 0, on redevient noir
      end

    end

    -- On traite l'orientation
    self.orientation = self.orientation + self.radial_speed*dt

    if self.orientation < 0 then
      self.orientation = self.orientation + math.pi*2
    elseif self.orientation > math.pi*2 then
      self.orientation = self.orientation - math.pi*2
    end

    -- On traite la vitesse
    local _speed = Vector:new(self.speed.norm, self.speed.angle) -- on adapte la vitesse à DT
    _speed:multiply(dt) -- on adapte la vitesse à DT
    self.position = self.position:add(_speed)

    -- Si l'asteroide sort de l'écran
    -- Si le vaisseau sort de l'écran, on le fait réaparaitre de l'autre coté
    if self.position.x < 0 then
      self.position = Vector:newByCoordinates(self.position.x + WIDTH, self.position.y)
    elseif self.position.x > WIDTH then
      self.position = Vector:newByCoordinates(self.position.x - WIDTH, self.position.y)
    end

    if self.position.y < 0 then
      self.position = Vector:newByCoordinates(self.position.x, self.position.y + HEIGHT)
    elseif self.position.y > HEIGHT then
      self.position = Vector:newByCoordinates(self.position.x, self.position.y - HEIGHT)
    end

  end,

  setBlink = function(self)
    self.blink.isBlinking = true
    self.blink.count = 5
  end,

  hit = function(self, index)

    self.life = self.life -1 -- La vie de l'astéroide diminue

    self:setBlink() -- On active le clignotement de l'astéroide

    local _hit = hit:clone() -- On joue un bruitage
    _hit:play()

    -- Si la vie de l'astéroide atteind 0
    if self.life == 0 then

      -- Créer de nouveau astéroides
      local new_life_level = self.life_level - 1

      -- On augmente le score
      if new_life_level > 0 then
        player.score = player.score + 100
      elseif new_life_level ==0 then
        player.score = player.score + 300
      end

      if new_life_level > 0 then

        local angle = math.random(0, 360)

        local debris_1 = Asteroid:new(self.position.x, self.position.y, angle, self.radius * 0.7, new_life_level)
        local debris_2 = Asteroid:new(self.position.x, self.position.y, angle + 180, self.radius * 0.7, new_life_level)

        debris_1:setBlink() -- On active le clignotement de l'astéroide
        debris_2:setBlink() -- On active le clignotement de l'astéroide

        table.insert(asteroids, debris_1)
        table.insert(asteroids, debris_2)
      end

      -- jouer le son d'explosion
      local _boom = boom:clone()
      _boom:play()

      -- Créer une nouvelle animation d'explosion
      local _explosion = {
        animation = table.copy(boomAnimation),
        x = self.position.x,
        y = self.position.y
      }
      table.insert(asteroidsExplosions, _explosion)

      -- Activer la "vibration" de l'écran
      screenShacking.setScreenShacking()

      -- Supprimer l'astéroide parent
      table.remove(asteroids, index)

    end

  end,

  draw = function(self)

    love.graphics.push()

    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.rotate(self.orientation)

    if self.blink.isBlinking and self.blink.isWhite then
      love.graphics.setColor(1, 1, 1, 0.5)
    else
      love.graphics.setColor(59/255, 43/255, 0)
    end


    love.graphics.polygon('fill', self.vertices)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon('line', self.vertices)



    --love.graphics.setColor(1, 1, 1, 0.5)
    --love.graphics.circle('line', 0, 0, self.radius, 64)
    --love.graphics.circle('fill', 0, 0, 3, 16)

    --love.graphics.print(self.life_level)

    love.graphics.pop()
  end

}

return Asteroid
