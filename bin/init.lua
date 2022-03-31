local gui = lib.get("gui")
local gpu = lib.get("component").gpu
local sys = lib.get("system")

local fullW, fullH = gpu.getResolution()

local function updateClock()
	gpu.setForeground(gui.color.text())
	gpu.setBackground(gui.color.background())
  gpu.set(fullW-9, fullH-2, os.date("%d.%m.%Y"))
  gpu.set(fullW-9, fullH-1, os.date("%H:%M"))
  gpu.set(fullW-3, fullH-1, os.date("%a"))
end
gui.newWindow("Nya OS")
--gui.updateMainScreen()

os.setenv("SHELL", "/bin/sh.lua")
os.setenv("PWD", lib.get("users").defUser.home)

--sys.start("/bin/execute.lua")
local event = lib.get("event")
while true do
	--updateMainScreen()
	updateClock()
  local ev = {event.pull(1, {key_down=true})}
  if ev[3] == 18 then
    sys.start("/bin/execute.lua")
  end
	
	--[[local ev = {event.pull(10, {touch=true, drag=true})}
	--os.log("bin-init", table.unpack(ev))
	--os.log("bin-init", tostring(ev))
	if ev[1] ~= nil then
		if ev[5] == 1 then
			gpu.setBackground(0x000000)
		else
			gpu.setBackground(gui.color.background())
		end
		gpu.set(ev[3],ev[4]," ")
	end]]
	--os.sleep(1)
end
