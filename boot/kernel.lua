local thr = lib.get("thread")
local adv = lib.get("adv")
local event = lib.get("event")
local gui = lib.get("gui")
local gpu = lib.get("component").gpu
local sys = lib.get("system")

local lastEv = {}

gui.init()

local function run(id, i, ev, type)
  sys.processes[id].status = "run"
  sys.processes[id].arg = {}
  sys.current = sys.processes[id]
  local res = {}
  if type == "event" then
    res = {coroutine.resume(i.coro, table.unpack(ev))}
  else
    res = {coroutine.resume(i.coro)}
  end
  if res[1] == false then
    local tmp = string.gsub(i.path, "/", "_")
    os.log("kern"..tmp, res[2])
    table.remove(sys.processes, id)
  elseif res[2] == "sleep" then
    sys.processes[id].status = "sleep"
    sys.processes[id].arg = {computer.uptime()+res[3]}
  elseif res[2] == "wait" then
    sys.processes[id].status = "wait"
    sys.processes[id].arg = {res[3]}
  elseif res[2] == "loop" then
    sys.processes[id].status = "loop"
    sys.processes[id].arg = {}
  elseif res[2] == "event" then
    sys.processes[id].status = "event"
    if res[3] == -1 then
      sys.processes[id].arg = {-1, res[4]}
    else
      sys.processes[id].arg = {computer.uptime()+res[3], res[4]}
    end
  end
end

local skip = true

local function checkAndRun(id, i, ev)
  if coroutine.status(i.coro) == "dead" then gui.close(id); goto skip end
  
  --os.log("kernel", i.path .. " " .. i.status .. " " .. (tostring((i.arg[1] or computer.uptime()-computer.uptime()) or "") .. " " .. (tostring(i.arg[2]) or ""))
  --os.log("kernel", ev[1])
  --os.log("kernel", i.arg[2])
  if i.status == "run" then
    run(id, i)
  elseif i.status == "sleep" and computer.uptime() >= i.arg[1] then
    run(id, i)
  elseif i.status == "wait" and sys.processes[i.arg[1]] == nil then
    run(id, i)
  elseif i.status == "event" and i.arg[1] ~= -1 and computer.uptime() >= i.arg[1] then
    run(id, i)
  elseif i.status == "event" and i.arg[2][ev[1]] then
    run(id, i, ev, "event")
  elseif i.status == "loop" then
    sys.current = sys.processes[id]
  end
  if ev[1] ~= nil and skip then if gui.checkPress(ev) then skip = false end end
  ::skip::
end

while true do
  if #sys.processes == 0 then
    error("There is no process")
  end
  local ev = {computer.pullSignal(tonumber(sys.conf["updateRate"]))}
  skip = true
  if gui.ontop and gui.ontop.coro then checkAndRun(gui.ontop.pid, gui.ontop, ev) end
  for id,i in pairs(sys.processes) do
    if ev[1] ~= nil then lastEv = adv.duplicate(ev,z) end
    if gui.ontop and gui.ontop ~= i then
      checkAndRun(id, i, ev)
    end
  end
  
end
