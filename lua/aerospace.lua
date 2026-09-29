local M = {}

M.fallback_bottom_inset = 60

function M.config_path()
  local path = aeroplace.aerospace('config', '--config-path')
  if path and path ~= '' then return path end
  local base = os.getenv('XDG_CONFIG_HOME') or (os.getenv('HOME') .. '/.config')
  return base .. '/aerospace/aerospace.toml'
end

local row_format = '%{window-id}|%{app-pid}|%{monitor-appkit-nsscreen-screens-id}|%{window-title}'

function M.focused_window_id()
  local id = os.getenv('AEROSPACE_WINDOW_ID')
  if not (id and id:match('^%d+$')) then
    id = aeroplace.aerospace('list-windows', '--focused', '--format', '%{window-id}')
  end
  return id and id:match('^%d+$')
end

function M.row(id)
  local output = aeroplace.aerospace('list-windows', '--all', '--format', row_format)
  for line in (output or ''):gmatch('[^\n]+') do
    local window_id, pid, screen, title = line:match('^([^|]*)|([^|]*)|([^|]*)|(.*)$')
    if window_id == id and pid:match('^%d+$') then
      local index = screen:match('^%-?%d+$') and tonumber(screen) or 0
      return {pid = tonumber(pid), screen = index, title = title}
    end
  end
end

function M.focused_row()
  local id = M.focused_window_id()
  if not id then return nil end
  for _ = 1, 20 do
    local row = M.row(id)
    if row then return row end
    aeroplace.sleep(0.05)
  end
end

function M.bottom_inset(path)
  local file = io.open(path)
  if not file then return M.fallback_bottom_inset end
  for line in file:lines() do
    local digits = line:sub(1, 12) == 'outer.bottom' and (line:match('=.*') or ''):gsub('%D', '')
    local value = digits and tonumber(digits)
    if value then
      file:close()
      return value
    end
  end
  file:close()
  return M.fallback_bottom_inset
end

return M
