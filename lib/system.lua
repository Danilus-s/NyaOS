local system = {}

local fs = lib.get("filesystem")
local adv = lib.get("adv")
local users = lib.get("users")

system.processes = {}
system.current = {}
system.ontop = {}
system.conf = {}

local f = fs.open("/etc/system.conf")
local raw = f.read()
local spl = adv.split(raw, "\n")
for _,b in pairs(spl) do
  local tmp = adv.split(b, " ")
  system.conf[tmp[1]] = tmp[2]
end

function system.setParam(key, value)
  if type(key) ~= "string" or type(value) ~= "string" then
    return nil, "key and value must be a string"
  end
  system.current.conf[key] = value
end

function system.start(path, G)
  if not G then
    G = adv.duplicate(_G)
    G.os.sleep = function(timeout) coroutine.yield("sleep", timeout) end
    G.event = {}
    G.event.pull = function(timeout, event) return coroutine.yield("event", timeout, event) end
    G.waitForDead = function(pid) coroutine.yield("wait", pid) end
  end

  if not fs.exists(path) then return nil, path .. " not exists." end
  local f = fs.open(path)
  
  local func, res = load(f.read(), "=" .. path, "bt", G)
  if not func then return nil, res end
  local coro, res = coroutine.create(func)
  if not coro then return nil, res end
  system.processes[#system.processes+1] = {path = path, status = "run", arg={}, coro = coro, conf={name="App"}, user=(system.current.user or "root"), parent=system.current}
  system.ontop = system.processes[#system.processes]
  f.close()
  return true, #system.processes
end

return system
