AnimationUtils = require "librairies/animationUtils"
Vector = require "librairies/vector"
require "librairies/mathUtils"
require "librairies/tableUtils"

Starship = require "starship"
Asteroid = require "asteroid"
Projectile = require "projectile"
Star = require "star"
Bonus = require "bonus"

function love.load()

  theme = love.audio.newSource("resources/audio/mars.wav", "stream")
  theme:setLooping(true)
  theme:setVolume(1)
  theme:play()

  piou = love.audio.newSource("resources/audio/piou.wav", "static")
  piou:setVolume(0.1)

  intro = love.audio.newSource("resources/audio/intro.wav", "static")
  intro:setVolume(0.8)
  intro:play()

  outro_gameover = love.audio.newSource("resources/audio/gameover.wav", "static")
  outro_gameover:setVolume(0.8)

  hit = love.audio.newSource("resources/audio/hit.wav", "static")
  hit:setVolume(0.3)
  boom = love.audio.newSource("resources/audio/boum.wav", "static")
  boom:setVolume(0.3)

  boomAnimation = AnimationUtils:new(love.graphics.newImage("resources/images/explosion.png"), 192, 192, 1)

  math.randomseed(os.time())
  love.mouse.setVisible(false)

  WIDTH = love.graphics.getWidth()
  HEIGHT = love.graphics.getHeight()

  player = Starship:new(WIDTH/2, HEIGHT/2)

  asteroids = {}
  nb_max_asteroids = 5

  asteroidsExplosions = {} -- Permet de gérer les animations d'explosion des astéroides indépendament

  screenShacking = {
    isShacking = false,
    isLeft = true,
    isRight = false,
    timer = 0
  }

  -- étoiles
  stars = Star:generateStars(2000)

  -- bonus
  allBonus = {}

  gameStarting = false
  gameStartingCounter = 0

  gameover_sound_isPlayed = false

end

function setShacking()
  screenShacking.isShacking = true
  screenShacking.timer = 0.3
end

function setScanlines()

  love.graphics.setLineWidth(2)
  love.graphics.setColor(0.2, 0.2, 0.2, 0.5)

  for i=0, HEIGHT, 4 do
    love.graphics.line(0, i, WIDTH, i)
  end

end

local function oldScreenStencilFunction()

  local strokeHeight = 15
  local cornerRadius = 20

  love.graphics.rectangle('fill', strokeHeight, strokeHeight, love.graphics.getWidth()-2*strokeHeight, love.graphics.getHeight()-2*strokeHeight, cornerRadius, cornerRadius, 8 )
end

function love.update(dt)

  if player.energy > 0 and gameStarting then

    -- Le nombre max d'astéroide augmente en fonction du score
    nb_max_asteroids = (math.floor(player.score / 2000) + 1) * 5
    if nb_max_asteroids > 40 then
      nb_max_asteroids = 40
    end

    -- Sintillement des étoiles
    for i, star in ipairs(stars) do
      star:update(dt)
    end

    -- Ajout de bonus de vie régulièrement
    if math.random(0, 100) < 3 and table.length(allBonus) < 3 and player.energy < 50 then
      local _bonus = Bonus:new('life')
      table.insert(allBonus, _bonus)
    end

    -- Ajout de bonus d'arme régulièrement
    if math.random(0, 1000) < 1 and table.length(allBonus) < 3 then
      local _bonus = Bonus:new('ammo')
      table.insert(allBonus, _bonus)
    end

    -- Mise à jour de l'effet tremblement
    if screenShacking.isShacking and screenShacking.timer > 0 then
      screenShacking.isLeft = not screenShacking.isLeft
      screenShacking.isRight = not screenShacking.isRight
      screenShacking.timer = screenShacking.timer - dt
    elseif screenShacking.timer < 0 then
      screenShacking.isShacking = false
    end

    -- Mise à jour du joueur
    player:update(dt)

    -- Aléatoirement, on ajoute un astéroide
    if math.random(0, 100) < 1 and table.length(asteroids) < nb_max_asteroids then
      local asteroid = Asteroid:new()
      table.insert(asteroids, asteroid)
    end

    -- Mise à jour des astéroides
    for i, asteroid in ipairs(asteroids) do
      asteroid:update(dt)
    end

    -- Mise à jour des animations d'explosion des astéroides
    for i, explosion in ipairs(asteroidsExplosions) do
      -- Calcul de l'animation de mort
        explosion.animation.currentTime = explosion.animation.currentTime + dt
        if explosion.animation.currentTime >= explosion.animation.duration then
            table.remove(asteroidsExplosions,i)
        end
    end

    -- Mise à jour des projectiles
    for i, projectile in ipairs(player.projectiles) do
      projectile:update(dt)
    end

    -- Pour chaque astéroide
    for asteroid_index, asteroid in ipairs(asteroids) do

      -- Gestion des colisions entre l'astéroide et les projectiles
      for projectile_index, projectile in ipairs(player.projectiles) do
        local _distance = math.getDistance(asteroid.position.x,asteroid.position.y,projectile.position.x,projectile.position.y)
        if _distance <= asteroid.radius then
          asteroid:hit(asteroid_index)
          --table.remove(asteroids, asteroid_index)
          table.remove(player.projectiles, projectile_index)
        end
      end

      -- Gestion de la colision entre l'astéroide et le joueur
      local _distance = math.getDistance(asteroid.position.x,asteroid.position.y,player.position.x,player.position.y)
      if _distance <= asteroid.radius and not player.invincibility.isOn then
        player:hit()
      end
    end

    -- Gestion des bonus
    for i, currentBonus in ipairs(allBonus) do
      if math.getDistance(currentBonus.position.x,currentBonus.position.y,player.position.x,player.position.y) < currentBonus.radius + player.radius then

        if currentBonus.type == 'life' then
          player.energy = player.maxEnergy
        elseif currentBonus.type == 'ammo' then
          player.max_fire_cooldown = player.max_fire_cooldown * 0.90
        end

        table.remove(allBonus, i)
      end
    end

  elseif not gameStarting then

    -- Mise à jour du joueur
    player:update(dt)

    -- Sintillement des étoiles
    for i, star in ipairs(stars) do
      star:update(dt)
    end

    -- Mise à jour des projectiles
    for i, projectile in ipairs(player.projectiles) do
      projectile:update(dt)
    end

    gameStartingCounter = gameStartingCounter + dt
    if gameStartingCounter >= 12 then
      gameStarting = true -- On "démare" le jeu

      -- On initialise les premiers astéroides
      for i=1,nb_max_asteroids do
        local asteroid = Asteroid:new()
        table.insert(asteroids, asteroid)
      end

    end
  elseif not gameover_sound_isPlayed then
    gameover_sound_isPlayed = true
    if not outro_gameover:isPlaying() then
      outro_gameover:play()
    end
  end

end

function love.draw()

  -- draw a rectangle as a stencil. Each pixel touched by the rectangle will have its stencil value set to 1. The rest will be 0.
  love.graphics.stencil(oldScreenStencilFunction, "replace", 1)

  -- Only allow rendering on pixels which have a stencil value greater than 0.
  love.graphics.setStencilTest("greater", 0)

  if player.energy > 0 then
    -- Affichage des étoiles
    for i,star in ipairs(stars) do
      star:draw()
    end


    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("SCORE : " .. player.score, 20, 20)

    -- On dessine la barre d'énergie
    local energyBar_width = 200
    local energyBar_height = 20

    love.graphics.setLineWidth(2)
    love.graphics.setColor(235/255, 64/255, 52/255, 1)
    love.graphics.rectangle('fill', 20, 40, player.energy * energyBar_width / player.maxEnergy, energyBar_height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', 20, 40, energyBar_width, energyBar_height)
    love.graphics.print(player.energy, energyBar_width + 30, 45)


    love.graphics.setLineWidth(1)

    if screenShacking.isShacking then
      if screenShacking.isLeft then
        love.graphics.translate(-5, -5)
      elseif screenShacking.isRight then
        love.graphics.translate(5, 5)
      end
    end

    player:draw()

    -- Affichage des animations d'explosion des astéroides
    for i, explosion in ipairs(asteroidsExplosions) do
      local spriteNum = math.floor(explosion.animation.currentTime / explosion.animation.duration * #explosion.animation.quads) + 1
      love.graphics.draw(explosion.animation.spriteSheet, explosion.animation.quads[spriteNum], explosion.x - explosion.animation.width/2, explosion.y - explosion.animation.height/2, 0, 1)
    end

    -- Affichage des bonus
    for i, currentBonus in ipairs(allBonus) do
      currentBonus:draw()
    end

    -- Affichage des astéroides
    for i, asteroid in ipairs(asteroids) do
      asteroid:draw()
    end

    for i, projectile in ipairs(player.projectiles) do
      projectile:draw()
    end

    -- Affichage du curseur custom
    -- Le curseur de visée
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', love.mouse.getX(), love.mouse.getY(), 16, 32)
    love.graphics.line(love.mouse.getX()-16-5, love.mouse.getY(), love.mouse.getX()-16+5, love.mouse.getY())
    love.graphics.line(love.mouse.getX()+16-5, love.mouse.getY(), love.mouse.getX()+16+5, love.mouse.getY())
    love.graphics.line(love.mouse.getX(), love.mouse.getY()-16-5, love.mouse.getX(), love.mouse.getY()-16+5)
    love.graphics.line(love.mouse.getX(), love.mouse.getY()+16-5, love.mouse.getX(), love.mouse.getY()+16+5)

    -- Affichage des scanlines
    setScanlines()

  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("GAME OVER", 10, 10)
    love.graphics.print("SCORE : " .. player.score, 10, 25)
  end

end
