-- Librairies "système"
AnimationUtils = require "librairies/animationUtils"
Vector = require "librairies/vector"
require "librairies/mathUtils"
require "librairies/tableUtils"
require "librairies/graphicsUtils"

-- Librairies "objets"
Starship = require "starship"
Asteroid = require "asteroid"
Projectile = require "projectile"
Star = require "star"
Bonus = require "bonus"

-- Constantes
WIDTH = love.graphics.getWidth()
HEIGHT = love.graphics.getHeight()

local function init()
  -- Initialisation du joueur
  player = Starship:new(WIDTH/2, HEIGHT/2)

  -- Initialisation des astéroïdes
  asteroids = {}
  asteroidsExplosions = {} -- Permet de gérer les animations d'explosion des astéroides indépendament
  nb_max_asteroids = 5

  -- Initialisation des bonus
  allBonus = {}

  -- Controle l'effet de "tremblement de l'écran"
  screenShacking = {
    isShacking = false,
    isLeft = true,
    isRight = false,
    timer = 0,
    setScreenShacking = function()
      screenShacking.isShacking = true
      screenShacking.timer = 0.3
    end
  }

  -- Controlle l'effet de clignotement de l'écran
  screenBlinking = {
    count = 0,
    isWhite = false,
    isBlinking = false,
    setScreenBlinkinging = function()
      screenBlinking.isBlinking = true
      screenBlinking.count = 5
    end
  }

  -- alerte rouge = son alarme + écran rouge
  redAlert = {
    isOn = false,
    screenMaskAlpha = 0,
    screenMaskDirection = 1
  }

  -- Controlle le statut du jeu
  gameStatus = {
    title = true,
    intro = false,
    inGame = false,
    gameOver = false,
    pause = false,
  }

  -- Permet de ne lire certains sons appelées dans la GameLoop qu'une seule fois
  introWasPlayed = false
  outroGameoverWasPlayed = false
end

function love.load()
  math.randomseed(os.time())
  love.mouse.setVisible(false)

  theme = love.audio.newSource("resources/audio/mars.wav", "stream")
  theme:setLooping(true)
  theme:setVolume(1)

  piou = love.audio.newSource("resources/audio/piou.wav", "static")
  piou:setVolume(0.1)

  intro = love.audio.newSource("resources/audio/intro.wav", "static")
  intro:setVolume(0.8)

  outroGameover = love.audio.newSource("resources/audio/gameover.wav", "static")
  outroGameover:setVolume(0.8)

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
  earthAnimation = AnimationUtils:new(love.graphics.newImage("resources/images/earth2.png"), 450, 450, 3) -- Earth : 250 // Earth2 : 450

  -- Polices
  hudFont = love.graphics.newFont(20)
  titleFont = love.graphics.newFont(50)

  -- Etoiles
  stars = Star:generateStars(2000)

  -- Initialisation du joueur, des astéroïdes, des bonus et des effets de tremblement et de clignotement de l'écran
  init()

end

local function updateEarthAnimation(dt)
  earthAnimation.currentTime = earthAnimation.currentTime + dt
  if earthAnimation.currentTime >= earthAnimation.duration then
      earthAnimation.currentTime = earthAnimation.currentTime - earthAnimation.duration
  end
end

local function updateRedAlert(dt)
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
end

local function updateScreenBlinking(dt)
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
end

local function updateScreenShaking(dt)
  -- Mise à jour de l'effet tremblement
  if screenShacking.isShacking and screenShacking.timer > 0 then
    screenShacking.isLeft = not screenShacking.isLeft
    screenShacking.isRight = not screenShacking.isRight
    screenShacking.timer = screenShacking.timer - dt
  elseif screenShacking.timer < 0 then
    screenShacking.isShacking = false
  end
end

local function updateStarsShine(dt)
  for i, star in ipairs(stars) do
    star:update(dt)
  end
end

local function updateBonus(dt)

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

  -- Gestion de la collision entre les bonus et le joueur (récupération des bonus)
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
end

local function updateAsteroids(dt)

  -- Le nombre max d'astéroide augmente en fonction du score
  nb_max_asteroids = (math.floor(player.score / 2000) + 1) * 5
  if nb_max_asteroids > 40 then
    nb_max_asteroids = 40
  end

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
end

local function updateProjectiles(dt)
  -- Mise à jour des projectiles
  for i, projectile in ipairs(player.projectiles) do
    projectile:update(dt)
  end
end

local function updatePlayer(dt)
  player:update(dt)
  if player.energy <= 0 then
    gameStatus.inGame = false
    gameStatus.gameOver = true
  end
end

local function initAsteroids()
  -- On initialise les premiers astéroides
  for i=1,nb_max_asteroids do
    local asteroid = Asteroid:new()
    table.insert(asteroids, asteroid)
  end
end

function love.update(dt)

  -- Mise à jour de l'animation de la terre
  updateEarthAnimation(dt)

  -- Mise à jour du sintillement des étoiles
  updateStarsShine(dt)

  if gameStatus.title then
    -- Si la musique est en cours, la stopper
    if theme:isPlaying() then
      theme:stop()
    end

    -- Si le son d'outro est en cours, le stopper
    if outroGameover:isPlaying() then
      outroGameover:stop()
    end
  elseif gameStatus.intro and not gameStatus.pause then
    -- Mise à jour du joueur
    updatePlayer(dt)

    -- Mise à jour des projectiles
    updateProjectiles(dt)

    -- Lancer la musique principale
    if not theme:isPlaying() then
      theme:play()
    end

    -- Lancer l'intro
    if not intro:isPlaying() and not introWasPlayed then
      intro:play()
      introWasPlayed = true
    elseif introWasPlayed and not intro:isPlaying() then
      -- On "démarre" le jeu
      gameStatus.intro = false
      gameStatus.inGame = true
      initAsteroids()
    end
  elseif gameStatus.inGame and not gameStatus.pause then
    -- Mise à jour du joueur
    updatePlayer(dt)

    -- Gestion de l'alerte rouge
    updateRedAlert(dt)

    -- Gestion du clignotement de l'écran
    updateScreenBlinking(dt)

    -- Mise à jour du tremblement de l'écran
    updateScreenShaking(dt)

    -- Mise à jour des bonus (ajout de bonus régulièrement + gestion des collisions)
    updateBonus(dt)

    -- Mise à jour des projectiles
    updateProjectiles(dt)

    -- Mise à jour des astéroïdes
    updateAsteroids(dt)
  elseif gameStatus.gameOver then
    -- Je stoppe l'alarme
    if alarm:isPlaying() then
      alarm:stop()
    end

    -- Je joue le son d'outro
    if not outroGameover:isPlaying() and not outroGameoverWasPlayed then
      outroGameover:play()
      outroGameoverWasPlayed = true
    end
  end
end

function love.draw()

  -- Utilisation d'un masque en forme d'écran cathodique, on rend seulement les pixels avec une valeur supérieure à 0
  love.graphics.stencil(love.graphics.crtSencilFunction, "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  -- Affichage des étoiles
  love.graphics.setColor(1, 1, 1, 1)
  for i,star in ipairs(stars) do
    star:draw()
  end

  -- Affichage de la terre
  if not gameStatus.gameOver then
    love.graphics.setColor(1, 1, 1, 1)
    local spriteNum = math.floor(earthAnimation.currentTime / earthAnimation.duration * #earthAnimation.quads) + 1
    love.graphics.draw(earthAnimation.spriteSheet, earthAnimation.quads[spriteNum], WIDTH/2, HEIGHT/2, 0, 1, 1, earthAnimation.width/2, earthAnimation.height/2)
  end

  -- Affichage de l'atmosphère de la terre
  --love.graphics.setColor(178/255, 228/255, 247/255, 0.3)
  --love.graphics.circle('fill', WIDTH/2, HEIGHT/2, earthAnimation.width/2+10, 64)

  if gameStatus.title then
    -- Affichage du titre
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, HEIGHT/2 - titleFont:getHeight(), WIDTH, titleFont:getHeight()*1.5)

    love.graphics.setColor(1, 1, 1, 1)

    local title_txt = "ASTEROIDS"
    local startMessage_txt = "Press Enter to start"

    love.graphics.setFont(titleFont)
    love.graphics.print(title_txt, love.graphics.getWidth()/2 - titleFont:getWidth(title_txt)/2, love.graphics.getHeight()/2 - titleFont:getHeight())

    love.graphics.setFont(hudFont)
    love.graphics.print(startMessage_txt, love.graphics.getWidth()/2 - hudFont:getWidth(startMessage_txt)/2, love.graphics.getHeight()/2)
  elseif gameStatus.intro or gameStatus.inGame then

    -- Affichage du tremblement de l'écran
    if screenShacking.isShacking then
      if screenShacking.isLeft then
        love.graphics.translate(-5, -5)
      elseif screenShacking.isRight then
        love.graphics.translate(5, 5)
      end
    end

    -- Affichage du joueur
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

    -- Affichage des projectiles
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
  elseif gameStatus.gameOver then

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(titleFont)

    local gameOver_txt = "GAME OVER"
    local score_txt = "SCORE : " .. player.score
    local message_txt = "Press Enter to restart"

    love.graphics.print(gameOver_txt, love.graphics.getWidth()/2 - titleFont:getWidth(gameOver_txt)/2, love.graphics.getHeight()/2 - titleFont:getHeight())
    love.graphics.print(score_txt, love.graphics.getWidth()/2 - titleFont:getWidth(score_txt)/2, love.graphics.getHeight()/2)


    love.graphics.setFont(hudFont)
    love.graphics.print(message_txt, love.graphics.getWidth()/2 - hudFont:getWidth(message_txt)/2, love.graphics.getHeight()/2 + titleFont:getHeight())
  end

  if gameStatus.pause then
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, 0, WIDTH, HEIGHT)

    love.graphics.setColor(1, 1, 1, 1)

    local title_txt = "GAME PAUSED"
    local message_txt = "Press Escape to return to the game"

    love.graphics.setFont(titleFont)
    love.graphics.print(title_txt, love.graphics.getWidth()/2 - titleFont:getWidth(title_txt)/2, love.graphics.getHeight()/2 - titleFont:getHeight())

    love.graphics.setFont(hudFont)
    love.graphics.print(message_txt, love.graphics.getWidth()/2 - hudFont:getWidth(message_txt)/2, love.graphics.getHeight()/2)

  end

  -- Affichage du curseur
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', love.mouse.getX(), love.mouse.getY(), 16, 32)
  love.graphics.line(love.mouse.getX()-16-5, love.mouse.getY(), love.mouse.getX()-16+5, love.mouse.getY())
  love.graphics.line(love.mouse.getX()+16-5, love.mouse.getY(), love.mouse.getX()+16+5, love.mouse.getY())
  love.graphics.line(love.mouse.getX(), love.mouse.getY()-16-5, love.mouse.getX(), love.mouse.getY()-16+5)
  love.graphics.line(love.mouse.getX(), love.mouse.getY()+16-5, love.mouse.getX(), love.mouse.getY()+16+5)

  -- Affichage des scanlines
  love.graphics.scanLines()
end

local function togglePause()

  gameStatus.pause = not gameStatus.pause

  if gameStatus.pause then
    if intro:isPlaying() then
      intro:pause()
    end

    if theme:isPlaying() then
      theme:pause()
    end

    if alarm:isPlaying() then
      alarm:pause()
    end

  else
    if gameStatus.intro then
      intro:play()
    end

    theme:play()

    -- Note : l'alarme se relancera toute seule du fait du fonctionnement de l'alerte rouge
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'return' then
    if gameStatus.title then
      gameStatus.title = false
      gameStatus.intro = true
    elseif gameStatus.gameOver then
      init()
    end
  elseif key == 'escape' then
    if gameStatus.intro or gameStatus.inGame then
      togglePause()
    end
  end
end
