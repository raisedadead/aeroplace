local aerospace = require('aerospace')
local placement = require('placement')

local M = {}

local function size(width, height)
  return string.format('%dx%d', placement.truncate(width), placement.truncate(height))
end

function M.stages(write)
  write = write or print
  local x, y, width, height = aeroplace.screen(0)
  if not x then error(y, 0) end
  local inset = aerospace.bottom_inset(aerospace.config_path())
  local area = placement.usable(x, y, width, height, inset)
  write('usable ' .. size(area.width, area.height))
  local stage_height = area.height
  for stage = 1, placement.stages do
    local stage_width
    stage_width, stage_height = placement.next_stage(area, stage_height)
    write(stage .. ' ' .. size(stage_width, stage_height))
  end
  return 0
end

return M
