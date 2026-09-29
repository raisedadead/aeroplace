local M = {}

function M.with(stub, body)
  local real = aeroplace
  aeroplace = stub
  local ok, message = pcall(body)
  aeroplace = real
  if not ok then error(message, 0) end
end

function M.file(content)
  local path = os.tmpname()
  local file = assert(io.open(path, 'w'))
  file:write(content)
  file:close()
  return path
end

function M.refuse(name)
  return function() error(name .. ' must not be called', 0) end
end

return M
