local io = {}

local adv = lib.get("adv")

local gpu = component.proxy(component.list("gpu")())
local line = 1

local function newLine()
  local w,h = gpu.getResolution()
  line = line + 1
  if line > h then
    line = h
    gpu.copy(1, 1, w, h, 0, -1, w, h)
    gpu.fill(1, h, w, 1, ' ')
  end
end

function io.print(...)
  local tbl = {...}
  local text = ''
  for _,i in pairs(tbl) do
    if text == '' then 
      text = tostring(i)
    else
      text = text .. ' ' .. tostring(i)
    end
  end
  local newText = adv.split(tostring(text), '\n')
  for _,i in pairs(newText) do
    local gtext = string.gsub(i,'\t', '   ')
    gpu.set(1,line,gtext)
    newLine()
  end
end
  
local history = {}
function io.read(text, hist)
  hist = hist or history
  local histPos = 0
  local buffer = ''
  local curText = ""
  local pos = 0
  local w = gpu.getResolution()
  gpu.set(1,line,(text or '') .. '┃')
  while true do
    local r = {computer.pullSignal(1)}
  if r and r[1] == 'key_down' then
      -- Return
      if r[3] == 13 then
        gpu.fill(1,line,w,1,' ')
        gpu.set(1,line,(text or '') .. buffer)
        newLine()
        table.insert(hist, 1, buffer)
        return buffer
      -- Backspace
      elseif r[4] == 14 then
        if buffer:len() > 0 and pos > 0 then
          buffer =buffer:sub(1,pos-1) .. buffer:sub(pos+1)
          pos = pos - 1
        end
      -- Delet
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
end

return io
