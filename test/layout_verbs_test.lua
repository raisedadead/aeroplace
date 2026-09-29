local stub = require('stub')

local main = assert(loadfile('lua/main.lua'))
local executable = '/fixture/bin/aeroplace'
local state_dir = '/fixture/home/.local/state/aerospace'
local environment = {HOME = '/fixture/home', AEROSPACE_WINDOW_ID = '999', AEROSPACE_WORKSPACE = '9'}
local rows = '11|h_tiles\n22|floating\n33|v_accordion'
local extract = '--boundaries workspace --boundaries-action create-implicit-container'

local function words(command)
  local result, word, quoted, escaped = {}, nil, false, false
  for character in command:gmatch('.') do
    if escaped then
      word, escaped = (word or '') .. character, false
    elseif character == '\\' and not quoted then
      word, escaped = word or '', true
    elseif character == "'" then
      word, quoted = word or '', not quoted
    elseif character:match('%s') and not quoted then
      if word then result[#result + 1], word = word, nil end
    else
      word = (word or '') .. character
    end
  end
  assert(not quoted and not escaped, 'unclosed shell word')
  if word then result[#result + 1] = word end
  return result
end

local function run(arguments, fixture)
  local state = {locks = 0, evals = {}}
  local api = {executable = executable}
  function api.aerospace(...)
    local argv = {...}
    if argv[1] == 'list-windows' and argv[2] == '--focused' then
      return state.locks > 0 and fixture.focus_after_lock or fixture.focus
    end
    if argv[1] == 'list-workspaces' and argv[2] == '--focused' then return fixture.workspace end
    if argv[1] == 'list-windows' and argv[2] == '--workspace' then
      assert(argv[3] == state.workspace, 'the child lists another workspace')
      return fixture.rows
    end
    if argv[1] == 'eval' and #argv == 2 then
      state.evals[#state.evals + 1] = argv[2]
      if fixture.eval_fails then return nil, 'eval failed' end
      return ''
    end
    error('unexpected aerospace ' .. table.concat(argv, ' '), 0)
  end
  local function execute(command)
    if command == "/bin/mkdir -p '" .. state_dir .. "'" then return true end
    local tokens = words(command)
    local prefix = {'/usr/bin/lockf', '-k', '-t', '10', state_dir .. '/layout.lock', executable}
    assert(table.concat(tokens, ' ', 1, 6) == table.concat(prefix, ' '), command)
    state.locks = state.locks + 1
    assert(state.locks == 1, 'recursive lock acquisition')
    if fixture.lock_fails then return nil, 'exit', 75 end
    state.workspace = tokens[9]
    local ok, result = pcall(main, table.unpack(tokens, 7))
    if not ok then state.child_error = result end
    if ok and result == 0 then return true, 'exit', 0 end
    return nil, 'exit', ok and result or 1
  end
  local getenv, real_execute = os.getenv, os.execute
  os.getenv = function(name) return environment[name] end
  os.execute = execute
  local ok, result
  stub.with(api, function() ok, result = pcall(main, 'layout', table.unpack(arguments)) end)
  os.getenv, os.execute = getenv, real_execute
  return ok, result, state
end

local reference = {
  {arguments = {}, fixture = {focus = '22|1', focus_after_lock = '33|2', rows = rows}, eval = {
    'fullscreen off --window-id 22', 'layout --window-id 22 tiling',
    'fullscreen off --window-id 11', 'layout --window-id 11 tiling',
    'fullscreen off --window-id 33', 'layout --window-id 33 tiling',
    "flatten-workspace-tree --workspace '1'", "layout --workspace '1' --root v_tiles",
    'move left --window-id 22 ' .. extract, "balance-sizes --workspace '1'",
  }},
  {arguments = {'work space'}, fixture = {focus = '22|work space', rows = rows}, eval = {
    'fullscreen off --window-id 22', 'layout --window-id 22 tiling',
    'fullscreen off --window-id 11', 'layout --window-id 11 tiling',
    'fullscreen off --window-id 33', 'layout --window-id 33 tiling',
    "flatten-workspace-tree --workspace 'work space'",
    "layout --workspace 'work space' --root v_tiles",
    'move left --window-id 22 ' .. extract, "balance-sizes --workspace 'work space'",
  }},
  {arguments = {}, fixture = {focus = '22|1', rows = '11|h_tiles\n33|h_tiles'}, eval = {
    'fullscreen off --window-id 11', 'layout --window-id 11 tiling',
    'fullscreen off --window-id 33', 'layout --window-id 33 tiling',
    "flatten-workspace-tree --workspace '1'", "layout --workspace '1' --root v_tiles",
    'move left --window-id 11 ' .. extract, "balance-sizes --workspace '1'",
  }},
  {arguments = {}, fixture = {focus = '11|1', rows = '11|h_tiles'}, eval = {
    'fullscreen off --window-id 11', 'layout --window-id 11 tiling',
    "flatten-workspace-tree --workspace '1'", "layout --workspace '1' --root h_tiles",
  }},
  {arguments = {}, fixture = {focus = '', workspace = '3', rows = '11|h_tiles\n22|other'}, eval = {
    'fullscreen off --window-id 11', 'layout --window-id 11 tiling',
    "flatten-workspace-tree --workspace '3'", "layout --workspace '3' --root h_tiles",
  }},
}

return {
  {'layout sends the same eval as the dotfiles runner', function()
    for index, case in ipairs(reference) do
      local ok, result, state = run(case.arguments, case.fixture)
      assert(ok and result == 0, 'case ' .. index .. ': ' .. tostring(state.child_error or result))
      local sent = #state.evals == 1 and state.evals[1]
      assert(sent == table.concat(case.eval, ' && '), 'case ' .. index .. ': ' .. tostring(sent))
    end
  end},
  {'an empty workspace sends no eval', function()
    local ok, result, state = run({}, {focus = '', workspace = '1', rows = ''})
    assert(ok and result == 0, result)
    assert(state.locks == 1 and #state.evals == 0)
  end},
  {'a failed lock prevents window commands', function()
    local ok, result, state = run({}, {focus = '22|1', rows = rows, lock_fails = true})
    assert(not ok and tostring(result):find('command failed', 1, true), result)
    assert(#state.evals == 0)
  end},
  {'a failed eval fails the layout', function()
    local ok, result, state = run({}, {focus = '22|1', rows = rows, eval_fails = true})
    assert(not ok and tostring(result):find('command failed', 1, true), result)
    assert(state.child_error == 'eval failed' and #state.evals == 1, state.child_error)
  end},
  {'a workspace name with an apostrophe is rejected, not mangled', function()
    local ok, _, state = run({"work's space"}, {focus = "22|work's space", rows = rows})
    assert(not ok and tostring(state.child_error):find('cannot quote an apostrophe', 1, true))
    assert(#state.evals == 0)
  end},
}
