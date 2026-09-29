local verbs = require('verbs')

local version = '0.1.0'
local usage = 'usage: aeroplace <center|cycle|stages|layout [workspace]|--version|--help>\n'

local verb, first, second, third = ...
local count = select('#', ...)
if count == 1 and verb == '--version' then
  io.write('aeroplace ', version, '\n')
  return 0
end
if count == 1 and verb == '--help' then
  io.write(usage)
  return 0
end
if count == 1 and (verb == 'center' or verb == 'cycle' or verb == 'stages') then
  return verbs[verb]()
end
if verb == 'layout' and count <= 2 and not (first or ''):match('^%-') then
  return verbs.layout(first)
end
if verb == 'layout' and count == 4 and first == '--locked' then
  return verbs.layout_locked(second, third)
end
io.stderr:write(usage)
return 2
