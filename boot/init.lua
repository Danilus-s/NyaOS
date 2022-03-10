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

local loadText = {"M","e","o","w",".",".","."}
local il = 1
local function dofiles(text, set)
  gpu.setForeground(colFore)
  gpu.setBackground(colShade)
  gpu.copy(startW, 26, endW, 14, 0, -1)
  gpu.fill(startW, 15+24, endW, 1, " ")
  gpu.set(startW, 15+24, text:sub(1,endW))
  gpu.setBackground(colFore)
  gpu.fill(startW, 15+26, set, 1, " ")
  gpu.setBackground(colBack)
  if il > #loadText then il = 1 gpu.set(w/2 - #loadText/2, 15+25, string.rep(" ", #loadText)) end
  gpu.set((w/2 - #loadText/2)+il-1, 15+25, loadText[il])
  il = il + 1
  computer.pullSignal(0)
end

function os.log(path, msg)
  local fs = component.proxy(computer.getBootAddress())
  fs.makeDirectory("/var/")
  fs.makeDirectory("/var/sys_log/")
  local file = fs.open("/var/sys_log/"..path..".log", "a")
  fs.write(file, os.date("[%d.%m.%Y %H:%M:%S] ")..tostring(msg).."\n")
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
local ev = {lib.get("event").pull(1, {key_down=true})}

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

  io.print('Nya OS\nTerminal\n \n ')

  while true do
    local text = io.read('lua> ')
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
  do 
    local res = {lib.get("system").start("/bin/init.lua")}
    if res[1] == nil then
      error(res[2])
    end
  end
  os.log("boot_init",tostring(#lib.get("system").processes))
  loadfile('/boot/kernel.lua')()
end