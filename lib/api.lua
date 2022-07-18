local componen = {}

local loaded = { 

}

componen["gpu"] = component.proxy(component.list("gpu")())
componen["filesystem"] = component.proxy(computer.getBootAddress())



local function loadcom(path, component)
  --if module == "gui" then return nil, path .. ": block" end
  if component.invoke(computer.getBootAddress(), "exists", path) then
    local f = loadfile(path)
    local res, reas = pcall(f, component)
    if not res then
      return nil, reas
		elseif type(reas) == "table" then
      return reas
    else
			return nil, path ..": component returned nil or not table."
		end
  end
end

function componen.get(name)
	if loaded[name] then return loaded[name]
	else
		local res, reas = loadlib("/lib/components/" .. name .. ".lua", name)
	    if not res then
	      return nil, reas
	    else
	      loaded[name] = res
	      return loaded[name]
	    end
	end
end

return componen
