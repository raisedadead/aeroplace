local aerospace = require('aerospace')
local placement = require('placement')

local M = {}

local function size(width, height)
  return string.format('%dx%d', placement.truncate(width), placement.truncate(height))
end

local function usable_area(index)
  local x, y, width, height = aeroplace.screen(index)
  if not x then error(y, 0) end
  return placement.usable(x, y, width, height, aerospace.bottom_inset(aerospace.config_path()))
end

local function focused_window()
  if not aeroplace.trusted() then error('needs Accessibility permission', 0) end
  local row = aerospace.focused_row()
  local handle = row and aeroplace.window(row.pid, row.title)
  if not handle then return nil end
  local width, height = aeroplace.size(handle)
  if not width then return nil end
  return {handle = handle, width = width, height = height, area = usable_area(row.screen)}
end

function M.center()
  local window = focused_window()
  if not window then return 0 end
  aeroplace.set_position(window.handle, placement.centre(window.area, window.width, window.height))
  return 0
end

function M.cycle()
  local window = focused_window()
  if not window then return 0 end
  aeroplace.set_size(window.handle, placement.next_stage(window.area, window.height))
  local width, height = aeroplace.size(window.handle)
  if not width then width, height = window.width, window.height end
  aeroplace.set_position(window.handle, placement.centre(window.area, width, height))
  return 0
end

function M.stages(write)
  write = write or print
  local area = usable_area(0)
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
