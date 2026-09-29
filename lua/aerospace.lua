local M = {}

M.fallback_bottom_inset = 60

function M.config_path()
  local path = aeroplace.aerospace('config', '--config-path')
  if path and path ~= '' then return path end
  local base = os.getenv('XDG_CONFIG_HOME') or (os.getenv('HOME') .. '/.config')
  return base .. '/aerospace/aerospace.toml'
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
