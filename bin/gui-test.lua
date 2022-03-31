local gui = lib.get("gui")

local app = gui.newWindow("Test")

local function te()
  computer.beep(1000,0.1)
end

app:newButton(5,5,10,3,gui.color.shadow(),gui.color.text(),"Hi!:)",te)

app:newButton(20,5,10,3,gui.color.shadow(),gui.color.text(),"Exit",os.close)

gui.mainloop()
