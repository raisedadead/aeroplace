local verbs = require('verbs')

local verb = ...
if select('#', ...) == 1 and verb == 'stages' then return verbs.stages() end
io.stderr:write('usage: aeroplace <center|cycle|stages>\n')
return 2
