local users = {}

local gui = lib.get("gui")
local adv = lib.get("adv")
local fs = lib.get("filesystem")
local sha = lib.get("sha2")
local gpu = lib.get("component").gpu
local unicode = lib.get("unicode")
local w,h = gpu.getResolution()

users.gui = {}
users.defUser = {}

function users.readData()
  local f = fs.open("/etc/passwd")
  local dt = f.read()
  f.close()
  local entrys = adv.split(dt, "\n")
  local ret = {}
  for i=1,#entrys do 
    local spl = adv.split(entrys[i], ":")
    ret[spl[1]] = {}
    ret[spl[1]].perm = spl[2]
    ret[spl[1]].passwd = spl[3]
    ret[spl[1]].home = spl[4]
  end
  return ret
end

local function rectangle(x,y,w,h,bg)
  local old = gpu.getBackground()
  gpu.setBackground(bg)
  gpu.fill(x,y,w,h," ")
  gpu.setBackground(old)
end

function users.gui.reg()
  if fs.exists("/etc/passwd") then
    return
  end
  gpu.setBackground(0xDD80CC)
  gpu.fill(1,1,w,h," ")
  local mainText = "Initial setup"
  local text = "Root password"
  ::retRootPass::
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local rawRootPasswd = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16, ["pwdchar"]=unicode.char(0x002022)}), "[%p]?[%s]?", "")

  local text = "Retry root password"
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local retryRootPasswd = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16, ["pwdchar"]=unicode.char(0x002022)}), "[%p]?[%s]?", "")
  if retryRootPasswd == "" then goto retRootPass end
  if rawRootPasswd ~= retryRootPasswd then goto retRootPass end
  local rootPasswd = sha.sha3_256(rawRootPasswd)

  local text = "Username"
  ::retUserName::
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local usrn = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16}), "[%p]?[%s]?", "")
  if usrn == "" then goto retUserName end

  local text = "Password"
  ::retUserPass::
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local rawUserPasswd = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16, ["pwdchar"]=unicode.char(0x002022)}), "[%p]?[%s]?", "")
  if rawUserPasswd == "" then goto retUserPass end
  local userPasswd = sha.sha3_256(rawUserPasswd)

  local newEntry = "root:1:" .. rootPasswd .. ":/root\n" .. usrn .. ":2:" .. userPasswd .. ":/home/" .. usrn .. "\n"

  fs.makeDir("/etc")
  local f = fs.open("/etc/passwd", "w")
  f.write(newEntry)
  f.close()
  fs.makeDir("/home/")
  fs.makeDir("/home/" .. usrn)
  fs.makeDir("/home/" .. usrn .. "/Desktop")
end

function users.gui.login()
  local dt = users.readData()
  do 
    local sys = lib.get("system")
    --os.log("login", sys.conf["autologin"] .. ", " .. sys.conf["autologinusername"])
    --os.log("login", tostring(sys.conf["autologin"] == "true") .. ", " .. tostring(dt[sys.conf["autologinusername"]]))
    if sys.conf["autologin"] and sys.conf["autologinusername"] and dt[sys.conf["autologinusername"]] and sys.conf["autologin"] == "true" then
      local usrn = sys.conf["autologinusername"]
      users.defUser.userName = usrn
      users.defUser.passwd = dt[usrn].passwd
      users.defUser.perm = dt[usrn].perm
      users.defUser.home = dt[usrn].home
      return
    end
  end

  gpu.setBackground(0xDD80CC)
  gpu.fill(1,1,w,h, " ")
  local mainText = "Login"
  local text = "Username"
  ::retUserName::
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local usrn = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16}), "[%p]?[%s]?", "")
  if usrn == "" then goto retUserName end
  if not dt[usrn] then
    goto retUserName
  end

  local text = "Password"
  ::retUserPass::
  gpu.setBackground(0xC364C5)
  gpu.setForeground(0x414141)
  rectangle(w/2-15, h/2-3, 30, 6, 0xC364C5)
  gpu.set(w/2-#mainText/2, h/2-2, mainText)
  gpu.set(w/2-14, h/2, text)
  gpu.setBackground(0xDD80CC)
  rectangle(w/2-14, h/2+1, 28, 1, 0xDD80CC)
  local rawUserPasswd = string.gsub(gui.read(w/2-14, h/2+1, 28, {["maxlen"]=16, ["pwdchar"]=unicode.char(0x002022)}), "[%p]?[%s]?", "")
  if rawUserPasswd == "" then goto retUserPass end
  local userPasswd = sha.sha3_256(rawUserPasswd)
  if dt[usrn].passwd == userPasswd then
    users.defUser.userName = usrn
    users.defUser.passwd = dt[usrn].passwd
    users.defUser.perm = dt[usrn].perm
    users.defUser.home = dt[usrn].home
  else
    goto retUserPass
  end
  
end

return users
