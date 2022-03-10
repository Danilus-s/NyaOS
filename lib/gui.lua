local gui = {}

local gpu = lib.get("component").gpu
local uni = lib.get("unicode")
local event = lib.get("event")
local sys = lib.get("system")

local draw = {}
gui.draw = {}
gui.color = {}


local fullW, fullH = gpu.getResolution()
-----------------------------------------------------------
function gui.color.background() return 0xDD80CC end
function gui.color.shadow() return 0xC364C5 end
function gui.color.foreground() return 0x414141 end
function gui.color.text() return 0x414141 end
-----------------------------------------------------------

function gui.updateMainScreen()
	gpu.setBackground(0x000000)
  gpu.fill(1,1,fullW,fullH," ")

  gpu.setBackground(gui.color.background())
  gpu.fill(1,fullH-2,fullW,3," ")
  gpu.fill(1,1,fullW,1," ")

  gpu.setForeground(gui.color.text())
  gpu.set(2,1,sys.current.conf.name)
end

function gui.draw.rectangle(x,y,w,h,BColor)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, w, "number")
  checkArg(4, h, "number")
  checkArg(5, BColor, "number")
  local oldCol = gpu.getBackground()
  gpu.setBackground(BColor)
  gpu.fill(x,y,w,h, " ")
  gpu.setBackground(oldCol)
end

function gui.read(ev,x,y,maxX,arg)
  --[[
  pwdchar:char
  maxlen:num
  numonly:bool
  passwd:bool
  ]]
	if type(ev) ~= "table" then return nil, "ev must be a table" end
  local ch = "┃"--uni.char(9614)
  x = x or 1
  y = y or 1
  maxX = maxX or 25
  arg = arg or {}
  local useChar = false
  if arg.pwdchar then useChar = true arg.pwdchar = unicode.sub(arg.pwdchar,1,1) end
  local input = ""
  local curX = uni.len(input)
  gpu.set(x,y,ch .. string.rep(" ",maxX-1))
  local startX, endX = 1,1
  local Control = false
  while true do
    local r = {ev.pull(-1,{ key_down=true,key_up=true,clipboard=true,touch=true}) }
  if r[1] == "key_down" and (r[4] == 29 or r[4] == 157) then
    Control = true
  elseif r[1] == "key_up" and (r[4] == 29 or r[4] == 157) then
      Control = false
  end
	if r[1] == "key_down" then
      -- Return
    if r[3] == 13 then
	    if useChar then
	  	  if uni.len(input) > maxX then gpu.set(x,y,unicode.sub(string.rep(arg.pwdchar,#input) .. " ", uni.len(input)+1-maxX)) else gpu.set(x,y,string.rep(arg.pwdchar,#input) .. " ") end
	    else
		  if uni.len(input) > maxX then gpu.set(x,y,unicode.sub(input .. " ", uni.len(input)+1-maxX)) else gpu.set(x,y,input .. " ") end
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
    if uni.len(input)+1 > maxX then gpu.set(x,y,unicode.sub(string.rep(arg.pwdchar,#input), --[[uni.len(input)+1-maxX+1]] startX, endX-1)) else gpu.set(x,y,string.rep(arg.pwdchar,#input)) end
  else
    if uni.len(input)+1 > maxX then gpu.set(x,y,unicode.sub(input, --[[uni.len(input)+1-maxX+1]] startX, endX-1)) else gpu.set(x,y,input) end
  end
  --f curX >= endX - startX+1 then gpu.set(curX-startX+2,y, ch) else gpu.set(curX+1,y, ch) end
  gpu.set(x-1+curX-startX+2,y, ch)
  --gpu.set(x,y+1, "curX=" .. curX .. ", len="..uni.len(input)..", start="..startX..", end="..endX.."       ")
  end
end
-----------------------------------------------------------
function gui.newWindow(name)
	local app = {}
	if type(name) == "string" and name ~= "" then
		app.name = name
	else
		app.name = "App"
	end
	app.backgroundColor = gui.color.foreground()
	app.gui = {}

	app.gui.icon = {}
	app.gui.icon.text = app.name

	return setmetatable(app, {__index = draw})
end

function draw:newLabel(x,y,fg, text)
	self.gui[#self.gui+1] = {type = "label", x = x,y = y,fg = fg, text = text}
end
function draw:newButton(x,y,w,h,bg,fg,text,func)
	self.gui[#self.gui+1] = {type = "button", x = x, y = y, w = w, h = h, bg=bg, fg = fg, text = text, func = func}
end
-----------------------------------------------------------
return gui
