function math.getDistance(x1,y1,x2,y2)
  return math.sqrt(math.pow(x1-x2, 2) + math.pow(y1-y2, 2))
end

function math.degreesToRads(angle)
  local _radsAngle = angle * math.pi / 180
  return _radsAngle
end

function math.radsTodegrees(angle)
  local degreesAngle = angle * 180 / math.pi
  return degreesAngle
end

-- If an angle is >=360° or <0°, return the correspondant angle between 0° and 359°
function math.capAngle(angle)

  local _capedAngle = angle

  if _capedAngle >= 360 then
    _capedAngle = _capedAngle - 360
  elseif _capedAngle < 0 then
    _capedAngle = _capedAngle + 360
  end

  return _capedAngle
end

function math.map(x1, x2, y1, y2, nb)
  -- On souhaite "mapper" les valeurs contenues entre x1 et x2 sur l'intervale y1, y2

  -- 1. Calcul du coefficient directeur "a"
  local a = (y2 - y1) / (x2 - x1)

  -- 2. On calcule l'ordonnée d'origine "b"
  local b = y1 - a * x1

  -- 3. On calcule l'image du nombre nb contenu dans l'intervale x1, x2 sur l'intervalue y1, y2
  return a * nb + b

end
