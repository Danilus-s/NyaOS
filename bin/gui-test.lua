local gui = lib.get("gui")

local app = gui.newWindow("Test - $USER")

--app:newButton(5,5,10,3,gui.color.shadow(),gui.color.text(),"Hi!:)",te)

--app:newButton(20,5,10,3,gui.color.shadow(),gui.color.text(),"Exit",os.close)

local x,y,w,h = gui.getViewport()

app:newPlane(x,y,w,h,0x454545)

local function beep()
 computer.beep()
end

local get1 = app:newEdit(2,5,25)
local get2 = app:newEdit(30,5,25,nil,nil,nil,beep)


local lab = app:newLabel(5,17,30,nil,gui.color.text(),"*.*")

local function te()
  os.log("gui-test.lua", tostring(app) .. ", " .. (app.elem[get1].buffer or "X"))
  app.elem[lab].text = app.elem[get1].buffer
  gui.updateAppWindow()
end

app:newButton(5,10,10,3,gui.color.shadow(),gui.color.text(),"Get",te)

gui.updateAppWindow()

gui.mainloop()
