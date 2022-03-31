local adv = {}

function adv.tblConcat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

function adv.split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function adv.trim(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function adv.duplicate(tab)
  local sec = {}
  local i,v = next(tab, nil)
  while i do
    if type(v) == "table" and i ~= "_G" then
      v = adv.duplicate(v)
    end
  	sec[i] = v
  	i,v = next(tab, i)
  end
  return sec
end

return adv
