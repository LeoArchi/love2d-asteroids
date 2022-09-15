function table.length(table)
  local count = 0
  for k,v in pairs(table) do
    count = count + 1
  end
  return count
end

function table.copy(table)
  local copy = {}
  for key, value in pairs(table) do
      copy[key] = value
  end
  return copy
end