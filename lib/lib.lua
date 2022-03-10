lib = {}
local liblib = {}

local loaded = {
  ["_G"] = _G,
  ["bit32"] = bit32,
  ["coroutine"] = coroutine,
  ["math"] = math,
  ["os"] = os,
  ["lib"] = lib,
  ["string"] = string,
  ["table"] = table,
  ["unicode"] = unicode
}

local syspath = {
  "/bin/sudo.lua",
  "/lib/users.lua"
}

local function loadlib(path, module)
  if component.invoke(computer.getBootAddress(), "exists", path) then
    local f = loadfile(path)
    local res, reas = pcall(f, module)
    if not res then
      return nil, reas
		elseif type(reas) == "table" then
      return reas
    else
			return nil, path ..": lib returned nil or not table."
		end
  end
end

function lib.get(module)
  checkArg(1, module, "string")
  --os.log("lib-load", "name: "..module)
  --os.log("lib-load", "load: "..tostring(loaded[module]))
  if loaded[module] then
    return loaded[module]
  else
    local res, reas = loadlib("/lib/" .. module .. ".lua", module)
    --os.log("lib-load", "res: "..(tostring(res) or "-"))
    --os.log("lib-load", "reas: "..(reas or "-"))
    if not res then
      return nil, reas
    else
      loaded[module] = res
      return loaded[module]
    end
  end
end

function lib.load(module, path)
  checkArg(1, module, "string");
  path = path or ""
  if path:sub(#path) == "/" then
    path = path:sub(1, #path-1)
  end
  path = path .. "/" .. module .. ".lua"
  return loadlib(path, module)
end

function liblib.init(func)
  local fs = component.proxy(computer.getBootAddress())
  local libList = fs.list("/lib")
  local name
  local count = 1
  local file = fs.open("/var/boot.log", "w")
  for _,i in pairs(libList) do
    count = count + 1
    if type(i) == "string" and loaded[i:sub(1,#i-4)] == nil and i:sub(#i-3) == ".lua" then
      name = i:sub(1,#i-4)
      local text = name .. " > "
      local res, reas = loadlib("/lib/" .. i, name)
      if not res then
        text = text .. "error"
        fs.write(file, name .. ": " .. reas.. "\n" .. debug.traceback() .. "\n")
      else
				loaded[name] = res
        text = text .. "loaded"
      end
      func(text, 44/#libList*count)
    end
  end
  fs.close(file)
  name = nil
end

return liblib
