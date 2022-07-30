local str = {}

str[1] = "███╗  ██╗██╗   ██╗ █████╗    █████╗  ██████╗"
str[2] = "████╗ ██║╚██╗ ██╔╝██╔══██╗  ██╔══██╗██╔════╝"
str[3] = "██╔██╗██║ ╚████╔╝ ███████║  ██║  ██║╚█████╗ "
str[4] = "██║╚████║  ╚██╔╝  ██╔══██║  ██║  ██║ ╚═══██╗"
str[5] = "██║ ╚███║   ██║   ██║  ██║  ╚█████╔╝██████╔╝"
str[6] = "╚═╝  ╚══╝   ╚═╝   ╚═╝  ╚═╝   ╚════╝ ╚═════╝ "

local colBack = 0xDD80CC
local colShade = 0xC364C5
local colFore = 0x414141

local gpu = component.proxy(component.list("gpu")())
local w,h = gpu.getResolution()
local startW, startH, endW = (w/2)-(unicode.len(str[1])/2), (h/2)-(#str/2)-10, unicode.len(str[1])
gpu.setBackground(colBack) -- 0xCD00CD 0xDD80CC
gpu.setForeground(colFore)
gpu.fill(1,1,w,h," ")
gpu.setBackground(colShade) -- 0xDD80CC 0xC364C5
gpu.fill(startW-2,startH-1,unicode.len(str[1])+4,#str+2," ")
for i = 1, #str do
  gpu.set(startW, startH+i-1, str[i])
end
gpu.fill(startW, 25, endW, 15, " ")
gpu.fill(startW, 15+26, endW, 1, " ")

local il = 1
local function dofiles(text, set)
  gpu.setForeground(colFore)
  gpu.setBackground(colShade)
  gpu.copy(startW, 26, endW, 14, 0, -1)
  gpu.fill(startW, 15+24, endW, 1, " ")
  gpu.set(startW, 15+24, text:sub(1,endW))
  gpu.setBackground(colBack)
  gpu.set((w/2 - 6), 15+25, "Loading " .. tostring(math.floor(set)) .. "%")
  computer.pullSignal(0)
end

local fs = component.proxy(computer.getBootAddress())
deb_info = debug.getinfo

function os.log(path, msg)
  fs.makeDirectory("/var/")
  fs.makeDirectory("/var/sys_log/")
  local file = fs.open("/var/sys_log/"..path..".log", "a")
  fs.write(file, string.format("[%s][%s][%s] %s\n",os.date("%d.%m.%Y %H:%M:%S"),deb_info(3).short_src,deb_info(3).name,tostring(msg)))
  fs.close(file)
end
function os.dumpstack(path)
  fs.makeDirectory("/var/")
  fs.makeDirectory("/var/sys_log/")
  local file = fs.open("/var/sys_log/dump_"..path..".log", "a")
  fs.write(file, os.date("%d.%m.%Y %H:%M:%S\n"))
  for i=3,25 do
    local info = deb_info(i)
    if not info then break end
    fs.write(file, (info.short_src or "~") .. " - " .. (info.name or "~") .. "\n")
  end
  fs.write(file, "===========END==========\n")
  fs.close(file)
end

do
  local lib = loadfile("/lib/lib.lua")()
  lib.init(dofiles)
end

function os.sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

--[[for i=1,50 do
  computer.pullSignal(5)
  --dofiles("test " .. i .. " " .. math.random(1,100), le/50*i)
end]]
local ev = {lib.get("event").rawpull(1, {key_down=true})}
if ev[4] == 41 then computer.beep(1300,0.05) end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1,1,w,h," ")

lib.get("users").gui.reg()
lib.get("users").gui.login()

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1,1,w,h," ")


if ev and ev[4] == 41 then
  local io = lib.get("io")
  for a,b in pairs(lib.getLoaded()) do
    _G[a] = b
  end

  io.print('Nya OS\nTerminal\n \n ')

  while true do
    local text = io.rawread('lua> ')
    local res, reas
    if text:sub(1,1) == '=' then
      text = text:sub(2)
      res, reas = pcall(load('return '..text))
    else 
      res, reas = pcall(load(text))
    end
    if reas ~= nil then io.print(reas) end
  end
else
  os.getenv = function(name) return lib.get("system").current.env[name] end
  os.setenv = function(name, value) lib.get("system").current.env[name] = value; return lib.get("system").current.env[name] end
  do 
    local res = {lib.get("system").start("/bin/init.lua")}
    if res[1] == nil then
      error(res[2])
    end
  end
  --os.log("boot_init",tostring(#lib.get("system").processes))
  loadfile('/boot/kernel.lua')()
end
