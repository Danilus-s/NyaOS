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
  ["unicode"] = unicode,
  ["computer"] = computer,
  ["component"] = component
}

local syspath = {
  "/bin/sudo.lua",
  "/lib/users.lua"
}

local all_loadede = false

local function loadlib(path, module)
  --if module == "gui" then return nil, path .. ": block" end
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
  os.log("lib-load-call", "name: "..module)
  --os.log("lib-load", "load: "..tostring(loaded[module]))
  if loaded[module] then
    return loaded[module]
  else
    local res, reas = loadlib("/lib/" .. module .. ".lua", module)
    if not res then
      return nil, reas
    else
      loaded[module] = res
      return loaded[module]
    end
  end
end

function lib.getLoaded()
  return loaded
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
  os.log("lib-load", "--- start loading ---")
  local fs = component.proxy(computer.getBootAddress())
  local libList = fs.list("/lib")
  local name
  local count = 1
  local file = fs.open("/var/boot.log", "w")
  for _,i in pairs(libList) do
    count = count + 1
    if type(i) == "string" and i:sub(#i-3) == ".lua" then
      name = i:sub(1,#i-4)
      local text = name .. " > "
      local res, reas = loadlib("/lib/" .. i, name)
      if not res then
        text = text .. "error"
        fs.write(file, name .. ": " .. reas.. "\n" .. debug.traceback() .. "\n")
        os.log("lib-load", name .. ": not loaded.")
      else
        if not loaded[name] then
			   loaded[name] = res
         os.log("lib-load", name .. ": loaded as new.")
        else
          for a,b in pairs(res) do
            loaded[name][a] = b
          end
          os.log("lib-load", name .. ": loaded with overwrite.")
        end
        text = text .. "loaded"
      end
      func(text, 44/#libList*count)
    end
  end
  fs.close(file)
  do
    unicode = nil
  end
  all_loadede = true
end

return liblib
