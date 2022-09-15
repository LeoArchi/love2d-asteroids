
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
