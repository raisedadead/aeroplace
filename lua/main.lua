local verbs = require('verbs')

local verb, first, second, third = ...
local count = select('#', ...)
if count == 1 and (verb == 'center' or verb == 'cycle' or verb == 'stages') then
  return verbs[verb]()
end
if verb == 'layout' and count <= 2 and not (first or ''):match('^%-') then
  return verbs.layout(first)
end
if verb == 'layout' and count == 4 and first == '--locked' then
  return verbs.layout_locked(second, third)
end
io.stderr:write('usage: aeroplace <center|cycle|stages|layout [workspace]>\n')
return 2
