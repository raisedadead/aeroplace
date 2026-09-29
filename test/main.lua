package.path = 'lua/?.lua;' .. package.path

local failures = 0
local function report(ok, name, message)
  if ok then
    print('PASS: ' .. name)
  else
    failures = failures + 1
    print('FAIL: ' .. name .. ': ' .. tostring(message))
  end
end

for _, suite in ipairs({'primitives_test', 'placement_test', 'verbs_test', 'window_verbs_test'}) do
  local loaded, cases = pcall(require, suite)
  if not loaded then
    report(false, suite, cases)
  else
    for _, case in ipairs(cases) do
      local ok, message = pcall(case[2])
      report(ok, suite .. ': ' .. case[1], message)
    end
  end
end
return failures > 0 and 1 or 0
