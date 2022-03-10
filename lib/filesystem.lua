local filesystem = {}

--[[local metatable = {
  __index = filesystem
}

function test.new(text)
	return setmetatable({tx = text}, metatable)
end

function test:draw()
	print (self.tx)
end

function filesystem.open(path, mode)
  checkArg(1, path, "string")
  local device = computer.getBootAddress()
  mode = mode or "r"
  if component.list("filesystem")[device] == "filesystem" then
    local fis = component.proxy(device)
    return setmetatable ({handle = fis.open(path, mode), fs = fis}, metatable)
  end
end

function filesystem.ropen(device, path, mode)
  mode = mode or "r"
  if component.list("filesystem")[device] == "filesystem" then
    local fis = component.proxy(device)
    return setmetatable ({handle = fis.open(path, mode), fs = fis}, metatable)
  end
end

function filesystem:read(size)
  fs = self.fs
  return fs.read(self.handle, size)
end

function filesystem:write(text)
  fs = self.fs
  return fs.write(self.handle, text)
end

function filesystem:close()
  fs = self.fs
  fs.close(self.handle)
end]]

function filesystem.open(path, mode)
  checkArg(1, path, "string")
  mode = mode or "r"
  local fs = component.proxy(computer.getBootAddress())
  local f = fs.open(path, mode)
  return {write = function(text) fs.write(f, text) end,
          read = function(len) return fs.read(f, (len or math.huge)) end,
          close = function() fs.close(f) end}
end

function filesystem.exists(path)
  local fis = component.proxy(computer.getBootAddress())
  return fis.exists(path)
end

function filesystem.makeDir(path)
  component.invoke(computer.getBootAddress(), "makeDirectory", path)
end

return filesystem
