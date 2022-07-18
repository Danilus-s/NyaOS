local gui = {}

local gpu = lib.get("component").gpu
local uni = lib.get("unicode")
local event = lib.get("event")
local sh = lib.get("shell")
local sys = {}

local draw = {}
gui.color = {}
gui.ontop = {}
gui.panel = {}
gui.edit = nil
gui.tabSize = 15

local editChar = "┃"


local fullW, fullH = gpu.getResolution()
-----------------------------------------------------------
function gui.color.background() return 0xDD80CC end
function gui.color.shadow() return 0xC364C5 end
function gui.color.foreground() return 0x414141 end
function gui.color.text() return 0x414141 end
function gui.getViewport() return 1,2,fullW,fullH-4 end
-----------------------------------------------------------
local gpuSB = gpu.setBackground
local gpuSF = gpu.setForeground
local gpuFill = gpu.fill
local gpuSet = gpu.set
local uniLen = uni.len
-----------------------------------------------------------

function gui.init()
  sys = lib.get("system")
end

function gui.updateAppWindow()
  if sys.current.gui then
    gpuSB(0x000000)
    gpuFill(1,2,fullW,fullH-4," ")
    if gui.panel[1] ~= gui.ontop then 
      gpuSB(0xFF0000)
      gpuFill(fullW-1,1,2,1," ")
    end
    for _,i in pairs(gui.ontop.gui.elem) do
      if i.type == "plane" then
        gpuSB(i.bg)
        gpuFill(i.x,i.y,i.w,i.h, " ")
      elseif i.type == "label" then
        gpuSF(i.fg)
        gpuSB(i.bg)
        gpuSet(i.x,i.y,i.text:sub(1,i.w))
      elseif i.type == "edit" then
        gpuSF(i.fg)
        gpuSB(i.bg)
        gpuFill(i.x,i.y,i.w,1," ")
        gpuSet(i.x,i.y,i.dsplText)
      elseif i.type == "button" then
        gpuSF(i.fg)
        gpuSB(i.bg)
        gpuFill(i.x,i.y,i.w,i.h," ")
        gpuSet(i.x+(i.w/2-math.floor(uniLen(i.text:sub(1,i.w))/2)),i.y+(math.ceil(i.h/2))-1,i.text:sub(1,i.w))
      end
      computer.pullSignal(0)
    end
    computer.pushSignal("updateAppWindow")
  end
end

function gui.updateMainScreen()
  gpuSB(gui.color.background())
  gpuFill(1,1,fullW,1," ")
  gpuFill(1,fullH-2,fullW,3," ")
  gpuSF(gui.color.text())
  gpuSet(2,1,sh.expand(gui.ontop.gui.name))

  for i,b in pairs(gui.panel) do
    local x1 = (gui.tabSize*i)-(gui.tabSize-1)
    if gui.ontop == b then
      gpuSB(gui.color.shadow())
    else
      gpuSB(gui.color.background())
    end
    gpuFill(x1,fullH-2,gui.tabSize,3," ")
    local nm = sh.expand(b.gui.name):sub(1,gui.tabSize-2)
    gpuSet(x1+1,fullH-1,nm)
  end
  computer.pushSignal("updateMainScreen")
end

function gui.settop(process)
    gui.ontop = process
    gui.edit = nil
    gui.updateMainScreen()
    gui.updateAppWindow()
end

local function getPanelID(pid)
  if pid then
    for i,b in pairs(gui.panel) do
      if sys.processes[pid] == b then
        return i
      end
    end
  else
    for i,b in pairs(gui.panel) do
      if gui.ontop == b then
        return i
      end
    end
  end
  return -1
end

function gui.close(pid)
  if not sys.processes[pid] then return end
  for _,b in pairs(sys.processes[pid].child) do
    gui.close(b.pid)
  end
  local id = getPanelID(pid)
  if id then table.remove(gui.panel, id) end
  sys.processes[pid] = nil
  gui.settop(gui.panel[1])
end

local function onEdit(ev)
  os.log("onEdit", "call")
  if not gui.edit then return end
  local x,y,maxX = gui.edit.x, gui.edit.y, gui.edit.w
  local useChar = false
  if gui.edit.arg.pwdchar then useChar = true gui.edit.arg.pwdchar = uni.sub(gui.edit.arg.pwdchar,1,1) end
  gui.edit.data.curX = gui.edit.data.curX or uniLen(gui.edit.buffer)
  gpuSB(gui.edit.bg)
  gpuSF(gui.edit.fg)
  gpuSet(x,y,editChar .. string.rep(" ",maxX-1))
  gui.edit.data.startX = gui.edit.data.startX or 1
  gui.edit.data.endX = gui.edit.data.endX or 1
  gui.edit.control = false
  if ev[1] == "key_down" and (ev[4] == 29 or ev[4] == 157) then
    gui.edit.control = true
  elseif ev[1] == "key_up" and (ev[4] == 29 or ev[4] == 157) then
    gui.edit.control = false
  end
  if ev[1] == "key_down" then
      -- Return
    if ev[3] == 13 then
      if useChar then
        if uniLen(gui.edit.buffer) > maxX then gpuSet(x,y,uni.sub(string.rep(gui.edit.arg.pwdchar,uniLen(gui.edit.buffer)) .. " ", uniLen(gui.edit.buffer)+1-maxX)) else gpuSet(x,y,string.rep(gui.edit.arg.pwdchar,uniLen(gui.edit.buffer)) .. " ") end
      else
      if uniLen(gui.edit.buffer) > maxX then gpuSet(x,y,uni.sub(gui.edit.buffer .. " ", uniLen(gui.edit.buffer)+1-maxX)) else gpuSet(x,y,gui.edit.buffer .. " ") end
      end
      return true
      -- Backspace
    elseif ev[4] == 14 then
      if gui.edit.data.curX > 0 then
        if gui.edit.data.curX ~= uniLen(gui.edit.buffer) then
          gui.edit.buffer = uni.sub(gui.edit.buffer, 1, gui.edit.data.curX-1) .. uni.sub(gui.edit.buffer, gui.edit.data.curX+1)
        else
          gui.edit.buffer = uni.sub(gui.edit.buffer, 1, -2)
        end
        gui.edit.data.curX = gui.edit.data.curX - 1
        gui.edit.data.endX = uniLen(gui.edit.buffer)
        if gui.edit.data.startX > 1 then gui.edit.data.startX = gui.edit.data.startX - 1;gui.edit.data.endX = uniLen(gui.edit.buffer) + 1 end
      end
    -- Delete
    elseif ev[4] == 211 then
      if gui.edit.data.curX < uniLen(gui.edit.buffer) then
        if gui.edit.data.curX ~= 0 then
          gui.edit.buffer = uni.sub(gui.edit.buffer, 1, gui.edit.data.curX) .. uni.sub(gui.edit.buffer, gui.edit.data.curX+2)
        else
          gui.edit.buffer = uni.sub(gui.edit.buffer, 2)
        end
      if uniLen(gui.edit.buffer) < maxX then gui.edit.data.endX = gui.edit.data.endX - 1 end
      end
    -- Home
    elseif ev[4] == 199 then
      gui.edit.data.curX = 0
      gui.edit.data.startX = 1
      if gui.edit.data.endX > maxX then gui.edit.data.endX = maxX end
    -- End
    elseif ev[4] == 207 then
      gui.edit.data.curX = uniLen(gui.edit.buffer)
      gui.edit.data.endX = uniLen(gui.edit.buffer)
      if uniLen(gui.edit.buffer) > maxX then gui.edit.data.startX = gui.edit.data.endX - maxX + 1 end
      if gui.edit.data.startX > 1 then gui.edit.data.endX = uniLen(gui.edit.buffer) + 1 end
    -- Arrows
    -- <
    elseif ev[4] == 203 then
      if gui.edit.data.curX > 0 then
        gui.edit.data.curX = gui.edit.data.curX - 1
      if gui.edit.data.curX < gui.edit.data.startX-1 then gui.edit.data.startX = gui.edit.data.startX - 1; gui.edit.data.endX = gui.edit.data.endX - 1 end
      end
    -- >
    elseif ev[4] == 205 then
      if gui.edit.data.curX < uniLen(gui.edit.buffer) then
        gui.edit.data.curX = gui.edit.data.curX + 1
      end 
      if gui.edit.data.curX > gui.edit.data.endX-1 then
        if uniLen(gui.edit.buffer) > maxX then
          gui.edit.data.startX = gui.edit.data.startX + 1
        end
        gui.edit.data.endX = gui.edit.data.endX + 1
      end
    elseif ev[3] == 0 then
    elseif not Control then
      if uniLen(gui.edit.buffer) >= (gui.edit.arg.maxlen or 32) and gui.edit.arg.maxlen ~= nil then goto skip end
      local char = uni.char(ev[3])
      if ev[4] == 15 then char = "  " end
      gui.edit.buffer = uni.sub(gui.edit.buffer,1,gui.edit.data.curX) .. char .. uni.sub(gui.edit.buffer,gui.edit.data.curX+1)--gui.read(1,1,8)
      gui.edit.data.curX = gui.edit.data.curX + 1
      if ev[4] == 15 then gui.edit.data.curX = gui.edit.data.curX + 1 end
      gui.edit.data.endX = uniLen(gui.edit.buffer)
      if uniLen(gui.edit.buffer) >= maxX then gui.edit.data.startX = gui.edit.data.startX + 1 end
      if gui.edit.data.startX > 1 then gui.edit.data.endX = uniLen(gui.edit.buffer) + 1 end
      ::skip::
    end
  elseif ev[1] == "clipboard" then
    local text = ev[3]
    if gui.edit.arg.maxlen then text = text:sub(1,gui.edit.arg.maxlen - uniLen(gui.edit.buffer)) end
    gui.edit.buffer = uni.sub(gui.edit.buffer,1,gui.edit.data.curX) .. text .. uni.sub(gui.edit.buffer,gui.edit.data.curX+1)--gui.read(1,1,8)
    gui.edit.data.curX = gui.edit.data.curX + uniLen(text)
    gui.edit.data.endX = uniLen(gui.edit.buffer)
    if uniLen(gui.edit.buffer) >= maxX then gui.edit.data.startX = gui.edit.data.startX + uniLen(text) end
    if gui.edit.data.startX > 1 then gui.edit.data.endX = uniLen(gui.edit.buffer) + 1 end
  elseif ev[1] == "touch" then
    if ev[3] >= x and ev[3] <= x+gui.edit.data.endX-1 then gui.edit.data.curX = gui.edit.data.startX+(ev[3]-x) end
  end
  gpuFill(x,y,maxX,1," ")
  if useChar then
    if uniLen(gui.edit.buffer)+1 > maxX then gui.edit.dsplText = uni.sub(string.rep(gui.edit.arg.pwdchar,uniLen(gui.edit.buffer)), gui.edit.data.startX, gui.edit.data.endX-1) else gui.edit.dsplText = string.rep(gui.edit.arg.pwdchar,uniLen(gui.edit.buffer)) end
  else
    if uniLen(gui.edit.buffer)+1 > maxX then gui.edit.dsplText = uni.sub(gui.edit.buffer, gui.edit.data.startX, gui.edit.data.endX-1) else gui.edit.dsplText = gui.edit.buffer end
  end
  gpuSet(x,y,gui.edit.dsplText)
  gpuSet(x-1+gui.edit.data.curX-gui.edit.data.startX+2,y, editChar)
end

function gui.checkPress(event)
  if event[1] == "touch" and event[5] == 0 then
    local x, y = event[3], event[4]

    if x >= 1 and x <= fullW-15 and y >= fullH-2 and y <= fullH then
      local index = math.floor(x/gui.tabSize)+1
      gui.settop(gui.panel[index])
      return true
    end

    if gui.ontop == sys.current then
      if x >= fullW-1 and x <= fullW and y >= 1 and y <= 1 and gui.ontop and gui.panel[1] ~= gui.ontop then
        gui.close(gui.ontop.pid)
        return
      end
      local setEdit = false
      for _,i in pairs(gui.ontop.gui.elem) do
        if i.type == "button" and x >= i.x and x <= i.x+i.w and y >= i.y-1 and y <= i.y+i.h-1 then
          i.func()
        elseif i.type == "edit" and x >= i.x and x <= i.x+i.w and y >= i.y and y <= i.y then
          gui.edit = i
          gui.updateAppWindow()
          setEdit = true
        end
      end
      if not setEdit then gui.edit = nil end
    end
  end
if gui.ontop == sys.current and gui.edit then if onEdit(event) then gui.edit.func(); gui.edit = nil end end
end

function gui.read(x,y,maxX,arg)
  --[[
  pwdchar:char
  maxlen:num
  numonly:bool
  passwd:bool
  ]]
  local ch = "┃"--uni.char(9614)
  x = x or 1
  y = y or 1
  maxX = maxX or 25
  arg = arg or {}
  local useChar = false
  if arg.pwdchar then useChar = true arg.pwdchar = uni.sub(arg.pwdchar,1,1) end
  local input = ""
  local curX = uniLen(input)
  gpuSet(x,y,ch .. string.rep(" ",maxX-1))
  local startX, endX = 1,1
  local Control = false
  while true do
    gpuSB(gui.color.background())
    local r = {event.pull(-1,{ key_down=true,key_up=true,clipboard=true,touch=true}) }
    if r[1] == "key_down" and (r[4] == 29 or r[4] == 157) then
      Control = true
    elseif r[1] == "key_up" and (r[4] == 29 or r[4] == 157) then
        Control = false
    end
  	if r[1] == "key_down" then
        -- Return
      if r[3] == 13 then
  	    if useChar then
  	  	  if uniLen(input) > maxX then gpuSet(x,y,uni.sub(string.rep(arg.pwdchar,#input) .. " ", uniLen(input)+1-maxX)) else gpuSet(x,y,string.rep(arg.pwdchar,#input) .. " ") end
  	    else
  		  if uniLen(input) > maxX then gpuSet(x,y,uni.sub(input .. " ", uniLen(input)+1-maxX)) else gpuSet(x,y,input .. " ") end
  	    end
  	    return input
        -- Backspace
  	  elseif r[4] == 14 then
  	    if curX > 0 then
  	      if curX ~= uniLen(input) then
  	        input = uni.sub(input, 1, curX-1) .. uni.sub(input, curX+1)
  	      else
  	        input = uni.sub(input, 1, -2)
  	      end
  	      curX = curX - 1
  		  endX = uniLen(input)
  	      if startX > 1 then startX = startX - 1;endX = uniLen(input) + 1 end
  	    end
  	  -- Delete
  	  elseif r[4] == 211 then
  	    if curX < uniLen(input) then
  	      if curX ~= 0 then
  	        input = uni.sub(input, 1, curX) .. uni.sub(input, curX+2)
  	      else
  	        input = uni.sub(input, 2)
  	      end
  		  if uniLen(input) < maxX then endX = endX - 1 end
  	    end
  	  -- Home
  	  elseif r[4] == 199 then
  	    curX = 0
  	    startX = 1
  	    if endX > maxX then endX = maxX end
  	  -- End
  	  elseif r[4] == 207 then
  	    curX = uniLen(input)
  	    endX = uniLen(input)
  	    if uniLen(input) > maxX then startX = endX - maxX + 1 end
  	    if startX > 1 then endX = uniLen(input) + 1 end
  	  -- Arows
  	  elseif r[4] == 203 then
  	    if curX > 0 then
  	      curX = curX - 1
  		  if curX < startX-1 then startX = startX - 1; endX = endX - 1 end
  	    end
  	  elseif r[4] == 205 then
  	    if curX < uniLen(input) then curX = curX + 1 end 
  	    if curX > endX then if uniLen(input) > maxX then startX = startX + 1 end endX = endX + 1 end
  	  elseif r[3] == 0 then
  	  elseif not Control then
  	    if uniLen(input) >= (arg.maxlen or 32) and arg.maxlen ~= nil then goto skip end
  		  local char = uni.char(r[3])
  		  if r[4] == 15 then char = "  " end
  		  input = uni.sub(input,1,curX) .. char .. uni.sub(input,curX+1)
  		  curX = curX + 1
  		  if r[4] == 15 then curX = curX + 1 end
  		  endX = uniLen(input)
  		  if uniLen(input) >= maxX then startX =  startX + 1 end
  		  if startX > 1 then endX = uniLen(input) + 1 end
  		  ::skip::
  	  end
      elseif r[1] == "clipboard" then
  	    local text = r[3]
  	    if arg.maxlen then text = text:sub(1,arg.maxlen - uniLen(input)) end
  	    input = uni.sub(input,1,curX) .. text .. uni.sub(input,curX+1)
  	    curX = curX + uniLen(text)
  	    endX = uniLen(input)
  	    if uniLen(input) >= maxX then startX = startX + uniLen(text) end
  	    if startX > 1 then endX = uniLen(input) + 1 end
  	elseif r[1] == "touch" then
  	  if x+startX-3+r[3] <= endX-startX+x and r[4] == y then curX = x+startX-3+r[3] end
  	end
  	gpuFill(x,y,maxX,1," ")
    if useChar then
      if uniLen(input)+1 > maxX then gpuSet(x,y,uni.sub(string.rep(arg.pwdchar,#input), startX, endX-1)) else gpuSet(x,y,string.rep(arg.pwdchar,#input)) end
    else
      if uniLen(input)+1 > maxX then gpuSet(x,y,uni.sub(input, startX, endX-1)) else gpuSet(x,y,input) end
    end
    gpuSet(x-1+curX-startX+2,y, ch)
  end
end
-----------------------------------------------------------
function gui.mainloop()
  coroutine.yield("loop")
end

function gui.newWindow(name)
	if sys.current.gui then return sys.current.gui end
  sys.current.gui = {}
	if type(name) == "string" and name ~= "" then
		sys.current.gui.name = name
	else
		sys.current.gui.name = "App"
	end
	sys.current.gui.elem = {}
	sys.current.gui.elem.labels = {}
	sys.current.gui.elem.buttons = {}
	sys.current.gui.elem.planes = {}
	sys.current.gui.conf = {}

	sys.current.gui = setmetatable(sys.current.gui, {__index = draw})

  gui.panel[#gui.panel+1] = sys.current
  gui.settop(sys.current)  
	return sys.current.gui
end
function draw:config(id, param, value)
  if self.elem[id] and self.elem[id][param] then
    self.elem[id][param] = value
  end
end
function draw:get(id, param)
  if self.elem[id] and self.elem[id][param] then
    return self.elem[id][param]
  end
end
function draw:newLabel(x,y,w,bg,fg,text)
	self.elem[#self.elem+1] = {type="label",x=x,y=y,w=w,bg=(bg or gui.color.background()),fg=(fg or gui.color.foreground()),text=text}
  return #self.elem
end
function draw:newPlane(x,y,w,h,bg)
	self.elem[#self.elem+1] = {type="plane",x=x,y=y,bg=(bg or gui.color.background()),w=w,h=h}
  return #self.elem
end
function draw:newButton(x,y,w,h,bg,fg,text,func)
	self.elem[#self.elem+1] = {type="button",x=x,y=y,w=w,h=h,bg=(bg or gui.color.background()),fg=(fg or gui.color.text()),text=(text or "Button"),func=(func or function() end)}
  return #self.elem
end
function draw:newEdit(x,y,w,bg,fg,arg,func)
  self.elem[#self.elem+1] = {type="edit",x=x,y=y,w=w,bg=(bg or gui.color.background()),fg=(fg or gui.color.text()),buffer="",dsplText="",arg=(arg or {}),data={},func=(func or function() end)}
  return #self.elem
end
-----------------------------------------------------------
return gui
