local placement = require('placement')
local stub = require('stub')
local verbs = require('verbs')

local config = stub.file('outer.bottom = 44\n')
local rows = '41|100|1|Other|\n42|200|2|Title | with pipe |'

local function desktop(options)
  options = options or {}
  local calls, row_reads = {}, 0
  local function record(...) calls[#calls + 1] = table.concat({...}, ' ') end
  local api = {
    trusted = function() return options.trusted ~= false end,
    aerospace = function(...)
      local command = table.concat({...}, ' ')
      if command == 'config --config-path' then return config end
      if command:match('^list%-windows %-%-focused') then return options.focused end
      if command:match('^list%-windows %-%-all') then
        row_reads = row_reads + 1
        if row_reads < (options.row_after or 1) then return '' end
        return rows
      end
      error('unexpected aerospace ' .. command, 0)
    end,
    sleep = function(seconds) record('sleep', seconds) end,
    window = function(pid, title)
      record('window', pid, title)
      return 'handle'
    end,
    size = function(handle)
      record('size', handle)
      local sizes = options.sizes or {{1000, 800}}
      local next = table.remove(sizes, 1)
      if not next then return nil, 'unreadable' end
      return next[1], next[2]
    end,
    screen = function(index)
      record('screen', index)
      return -2560, 0, 2560, 1410
    end,
    set_size = function(handle, width, height) record('set_size', handle, width, height) end,
    set_position = function(handle, x, y) record('set_position', handle, x, y) end,
  }
  return api, calls
end

local function run(verb, options)
  local api, calls = desktop(options)
  local result
  stub.with(api, function() result = verbs[verb]() end)
  return result, table.concat(calls, '; ')
end

local area = {x = -2560, y = 0, width = 2560, height = 1366}

local function clipping_desktop(width, height)
  local api = desktop({focused = '42'})
  local frame = {width = width, height = height}
  frame.x, frame.y = placement.centre(area, width, height)
  api.size = function() return frame.width, frame.height end
  api.set_position = function(_, x, y) frame.x, frame.y = x, y end
  api.set_size = function(_, new_width, new_height)
    frame.width = math.min(new_width, area.x + area.width - frame.x)
    frame.height = math.min(new_height, 1410 - frame.y)
  end
  return api, frame
end

return {
  {'center moves the focused window to the centre of its screen', function()
    local result, calls = run('center', {focused = '42'})
    assert(result == 0)
    local expected = 'window 200 Title | with pipe ; size handle; screen 2; '
      .. 'set_position handle -1780 283'
    assert(calls == expected, calls)
  end},
  {'center reads AEROSPACE_WINDOW_ID before asking AeroSpace', function()
    local getenv = os.getenv
    os.getenv = function(name)
      if name == 'AEROSPACE_WINDOW_ID' then return '42' end
      return getenv(name)
    end
    local ok, result, calls = pcall(run, 'center', {focused = '41'})
    os.getenv = getenv
    assert(ok, result)
    assert(calls:match('^window 200 '), calls)
  end},
  {'center waits for the row to appear', function()
    local _, calls = run('center', {focused = '42', row_after = 3})
    assert(calls:match('^sleep 0%.05; sleep 0%.05; window 200 '), calls)
  end},
  {'center does nothing without a focused window', function()
    local result, calls = run('center', {})
    assert(result == 0 and calls == '', calls)
  end},
  {'center needs Accessibility permission', function()
    local ok, message = pcall(run, 'center', {focused = '42', trusted = false})
    assert(not ok and message:match('Accessibility'), message)
  end},
  {'cycle moves a growing window before it sets the size', function()
    local _, calls = run('cycle', {focused = '42', sizes = {{1000, 800}, {1600, 1084}}})
    local expected = 'window 200 Title | with pipe ; size handle; screen 2; '
      .. 'set_position handle -2087 141; set_size handle 1613 1084; size handle; '
      .. 'set_position handle -2080 141'
    assert(calls == expected, calls)
  end},
  {'cycle keeps every step on the ladder when the screen edge clips a resize', function()
    local api, frame = clipping_desktop(1016, 861)
    for _, size in ipairs({{1613, 1084}, {2113, 1241}, {2560, 1366}, {1016, 861}}) do
      stub.with(api, function() assert(verbs.cycle() == 0) end)
      local x, y = placement.centre(area, size[1], size[2])
      local got = table.concat({frame.x, frame.y, frame.width, frame.height}, ' ')
      assert(got == table.concat({x, y, size[1], size[2]}, ' '), got)
    end
  end},
  {'cycle centres the old size when the read-back fails', function()
    local _, calls = run('cycle', {focused = '42', sizes = {{1000, 800}}})
    assert(calls:match('set_position handle %-1780 283$'), calls)
  end},
}
