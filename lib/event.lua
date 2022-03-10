local event = {}

function event.pull(cd, eve)
  if type(cd) ~= "number" or cd == -1 then
    cd = math.huge
  end
  local wait = computer.uptime()+cd
  while true do
    local ev = {computer.pullSignal(wait - computer.uptime())}
    if eve[ev[1]] then return table.unpack(ev) end
    if computer.uptime() >= wait then return nil end
  end
end

return event
