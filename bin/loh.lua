local gui = lib.get("gui")
local gpu = lib.get("component").gpu
local sys = lib.get("system")

sys.setParam("name", "Execute")

local text = gui.read(event,5,5,25)
local pid = sys.start(text)
waitForDead(pid)
