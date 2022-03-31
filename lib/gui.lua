local gui = {}

local gpu = lib.get("component").gpu
local uni = lib.get("unicode")
local event = lib.get("event")
local sh = lib.get("shell")
local sys = {}

local draw = {}
gui.color = {}
gui.ontop = {}
--gui.oldontop = {}
gui.panel = {}


local fullW, fullH = gpu.getResolution()
-----------------------------------------------------------
function gui.color.background() return 0xDD80CC end
function gui.color.shadow() return 0xC364C5 end
function gui.color.foreground() return 0x414141 end
function gui.color.text() return 0x414141 end
-----------------------------------------------------------

function gui.init()
  sys = lib.get("system")
end

function gui.updateAppWindow()
  if sys.current.gui then
    gpu.setBackground(0x000000)
    gpu.fill(1,2,fullW,fullH-4," ")
    if gui.panel[1] ~= gui.ontop then 
      gpu.setBackground(0xFF0000)
      gpu.fill(fullW-1,1,2,1," ")
    end
    for _,i in pairs(gui.ontop.gui.elem.planes) do
      local oldCol = gpu.getBackground()
      gpu.setBackground(i.bg)
      gpu.fill(i.x,i.y,i.w,i.h, " ")
      gpu.setBackground(oldCol)
    end

    for _,i in pairs(gui.ontop.gui.elem.labels) do
      local oldCol = gpu.getForeground()
      gpu.setForeground(i.bg)
      gpu.set(i.x,i.y,i.text)
      gpu.setForeground(oldCol)
    end

    for _,i in pairs(gui.ontop.gui.elem.buttons) do
      local oldColB = gpu.getBackground()
      local oldColF = gpu.getForeground()
      gpu.setForeground(i.fg)
      gpu.setBackground(i.bg)
      gpu.fill(i.x,i.y,i.w,i.h," ")
      gpu.set(i.x+(i.w/2-math.floor(uni.len(i.text:sub(1,i.w))/2)),i.y+(math.ceil(i.h/2))-1,i.text:sub(1,i.w))
      gpu.setForeground(oldColF)
      gpu.setBackground(oldColB)
    end
  end
end

function gui.updateMainScreen()
  gpu.setBackground(gui.color.background())
  gpu.fill(1,1,fullW,1," ")
  gpu.fill(1,fullH-2,fullW,3," ")
  gpu.setForeground(gui.color.text())
  gpu.set(2,1,sh.expand(sys.current.gui.name))

  --os.log("gui-update", "len elem: " .. #gui.panel)

  for i,b in pairs(gui.panel) do
    local x1,x2 = (15*i)-14,15*i
    --os.log("gui-update", "ID: " .. i .. " Pos: " .. x1 .. "x" .. x2)
    if gui.ontop == b then
      gpu.setBackground(gui.color.shadow())
    else
      gpu.setBackground(gui.color.background())
    end
    gpu.fill(x1,fullH-2,15,3," ")
    local nm = b.gui.name:sub(1,13)
    gpu.set(x1+1,fullH-1,nm)
  end
end

function gui.settop(process)
  --[[if gui.ontop ~= process then
    gui.oldontop = gui.ontop]]
    gui.ontop = process
    gui.updateMainScreen()
    gui.updateAppWindow()
  --end
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
  os.log("gui-close", sys.current.path .. " = " .. pid)
  if not sys.processes[pid] then return end
  for _,b in pairs(sys.processes[pid].child) do
    --os.log("gui-close", pid .. " > " .. b.pid)
    gui.close(b.pid)
  end
  local id = getPanelID(pid)
  if id then table.remove(gui.panel, id) end
  sys.processes[pid] = nil
  gui.settop(gui.panel[1])
  gui.updateMainScreen()
  gui.updateAppWindow()
end

function gui.checkPress(event)
	if event[1] == "touch" and event[5] == 0 then
		local x, y = event[3], event[4]
		if x >= fullW-1 and x <= fullW and y >= 1 and y <= 1 and gui.ontop and gui.panel[1] ~= gui.ontop then
      gui.close(gui.ontop.pid)
      return
    end
		
    for i,b in pairs(gui.panel) do
      local x1,x2 = (15*i)-14,15*i
      if x >= x1 and x <= x2 and y >= fullH-2 and y <= fullH then
        gui.settop(b)
        gui.updateMainScreen()
        gui.updateAppWindow()
      end
    end

		for _,i in pairs(gui.ontop.gui.elem.buttons) do
			if x >= i.x and x <= i.x+i.w and y >= i.y-1 and y <= i.y+i.h-1 then
				i.func()
			end
		end
	end
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
  local curX = uni.len(input)
  gpu.set(x,y,ch .. string.rep(" ",maxX-1))
  local startX, endX = 1,1
  local Control = false
  while true do
    gpu.setBackground(gui.color.background())
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
  	  	  if uni.len(input) > maxX then gpu.set(x,y,uni.sub(string.rep(arg.pwdchar,#input) .. " ", uni.len(input)+1-maxX)) else gpu.set(x,y,string.rep(arg.pwdchar,#input) .. " ") end
  	    else
  		  if uni.len(input) > maxX then gpu.set(x,y,uni.sub(input .. " ", uni.len(input)+1-maxX)) else gpu.set(x,y,input .. " ") end
  	    end
  	    return input
        -- Backspace
  	  elseif r[4] == 14 then
  	    if curX > 0 then
  	      if curX ~= uni.len(input) then
  	        input = uni.sub(input, 1, curX-1) .. uni.sub(input, curX+1)
  	      else
  	        input = uni.sub(input, 1, -2)
  	      end
  	      curX = curX - 1
  		  endX = uni.len(input)
  		  --if uni.len(input) <= maxX then endX = endX - 1 end
  	      if startX > 1 then startX = startX - 1;endX = uni.len(input) + 1 end
  	    end
  	  -- Delete
  	  elseif r[4] == 211 then
  	    if curX < uni.len(input) then
  	      if curX ~= 0 then
  	        input = uni.sub(input, 1, curX) .. uni.sub(input, curX+2)
  	      else
  	        input = uni.sub(input, 2)
  	      end
  		  if uni.len(input) < maxX then endX = endX - 1 end
  	    end
  	  -- Home
  	  elseif r[4] == 199 then
  	    curX = 0
  	    startX = 1
  	    if endX > maxX then endX = maxX end
  	  -- End
  	  elseif r[4] == 207 then
  	    curX = uni.len(input)
  	    endX = uni.len(input)
  	    if uni.len(input) > maxX then startX = endX - maxX + 1 end
  	    if startX > 1 then endX = uni.len(input) + 1 end
  	  -- Arows
  	  elseif r[4] == 203 then
  	    if curX > 0 then
  	      curX = curX - 1
  		  if curX < startX-1 then startX = startX - 1; endX = endX - 1 end
  	    end
  	  elseif r[4] == 205 then
  	    if curX < uni.len(input) then curX = curX + 1 end 
  	    if curX > endX then if uni.len(input) > maxX then startX = startX + 1 end endX = endX + 1 end
  	  elseif r[3] == 0 then
  	  elseif not Control then
  	    if uni.len(input) >= (arg.maxlen or 32) and arg.maxlen ~= nil then goto skip end
  		  local char = uni.char(r[3])
  		  if r[4] == 15 then char = "  " end
  		  input = uni.sub(input,1,curX) .. char .. uni.sub(input,curX+1)--gui.read(1,1,8)
  		  curX = curX + 1
  		  if r[4] == 15 then curX = curX + 1 end
  		  endX = uni.len(input)
  		  if uni.len(input) >= maxX then startX = --[[curX - maxX+2]] startX + 1 end
  		  if startX > 1 then endX = uni.len(input) + 1 end
  		  ::skip::
  	  end
      elseif r[1] == "clipboard" then
  	    local text = r[3]
  	    if arg.maxlen then text = text:sub(1,arg.maxlen - uni.len(input)) end
  	    input = uni.sub(input,1,curX) .. text .. uni.sub(input,curX+1)--gui.read(1,1,8)
  	    curX = curX + uni.len(text)
  	    endX = uni.len(input)
  	    if uni.len(input) >= maxX then startX = --[[curX - maxX+2]] startX + uni.len(text) end
  	    if startX > 1 then endX = uni.len(input) + 1 end
  	elseif r[1] == "touch" then
  	  if x+startX-3+r[3] <= endX-startX+x and r[4] == y then curX = x+startX-3+r[3] end
  	end
  	gpu.fill(x,y,maxX,1," ")
    if useChar then
      if uni.len(input)+1 > maxX then gpu.set(x,y,uni.sub(string.rep(arg.pwdchar,#input), --[[uni.len(input)+1-maxX+1]] startX, endX-1)) else gpu.set(x,y,string.rep(arg.pwdchar,#input)) end
    else
      if uni.len(input)+1 > maxX then gpu.set(x,y,uni.sub(input, --[[uni.len(input)+1-maxX+1]] startX, endX-1)) else gpu.set(x,y,input) end
    end
    --f curX >= endX - startX+1 then gpu.set(curX-startX+2,y, ch) else gpu.set(curX+1,y, ch) end
    gpu.set(x-1+curX-startX+2,y, ch)
    --gpu.set(x,y+1, "curX=" .. curX .. ", len="..uni.len(input)..", start="..startX..", end="..endX.."       ")
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

  gui.settop(sys.current)
  gui.panel[#gui.panel+1] = sys.current
  gui.updateMainScreen()
  gui.updateAppWindow()
	return sys.current.gui
end

function draw:newLabel(x,y,fg,text)
	self.elem.labels[#self.elem.labels+1] = {x=x,y=y,fg=(fg or gui.color.foreground()),text=text}
  gui.updateAppWindow()
end
function draw:newPlane(x,y,w,h,bg)
	self.elem.planes[#self.elem.planes+1] = {x=x,y=y,bg=(bg or gui.color.background()),w=w,h=h}
  gui.updateAppWindow()
end
function draw:newButton(x,y,w,h,bg,fg,text,func)
	self.elem.buttons[#self.elem.buttons+1] = {x=x,y=y,w=w,h=h,bg=(bg or gui.color.background()),fg=(fg or gui.color.text()),text=(text or "Button"),func=(func or function() end)}
  gui.updateAppWindow()
end
-----------------------------------------------------------
return gui
