local gui = lib.get("gui")
--local gpu = lib.get("component").gpu
local sys = lib.get("system")

local g = gui.newWindow("Execute")

g:newLabel(5,5,50,0x000000,0xFFFFFF,"Execute program at absolute path or /bin/?.lua")
g:newLabel(5,6,50,0x000000,0xFFFFFF,"Execute as " .. sys.current.user)

local lab = g:newLabel(5,8,50,0x000000,0xFFFFFF,"Status")

local text

local function exe()
  local name = g:get(text, "buffer")
  if name:sub(1,1) ~= "/" then
    name = "/bin/" .. name .. ".lua"
  end
  local pid, res = sys.start(name)
  if not pid then
    g:config(lab, "fg", 0xFF0000)
    g:config(lab, "text", "Error: " .. res)
    gui.updateAppWindow()
  else
    g:config(lab, "fg", 0x00FF00)
    g:config(lab, "text", "Succes")
    gui.updateAppWindow()
    waitForDead(pid)
  end
end

text = g:newEdit(5,10,25,nil,nil,nil,exe)
gui.updateAppWindow()

gui.mainloop()
