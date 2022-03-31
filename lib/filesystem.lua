local filesystem = {}

local uni = lib.get("unicode")
local component = lib.get("component")

function filesystem.open(path, mode)
  checkArg(1, path, "string")
  mode = mode or "r"
  local fs = component.proxy(computer.getBootAddress())
  local f = fs.open(path, mode)
  local file = {}
  file.buffer = ""
  file.cursor = 1
  file.bufSize = 512
  file.file = f
  function file.write(text)
    return fs.write(file.file, text)
  end 
  function file.read(size)
    if size then
      return fs.read(file.file, size)
    end
    local data = ""
    local new = ""
    repeat
      data = data .. new
      new = fs.read(file.file, file.bufSize)
    until not new
    return data
  end
  function file.readLine()
    local en = false
    repeat
      local data = fs.read(file.file, file.bufSize)
      if not data then file.buffer = file.buffer .. "\n"; en = true; break end
      file.buffer = file.buffer .. data
    until file.buffer:find("[\n \r]",file.cursor)
    local line = file.buffer:sub(file.cursor,file.buffer:find("[\n \r]",file.cursor)-1)
    file.cursor = file.buffer:find("[\n \r]",file.cursor)+1
    if file.cursor == uni.len(file.buffer) and en and line == "" then return nil end
    return line
  end
  function file.lines()
    return function()
      local line = file.readLine()
      if line then return line end
      return nil
    end
  end
  function file.close()
    fs.close(file.file)
  end
  return file
end

function filesystem.exists(path)
  local fis = component.proxy(computer.getBootAddress())
  return fis.exists(path)
end

function filesystem.makeDir(path)
  component.invoke(computer.getBootAddress(), "makeDirectory", path)
end

return filesystem
