local function fails(...)
  local count = select('#', ...)
  local value, message = ...
  assert(count == 2 and value == nil and type(message) == 'string',
    'expected nil and a message, got ' .. tostring(value))
end

return {
  {'the table holds every primitive', function()
    for _, name in ipairs({'aerospace', 'trusted', 'window', 'size', 'set_size',
      'set_position', 'screen', 'sleep'}) do
      assert(type(aeroplace[name]) == 'function', name)
    end
  end},
  {'executable is the absolute path of the binary', function()
    assert(aeroplace.executable:match('^/.+/aeroplace$'), aeroplace.executable)
  end},
  {'aerospace returns trimmed stdout', function()
    local output = assert(aeroplace.aerospace('--version'))
    assert(output:match('^aerospace CLI client version'), output)
    assert(not output:match('%s$'), 'trailing whitespace')
  end},
  {'aerospace returns nil and stderr on failure', function()
    fails(aeroplace.aerospace('no-such-subcommand'))
  end},
  {'aerospace rejects a table argument', function()
    fails(aeroplace.aerospace({}))
  end},
  {'trusted returns a boolean', function()
    assert(type(aeroplace.trusted()) == 'boolean')
  end},
  {'window rejects wrong argument types', function()
    fails(aeroplace.window('pid', 'title'))
    fails(aeroplace.window(1, {}))
  end},
  {'size and writes reject a missing handle', function()
    fails(aeroplace.size('handle'))
    fails(aeroplace.set_size(nil, 100, 100))
    fails(aeroplace.set_position({}, 0, 0))
  end},
  {'screen returns the main visible frame for index 0', function()
    local x, y, width, height = aeroplace.screen(0)
    assert(type(x) == 'number' and type(y) == 'number', 'origin')
    assert(width > 0 and height > 0, 'size')
  end},
  {'screen rejects a string index', function()
    fails(aeroplace.screen('main'))
  end},
  {'sleep takes seconds and rejects a string', function()
    assert(select('#', aeroplace.sleep(0)) == 0)
    fails(aeroplace.sleep('soon'))
  end},
}
