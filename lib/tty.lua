local tty = {}

local sys = lib.get("system")
local uni = lib.get("unicode")
local gpu = component.proxy(component.list("gpu")())

tty.ttys = {}

local stream = {}

function stream.write(text)
	sys.current.tty.buffer = sys.current.tty.buffer .. text
	local t = sys.current.tty
  if not t then return end
  local iter = 1
  for i=1, uni.len(text) do
  	if iter > uni.len(text) then break end
	  if text:sub(iter,iter) == "\27" then
	    local tmp = text:sub(iter+1,iter+1)
	    if tmp == "[m" then gpu.setForeground(0xFFFFFF) gpu.setBackground(0x000000) iter = iter + 3
	    elseif tmp == "[31m" then gpu.setForeground(0xFF0000) iter = iter + 5
	    elseif tmp == "[32m" then gpu.setForeground(0x00FF00) iter = iter + 5
	    elseif tmp == "[33m" then gpu.setForeground(0x0000FF) iter = iter + 5
	    end
	    goto skip
	  elseif text:sub(iter,iter) == "\n" then
      iter = iter + 1
      t.cursorx = 1
      if t.cursory < t.viewport.h then
        t.cursory = t.cursory + 1
      else
        gpu.copy(1,2,w,h-1,0,-1)
        gpu.fill(1,h,w,1," ")
      end
      goto skip
    elseif text:sub(iter,iter) == "\r" then
      iter = iter + 1
      t.cursorx = 1
      goto skip
    end
	  local char = text:sub(iter,iter)
	  if t.cursorx > t.viewport.w then
	  	t.cursorx = 1
	  	if t.cursory < t.viewport.h then
	  		t.cursory = t.cursory + 1
	  	else
	  		gpu.copy(1,2,w,h-1,0,-1)
	  		gpu.fill(1,h,w,1," ")
	  	end
	  end
	  gpu.set(t.cursorx,t.cursory,char)
	  t.cursorx = t.cursorx+1
	  iter = iter + 1
	  ::skip::
	end
end

local function read()
	local buffer = ""
  local ev = sys.current.G.event
  local t = sys.current.tty
  local pos = 0
  while true do
    local r = {ev.pull(-1, {key_down=true,clipboard=true})}
    if r and r[1] == 'key_down' then
      -- Return
      if r[3] == 13 then
        --gpu.set(cursorx,cursory,buffer)
        t.cursory = t.cursory+1
        --table.insert(hist, 1, buffer)
        return buffer
      -- Backspace
      elseif r[4] == 14 then
        if buffer:len() > 0 and pos > 0 then
          buffer = buffer:sub(1,pos-1) .. buffer:sub(pos+1)
          pos = pos - 1
        end
      -- Delete
      elseif r[4] == 211 then
        if pos < uni.len(buffer) then
          buffer = buffer:sub(1,pos) .. buffer:sub(pos+2)
          
        end
      -- Left
      elseif r[4] == 203 then
        if  pos > 0 then
          pos = pos - 1
        end
      -- Right
      elseif r[4] == 205 then
        if pos < uni.len(buffer) then
          pos = pos + 1
        end
      -- Up
      --[[elseif r[4] == 200 then
        if  histPos < #hist then
          if histPos == 0 then
            curText = buffer
          end
          histPos = histPos + 1
          buffer = hist[histPos]
          pos = #buffer
        end
      -- Down
      elseif r[4] == 208 then
        if  histPos > 0 then
          histPos = histPos - 1
          if histPos == 0 then
            buffer = curText
          else
            buffer = hist[histPos]
          end
          pos = #buffer
        end]]
      elseif r[3] ~= 0 then
        buffer = buffer:sub(1,pos) .. unicode.char(r[3]) .. buffer:sub(pos+1)
        pos = pos + 1
      end
      gpu.fill(1,line,w,1,' ')
      gpu.set(1,line,(text or '') .. buffer:sub(1,pos) .. '┃' .. buffer:sub(pos+1))
    elseif r and r[1] == "clipboard" then 
      buffer = buffer:sub(1,pos) .. r[3] .. buffer:sub(pos+1)
      pos = pos + #r[3]
    end
  end
end

function tty.new()
	local w,h = gpu.getResolution()
	tty.ttys["tty"..#tty.ttys+1] = {cursorx=1,cursory=1,hist={},stdout=stream,stdin=stream,buffer="",viewport={x=2,y=1,w=w,h=h-3}}
	sys.current.tty = {}
	sys.current.tty = tty.ttys["tty"..#tty.ttys]
	return "tty"..#tty.ttys
end

--[[function tty.read()
	local t = sys.current.tty
	if not t then return nil, "tty not found."
  local histPos = 0
  local buffer = ''
  local curText = ""
  local w,h = gpu.getResolution()
  gpu.set(cursorx,cursory,'┃')
  while true do
    local r = {computer.pullSignal(1)}
  	if r and r[1] == 'key_down' then
      -- Return
      if r[3] == 13 then
        --gpu.set(cursorx,cursory,buffer)
        t.cursory = t.cursory+1
        table.insert(hist, 1, buffer)
        return buffer
      -- Backspace
      elseif r[4] == 14 then
        if buffer:len() > 0 and pos > 0 then
          buffer =buffer:sub(1,pos-1) .. buffer:sub(pos+1)
          pos = pos - 1
        end
      -- Delete
      elseif r[4] == 211 then
        if pos < #buffer then
          buffer =buffer:sub(1,pos) .. buffer:sub(pos+2)
        	
        end
      -- Left
      elseif r[4] == 203 then
        if  pos > 0 then
          pos = pos - 1
        end
      -- Right
      elseif r[4] == 205 then
        if pos < #buffer then
          pos = pos + 1
        end
      -- Up
      elseif r[4] == 200 then
        if  histPos < #hist then
          if histPos == 0 then
            curText = buffer
          end
          histPos = histPos + 1
          buffer = hist[histPos]
          pos = #buffer
        end
      -- Down
      elseif r[4] == 208 then
        if  histPos > 0 then
          histPos = histPos - 1
          if histPos == 0 then
            buffer = curText
          else
            buffer = hist[histPos]
          end
          pos = #buffer
        end
      elseif r[3] ~= 0 then
        buffer = buffer:sub(1,pos) .. unicode.char(r[3]) .. buffer:sub(pos+1)
        pos = pos + 1
      end
      gpu.fill(1,line,w,1,' ')
      gpu.set(1,line,(text or '') .. buffer:sub(1,pos) .. '┃' .. buffer:sub(pos+1))
    elseif r and r[1] == "clipboard" then 
      buffer = buffer:sub(1,pos) .. r[3] .. buffer:sub(pos+1)
      pos = pos + #r[3]
    end
    --gpu.set(1,1,pos .. "                                      ")
  end
end]]

return tty
