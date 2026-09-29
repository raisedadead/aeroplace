local verbs = require('verbs')

local verb = ...
if select('#', ...) == 1 and verbs[verb] then return verbs[verb]() end
io.stderr:write('usage: aeroplace <center|cycle|stages>\n')
return 2
