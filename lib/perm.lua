local perm = {}

local io = lib.get("io")

local env = {}
local userData = {}

userData.username = ""
userData.perm = 1
userData.home = ""

function perm.setUser(username, perm, home)
  userData.home = home
  userData.perm = perm
  userData.home = home
end

function perm.setenv(name, var)
  checkArg(1, name, "string");
  checkArg(2, var, "string", "number");
  env[name] = var
end

function perm.getenv(name)
  if env[name] then return env[name] end
end

return perm
