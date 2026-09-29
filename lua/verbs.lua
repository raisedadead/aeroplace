local aerospace = require('aerospace')
local layout = require('layout')
local placement = require('placement')

local M = {}

local function read(...)
  local output, message = aeroplace.aerospace(...)
  if not output then error(message, 0) end
  return output
end

local function execute(command)
  if not os.execute(command) then error('command failed: ' .. command, 0) end
end

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

function M.layout(workspace)
  local focused = aeroplace.aerospace('list-windows', '--focused',
    '--format', '%{window-id}|%{workspace}')
  local focused_id, focused_workspace = (focused or ''):match('^(%d+)|(.+)$')
  workspace = workspace or focused_workspace or read('list-workspaces', '--focused')
  local primary = focused_workspace == workspace and focused_id or ''
  local state = (os.getenv('XDG_STATE_HOME') or (assert(os.getenv('HOME')) .. '/.local/state'))
    .. '/aerospace'
  local quote = layout.quote
  execute('/bin/mkdir -p ' .. quote(state))
  execute(table.concat({
    '/usr/bin/lockf -k -t 10', quote(state .. '/layout.lock'), quote(aeroplace.executable),
    'layout --locked', quote(workspace), quote(primary),
  }, ' '))
  return 0
end

function M.layout_locked(workspace, primary)
  local rows = read('list-windows', '--workspace', workspace,
    '--format', '%{window-id}|%{window-layout}')
  local ids, present = {}, {}
  for id, window_layout in rows:gmatch('(%d+)|([^\n]+)') do
    if layout.includes(window_layout) then
      ids[#ids + 1] = id
      present[id] = true
    end
  end
  if #ids == 0 then return 0 end
  local plan = layout.plan(ids, present[primary] and primary or ids[1], workspace)
  read('eval', table.concat(plan, ' && '))
  return 0
end

return M
