local gui = lib.get("gui")
--local gpu = lib.get("component").gpu
local sys = lib.get("system")

local g = gui.newWindow("Execute")

::ret::
local text = gui.read(5,5,25)
local name = text
if text:sub(1,1) ~= "/" then
  name = "/bin/" .. text .. ".lua"
end
local pid = sys.start(name)
if not pid then goto ret end
waitForDead(pid)
