local system = {}

local fs = lib.get("filesystem")
local adv = lib.get("adv")
local users = lib.get("users")
local gui = lib.get("gui")

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

function system.start(path, G, args)
  args = args or {}
  G = G or adv.duplicate(_G)
  G.os.sleep = function(timeout) coroutine.yield("sleep", timeout) end
  G.os.getenv = function(name) return system.current.env[name] end
  G.os.setenv = function(name, value) system.current.env[name] = value; return system.current.env[name] end
  G.os.close = function() gui.close(gui.ontop.pid) end
  G.waitForDead = function(pid) coroutine.yield("wait", pid) end

  if not fs.exists(path) then return nil, path .. " not exists." end
  local f = fs.open(path)
  
  local func, res = load(f.read(), "=" .. path, "bt", G)
  if not func then return nil, res end
  local coro, res = coroutine.create(func)
  if not coro then return nil, res end
  local pid = #system.processes+1
  system.processes[pid] = {pid = pid,path = path, status = "run", arg={}, coro = coro, conf={},env={}, gui=false,G=G, user=(system.current.user or "system"), parent=system.current, child={}}
  system.processes[pid].env = adv.duplicate(system.current.env or {})
  if system.current.tty then system.processes[pid].tty = system.current.tty end
  if system.current.child then system.current.child[#system.current.child+1] = system.processes[pid] end
  if not system.current.user or system.current.user == "system" or system.current.user == "root" then
    for i,b in pairs(args) do
      system.processes[pid][i] = b
    end
  end
  f.close()
  return pid
end

return system
