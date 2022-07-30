local componen = {}

local users

function init()
  users = lib.get("users")
end

local com_gpu = component.proxy(component.list("gpu")())

--componen["gpu"] = component.proxy(component.list("gpu")())
--componen["filesystem"] = component.proxy(computer.getBootAddress())

---------------------GPU---------------------

componen.gpu = {}

function componen.gpu.set(x,y,text)
  if not users.checkPerm(1, {["/lib/gui"]=true}) then return nil, "permission denied." end

  return com_gpu.set(x,y,text)
end

function componen.gpu.getResolution()
  return com_gpu.getResolution()
end

function componen.gpu.setForeground(color)
  if not users.checkPerm(1, {["/lib/gui"]=true}) then return nil, "permission denied." end

  return com_gpu.setForeground(color)
end

function componen.gpu.setBackground(color)
  if not users.checkPerm(1, {["/lib/gui"]=true}) then return nil, "permission denied." end

  return com_gpu.setBackground(color)
end


---------------------------------------------

return componen, init
