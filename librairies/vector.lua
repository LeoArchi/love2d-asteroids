local Vector = {

  x,
  y,
  norm,
  angle,
  maxNorm,

  new = function(self, norm, angle)

    -- Si la norme est négative, inverser l'angle (+180°)
    if norm < 0 then
      angle = math.capAngle(angle + 180)
    end

    local _vector = {}

    setmetatable(_vector, self)
    self.__index = self

    local _angleRads = math.degreesToRads(angle)

    _vector.norm = math.abs(norm)
    _vector.angle = angle
    _vector.x = math.cos(_angleRads) * norm
    _vector.y = - math.sin(_angleRads) * norm

    return _vector
  end,

  add = function(self, vectorB)

    local _newVector = {}

    setmetatable(_newVector, Vector)
    Vector.__index = Vector

    _newVector.maxNorm = self.maxNorm -- La valeur max du nouveau vecteur est égale à celle du vecteur principal auquel on aditionne le vecteur B

    -- On calcule les composantes temporaires x et y du nouveau vecteur, sans tenir compte de la valeur max du vecteur principal (self)
    local newX = self.x + vectorB.x
    local newY = self.y + vectorB.y

    -- On calcule l'angle du nouveau vecteur
    _newVector.angle = math.capAngle(math.radsTodegrees(math.atan2(-newY, newX)))

    -- On calcule la norme du nouveau vecteur, qui ne dépend pas de la valeur max du vecteur principal (self)
    _newVector.norm = math.sqrt(math.pow(newX, 2) + math.pow(newY, 2))

    -- On réduit la norme si la valeur max du vecteur principal (self) est définie et dépassée
    if _newVector.maxNorm ~= nil then
      if _newVector.norm > _newVector.maxNorm then
        _newVector.norm = _newVector.maxNorm
      end
    end

    -- On calcule les véritables valeurs des composantes x et y du nouveau vecteur, en prenant en compte la valeur max du vecteur principal (self)
    _newVector.x = math.cos(math.degreesToRads(_newVector.angle)) * _newVector.norm -- CAH
    _newVector.y = -math.sin(math.degreesToRads(_newVector.angle)) * _newVector.norm -- SOH

    return _newVector

  end,

  multiply = function(self, value)

    -- L'angle reste inchangé, on ne fait rien
    self.angle = self.angle

    -- La norme est multipliée par la valeur passée en paramètre, et réduite à la valeur max si besoin
    self.norm = self.norm * value

    if self.maxNorm ~= nil then
      if self.norm > self.maxNorm then
        self.norm = self.maxNorm
      end
    end

    -- On calcule les nouvelles composantes x et y

    -- On calcule les véritables valeurs des composantes x et y du nouveau vecteur, en prenant en compte la valeur max du vecteur principal (self)
    self.x = math.cos(math.degreesToRads(self.angle)) * self.norm -- CAH
    self.y = -math.sin(math.degreesToRads(self.angle)) * self.norm -- SOH

  end


}

return Vector
