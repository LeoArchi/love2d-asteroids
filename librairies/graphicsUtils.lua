function love.graphics.getRandomColor(isGrayScale)
  local _color = {}

  if isGrayScale then
    local _grayLevel = math.random(0, 255)/255
    _color = {_grayLevel, _grayLevel, _grayLevel,1}
  else
    local _r = math.random(0, 255)/255
    local _g = math.random(0, 255)/255
    local _b = math.random(0, 255)/255
    _color = {_r, _g, _b ,1}
  end

  return _color
end

function love.graphics.scanLines()
  love.graphics.setLineWidth(2)
  love.graphics.setColor(0.2, 0.2, 0.2, 0.5)

  for i=0, HEIGHT, 4 do
    love.graphics.line(0, i, WIDTH, i)
  end
end

function love.graphics.crtSencilFunction()
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
