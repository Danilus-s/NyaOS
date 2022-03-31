local shell = {}
  
function shell.expand(text)
  while true do
    local f1,f2 = string.find(text, "%$%u+")
    if f1 then
      text = text:sub(1,f1-1) .. (os.getenv(text:sub(f1+1,f2)) or "") .. text:sub(f2+1)
    else
      break
    end
  end
  return text
end

return shell
