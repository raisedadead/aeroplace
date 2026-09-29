local M = {}

M.fractions = {1 / 4, 2 / 4, 3 / 4}
M.width_exponent = 2 / 3
M.height_exponent = 1 / 3

function M.round(value)
  if value >= 0 then return math.floor(value + 0.5) end
  return -math.floor(-value + 0.5)
end

function M.truncate(value)
  if value >= 0 then return math.floor(value) end
  return math.ceil(value)
end

function M.usable(x, y, width, height, inset)
  return {x = x, y = y, width = width, height = math.max(height - inset, 1)}
end

function M.centre(area, width, height)
  return M.round(area.x + (area.width - width) / 2), M.round(area.y + (area.height - height) / 2)
end

function M.next_stage(area, height)
  local heights = {}
  for stage, fraction in ipairs(M.fractions) do
    heights[stage] = M.round(area.height * fraction ^ M.height_exponent)
  end
  local nearest = 1
  local function distance(stage) return math.abs(heights[stage] - height) end
  for stage = 2, #M.fractions do
    if distance(stage) < distance(nearest) then nearest = stage end
  end
  local next = nearest % #M.fractions + 1
  return M.round(area.width * M.fractions[next] ^ M.width_exponent), heights[next]
end

return M
