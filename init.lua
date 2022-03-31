local addr, invoke = computer.getBootAddress(), component.invoke
function loadfile(file)
  local handle = assert(invoke(addr, "open", file))
  local buffer = ""
  repeat
    local data = invoke(addr, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  invoke(addr, "close", handle)
  return load(buffer, "=" .. file, "bt", _G)
end
--[[

while true do
    local result, reason = xpcall(require("core").start()), function(msg)
        return tostring(msg).."\n"..debug.traceback()
    end)
    if not result then
        io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
        io.write("Press any key to continue.\n")
        os.sleep(0.5)
        require("event").pull("key")
    end
end
]]--



local function split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local gpu = component.proxy(component.list("gpu")())
local line = 1

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
local w,h = gpu.getResolution()
gpu.fill(1,1,w,h, ' ')

local function newLine()
  line = line + 1
  if line > h then
    line = h
    gpu.copy(1, 1, w, h, 0, -1, w, h)
    gpu.fill(1, h, w, 1, ' ')
  end
end

local function print(...)
  local tbl = {...}
  local text = ''
  for _,i in pairs(tbl) do
    if text == '' then 
      text = tostring(i)
    else
      text = text .. ' ' .. tostring(i)
    end
  end
  local newText = split(tostring(text), '\n')
  for _,i in pairs(newText) do
    local gtext = string.gsub(i,'\t', '   ')
    gpu.set(1,line,gtext)
    newLine()
  end
end

local xcomputer = computer
local fs = component.proxy(addr)

local function cycle(tab)
  local text = ""
  for i,b in pairs(tab) do
    --if i == _G then goto skip
    if type(b) == "table" then cycle(b)
    elseif type(b) == "function" then text = text .. tostring(i) .. "=function\n"
    else text = text .. tostring(i) .. "=" .. tostring(b) .. "\n" end
    ::skip::
    xcomputer.pullSignal(0)
  end
  return text
end

local function dump()
  local file = fs.open("/var/dump_".. os.date("%d-%m-%Y_%H.%M") ..".dmp", "w")
  fs.write(file, cycle(_ENV))
  fs.close(file)
end

local result, reason = xpcall(loadfile('/boot/init.lua'), function(msg)
  return tostring(msg).."\n"..debug.traceback()
end)
if not result then
  line = 1
  gpu.setBackground(0x0000AA)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1,1,w,h, ' ')
  print('/// Critical error has occurred! ///\n ')
  reason = reason or "unknown error"
  print(tostring(reason))
  xcomputer.beep(1500,0.1)
  if os.sleep ~= nil then os.sleep(0.1) end
  xcomputer.beep(1500,0.1)
  --dump()
  while true do
    e = xcomputer.pullSignal(1)
    if e == 'key_down' then 
      xcomputer.shutdown(true)
    end
  end
end
