local stub = require('stub')
local verbs = require('verbs')
local aerospace = require('aerospace')

local config = stub.file('[gaps]\nouter.top = 8\nouter.bottom = 44\n')

local function display()
  return {
    aerospace = function(...)
      if select(1, ...) == 'config' then return config end
      error('unexpected aerospace call', 0)
    end,
    screen = function(index)
      assert(index == 0, 'stages reads the main screen')
      return 0, 25, 2560, 1410
    end,
    trusted = stub.refuse('trusted'),
    window = stub.refuse('window'),
    size = stub.refuse('size'),
    set_size = stub.refuse('set_size'),
    set_position = stub.refuse('set_position'),
  }
end

return {
  {'bottom inset reads outer.bottom', function()
    assert(aerospace.bottom_inset(config) == 44)
  end},
  {'bottom inset falls back to 60', function()
    assert(aerospace.bottom_inset('/nonexistent/aerospace.toml') == 60)
    assert(aerospace.bottom_inset(stub.file('  outer.bottom = 44\n')) == 60)
  end},
  {'config path falls back to XDG when aerospace fails', function()
    stub.with({aerospace = function() return nil, 'down' end}, function()
      assert(aerospace.config_path():match('/aerospace/aerospace%.toml$'))
    end)
  end},
  {'stages prints the ladder and touches no window', function()
    local lines = {}
    stub.with(display(), function()
      assert(verbs.stages(function(line) lines[#lines + 1] = line end) == 0)
    end)
    local expected = {'usable 2560x1366', '1 1016x861', '2 1613x1084', '3 2113x1241', '4 2560x1366'}
    assert(table.concat(lines, '|') == table.concat(expected, '|'), table.concat(lines, '|'))
  end},
}
