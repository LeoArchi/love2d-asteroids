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

  piou = love.audio.newSource("resources/audio/piou.wav", "static")
  piou:setVolume(0.1)

  intro = love.audio.newSource("resources/audio/intro.wav", "static")
  intro:setVolume(0.8)

  outro_gameover = love.audio.newSource("resources/audio/gameover.wav", "static")
  outro_gameover:setVolume(0.8)

  hit = love.audio.newSource("resources/audio/hit.wav", "static")
  hit:setVolume(0.3)

  oof = love.audio.newSource("resources/audio/oof.wav", "static")
  oof:setVolume(0.3)

  boom = love.audio.newSource("resources/audio/boum.wav", "static")
  boom:setVolume(0.3)

  alarm = love.audio.newSource("resources/audio/alarm.wav", "static")
  alarm:setLooping(true)
  alarm:setVolume(0.2)


  boomAnimation = AnimationUtils:new(love.graphics.newImage("resources/images/explosion.png"), 192, 192, 1)

  -- Polices
  hudFont = love.graphics.newFont(20)
  titleFont = love.graphics.newFont(50)

  math.randomseed(os.time())
  love.mouse.setVisible(false)

  WIDTH = love.graphics.getWidth()
  HEIGHT = love.graphics.getHeight()

  player = Starship:new(WIDTH/2, HEIGHT/2)

  asteroids = {}
  nb_max_asteroids = 5

  asteroidsExplosions = {} -- Permet de gérer les animations d'explosion des astéroides indépendament

  -- Controle l'effet de "tremblement de l'écran"
  screenShacking = {
    isShacking = false,
    isLeft = true,
    isRight = false,
    timer = 0
  }

  -- Controlle l'effet de clignotement de l'écran
  screenBlinking = {
    count = 0,
    isWhite = false,
    isBlinking = false
  }

  -- alerte rouge = son alarme + écran rouge
  redAlert = {
    isOn = false,
    screenMaskAlpha = 0,
    screenMaskDirection = 1
  }

  -- étoiles
  stars = Star:generateStars(2000)

  -- bonus
  allBonus = {}

  gameStarting = false
  gameStartingCounter = 0

  gameover_sound_wasPlayed = false

  titleScreen = true
  intro_sound_wasPlayed = false

end

function setShacking()
  screenShacking.isShacking = true
  screenShacking.timer = 0.3
end

function setScreenBlink()
  screenBlinking.isBlinking = true
  screenBlinking.count = 5
end

function setScanlines()

  love.graphics.setLineWidth(2)
  love.graphics.setColor(0.2, 0.2, 0.2, 0.5)

  for i=0, HEIGHT, 4 do
    love.graphics.line(0, i, WIDTH, i)
  end

end

local function oldScreenStencilFunction()

  local margin = 50
  local offset = -1500

  local rectangle_width = love.graphics.getWidth() - 2*margin
  local rectangle_height = love.graphics.getHeight() - 2*margin

  local center_x = love.graphics.getWidth()/2
  local center_y = love.graphics.getHeight()/2

  love.graphics.rectangle('fill', margin, margin, rectangle_width, rectangle_height)

  local horizontal_radius = math.sqrt(math.pow(rectangle_width/2, 2) + math.pow(rectangle_height-offset, 2))
  local vertical_radius = math.sqrt(math.pow(rectangle_width-offset, 2) + math.pow(rectangle_height/2, 2))

  local horizontal_alpha = math.atan2(rectangle_height-offset, rectangle_width/2)
  local vertical_alpha = math.atan2(rectangle_height/2, rectangle_width-offset)

  -- ARCS HORIZONTAUX

  -- arc du haut
  local _x = center_x
  local _y = center_y + rectangle_height/2 - offset

  love.graphics.arc('fill', 'closed', _x, _y, horizontal_radius, -horizontal_alpha, -math.pi + horizontal_alpha, 64)

  -- arc du bas
  local _x = center_x
  local _y = center_y - rectangle_height/2 + offset

  love.graphics.arc('fill', 'closed', _x, _y, horizontal_radius, horizontal_alpha, math.pi - horizontal_alpha, 64)

  -- ARCS VERTICAUX

  -- arc de gauche
  local _x = center_x + rectangle_width/2 - offset
  local _y = center_y

  love.graphics.arc('fill', 'closed', _x, _y, vertical_radius, -math.pi + vertical_alpha, -math.pi-vertical_alpha, 64)

  -- arc de droite
  local _x = center_x - rectangle_width/2 + offset
  local _y = center_y

  love.graphics.arc('fill', 'closed', _x, _y, vertical_radius, -vertical_alpha, vertical_alpha, 64)

end

function love.update(dt)

  if titleScreen then
    if love.keyboard.isDown('return') then
      print('HEY !')
      titleScreen = false
    end
  else
    if not theme:isPlaying() then
      theme:play()
    end
    if not intro:isPlaying() and not intro_sound_wasPlayed then
      intro:play()
      intro_sound_wasPlayed = true
    end
  end

  if player.energy > 0 and gameStarting then

    -- On gère l'alerte rouge
    if redAlert.isOn then
      -- Si l'alarme n'est pas jouée, on lance le son
      if not alarm:isPlaying() then
        alarm:play()
      end

      -- On met à jour l'effet rouge de l'écran
      if redAlert.screenMaskDirection == -1 then
        redAlert.screenMaskAlpha = redAlert.screenMaskAlpha - 0.45*dt
        if redAlert.screenMaskAlpha <=0 then
          redAlert.screenMaskAlpha = 0
          redAlert.screenMaskDirection = 1
        end
      elseif redAlert.screenMaskDirection == 1 then
        redAlert.screenMaskAlpha = redAlert.screenMaskAlpha + 0.45*dt
        if redAlert.screenMaskAlpha >=0.5 then
          redAlert.screenMaskAlpha = 0.5
          redAlert.screenMaskDirection = -1
        end
      end

    elseif not redAlert.isOn and alarm:isPlaying() then
      alarm:stop()
    end

    -- On traite l'effet de clignotement
    if screenBlinking.isBlinking and screenBlinking.count > 0 then

      screenBlinking.isWhite = not screenBlinking.isWhite -- On inverse la couleur du clignotement

      if screenBlinking.isWhite then
        screenBlinking.count = screenBlinking.count - 1 -- On décrémente le compteur de clignotement si on est sur une frame blanche
      end

      if screenBlinking.count == 0 then
        screenBlinking.isWhite = false -- Dans tout les cas, si le compteur de clignotement atteind 0, on redevient noir
      end

    end

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
          player.energy = player.energy + 30
          if player.energy > player.maxEnergy then
            player.energy = player.maxEnergy
          end
        elseif currentBonus.type == 'ammo' then
          player.max_fire_cooldown = player.max_fire_cooldown * 0.95
        end

        table.remove(allBonus, i)
      end
    end

  elseif not gameStarting and not titleScreen then

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
      gameStarting = true -- On "démarre" le jeu

      -- On initialise les premiers astéroides
      for i=1,nb_max_asteroids do
        local asteroid = Asteroid:new()
        table.insert(asteroids, asteroid)
      end

    end
  elseif not gameover_sound_wasPlayed and not titleScreen then

    -- Sintillement des étoiles
    for i, star in ipairs(stars) do
      star:update(dt)
    end

    if alarm:isPlaying() then
      alarm:stop()
    end

    gameover_sound_wasPlayed = true
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

  if titleScreen then

    -- Affichage des étoiles
    love.graphics.setColor(1, 1, 1, 1)
    for i,star in ipairs(stars) do
      star:draw()
    end

    love.graphics.setColor(1, 1, 1, 1)


    local title_txt = "ASTEROIDS"
    local startMessage_txt = "Press Enter to start"

    love.graphics.setFont(titleFont)
    love.graphics.print(title_txt, love.graphics.getWidth()/2 - titleFont:getWidth(title_txt)/2, love.graphics.getHeight()/2 - titleFont:getHeight())

    love.graphics.setFont(hudFont)
    love.graphics.print(startMessage_txt, love.graphics.getWidth()/2 - hudFont:getWidth(startMessage_txt)/2, love.graphics.getHeight()/2)

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

  elseif player.energy > 0 then
    -- Affichage des étoiles
    for i,star in ipairs(stars) do
      star:draw()
    end

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

    -- Affichage du HUD
    love.graphics.setFont(hudFont)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("SCORE : " .. player.score, 60, 60)

    -- On dessine la barre d'énergie
    local energyBar_width = 200
    local energyBar_height = 20

    love.graphics.setLineWidth(2)
    love.graphics.setColor(235/255, 64/255, 52/255, 1)
    love.graphics.rectangle('fill', 60, 90, player.energy * energyBar_width / player.maxEnergy, energyBar_height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', 60, 90, energyBar_width, energyBar_height)
    love.graphics.print(player.energy .. '%', energyBar_width + 70, 90)

    -- Affichage du curseur custom
    -- Le curseur de visée
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', love.mouse.getX(), love.mouse.getY(), 16, 32)
    love.graphics.line(love.mouse.getX()-16-5, love.mouse.getY(), love.mouse.getX()-16+5, love.mouse.getY())
    love.graphics.line(love.mouse.getX()+16-5, love.mouse.getY(), love.mouse.getX()+16+5, love.mouse.getY())
    love.graphics.line(love.mouse.getX(), love.mouse.getY()-16-5, love.mouse.getX(), love.mouse.getY()-16+5)
    love.graphics.line(love.mouse.getX(), love.mouse.getY()+16-5, love.mouse.getX(), love.mouse.getY()+16+5)

    -- Affichage de l'effet de clignotement
    if screenBlinking.isBlinking and screenBlinking.isWhite then
      love.graphics.setColor(1, 1, 1, 0.5)
      love.graphics.rectangle('fill', 0, 0, WIDTH, HEIGHT)
    end

    -- Affichage de l'effet "red alert"
    if redAlert.isOn then
      love.graphics.push()
      love.graphics.setColor(1, 0, 0, redAlert.screenMaskAlpha)
      love.graphics.rectangle('fill', 0, 0, WIDTH, HEIGHT)
      love.graphics.pop()
    end

    -- Affichage des scanlines
    setScanlines()

  else

    -- Affichage des étoiles
    love.graphics.setColor(1, 1, 1, 1)
    for i,star in ipairs(stars) do
      star:draw()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(titleFont)

    local gameOver_txt = "GAME OVER"
    local score_txt = "SCORE : " .. player.score

    love.graphics.print(gameOver_txt, love.graphics.getWidth()/2 - titleFont:getWidth(gameOver_txt)/2, love.graphics.getHeight()/2 - titleFont:getHeight())
    love.graphics.print(score_txt, love.graphics.getWidth()/2 - titleFont:getWidth(score_txt)/2, love.graphics.getHeight()/2)

    -- Affichage des scanlines
    setScanlines()
  end

end
