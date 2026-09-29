package.path = 'lua/?.lua;' .. package.path

local failures = 0
for _, suite in ipairs({'primitives'}) do
  for _, case in ipairs(require(suite)) do
    local ok, message = pcall(case[2])
    if ok then
      print('PASS: ' .. suite .. ': ' .. case[1])
    else
      failures = failures + 1
      print('FAIL: ' .. suite .. ': ' .. case[1] .. ': ' .. tostring(message))
    end
  end
end
return failures > 0 and 1 or 0
