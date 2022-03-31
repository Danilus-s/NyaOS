local event = {}

function event.rawpull(cd, eve)
  if type(cd) ~= "number" or cd == -1 then
    cd = math.huge
  end
  local wait = computer.uptime()+cd
  while true do
    local ev = {computer.pullSignal(wait - computer.uptime())}
    if eve[ev [1] ] then return table.unpack(ev) end
    if computer.uptime() >= wait then return nil end
  end
end

function event.pull(timeout, event)
  return coroutine.yield("event", timeout, event)
end

event.push = computer.push

return event
