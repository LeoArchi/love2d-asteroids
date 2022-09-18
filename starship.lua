local Starship = {

  position,
  speed,
  acceleration,
  orientation,
  max_fire_cooldown,
  fire_cooldown,
  projectiles,
  score,
  invincibility,
  energy,
  maxEnergy,
  energieTimer, -- Permet de faire perdre de l'énergie tous les n intervales de temps
  radius,

  new = function(self, x, y)

    local _starship = {}

    setmetatable(_starship, self)
    self.__index = self

    _starship.radius = 20
    _starship.position = Vector:newByCoordinates(x, y)
    _starship.speed = Vector:new(0,0)
    _starship.speed.maxNorm = 20
    _starship.acceleration = Vector:new(0,0)
    _starship.orientation = 0
    _starship.max_fire_cooldown = 0.3
    _starship.fire_cooldown = 0
    _starship.projectiles = {}
    _starship.score = 0
    _starship.maxEnergy = 100
    _starship.energy = _starship.maxEnergy
    _starship.energieTimer = 0
    _starship.invincibility = {
      isOn = false,
      timer,
    }

    return _starship

  end,

  update = function(self, dt)

    -- On update la perte d'énergie naturelle, seulement si le jeu à commencé
    if gameStatus.inGame then
      self.energieTimer = self.energieTimer + dt
      if self.energieTimer >= 1 then
        self.energieTimer = 0
        self.energy = self.energy - 1
      end
    end

    -- On joue le son d'alarme si la vie est inférieure à 20%
    if (self.energy / self.maxEnergy) * 100 < 20 and not redAlert.isOn then
      redAlert.isOn = true
    elseif (self.energy / self.maxEnergy) * 100 >= 20 and redAlert.isOn then
      redAlert.isOn = false
    end

    -- On update l'invincibilité
    if self.invincibility.isOn then
      self.invincibility.timer = self.invincibility.timer - dt
      if self.invincibility.timer < 0 then
        self.invincibility.isOn = false
      end
    end

    -- On reset l'accélération
    self.acceleration = Vector:new(0,0)

    -- La vitesse diminue d'elle même
    self.speed:multiply(0.95)


    if love.keyboard.isDown("z") then
      self.acceleration = self.acceleration:add(Vector:new(100*dt,90))
    elseif love.keyboard.isDown("s") then
      self.acceleration = self.acceleration:add(Vector:new(100*dt,270))
    end

    if love.keyboard.isDown("q") then
      self.acceleration = self.acceleration:add(Vector:new(100*dt,180))
    elseif love.keyboard.isDown("d") then
      self.acceleration = self.acceleration:add(Vector:new(100*dt,0))
    end

    self.speed = self.speed:add(self.acceleration)
    self.position = self.position:add(self.speed)

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

    -- Lorsque l'on connait la position finale du vaisseau, on calcule l'orientation par rapport à la position de la souris
    local _adj = love.mouse.getX() - self.position.x
    local _opp = love.mouse.getY() - self.position.y
    self.orientation = math.atan2(_opp, _adj)

    -- on tire des projectile si la souris est enfoncé
    self.fire_cooldown = self.fire_cooldown - dt
    if love.mouse.isDown(1) and self.fire_cooldown <= 0 then
      self.fire_cooldown = self.max_fire_cooldown
      local _piou = piou:clone()
      _piou:play()

      local _projectile_pos = Vector:new(self.position.norm, self.position.angle) -- on "clone" le vecteur
      local _projectile_speed = Vector:new(500, math.radsTodegrees(-self.orientation))
      local _projectile = Projectile:new(_projectile_pos, _projectile_speed, self.orientation)
      table.insert(self.projectiles, _projectile)
    end

  end,

  setInvicibility = function(self)
    self.invincibility.isOn = true
    self.invincibility.timer = 1.5
  end,

  hit = function(self)

    -- On joue le son "joueur touché"
    local _oof = oof:clone()
    _oof:play()

    -- Activer la "vibration" de l'écran
    screenShacking.setScreenShacking()

    -- Activer le clignotement de l'écran
    screenBlinking.setScreenBlinkinging()

    self:setInvicibility()
    self.energy = self.energy - 10
  end,

  draw = function(self)
    love.graphics.push()

    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.rotate(math.pi/2 + self.orientation)

    local top = {x= 0, y= -self.radius}
    local bottom_left = {x= -self.radius, y= self.radius}
    local bottom_right = {x= self.radius, y= self.radius}

    if not self.invincibility.isOn then
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
      love.graphics.polygon('fill', top.x, top.y, bottom_left.x, bottom_left.y, bottom_right.x, bottom_right.y)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(3)

    love.graphics.polygon('line', top.x, top.y, bottom_left.x, bottom_left.y, bottom_right.x, bottom_right.y)

    love.graphics.pop()
  end

}

return Starship
