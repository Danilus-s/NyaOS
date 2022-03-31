local tty = lib.get("tty")
local sys = lib.get("system")
local gui = lib.get("gui")

gui.newWindow("Terminal $PWD")

tty.new()

local pid = sys.start(os.getenv("SHELL"))
waitForDead(pid)