local sys = lib.get("system")
local io = lib.get("io")
local ev = lib.get("ev")

local t = sys.current.tty

io.write("Hi")

ev.pull(-1, {key_down=true})
